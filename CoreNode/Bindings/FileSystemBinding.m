// Copyright 2014-present 650 Industries. All rights reserved.

#import "FileSystemBinding.h"

#import <dirent.h>
#import <fcntl.h>
#import <sys/stat.h>
#import <sys/time.h>
#import <sys/types.h>
#import <unistd.h>

#import "CNRuntime.h"
#import "CNRuntime_Internal.h"
#import "JSContext+Runtime.h"
#import "JSValue+Errors.h"


@interface FileSystemBinding ()

@property (strong, nonatomic) JSValue *statsConstructor;

@end


@implementation FileSystemBinding {
    __weak CNRuntime *_runtime;
    JSManagedValue *_statsConstructor;

    NSDictionary *_nativeExports;
}

- (instancetype)initWithRuntime:(CNRuntime *)runtime
{
    if (self = [super init]) {
        _runtime = runtime;
    }
    return self;
}

- (JSValue *)statsConstructor
{
    return [_statsConstructor value];
}

- (void)setStatsConstructor:(JSValue *)statsConstructor
{
    JSContext *context = statsConstructor.context;
    _statsConstructor = [JSManagedValue managedValueWithValue:statsConstructor];
    [context.virtualMachine addManagedReference:_statsConstructor withOwner:_nativeExports];
}

#pragma mark - Bindings

