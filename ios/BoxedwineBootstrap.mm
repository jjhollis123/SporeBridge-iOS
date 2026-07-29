#import "BoxedwineBootstrap.h"

#include <atomic>
#include <exception>
#include <string>
#include <vector>

int boxedmain(int argc, const char** argv);

namespace {

constexpr char kExpectedMarker[] = "boxedwine-interpreter-ok\n";
std::atomic_bool gBootstrapStarted = false;

NSURL* DocumentsDirectory() {
  return [NSFileManager.defaultManager
      URLsForDirectory:NSDocumentDirectory
             inDomains:NSUserDomainMask]
      .firstObject;
}

NSDictionary<NSString*, id>* Failure(NSString* message,
                                     NSURL* _Nullable logURL) {
  return @{
    @"success" : @NO,
    @"message" : message,
    @"logPath" : logURL.path ?: @"unavailable",
  };
}

}  // namespace

NSDictionary<NSString*, id>* SporeBridgeRunBoxedwineBootstrap(void) {
  if (gBootstrapStarted.exchange(true)) {
    return Failure(
        @"The interpreter test can run once per app launch. Close and reopen "
         @"SporeBridge to repeat it.",
        nil);
  }

  NSFileManager* files = NSFileManager.defaultManager;
  NSURL* diagnostics =
      [DocumentsDirectory()
          URLByAppendingPathComponent:@"SporeBridgeDiagnostics"
                           isDirectory:YES];
  NSURL* root =
      [diagnostics URLByAppendingPathComponent:@"BoxedwineRoot"
                                    isDirectory:YES];
  NSURL* marker =
      [root URLByAppendingPathComponent:@"tmp/boxedwine-interpreter-ok.txt"];
  NSURL* log =
      [diagnostics URLByAppendingPathComponent:@"boxedwine-bootstrap.log"];
  NSURL* rootZip =
      [NSBundle.mainBundle URLForResource:@"boxedwine-bootstrap-root"
                           withExtension:@"zip"];

  if (rootZip == nil) {
    return Failure(@"The bundled Boxedwine bootstrap root is missing.", log);
  }

  NSError* error = nil;
  [files createDirectoryAtURL:diagnostics
  withIntermediateDirectories:YES
                   attributes:nil
                        error:&error];
  if (error != nil) {
    return Failure(
        [NSString stringWithFormat:@"Could not create diagnostics folder: %@",
                                   error.localizedDescription],
        log);
  }

  if ([files fileExistsAtPath:root.path] &&
      ![files removeItemAtURL:root error:&error]) {
    return Failure(
        [NSString stringWithFormat:@"Could not reset the test root: %@",
                                   error.localizedDescription],
        log);
  }
  if (![files createDirectoryAtURL:root
       withIntermediateDirectories:YES
                        attributes:nil
                             error:&error]) {
    return Failure(
        [NSString stringWithFormat:@"Could not create the test root: %@",
                                   error.localizedDescription],
        log);
  }
  [files removeItemAtURL:log error:nil];

  std::vector<std::string> values = {
      "SporeBridge",
      "-root",
      root.fileSystemRepresentation,
      "-zip",
      rootZip.fileSystemRepresentation,
      "-log",
      log.fileSystemRepresentation,
      "-nosound",
      "-novideo",
      "/bin/hello",
  };
  std::vector<const char*> arguments;
  arguments.reserve(values.size());
  for (const std::string& value : values) {
    arguments.push_back(value.c_str());
  }

  int exitCode = -1;
  @try {
    try {
      exitCode = boxedmain(static_cast<int>(arguments.size()),
                           arguments.data());
    } catch (const std::exception& exception) {
      NSString* message =
          [NSString stringWithUTF8String:exception.what()];
      return Failure(
          [NSString stringWithFormat:@"Boxedwine stopped: %@",
                                     message ?: @"unknown C++ error"],
          log);
    } catch (...) {
      return Failure(@"Boxedwine stopped with an unknown C++ error.", log);
    }
  } @catch (NSException* exception) {
    return Failure(
        [NSString stringWithFormat:@"Boxedwine stopped: %@",
                                   exception.reason ?: exception.name],
        log);
  }

  NSData* markerData = [NSData dataWithContentsOfURL:marker];
  NSString* markerText =
      markerData == nil
          ? nil
          : [[NSString alloc] initWithData:markerData
                                  encoding:NSUTF8StringEncoding];
  NSString* expectedMarker = [NSString stringWithUTF8String:kExpectedMarker];
  BOOL markerMatches = [markerText isEqualToString:expectedMarker];
  BOOL success = exitCode == 0 && markerMatches;

  NSString* message =
      success
          ? @"PASSED: Boxedwine interpreted a 32-bit x86 programme and its "
             @"emulated Linux syscalls wrote the expected marker file."
          : [NSString
                stringWithFormat:
                    @"FAILED: Boxedwine returned %d and the marker was %@. "
                     @"Keep the log for the next porting step.",
                    exitCode, markerMatches ? @"correct" : @"missing or wrong"];

  return @{
    @"success" : @(success),
    @"exitCode" : @(exitCode),
    @"markerMatched" : @(markerMatches),
    @"message" : message,
    @"logPath" : log.path,
    @"markerPath" : marker.path,
  };
}
