// Copyright (c) 2014-present 650 Industries, Inc. All rights reserved.

#import "OSBinding.h"

@import SystemConfiguration;

#import <ifaddrs.h>
#import <mach/mach.h>
#import <net/if.h>
#import <net/if_dl.h>
#import <netinet/in.h>
#import <netinet6/in6.h>
#import <sys/sysctl.h>
#import <sys/utsname.h>

#import "JSValue+Errors.h"


@implementation OSBinding

- (JSValue *)exportsForContext:(JSContext *)context
{
    // Explicitly create a JSValue rather than using the JavaScriptCore bridge since Node's os module doesn't invoke
    // the exported methods with the binding as "this"
    NSDictionary *exports = @{
        @"getEndianness": ^NSString *{
          return [self endianness];
        },
        @"getHostname": ^NSString *{
            return [self hostname];
        },
        @"getLoadAverage": ^NSArray *{
            return [self loadAverage];
        },
        @"uptime": ^NSNumber *{
            return [self uptime];
        },
        @"getFreeMemory": ^NSNumber *{
            return [self freeMemory];
        },
        @"getTotalMemory": ^NSNumber *{
            return [self totalMemory];
        },
        @"getCPUs": ^NSArray *{
            return [self CPUs];
        },
        @"getOSType": ^NSString *{
            return [self OSType];
        },
        @"getOSRelease": ^NSString *{
            return [self OSRelease];
        },
        @"getInterfaceAddresses": ^NSDictionary *{
            return [self interfaceAddresses];
        },
    };
    return [JSValue valueWithObject:exports inContext:context];
}

- (NSString *)endianness
{
    switch (NSHostByteOrder()) {
        case NS_LittleEndian:
            return @"LE";
        case NS_BigEndian:
            return @"BE";
        default:
            return @"Unknown";
    }
}

- (NSString *)hostname
{
    return [[NSProcessInfo processInfo] hostName];
}

- (NSArray *)loadAverage
{
    struct loadavg info;
    size_t size = sizeof(info);
    int which[] = {CTL_VM, VM_LOADAVG};
    if (sysctl(which, 2, &info, &size, NULL, 0) == -1) {
        JSContext *context = [JSContext currentContext];
        context.exception = [JSValue valueWithNewErrorFromSyscall:@"sysctl" errorCode:errno inContext:context];
        return nil;
    }

    NSUInteger count = 3;
    NSMutableArray *loadAverages = [NSMutableArray arrayWithCapacity:count];
    for (NSUInteger i = 0; i < count; i++) {
        double loadAverage = (double)info.ldavg[i] / info.fscale;
        [loadAverages addObject:@(loadAverage)];
    }
    return loadAverages;
}

- (NSNumber *)uptime
{
    return @([[NSProcessInfo processInfo] systemUptime]);
}

- (NSNumber *)freeMemory
{
    vm_statistics_data_t info;
    mach_msg_type_number_t count = sizeof(info) / sizeof(integer_t);
    kern_return_t status = host_statistics(mach_host_self(), HOST_VM_INFO, (host_info_t)&info, &count);

    if (status != KERN_SUCCESS) {
        JSContext *context = [JSContext currentContext];
        NSString *message = [NSString stringWithFormat:@"Error measuring free memory (%d)", (int)status];
        context.exception = [JSValue valueWithNewErrorFromMessage:message inContext:context];
        return 0;
    }

    return @(info.free_count * sysconf(_SC_PAGESIZE));
}

- (NSNumber *)totalMemory
{
    return @([[NSProcessInfo processInfo] physicalMemory]);
}

