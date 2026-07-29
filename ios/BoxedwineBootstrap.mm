#import "BoxedwineBootstrap.h"

#include <atomic>
#include <cstdio>
#include <exception>
#include <string>
#include <vector>

int boxedmain(int argc, const char** argv);

namespace {

constexpr char kExpectedMarker[] = "boxedwine-interpreter-ok\n";
constexpr char kProjectVersion[] = "0.3.1";
std::atomic_bool gBootstrapStarted = false;

NSURL* DocumentsDirectory() {
  return [NSFileManager.defaultManager
      URLsForDirectory:NSDocumentDirectory
             inDomains:NSUserDomainMask]
      .firstObject;
}

NSString* ISO8601Timestamp() {
  NSISO8601DateFormatter* formatter =
      [[NSISO8601DateFormatter alloc] init];
  formatter.formatOptions = NSISO8601DateFormatWithInternetDateTime |
                            NSISO8601DateFormatWithFractionalSeconds;
  return [formatter stringFromDate:NSDate.date];
}

NSDictionary<NSString*, id>* PersistResult(
    NSDictionary<NSString*, id>* values,
    NSURL* _Nullable resultURL) {
  NSMutableDictionary<NSString*, id>* result = [values mutableCopy];
  result[@"projectVersion"] =
      [NSString stringWithUTF8String:kProjectVersion];
  result[@"timestamp"] = ISO8601Timestamp();
  result[@"resultPath"] = resultURL.path ?: @"unavailable";

  if (resultURL == nil) {
    result[@"resultSaved"] = @NO;
    return result;
  }

  result[@"resultSaved"] = @YES;
  NSError* serialisationError = nil;
  NSData* data =
      [NSJSONSerialization dataWithJSONObject:result
                                      options:(NSJSONWritingPrettyPrinted |
                                               NSJSONWritingSortedKeys)
                                        error:&serialisationError];
  NSError* writeError = nil;
  BOOL written =
      data != nil &&
      [data writeToURL:resultURL
               options:NSDataWritingAtomic
                 error:&writeError];
  if (!written) {
    NSError* error = writeError ?: serialisationError;
    result[@"resultSaved"] = @NO;
    result[@"resultWriteError"] =
        error.localizedDescription ?: @"unknown error";
  }
  return result;
}

NSDictionary<NSString*, id>* Failure(NSString* message,
                                     NSURL* _Nullable logURL,
                                     NSURL* _Nullable markerURL,
                                     NSURL* _Nullable resultURL) {
  return PersistResult(@{
    @"status" : @"failed",
    @"success" : @NO,
    @"message" : message,
    @"logPath" : logURL.path ?: @"unavailable",
    @"markerPath" : markerURL.path ?: @"unavailable",
    @"markerMatched" : @NO,
  }, resultURL);
}

}  // namespace

NSDictionary<NSString*, id>* SporeBridgeRunBoxedwineBootstrap(void) {
  if (gBootstrapStarted.exchange(true)) {
    return Failure(
        @"The interpreter test can run once per app launch. Close and reopen "
         @"SporeBridge to repeat it.",
        nil, nil, nil);
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
  NSURL* result =
      [diagnostics
          URLByAppendingPathComponent:@"boxedwine-bootstrap-result.json"];
  NSURL* rootZip =
      [NSBundle.mainBundle URLForResource:@"boxedwine-bootstrap-root"
                           withExtension:@"zip"];

  NSError* error = nil;
  [files createDirectoryAtURL:diagnostics
  withIntermediateDirectories:YES
                   attributes:nil
                        error:&error];
  if (error != nil) {
    return Failure(
        [NSString stringWithFormat:@"Could not create diagnostics folder: %@",
                                   error.localizedDescription],
        log, marker, result);
  }

  [files removeItemAtURL:log error:nil];
  PersistResult(@{
    @"status" : @"running",
    @"phase" : @"initialising",
    @"success" : @NO,
    @"message" : @"Preparing the Boxedwine interpreter test.",
    @"logPath" : log.path,
    @"markerPath" : marker.path,
    @"markerMatched" : @NO,
  }, result);

  if (rootZip == nil) {
    return Failure(@"The bundled Boxedwine bootstrap root is missing.", log,
                   marker, result);
  }

  if ([files fileExistsAtPath:root.path] &&
      ![files removeItemAtURL:root error:&error]) {
    return Failure(
        [NSString stringWithFormat:@"Could not reset the test root: %@",
                                   error.localizedDescription],
        log, marker, result);
  }
  if (![files createDirectoryAtURL:root
       withIntermediateDirectories:YES
                        attributes:nil
                             error:&error]) {
    return Failure(
        [NSString stringWithFormat:@"Could not create the test root: %@",
                                   error.localizedDescription],
        log, marker, result);
  }

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

  PersistResult(@{
    @"status" : @"running",
    @"phase" : @"invokingBoxedwine",
    @"success" : @NO,
    @"message" : @"Boxedwine is running the interpreter test.",
    @"logPath" : log.path,
    @"markerPath" : marker.path,
    @"markerMatched" : @NO,
  }, result);

  int exitCode = -1;
  @try {
    try {
      exitCode = boxedmain(static_cast<int>(arguments.size()),
                           arguments.data());
      std::fflush(nullptr);
    } catch (const std::exception& exception) {
      std::fflush(nullptr);
      NSString* message =
          [NSString stringWithUTF8String:exception.what()];
      return Failure(
          [NSString stringWithFormat:@"Boxedwine stopped: %@",
                                     message ?: @"unknown C++ error"],
          log, marker, result);
    } catch (...) {
      std::fflush(nullptr);
      return Failure(@"Boxedwine stopped with an unknown C++ error.", log,
                     marker, result);
    }
  } @catch (NSException* exception) {
    std::fflush(nullptr);
    return Failure(
        [NSString stringWithFormat:@"Boxedwine stopped: %@",
                                   exception.reason ?: exception.name],
        log, marker, result);
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

  return PersistResult(@{
    @"status" : success ? @"passed" : @"failed",
    @"phase" : @"complete",
    @"success" : @(success),
    @"exitCode" : @(exitCode),
    @"markerMatched" : @(markerMatches),
    @"message" : message,
    @"logPath" : log.path,
    @"markerPath" : marker.path,
  }, result);
}
