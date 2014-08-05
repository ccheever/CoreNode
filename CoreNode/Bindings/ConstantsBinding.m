// Copyright 2014-present 650 Industries. All rights reserved.

#import "ConstantsBinding.h"

#import <sys/errno.h>
#import <sys/signal.h>
#import <sys/types.h>

#import "CNNativeBindingProtocol.h"

@implementation ConstantsBinding

- (JSValue *)exportsForContext:(JSContext *)context
{
    JSValue *exports = [JSValue valueWithNewObjectInContext:context];
    [self exportErrnoConstants:exports];
    [self exportSignalConstants:exports];
    [self exportSystemConstants:exports];
    return exports;
}

- (void)exportErrnoConstants:(JSValue *)exports
{
    // See <errno.h> for error codes
    exports[@"EPERM"] = @(EPERM);
    exports[@"ENOENT"] = @(ENOENT);
    exports[@"ESRCH"] = @(ESRCH);
    exports[@"EINTR"] = @(EINTR);
    exports[@"EIO"] = @(EIO);
    exports[@"ENXIO"] = @(ENXIO);
    exports[@"E2BIG"] = @(E2BIG);
    exports[@"ENOEXEC"] = @(ENOEXEC);
    exports[@"EBADF"] = @(EBADF);
    exports[@"ECHILD"] = @(ECHILD);
    exports[@"EDEADLK"] = @(EDEADLK);
    exports[@"ENOMEM"] = @(ENOMEM);
    exports[@"EACCES"] = @(EACCES);
    exports[@"EFAULT"] = @(EFAULT);
    exports[@"ENOTBLK"] = @(ENOTBLK);
    exports[@"EBUSY"] = @(EBUSY);
    exports[@"EEXIST"] = @(EEXIST);
    exports[@"EXDEV"] = @(EXDEV);
    exports[@"ENODEV"] = @(ENODEV);
    exports[@"ENOTDIR"] = @(ENOTDIR);
    exports[@"EISDIR"] = @(EISDIR);
    exports[@"EINVAL"] = @(EINVAL);
    exports[@"ENFILE"] = @(ENFILE);
    exports[@"EMFILE"] = @(EMFILE);
    exports[@"ENOTTY"] = @(ENOTTY);
    exports[@"ETXTBSY"] = @(ETXTBSY);
    exports[@"EFBIG"] = @(EFBIG);
    exports[@"ENOSPC"] = @(ENOSPC);
    exports[@"ESPIPE"] = @(ESPIPE);
    exports[@"EROFS"] = @(EROFS);
    exports[@"EMLINK"] = @(EMLINK);
    exports[@"EPIPE"] = @(EPIPE);
    exports[@"EDOM"] = @(EDOM);
    exports[@"ERANGE"] = @(ERANGE);
    exports[@"EAGAIN"] = @(EAGAIN);
    exports[@"EWOULDBLOCK"] = @(EWOULDBLOCK);
    exports[@"EINPROGRESS"] = @(EINPROGRESS);
    exports[@"EALREADY"] = @(EALREADY);
    exports[@"ENOTSOCK"] = @(ENOTSOCK);
    exports[@"EDESTADDRREQ"] = @(EDESTADDRREQ);
    exports[@"EMSGSIZE"] = @(EMSGSIZE);
    exports[@"EPROTOTYPE"] = @(EPROTOTYPE);
    exports[@"ENOPROTOOPT"] = @(ENOPROTOOPT);
    exports[@"EPROTONOSUPPORT"] = @(EPROTONOSUPPORT);
    exports[@"ESOCKTNOSUPPORT"] = @(ESOCKTNOSUPPORT);
    exports[@"ENOTSUP"] = @(ENOTSUP);
    exports[@"EOPNOTSUPP"] = @(EOPNOTSUPP);
    exports[@"EPFNOSUPPORT"] = @(EPFNOSUPPORT);
    exports[@"EAFNOSUPPORT"] = @(EAFNOSUPPORT);
    exports[@"EADDRINUSE"] = @(EADDRINUSE);
    exports[@"EADDRNOTAVAIL"] = @(EADDRNOTAVAIL);
    exports[@"ENETDOWN"] = @(ENETDOWN);
    exports[@"ENETUNREACH"] = @(ENETUNREACH);
    exports[@"ENETRESET"] = @(ENETRESET);
    exports[@"ECONNABORTED"] = @(ECONNABORTED);
    exports[@"ECONNRESET"] = @(ECONNRESET);
    exports[@"ENOBUFS"] = @(ENOBUFS);
    exports[@"EISCONN"] = @(EISCONN);
    exports[@"ENOTCONN"] = @(ENOTCONN);
    exports[@"ESHUTDOWN"] = @(ESHUTDOWN);
    exports[@"ETOOMANYREFS"] = @(ETOOMANYREFS);
    exports[@"ETIMEDOUT"] = @(ETIMEDOUT);
    exports[@"ECONNREFUSED"] = @(ECONNREFUSED);
    exports[@"ELOOP"] = @(ELOOP);
    exports[@"ENAMETOOLONG"] = @(ENAMETOOLONG);
    exports[@"EHOSTDOWN"] = @(EHOSTDOWN);
    exports[@"EHOSTUNREACH"] = @(EHOSTUNREACH);
    exports[@"ENOTEMPTY"] = @(ENOTEMPTY);
    exports[@"EPROCLIM"] = @(EPROCLIM);
    exports[@"EUSERS"] = @(EUSERS);
    exports[@"EDQUOT"] = @(EDQUOT);
    exports[@"ESTALE"] = @(ESTALE);
    exports[@"EREMOTE"] = @(EREMOTE);
    exports[@"EBADRPC"] = @(EBADRPC);
    exports[@"ERPCMISMATCH"] = @(ERPCMISMATCH);
    exports[@"EPROGUNAVAIL"] = @(EPROGUNAVAIL);
    exports[@"EPROGMISMATCH"] = @(EPROGMISMATCH);
    exports[@"EPROCUNAVAIL"] = @(EPROCUNAVAIL);
    exports[@"ENOLCK"] = @(ENOLCK);
    exports[@"ENOSYS"] = @(ENOSYS);
    exports[@"EFTYPE"] = @(EFTYPE);
    exports[@"EAUTH"] = @(EAUTH);
    exports[@"ENEEDAUTH"] = @(ENEEDAUTH);
    exports[@"EPWROFF"] = @(EPWROFF);
    exports[@"EDEVERR"] = @(EDEVERR);
    exports[@"EOVERFLOW"] = @(EOVERFLOW);
    exports[@"EBADEXEC"] = @(EBADEXEC);
    exports[@"EBADARCH"] = @(EBADARCH);
    exports[@"ESHLIBVERS"] = @(ESHLIBVERS);
    exports[@"EBADMACHO"] = @(EBADMACHO);
    exports[@"ECANCELED"] = @(ECANCELED);
    exports[@"EIDRM"] = @(EIDRM);
    exports[@"ENOMSG"] = @(ENOMSG);
    exports[@"EILSEQ"] = @(EILSEQ);
    exports[@"ENOATTR"] = @(ENOATTR);
    exports[@"EBADMSG"] = @(EBADMSG);
    exports[@"EMULTIHOP"] = @(EMULTIHOP);
    exports[@"ENODATA"] = @(ENODATA);
    exports[@"ENOLINK"] = @(ENOLINK);
    exports[@"ENOSR"] = @(ENOSR);
    exports[@"ENOSTR"] = @(ENOSTR);
    exports[@"EPROTO"] = @(EPROTO);
    exports[@"ETIME"] = @(ETIME);
    exports[@"EOPNOTSUPP"] = @(EOPNOTSUPP);
    exports[@"ENOPOLICY"] = @(ENOPOLICY);
    exports[@"ENOTRECOVERABLE"] = @(ENOTRECOVERABLE);
    exports[@"EOWNERDEAD"] = @(EOWNERDEAD);
    exports[@"EQFULL"] = @(EQFULL);
    exports[@"ELAST"] = @(ELAST);
}