- (NSArray *)CPUs
{
    char model[512];
    size_t size = sizeof(model);
    if (sysctlbyname("machdep.cpu.brand_string", &model, &size, NULL, 0) &&
        sysctlbyname("hw.model", &model, &size, NULL, 0)) {
        JSContext *context = [JSContext currentContext];
        context.exception = [JSValue valueWithNewErrorFromSyscall:@"sysctlbyname" errorCode:errno inContext:context];
        return nil;
    }

    uint64_t frequency;
    size = sizeof(frequency);
    if (sysctlbyname("hw.cpufrequency", &frequency, &size, NULL, 0)) {
        JSContext *context = [JSContext currentContext];
        context.exception = [JSValue valueWithNewErrorFromSyscall:@"sysctlbyname" errorCode:errno inContext:context];
        return nil;
    }

    natural_t count;
    processor_cpu_load_info_t loadInfo;
    mach_msg_type_number_t infoSize;
    kern_return_t status = host_processor_info(mach_host_self(), PROCESSOR_CPU_LOAD_INFO, &count, (processor_info_array_t *)&loadInfo, &infoSize);
    if (status != KERN_SUCCESS) {
        JSContext *context = [JSContext currentContext];
        NSString *message = [NSString stringWithFormat:@"Error getting processor info (%d)", (int)status];
        context.exception = [JSValue valueWithNewErrorFromMessage:message inContext:context];
        return nil;
    }

    long multiplier = 1000L / sysconf(_SC_CLK_TCK);
    NSMutableArray *cpuInfoArray = [NSMutableArray arrayWithCapacity:count];
    for (NSUInteger i = 0; i < count; i++) {
        NSDictionary *cpuInfo = @{
            @"model": [NSString stringWithUTF8String:model],
            @"speed": @(frequency / 1000000),
            @"times": @{
                @"user": @(loadInfo[i].cpu_ticks[CPU_STATE_USER] * multiplier),
                @"sys" : @(loadInfo[i].cpu_ticks[CPU_STATE_SYSTEM] * multiplier),
                @"idle": @(loadInfo[i].cpu_ticks[CPU_STATE_IDLE] * multiplier),
                @"nice": @(loadInfo[i].cpu_ticks[CPU_STATE_NICE] * multiplier),
                @"irq" : @(0),
            },
        };
        [cpuInfoArray addObject:cpuInfo];
    }
    vm_deallocate(mach_task_self(), (vm_address_t)loadInfo, infoSize);
    
    return cpuInfoArray;
}

- (NSString *)OSType
{
    struct utsname info;
    if (uname(&info) == -1) {
        JSContext *context = [JSContext currentContext];
        context.exception = [JSValue valueWithNewErrorFromSyscall:@"uname" errorCode:errno inContext:context];
        return nil;
    }
    return [NSString stringWithUTF8String:info.sysname];
}

- (NSString *)OSRelease
{
    struct utsname info;
    if (uname(&info) == -1) {
        JSContext *context = [JSContext currentContext];
        context.exception = [JSValue valueWithNewErrorFromSyscall:@"uname" errorCode:errno inContext:context];
        return nil;
    }
    return [NSString stringWithUTF8String:info.release];
}

- (NSDictionary *)interfaceAddresses
{
    struct ifaddrs *interfaces;
    if (getifaddrs(&interfaces) == -1) {
        JSContext *context = [JSContext currentContext];
        context.exception = [JSValue valueWithNewErrorFromSyscall:@"getifaddrs" errorCode:errno inContext:context];
        return nil;
    }


    NSMutableDictionary *macAddresses = [NSMutableDictionary dictionary];
    NSMutableDictionary *interfaceAddresses = [NSMutableDictionary dictionary];
    for (struct ifaddrs *interface = interfaces; interface != NULL; interface = interface->ifa_next) {
        if (!(interface->ifa_flags & IFF_UP) || !(interface->ifa_flags & IFF_RUNNING) || !interface->ifa_addr) {
            continue;
        }

        NSString *interfaceName = [NSString stringWithUTF8String:interface->ifa_name];
        sa_family_t family = interface->ifa_addr->sa_family;
        if (family == AF_LINK) {
            caddr_t physicalAddress = LLADDR((struct sockaddr_dl *)interface->ifa_addr);
            macAddresses[interfaceName] = [self macAddressStringFromBytes:physicalAddress];
            continue;
        }

        NSMutableDictionary *interfaceAddress = [self dictionaryWithInterfaceAddress:interface];
        if (interfaceAddresses[interfaceName]) {
            [interfaceAddresses[interfaceName] addObject:interfaceAddress];
        } else {
            interfaceAddresses[interfaceName] = [NSMutableArray arrayWithObject:interfaceAddress];
        }
    }

    for (NSString *interfaceName in interfaceAddresses) {
        NSString *macAddress = macAddresses[interfaceName] ? macAddresses[interfaceName] : @"00:00:00:00:00:00";
        for (NSMutableDictionary *interfaceAddress in interfaceAddresses[interfaceName]) {
            interfaceAddress[@"mac"] = macAddress;
        }
    }

    freeifaddrs(interfaces);
    return interfaceAddresses;
}