- (JSValue *)exportsForContext:(JSContext *)context
{
    __weak FileSystemBinding *weakSelf = self;
    _nativeExports =
    @{
      @"DDLog": ^(NSString *m) {
          DDLogInfo(@"fs bindings: %@", m);
      },
      @"FSInitialize": ^(JSValue *statsConstructor) {
          [weakSelf FSInitialize:statsConstructor];
      },
      @"_stat_sync": ^JSValue *(JSValue *path) {
        // https://github.com/joyent/node/blob/76b98462e589a69d9fd48ccb9fb5f6e96b539715/src/node_file.cc#L397
        struct stat s;
        int err = stat([[path toString] UTF8String], &s);
        if (err) {
            context.exception = [JSValue valueWithObject:[NSString stringWithFormat:@"Error (%d) stat-ing file", errno] inContext:context];
            return nil;
        } else {
            return [self jsValueForStatStruct:&s inContext:context];
        }
      },
      @"_stat_async": ^JSValue *(JSValue *path, JSValue *callback) {
          dispatch_async(_runtime.ioQueue, ^{
              struct stat *s = malloc(sizeof(struct stat));
              int err = stat([[path toString] UTF8String], s);

              dispatch_async(_runtime.jsQueue, ^{

                  JSValue *errJs;
                  JSValue *resultJs;
                  
                  if (err) {
                      errJs = [JSValue valueWithObject:[NSString stringWithFormat:@"Error (%d) stat-ing file", errno] inContext:context];
                      resultJs = [JSValue valueWithNullInContext:context];
                  } else {
                      errJs = [JSValue valueWithNullInContext:context];
                      resultJs = [self jsValueForStatStruct:s inContext:context];
                  }
                  free(s);

                  // TODO: Switch all the callback invocations in `fs` to use the CNRuntime callback mechanism
                  [CNRuntime invokeCallbackFunction:callback withArguments:@[errJs, resultJs]];
              });
          });
          
          // TODO: Return the { domain: null, oncomplete: [Function] } object that Node does
          // once we figure out exactly what it is
          return [self asyncReturnObject];
      },
      @"_fstat_sync": ^JSValue *(JSValue *fd) {
          // https://github.com/joyent/node/blob/76b98462e589a69d9fd48ccb9fb5f6e96b539715/src/node_file.cc#L435
          struct stat s;
          int err = fstat([fd toInt32], &s);
          if (err) {
              context.exception = [JSValue valueWithObject:[NSString stringWithFormat:@"Error (%d) fstat-ing file", errno] inContext:context];
              return nil;
          } else {
              return [self jsValueForStatStruct:&s inContext:context];
          }
      },
      @"_fstat_async": ^JSValue *(JSValue *fd, JSValue *callback) {
          dispatch_async(_runtime.ioQueue, ^{
              
              struct stat *s = malloc(sizeof(struct stat));
              int err = fstat([fd toInt32], s);
              
              dispatch_async(_runtime.jsQueue, ^{
                  
                  JSValue *errJs;
                  JSValue *resultJs;
                  if (err) {
                      errJs = [JSValue valueWithObject:[NSString stringWithFormat:@"Error (%d) fstat-ing file", errno] inContext:context];
                      resultJs = [JSValue valueWithNullInContext:context];
                  } else {
                      errJs = [JSValue valueWithNullInContext:context];
                      resultJs = [self jsValueForStatStruct:s inContext:context];
                  }
                  free(s);
                  
                  [callback callWithArguments:@[errJs, resultJs]];
              });
          });
          // TODO: Figure out what that return object is here
          return  [self asyncReturnObject];
      },
      @"_open_sync": ^JSValue *(JSValue *path, JSValue *flags, JSValue *mode) {
          // https://github.com/joyent/node/blob/76b98462e589a69d9fd48ccb9fb5f6e96b539715/src/node_file.cc#L691
          // #include <fcntl.h>
          // int open(const char *path, int oflag, . . .);
          int fd = open([[path toString] UTF8String], [flags toUInt32], [mode toUInt32]);
          if (fd == -1) {
              context.exception = [JSValue valueWithObject:[NSString stringWithFormat:@"Error (%d) opening file", errno] inContext:context];
              return nil;
          }
          return [JSValue valueWithInt32:(fd) inContext:context];
      },
      @"_open_async": ^JSValue *(JSValue *path, JSValue *flags, JSValue *mode, JSValue *callback) {
          dispatch_async(_runtime.ioQueue, ^{
              int fd = open([[path toString] UTF8String], [flags toUInt32], [mode toUInt32]);
              dispatch_async(_runtime.jsQueue, ^{
                  if (fd == -1) {
                      [callback callWithArguments:@[[NSString stringWithFormat:@"Error (%d) opening file", errno], [JSValue valueWithNullInContext:context]]];
                  } else {
                      [callback callWithArguments:@[[JSValue valueWithNullInContext:context], [JSValue valueWithInt32:fd inContext:context]]];
                  }
              });
          });
          // TODO: figure out how to make that return object here
          return [self asyncReturnObject];
      },
      @"_close_sync": ^JSValue *(JSValue *fd) {
          // https://github.com/joyent/node/blob/76b98462e589a69d9fd48ccb9fb5f6e96b539715/src/node_file.cc#L308
          // #include <unistd.h>
          // int close(int fildes);
          int err = close([fd toInt32]);
          if (err) {
              context.exception = [JSValue valueWithObject:[NSString stringWithFormat:@"Error (%d) closing file", errno] inContext:context];
              return nil;
          } else {
              return [JSValue valueWithUndefinedInContext:context];
          }
      },
      @"_close_async": ^JSValue *(JSValue *fd, JSValue *callback) {
          dispatch_async(_runtime.ioQueue, ^{
              int err = close([fd toInt32]);
              dispatch_async(_runtime.jsQueue, ^{
                  if (err) {
                      [callback callWithArguments:@[[JSValue valueWithObject:[NSString stringWithFormat:@"Error (%d) closing file", errno] inContext:context], [JSValue valueWithNullInContext:context]]];
                  } else {
                      [callback callWithArguments:@[[JSValue valueWithNullInContext:context], [JSValue valueWithUndefinedInContext:context]]];
                  }
              });
          });
          // TODO: Figure out return object
          return [self asyncReturnObject];
      },
      @"_read_sync": ^JSValue *(JSValue *fd, JSValue *buf, JSValue *offset, JSValue *position, JSValue *length) {
          // https://github.com/joyent/node/blob/76b98462e589a69d9fd48ccb9fb5f6e96b539715/src/node_file.cc#L844
          // #include <unistd.h>
          // ssize_t read(int file_descriptor, void *buf, size_t nbyte);
          int len = [length toInt32];
          int pos = [position toInt32];

          NSMutableData *dataBuffer = [[NSMutableData alloc] initWithLength:len];
          void *tmpBuffer = [dataBuffer mutableBytes];
          ssize_t bytesRead;
          if (pos == -1) {
              bytesRead = read([fd toInt32], tmpBuffer, len);
          } else {
              bytesRead = pread([fd toInt32], tmpBuffer, len, pos);
          }

          NSString *bufferAsString = (bytesRead == -1) ? nil : [[NSString alloc] initWithData:dataBuffer encoding:NSASCIIStringEncoding];
          if (bytesRead == -1) {
              context.exception = [JSValue valueWithObject:[NSString stringWithFormat:@"Error (%d) reading file", errno] inContext:context];
              return nil;
          } else {
              [buf invokeMethod:@"write" withArguments:@[bufferAsString, offset, @(bytesRead), @"ascii"]];
              return [JSValue valueWithInt32:(int)bytesRead inContext:context];
          }
      },
      @"_read_async": ^JSValue *(JSValue *fd, JSValue *buf, JSValue *offset, JSValue *position, JSValue *length, JSValue *callback) {
          dispatch_async(_runtime.ioQueue, ^{
              int len = [length toInt32];
              int pos = [position toInt32];

              NSMutableData *dataBuffer = [[NSMutableData alloc] initWithCapacity:len];
              void *tmpBuffer = [dataBuffer mutableBytes];
              ssize_t bytesRead;
              if (pos == -1) {
                  bytesRead = read([fd toInt32], tmpBuffer, len);
              } else {
                  bytesRead = pread([fd toInt32], tmpBuffer, len, pos);
              }

              NSString *bufferAsString = (bytesRead == -1) ? nil : [[NSString alloc] initWithData:dataBuffer encoding:NSASCIIStringEncoding];
              dispatch_async(_runtime.jsQueue, ^{
                  if (bytesRead == -1) {
                      [callback callWithArguments:@[[JSValue valueWithUInt32:errno inContext:context], [JSValue valueWithUndefinedInContext:context]]];
                  } else {
                      [buf invokeMethod:@"write" withArguments:@[bufferAsString, offset, @(bytesRead), @"ascii"]];
                      [callback callWithArguments:@[[JSValue valueWithNullInContext:context], [JSValue valueWithInt32:(int)bytesRead inContext:context]]];
                  }
              });
          });
          return [self asyncReturnObject];
      },
      @"_lstat_sync": ^JSValue *(JSValue *path) {
          // #include <sys/types.h>
          // #include <sys/stat.h>
          // int lstat(const char *path, struct stat *sb);
          struct stat s;
          int err = lstat([[path toString] UTF8String], &s);
          if (err) {
              context.exception = [JSValue valueWithObject:[NSString stringWithFormat:@"Error (%d) lstat-ing file '%@'", errno, path] inContext:context];
              return nil;
          } else {
              return [self jsValueForStatStruct:&s inContext:context];
          }

      },
      @"_lstat_async": ^JSValue *(JSValue *path, JSValue *callback) {
          dispatch_async(_runtime.ioQueue, ^{
              struct stat *s = malloc(sizeof(struct stat));
              int err = lstat([[path toString] UTF8String], s);
              dispatch_async(_runtime.jsQueue, ^{
                  if (err) {
                      [callback callWithArguments:@[[JSValue valueWithObject:[NSString stringWithFormat:@"Error (%d) lstat-ing file '%@'", errno, path] inContext:context], [JSValue valueWithNullInContext:context]]];
                  } else {
                      [callback callWithArguments:@[[JSValue valueWithNullInContext:context], [self jsValueForStatStruct:s inContext:context]]];
                  }
                  free(s);
              });
          });
          return [self asyncReturnObject];
      },
      @"_link_sync": ^JSValue *(JSValue *destPath, JSValue *srcPath) {
          return [JSValue valueWithInt32:link([[destPath toString] UTF8String], [[srcPath toString] UTF8String]) inContext:context];
      },
      @"_link_async": ^JSValue *(JSValue *destPath, JSValue *srcPath, JSValue *callback) {
          dispatch_async(_runtime.ioQueue, ^{
              int err = link([[destPath toString] UTF8String], [[srcPath toString] UTF8String]);
              dispatch_async(_runtime.jsQueue, ^{
                  if (err) {
                      [callback callWithArguments:@[[JSValue valueWithInt32:err inContext:context], [JSValue valueWithUndefinedInContext:context]]];
                  } else {
                      [callback callWithArguments:@[[JSValue valueWithNullInContext:context], [JSValue valueWithUndefinedInContext:context]]];
                  }
              });
          });
          return [self asyncReturnObject];
      },
      @"_symlink_sync": ^JSValue *(JSValue *destPath, JSValue *srcPath, JSValue *flags) {
          // We get these flags but on this platform, it doesn't seem like the underlying API accepts them
          int err = symlink([[destPath toString] UTF8String], [[srcPath toString] UTF8String]);
          if (err) {
              return [JSValue valueWithInt32:errno inContext:context];
          } else {
              return [JSValue valueWithUndefinedInContext:context];
          }
          
      },
      @"_symlink_async": ^JSValue *(JSValue *destPath, JSValue *srcPath, JSValue *flags, JSValue *callback) {
          dispatch_async(_runtime.ioQueue, ^{
              int err = symlink([[destPath toString] UTF8String], [[srcPath toString] UTF8String]);
              dispatch_async(_runtime.jsQueue, ^{
                  if (err) {
                      [callback callWithArguments:@[[JSValue valueWithInt32:errno inContext:context], [JSValue valueWithUndefinedInContext:context]]];
                  } else {
                      [callback callWithArguments:@[[JSValue valueWithNullInContext:context], [JSValue valueWithUndefinedInContext:context]]];
                  }
              });
          });
          return [self asyncReturnObject];
      },
      @"_unlink_sync": ^JSValue *(JSValue *path) {
          // #include <unistd.h>
          // int unlink(const char *path);
          int err = unlink([[path toString] UTF8String]);
          if (err) {
              return [JSValue valueWithInt32:errno inContext:context];
          } else {
              return [JSValue valueWithUndefinedInContext:context];
          }
      },
      @"_unlink_async": ^JSValue *(JSValue *path, JSValue *callback) {
          dispatch_async(_runtime.ioQueue, ^{
              int err = unlink([[path toString] UTF8String]);
              dispatch_async(_runtime.jsQueue, ^{
                  if (err) {
                      [callback callWithArguments:@[[JSValue valueWithInt32:errno inContext:context], [JSValue valueWithUndefinedInContext:context]]];
                  } else {
                      [callback callWithArguments:@[[JSValue valueWithNullInContext:context], [JSValue valueWithUndefinedInContext:context]]];
                  }
              });
          });
          return [self asyncReturnObject];
      },
      @"_rmdir_sync": ^JSValue *(JSValue *path) {
          int err = rmdir([[path toString] UTF8String]);
          if (err) {
              return [JSValue valueWithInt32:errno inContext:context];
          } else {
              return [JSValue valueWithUndefinedInContext:context];
          }
      },
      @"_rmdir_async": ^JSValue *(JSValue *path, JSValue *callback) {
          dispatch_async(_runtime.ioQueue, ^{
              int err = rmdir([[path toString] UTF8String]);
              dispatch_async(_runtime.jsQueue, ^{
                  if (err) {
                      [callback callWithArguments:@[[JSValue valueWithInt32:errno inContext:context], [JSValue valueWithUndefinedInContext:context]]];
                  } else {
                      [callback callWithArguments:@[[JSValue valueWithNullInContext:context], [JSValue valueWithUndefinedInContext:context]]];
                  }
              });
          });
          return [self asyncReturnObject];
      },
      @"_mkdir_sync": ^JSValue *(JSValue *path, JSValue *mode) {
          int err = mkdir([[path toString] UTF8String], [mode toInt32]);
          if (err) {
              return [JSValue valueWithInt32:errno inContext:context];
          } else {
              return [JSValue valueWithUndefinedInContext:context];
          }
      },
      @"_mkdir_async": ^JSValue *(JSValue *path, JSValue *mode, JSValue *callback) {
          dispatch_async(_runtime.ioQueue, ^{
              int err = mkdir([[path toString] UTF8String], [mode toInt32]);
              dispatch_async(_runtime.jsQueue, ^{
                  if (err) {
                      [callback callWithArguments:@[[JSValue valueWithInt32:errno inContext:context], [JSValue valueWithUndefinedInContext:context]]];
                  } else {
                      [callback callWithArguments:@[[JSValue valueWithNullInContext:context], [JSValue valueWithUndefinedInContext:context]]];
                  }
              });
          });
          return [self asyncReturnObject];
      },
      @"_readlink_sync": ^JSValue *(JSValue *path) {
          // #include <unistd.h>
          // ssize_t readlink(const char *restrict path, char *restrict buf, size_t bufsiz);

          char result[PATH_MAX];
          ssize_t s = readlink([[path toString] UTF8String], result, sizeof(result) - 1);
          if (s == -1) {
              context.exception = [JSValue valueWithNewErrorFromSyscall:@"readlink" errorCode:errno inContext:context];
              return [JSValue valueWithUndefinedInContext:context];
          } else {
              result[s] = '\0';
              return [JSValue valueWithObject:[NSString stringWithUTF8String:result] inContext:context];
          }
          
      },
      @"_readlink_async": ^JSValue *(JSValue *path, JSValue *callback) {
          dispatch_async(_runtime.ioQueue, ^{
              char result[PATH_MAX];
              ssize_t s = readlink([[path toString] UTF8String], result, sizeof(result) - 1);
              if (s == -1) {
                  [callback callWithArguments:@[[JSValue valueWithInt32:errno inContext:context], [JSValue valueWithUndefinedInContext:context]]];
              } else {
                  result[s] = '\0';
                  [callback callWithArguments:@[[JSValue valueWithNullInContext:context], [JSValue valueWithObject:[NSString stringWithUTF8String:result] inContext:context]]];
              }
          });
          return [self asyncReturnObject];
      },
      @"_fdatasync_sync": ^JSValue *(JSValue *fd) {
          // #include <unistd.h>
          // int fdatasync(int fd);
          
          // Mac and Mac-like systems don't implement fdatasync so we use fcntl instead
          // See https://code.google.com/p/picoc/issues/detail?id=145
          int err = fcntl([fd toInt32], F_FULLFSYNC);
          return [JSValue valueWithInt32:err inContext:context];
      },
      @"_fdatasync_async": ^JSValue *(JSValue *fd, JSValue *callback) {
          dispatch_async(_runtime.ioQueue, ^{
              int err = fcntl([fd toInt32], F_FULLFSYNC);
              dispatch_async(_runtime.jsQueue, ^{
                  if (err) {
                      [callback callWithArguments:@[[JSValue valueWithInt32:err inContext:context], [JSValue valueWithUndefinedInContext:context]]];
                  } else {
                      [callback callWithArguments:@[[JSValue valueWithNullInContext:context], [JSValue valueWithUndefinedInContext:context]]];
                  }
              });
          });
          return [self asyncReturnObject];
      },
      @"_fsync_sync": ^JSValue *(JSValue *fd) {
          // #include <unistd.h>
          // int fsync(int fd);
          int err = fsync([fd toInt32]);
          if (err) {
              return [JSValue valueWithInt32:errno inContext:context];
          } else {
              return [JSValue valueWithUndefinedInContext:context];
          }
      },
      @"_fsync_async": ^JSValue *(JSValue *fd, JSValue *callback) {
          dispatch_async(_runtime.ioQueue, ^{
              int err = fsync([fd toInt32]);
              dispatch_async(_runtime.jsQueue, ^{
                  if (err) {
                      [callback callWithArguments:@[[JSValue valueWithInt32:errno inContext:context], [JSValue valueWithUndefinedInContext:context]]];
                  } else {
                      [callback callWithArguments:@[[JSValue valueWithNullInContext:context], [JSValue valueWithUndefinedInContext:context]]];
                  }
              });
          });
          return [self asyncReturnObject];
      },
      @"_rename_sync": ^JSValue *(JSValue *from, JSValue *to) {
          return [JSValue valueWithInt32:rename([[from toString] UTF8String], [[to toString] UTF8String]) inContext:context];
      },
      @"_rename_async": ^JSValue *(JSValue *from, JSValue *to, JSValue *callback) {
          dispatch_async(_runtime.ioQueue, ^{
              int err = rename([[from toString] UTF8String], [[to toString] UTF8String]);
              dispatch_async(_runtime.jsQueue, ^{
                  if (err == -1) {
                      [callback callWithArguments:@[[JSValue valueWithInt32:errno inContext:context], [JSValue valueWithUndefinedInContext:context]]];
                  } else {
                      [callback callWithArguments:@[[JSValue valueWithNullInContext:context], [JSValue valueWithUndefinedInContext:context]]];
                  }
              });
          });
          return [self asyncReturnObject];
      },
      @"_ftruncate_sync": ^JSValue *(JSValue *fd, JSValue *len) {
          // https://github.com/joyent/node/blob/master/src/node_file.cc#L554
          // http://www.unix.com/man-page/freebsd/2/ftruncate/
          return [JSValue valueWithInt32:ftruncate([fd toInt32], [len toInt32]) inContext:context];
      },
      @"_ftruncate_async": ^JSValue *(JSValue *fd, JSValue *len, JSValue *callback) {
          dispatch_async(_runtime.ioQueue, ^{
              int err = ftruncate([fd toInt32], [len toInt32]);
              dispatch_async(_runtime.jsQueue, ^{
                  if (err == -1) {
                      [callback callWithArguments:@[[JSValue valueWithInt32:errno inContext:context], [JSValue valueWithUndefinedInContext:context]]];
                  } else {
                      [callback callWithArguments:@[[JSValue valueWithNullInContext:context], [JSValue valueWithUndefinedInContext:context]]];
                  }
              });
          });
          return [self asyncReturnObject];
      },
      @"_chmod_sync": ^JSValue *(JSValue *path, JSValue *mode) {
          int err = chmod([[path toString] UTF8String], [mode toInt32]);
          if (err == -1) {
              return [JSValue valueWithInt32:errno inContext:context];
          } else {
              return [JSValue valueWithNullInContext:context];
          }
      },
      @"_chmod_async": ^JSValue *(JSValue *path, JSValue *mode, JSValue *callback) {
          dispatch_async(_runtime.ioQueue, ^{
              int err = chmod([[path toString] UTF8String], [mode toInt32]);
              if (err == -1) {
                  [callback callWithArguments:@[[JSValue valueWithInt32:errno inContext:context], [JSValue valueWithUndefinedInContext:context]]];
              } else {
                  [callback callWithArguments:@[[JSValue valueWithNullInContext:context], [JSValue valueWithUndefinedInContext:context]]];
              }
          });
          return [self asyncReturnObject];
      },
      @"_fchmod_sync": ^JSValue *(JSValue *fd, JSValue *mode) {
          int err = fchmod([fd toInt32], [mode toInt32]);
          if (err == -1) {
              return [JSValue valueWithInt32:errno inContext:context];
          } else {
              return [JSValue valueWithNullInContext:context];
          }
      },
      @"_fchmod_async": ^JSValue *(JSValue *fd, JSValue *mode, JSValue *callback) {
          dispatch_async(_runtime.ioQueue, ^{
              int err = fchmod([fd toInt32], [mode toInt32]);
              if (err == -1) {
                  [callback callWithArguments:@[[JSValue valueWithInt32:errno inContext:context], [JSValue valueWithUndefinedInContext:context]]];
              } else {
                  [callback callWithArguments:@[[JSValue valueWithNullInContext:context], [JSValue valueWithUndefinedInContext:context]]];
              }
          });
          return [self asyncReturnObject];
      },
      @"_chown_sync": ^JSValue *(JSValue *path, JSValue *uid, JSValue *gid) {
          int err = chown([[path toString] UTF8String], [uid toInt32], [gid toInt32]);
          if (err == -1) {
              return [JSValue valueWithInt32:errno inContext:context];
          } else {
              return [JSValue valueWithNullInContext:context];
          }
      },
      @"_chown_async": ^JSValue *(JSValue *path, JSValue *uid, JSValue *gid, JSValue *callback) {
          dispatch_async(_runtime.ioQueue, ^{
              int err = chown([[path toString] UTF8String], [uid toInt32], [gid toInt32]);
              if (err == -1) {
                  [callback callWithArguments:@[[JSValue valueWithInt32:errno inContext:context], [JSValue valueWithUndefinedInContext:context]]];
              } else {
                  [callback callWithArguments:@[[JSValue valueWithNullInContext:context], [JSValue valueWithUndefinedInContext:context]]];
              }
          });
          return [self asyncReturnObject];
      },
      @"_fchown_sync": ^JSValue *(JSValue *fd, JSValue *uid, JSValue *gid) {
          int err = fchown([fd toInt32], [uid toInt32], [gid toInt32]);
          if (err == -1) {
              return [JSValue valueWithInt32:errno inContext:context];
          } else {
              return [JSValue valueWithNullInContext:context];
          }
      },
      @"_fchown_async": ^JSValue *(JSValue *fd, JSValue *uid, JSValue *gid, JSValue *callback) {
          dispatch_async(_runtime.ioQueue, ^{
              int err = fchown([fd toInt32], [uid toInt32], [gid toInt32]);
              if (err == -1) {
                  [callback callWithArguments:@[[JSValue valueWithInt32:errno inContext:context], [JSValue valueWithUndefinedInContext:context]]];
              } else {
                  [callback callWithArguments:@[[JSValue valueWithNullInContext:context], [JSValue valueWithUndefinedInContext:context]]];
              }
          });
          return [self asyncReturnObject];
      },
      @"_utimes_sync": ^JSValue *(JSValue *path, JSValue *atime, JSValue *mtime) {
          struct timeval s[2];
          s[0].tv_sec = [atime toDouble];
          s[1].tv_sec = [mtime toDouble];
          int err = utimes([[path toString] UTF8String], s);
          if (err == -1) {
              return [JSValue valueWithInt32:errno inContext:context];
          } else {
              return [JSValue valueWithNullInContext:context];
          }
      },
      @"_utimes_async": ^JSValue *(JSValue *path, JSValue *atime, JSValue *mtime, JSValue *callback) {
          dispatch_async(_runtime.ioQueue, ^{
              struct timeval s[2];
              s[0].tv_sec = [atime toDouble];
              s[1].tv_sec = [mtime toDouble];
              int err = utimes([[path toString] UTF8String], s);
              dispatch_async(_runtime.jsQueue, ^{
                  if (err == -1) {
                      [callback callWithArguments:@[[JSValue valueWithInt32:errno inContext:context], [JSValue valueWithUndefinedInContext:context]]];
                  } else {
                      [callback callWithArguments:@[[JSValue valueWithNullInContext:context], [JSValue valueWithUndefinedInContext:context]]];
                  }
              });
          });
          return [self asyncReturnObject];
      },
      @"_futimes_sync": ^JSValue *(JSValue *fd, JSValue *atime, JSValue *mtime) {
          struct timeval s[2];
          s[0].tv_sec = [atime toDouble];
          s[1].tv_sec = [mtime toDouble];
          int err = futimes([fd toInt32], s);
          if (err == -1) {
              return [JSValue valueWithInt32:errno inContext:context];
          } else {
              return [JSValue valueWithNullInContext:context];
          }
      },
      @"_futimes_async": ^JSValue *(JSValue *fd, JSValue *atime, JSValue *mtime, JSValue *callback) {
          dispatch_async(_runtime.ioQueue, ^{
              struct timeval s[2];
              s[0].tv_sec = [atime toDouble];
              s[1].tv_sec = [mtime toDouble];
              int err = futimes([fd toInt32], s);
              dispatch_async(_runtime.jsQueue, ^{
                  if (err == -1) {
                      [callback callWithArguments:@[[JSValue valueWithInt32:errno inContext:context], [JSValue valueWithUndefinedInContext:context]]];
                  } else {
                      [callback callWithArguments:@[[JSValue valueWithNullInContext:context], [JSValue valueWithUndefinedInContext:context]]];
                  }
              });
          });
          return [self asyncReturnObject];
      },
      @"_write_sync": ^JSValue *(JSValue *fd, JSValue *buffer, JSValue *offset, JSValue *length, JSValue *position) {
          int off = [offset toInt32];
          int len = [length toInt32];
          int pos = [position toInt32];
          uint8_t *tmp = malloc(sizeof(uint8_t) * len);

          for (int i = 0; i < len; i++) {
              tmp[i] = [[buffer valueAtIndex:(i + off)] toUInt32];
          }
          ssize_t bytesWritten;
          if (pos == -1) {
              bytesWritten = write([fd toInt32], tmp, len);
          } else {
              bytesWritten = pwrite([fd toInt32], tmp, len, pos);
          }
          free(tmp);
          if (bytesWritten == -1) {
              context.exception = [JSValue valueWithObject:[NSString stringWithFormat:@"Error (%d) writing file", errno] inContext:context];
              return nil;
          } else {
              return [JSValue valueWithInt32:(int)bytesWritten inContext:context];
          }
      },
      @"_write_async": ^JSValue *(JSValue *fd, JSValue *buffer, JSValue *offset, JSValue *length, JSValue *position, JSValue *callback) {
          int off = [offset toInt32];
          int len = [length toInt32];
          int pos = [position toInt32];
          dispatch_async(_runtime.ioQueue, ^{
              uint8_t *tmp = malloc(sizeof(uint8_t) * len);
              for (int i = 0; i < len; i++) {
                  tmp[i] = [[buffer valueAtIndex:(i + off)] toUInt32];
              }
              ssize_t bytesWritten;
              if (pos == -1) {
                  bytesWritten = write([fd toInt32], tmp, len);
              } else {
                  bytesWritten = pwrite([fd toInt32], tmp, len, pos);
              }
              free(tmp);
              dispatch_async(_runtime.jsQueue, ^{
                  if (bytesWritten == -1) {
                      [callback callWithArguments:@[[JSValue valueWithInt32:errno inContext:context], [JSValue valueWithUndefinedInContext:context]]];
                  } else {
                      [callback callWithArguments:@[[JSValue valueWithNullInContext:context], [JSValue valueWithInt32:(int)bytesWritten inContext:context]]];
                  }
              });
          });

          return [self asyncReturnObject];
      },
      @"_write_string_sync": ^JSValue *(JSValue *fd, JSValue *string, JSValue *position, JSValue *enc) {
          NSString *s = [string toString];
          const char *cs = [s UTF8String];
          unsigned long len = strlen(cs);
          int pos = [position toInt32];
          ssize_t bytesWritten;
          if (pos == -1) {
              bytesWritten = write([fd toInt32], cs, len);
          } else {
              bytesWritten = pwrite([fd toInt32], cs, len, pos);
          }
          return [JSValue valueWithInt32:(int)bytesWritten inContext:context];
      },
      @"_write_string_async": ^JSValue *(JSValue *fd, JSValue *string, JSValue *position, JSValue *enc, JSValue *callback) {
          NSString *s = [string toString];
          int pos = [position toInt32];
          dispatch_async(_runtime.ioQueue, ^{
              const char *cs = [s UTF8String];
              unsigned long len = strlen(cs);
              ssize_t bytesWritten;
              if (pos == -1) {
                  bytesWritten = write([fd toInt32], cs, len);
              } else {
                  bytesWritten = pwrite([fd toInt32], cs, len, pos);
              }
              dispatch_async(_runtime.jsQueue, ^{
                  if (bytesWritten == -1) {
                      [callback callWithArguments:@[[JSValue valueWithInt32:errno inContext:context], [JSValue valueWithUndefinedInContext:context]]];
                  } else {
                      [callback callWithArguments:@[[JSValue valueWithNullInContext:context], [JSValue valueWithInt32:(int)bytesWritten inContext:context]]];
                  }
              });
          });
          return [self asyncReturnObject];
      },
      @"_readfile_utf8_sync": ^JSValue *(JSValue *path) {

          NSError *error = nil;
          NSString *contents = [NSString stringWithContentsOfFile:[path toString] encoding:NSUTF8StringEncoding error:&error];

          if (error) {
              context.exception = [JSValue valueWithObject:[error localizedDescription] inContext:context];
              return nil;
          } else {
              return [JSValue valueWithObject:contents inContext:context];
          }
      },
      @"_readfile_utf8_async": ^JSValue *(JSValue *path, JSValue *callback) {
          dispatch_async(_runtime.ioQueue, ^{
              NSError *error = nil;
              NSString *contents = [NSString stringWithContentsOfFile:[path toString] encoding:NSUTF8StringEncoding error:&error];
              dispatch_async(_runtime.jsQueue, ^{
                  if (error) {
                      [callback callWithArguments:@[[JSValue valueWithObject:[error localizedDescription] inContext:context], [JSValue valueWithUndefinedInContext:context]]];
                  } else {
                      [callback callWithArguments:@[[JSValue valueWithNullInContext:context], [JSValue valueWithObject:contents inContext:context]]];
                  }
              });
          });
          return [self asyncReturnObject];
      },
      @"_readdir_sync": ^JSValue *(JSValue *path) {
          // #include <dirent.h>
          NSMutableArray *entries = [[NSMutableArray alloc] initWithCapacity:10];
          DIR *dirp = opendir([[path toString] UTF8String]);
          if (dirp == NULL) {
              context.exception = [JSValue valueWithObject:[NSString stringWithFormat:@"Could not readdir '%@'", [path toString]] inContext:context];
              return nil;
          }
          struct dirent *dirent;
          while ((dirent = readdir(dirp))) {
              [entries addObject:[NSString stringWithUTF8String:dirent->d_name]];
          }
          closedir(dirp);
          return [JSValue valueWithObject:entries inContext:context];
      },
      @"_readdir_async": ^JSValue *(JSValue *path, JSValue *callback) {
          // #include <dirent.h>
          dispatch_async(_runtime.ioQueue, ^{
              NSMutableArray *entries = [[NSMutableArray alloc] initWithCapacity:10];
              NSString *pathString = [path toString];
              DIR *dirp = opendir([pathString UTF8String]);

              if (dirp == NULL) {
                  dispatch_async(_runtime.jsQueue, ^{
                      [callback callWithArguments:@[[JSValue valueWithObject:[NSString stringWithFormat:@"Could not readdir '%@'", pathString] inContext:context]]];
                  });
                  return;
              }

              struct dirent *dirent;
              while ((dirent = readdir(dirp))) {
                  [entries addObject:[NSString stringWithUTF8String:dirent->d_name]];
              }
              closedir(dirp);

              dispatch_async(_runtime.jsQueue, ^{
                  [callback callWithArguments:@[[JSValue valueWithNullInContext:context], [JSValue valueWithObject:entries inContext:context]]];
              });
          });
          return [self asyncReturnObject];
      },
      @"__end__": [NSNull null]};

    NSURL *bindingUrl = [CNRuntime urlWithBase:context.runtime.bundleUrl filePath:@"FileSystemBinding.js"];
    JSValue *factory = [context.runtime evaluateJSAtUrl:bindingUrl];
    return [factory callWithArguments:@[_nativeExports]];
}