- (void)exportSignalConstants:(JSValue *)exports
{
    // See <signal.h> for process signals
    exports[@"SIGHUP"] = @(SIGHUP);
    exports[@"SIGINT"] = @(SIGINT);
    exports[@"SIGQUIT"] = @(SIGQUIT);
    exports[@"SIGILL"] = @(SIGILL);
    exports[@"SIGTRAP"] = @(SIGTRAP);
    exports[@"SIGABRT"] = @(SIGABRT);
    exports[@"SIGIOT"] = @(SIGIOT);
    exports[@"SIGEMT"] = @(SIGEMT);
    exports[@"SIGFPE"] = @(SIGFPE);
    exports[@"SIGKILL"] = @(SIGKILL);
    exports[@"SIGBUS"] = @(SIGBUS);
    exports[@"SIGSEGV"] = @(SIGSEGV);
    exports[@"SIGSYS"] = @(SIGSYS);
    exports[@"SIGPIPE"] = @(SIGPIPE);
    exports[@"SIGALRM"] = @(SIGALRM);
    exports[@"SIGTERM"] = @(SIGTERM);
    exports[@"SIGURG"] = @(SIGURG);
    exports[@"SIGSTOP"] = @(SIGSTOP);
    exports[@"SIGTSTP"] = @(SIGTSTP);
    exports[@"SIGCONT"] = @(SIGCONT);
    exports[@"SIGCHLD"] = @(SIGCHLD);
    exports[@"SIGTTIN"] = @(SIGTTIN);
    exports[@"SIGTTOU"] = @(SIGTTOU);
    exports[@"SIGIO"] = @(SIGIO);
    exports[@"SIGXCPU"] = @(SIGXCPU);
    exports[@"SIGXFSZ"] = @(SIGXFSZ);
    exports[@"SIGVTALRM"] = @(SIGVTALRM);
    exports[@"SIGPROF"] = @(SIGPROF);
    exports[@"SIGWINCH"] = @(SIGWINCH);
    exports[@"SIGINFO"] = @(SIGINFO);
    exports[@"SIGUSR1"] = @(SIGUSR1);
    exports[@"SIGUSR2"] = @(SIGUSR2);
}