- (NSMutableDictionary *)dictionaryWithInterfaceAddress:(struct ifaddrs *)interface
{
    NSString *ip;
    NSString *netmask;
    NSString *family;

    struct sockaddr *address = interface->ifa_addr;
    if (address->sa_family == AF_INET) {
        ip = [self ipv4AddressStringFromBytes:&((struct sockaddr_in *)address)->sin_addr];
        netmask = [self ipv4AddressStringFromBytes:&((struct sockaddr_in *)interface->ifa_netmask)->sin_addr];
        family = @"IPv4";
    } else if (address->sa_family == AF_INET6) {
        ip = [self ipv6AddressStringFromBytes:&((struct sockaddr_in6 *)address)->sin6_addr];
        netmask = [self ipv6AddressStringFromBytes:&((struct sockaddr_in6 *)interface->ifa_netmask)->sin6_addr];
        family = @"IPv6";
    } else {
        ip = @"<unknown socket address family>";
        netmask = @"";
        family = @"<unknown>";
    }

    NSMutableDictionary *interfaceAddress = [NSMutableDictionary dictionary];
    interfaceAddress[@"address"] = ip;
    interfaceAddress[@"netmask"] = netmask;
    interfaceAddress[@"family"] = family;
    interfaceAddress[@"internal"] = (interface->ifa_flags & IFF_LOOPBACK) ? @(YES) : @(NO);
    return interfaceAddress;
}

- (NSString *)ipv4AddressStringFromBytes:(struct in_addr *)address
{
    uint8_t *bytes = (uint8_t *)&address->s_addr;
    return [NSString stringWithFormat:@"%u.%u.%u.%u", bytes[0], bytes[1], bytes[2], bytes[3]];
}

- (NSString *)ipv6AddressStringFromBytes:(struct in6_addr *)address
{
    uint16_t *groups = (uint16_t *)&address->s6_addr;
    NSMutableString *ipAddress = [NSMutableString stringWithFormat:@"%x:%x:%x:%x:%x:%x:%x:%x",
                                  htons(groups[0]), htons(groups[1]), htons(groups[2]), htons(groups[3]),
                                  htons(groups[4]), htons(groups[5]), htons(groups[6]), htons(groups[7])];

    // Compress the largest run of zero groups
    NSError *error = nil;
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"(^|:)(0(:|$))+" options:0 error:&error];
    if (error) {
        NSLog(@"Error compiling IPv6 regular expression: %@", [error localizedDescription]);
        return ipAddress;
    }

    NSArray *matches = [regex matchesInString:ipAddress options:0 range:NSMakeRange(0, [ipAddress length])];
    NSTextCheckingResult *longestMatch = nil;
    for (NSTextCheckingResult *match in matches) {
        if (!longestMatch || longestMatch.range.length < match.range.length) {
            longestMatch = match;
        }
    }

    if (longestMatch) {
        [ipAddress replaceCharactersInRange:longestMatch.range withString:@"::"];
    }
    return ipAddress;
}

- (NSString *)macAddressStringFromBytes:(caddr_t)address
{
    uint8_t *bytes = (uint8_t *)address;
    return [NSString stringWithFormat:@"%02x:%02x:%02x:%02x:%02x:%02x",
            bytes[0], bytes[1], bytes[2], bytes[3], bytes[4], bytes[5]];
}

@end