- (void)FSInitialize:(JSValue *)statsConstructor
{
    self.statsConstructor = statsConstructor;
}

- (JSValue *)jsValueForStatStruct:(struct stat *)s inContext:(JSContext *)context {
#define DEFINE_INT32(name) \
    JSValue *name = [JSValue valueWithInt32:(int32_t)s->st_##name inContext:context]; \
    if (!name) { \
        return [JSValue valueWithNewObjectInContext:context]; \
    }

#define DEFINE_UINT32(name) \
    JSValue *name = [JSValue valueWithUInt32:(uint32_t)s->st_##name inContext:context]; \
    if (!name) { \
        return [JSValue valueWithNewObjectInContext:context]; \
    }

#define DEFINE_DOUBLE(name) \
    JSValue *name = [JSValue valueWithDouble:s->st_##name inContext:context]; \
    if (!name) { \
        return [JSValue valueWithNewObjectInContext:context]; \
    }

#define DEFINE_TIME(name) \
    struct timespec name##spec = s->st_##name##spec; \
    JSValue *name = [JSValue valueWithDouble:name##spec.tv_sec * 1000.0 + name##spec.tv_nsec / 1000000.0 inContext:context]; \
    if (!name) { \
        return [JSValue valueWithNewObjectInContext:context]; \
    }

    DEFINE_INT32(dev)
    DEFINE_UINT32(mode)
    DEFINE_UINT32(nlink)
    DEFINE_UINT32(uid)
    DEFINE_UINT32(gid)
    DEFINE_INT32(rdev)
    DEFINE_INT32(blksize);
    DEFINE_DOUBLE(ino)
    DEFINE_DOUBLE(size)
    DEFINE_DOUBLE(blocks)
    DEFINE_TIME(atime)
    DEFINE_TIME(mtime)
    DEFINE_TIME(ctime)
    DEFINE_TIME(birthtime)

    NSArray *arguments = @[dev, mode, nlink, uid, gid, rdev, blksize, ino, size, blocks, atime, mtime, ctime, birthtime];
    JSValue *statsObject = [self.statsConstructor constructWithArguments:arguments];
    return statsObject ? statsObject : [JSValue valueWithNewObjectInContext:context];
}

- (JSValue *)asyncReturnObject {
    return [JSValue valueWithObject:@{@"domain": [NSNull null], @"oncomplete": ^{}} inContext:[JSContext currentContext]];
}

@end