- (void)exportSystemConstants:(JSValue *)exports
{
    // See <fnctl.h> for system flags
    exports[@"O_RDONLY"] = @(O_RDONLY);
    exports[@"O_WRONLY"] = @(O_WRONLY);
    exports[@"O_RDWR"] = @(O_RDWR);
    exports[@"O_ACCMODE"] = @(O_ACCMODE);

    exports[@"S_IFMT"] = @(S_IFMT);
    exports[@"S_IFIFO"] = @(S_IFIFO);
    exports[@"S_IFCHR"] = @(S_IFCHR);
    exports[@"S_IFDIR"] = @(S_IFDIR);
    exports[@"S_IFBLK"] = @(S_IFBLK);
    exports[@"S_IFREG"] = @(S_IFREG);
    exports[@"S_IFLNK"] = @(S_IFLNK);
    exports[@"S_IFSOCK"] = @(S_IFSOCK);
    exports[@"S_IFWHT"] = @(S_IFWHT);

    exports[@"O_NONBLOCK"] = @(O_NONBLOCK);
    exports[@"O_APPEND"] = @(O_APPEND);
    exports[@"O_SYNC"] = @(O_SYNC);
    exports[@"O_SHLOCK"] = @(O_SHLOCK);
    exports[@"O_EXLOCK"] = @(O_EXLOCK);
    exports[@"O_ASYNC"] = @(O_ASYNC);
    exports[@"O_FSYNC"] = @(O_FSYNC);
    exports[@"O_NOFOLLOW"] = @(O_NOFOLLOW);
    exports[@"O_CREAT"] = @(O_CREAT);
    exports[@"O_TRUNC"] = @(O_TRUNC);
    exports[@"O_EXCL"] = @(O_EXCL);
    exports[@"O_EVTONLY"] = @(O_EVTONLY);
    exports[@"O_NOCTTY"] = @(O_NOCTTY);
    exports[@"O_DIRECTORY"] = @(O_DIRECTORY);
    exports[@"O_SYMLINK"] = @(O_SYMLINK);
    exports[@"O_DSYNC"] = @(O_DSYNC);
    exports[@"O_CLOEXEC"] = @(O_CLOEXEC);
    exports[@"O_DP_GETRAWENCRYPTED"] = @(O_DP_GETRAWENCRYPTED);

    exports[@"S_IRWXU"] = @(S_IRWXU);
    exports[@"S_IRUSR"] = @(S_IRUSR);
    exports[@"S_IWUSR"] = @(S_IWUSR);
    exports[@"S_IXUSR"] = @(S_IXUSR);
    exports[@"S_IRWXG"] = @(S_IRWXG);
    exports[@"S_IRGRP"] = @(S_IRGRP);
    exports[@"S_IWGRP"] = @(S_IWGRP);
    exports[@"S_IXGRP"] = @(S_IXGRP);
    exports[@"S_IRWXO"] = @(S_IRWXO);
    exports[@"S_IROTH"] = @(S_IROTH);
    exports[@"S_IWOTH"] = @(S_IWOTH);
    exports[@"S_IXOTH"] = @(S_IXOTH);
    exports[@"S_ISUID"] = @(S_ISUID);
    exports[@"S_ISGID"] = @(S_ISGID);
    exports[@"S_ISVTX"] = @(S_ISVTX);
}

@end
