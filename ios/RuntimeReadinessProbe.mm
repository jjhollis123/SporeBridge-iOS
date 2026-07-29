#import "RuntimeReadinessProbe.h"

#import <Metal/Metal.h>
#import <UIKit/UIKit.h>

#include <cerrno>
#include <cstdint>
#include <cstring>
#include <sys/mman.h>
#include <sys/sysctl.h>
#include <unistd.h>
#include <vector>

namespace {

NSString* HardwareIdentifier() {
  size_t size = 0;
  if (sysctlbyname("hw.machine", nullptr, &size, nullptr, 0) != 0 ||
      size == 0) {
    return @"unknown";
  }

  std::vector<char> value(size);
  if (sysctlbyname("hw.machine", value.data(), &size, nullptr, 0) != 0) {
    return @"unknown";
  }

  NSString* identifier = [NSString stringWithUTF8String:value.data()];
  return identifier ?: @"unknown";
}

NSString* ErrorDescription(int errorNumber) {
  NSString* description =
      [NSString stringWithUTF8String:std::strerror(errorNumber)];
  return description ?: @"unknown error";
}

NSDictionary<NSString*, id>* RunVirtualMemoryProbe() {
  constexpr size_t kRegionSize = 64U * 1024U;
  void* region = mmap(nullptr, kRegionSize, PROT_NONE,
                      MAP_PRIVATE | MAP_ANON, -1, 0);
  if (region == MAP_FAILED) {
    return @{
      @"regionSizeBytes" : @(kRegionSize),
      @"reserved" : @NO,
      @"madeReadWrite" : @NO,
      @"writeVerified" : @NO,
      @"reprotected" : @NO,
      @"released" : @NO,
      @"error" : ErrorDescription(errno),
    };
  }

  BOOL madeReadWrite =
      mprotect(region, kRegionSize, PROT_READ | PROT_WRITE) == 0;
  int protectionError = madeReadWrite ? 0 : errno;
  BOOL writeVerified = NO;
  if (madeReadWrite) {
    auto* bytes = static_cast<volatile std::uint8_t*>(region);
    bytes[0] = 0x53;
    bytes[kRegionSize - 1] = 0x42;
    writeVerified =
        bytes[0] == 0x53 && bytes[kRegionSize - 1] == 0x42;
  }

  BOOL reprotected = mprotect(region, kRegionSize, PROT_NONE) == 0;
  int reprotectError = reprotected ? 0 : errno;
  BOOL released = munmap(region, kRegionSize) == 0;
  int releaseError = released ? 0 : errno;

  int errorNumber = protectionError;
  if (errorNumber == 0) {
    errorNumber = reprotectError;
  }
  if (errorNumber == 0) {
    errorNumber = releaseError;
  }

  return @{
    @"regionSizeBytes" : @(kRegionSize),
    @"reserved" : @YES,
    @"madeReadWrite" : @(madeReadWrite),
    @"writeVerified" : @(writeVerified),
    @"reprotected" : @(reprotected),
    @"released" : @(released),
    @"error" :
        errorNumber == 0 ? @"none" : ErrorDescription(errorNumber),
  };
}

}  // namespace

NSDictionary<NSString*, id>* SporeBridgeRunRuntimeReadinessProbe(void) {
  UIDevice* device = UIDevice.currentDevice;
  NSProcessInfo* process = NSProcessInfo.processInfo;
  id<MTLDevice> metalDevice = MTLCreateSystemDefaultDevice();
  NSDictionary<NSString*, id>* memory = RunVirtualMemoryProbe();

  BOOL memoryReady =
      [memory[@"reserved"] boolValue] &&
      [memory[@"madeReadWrite"] boolValue] &&
      [memory[@"writeVerified"] boolValue] &&
      [memory[@"reprotected"] boolValue] &&
      [memory[@"released"] boolValue];
  BOOL metalReady = metalDevice != nil;

  NSISO8601DateFormatter* formatter = [[NSISO8601DateFormatter alloc] init];
  NSString* timestamp = [formatter stringFromDate:NSDate.date];

  long pageSize = sysconf(_SC_PAGESIZE);
  return @{
    @"probeVersion" : @"1",
    @"timestamp" : timestamp ?: @"unknown",
    @"deviceModel" : device.model ?: @"unknown",
    @"hardwareIdentifier" : HardwareIdentifier(),
    @"systemName" : device.systemName ?: @"unknown",
    @"systemVersion" : device.systemVersion ?: @"unknown",
    @"processorCount" : @(process.processorCount),
    @"activeProcessorCount" : @(process.activeProcessorCount),
    @"physicalMemoryBytes" :
        @((unsigned long long)process.physicalMemory),
    @"pageSizeBytes" : @(pageSize),
    @"metalAvailable" : @(metalReady),
    @"metalDeviceName" : metalDevice.name ?: @"unavailable",
    @"virtualMemory" : memory,
    @"executableMemoryRequested" : @NO,
    @"readyForInterpreter" : @(memoryReady && metalReady),
  };
}

NSString* SporeBridgeRuntimeReadinessSummary(
    NSDictionary<NSString*, id>* report) {
  NSString* result =
      [report[@"readyForInterpreter"] boolValue] ? @"PASSED" : @"FAILED";
  NSString* hardware = report[@"hardwareIdentifier"] ?: @"unknown iPad";
  NSString* system = report[@"systemName"] ?: @"iPadOS";
  NSString* version = report[@"systemVersion"] ?: @"unknown";
  NSString* metal = report[@"metalDeviceName"] ?: @"unavailable";

  return [NSString
      stringWithFormat:
          @"Runtime readiness %@ on %@ (%@ %@). Graphics: %@. No executable "
           @"memory was requested.",
          result, hardware, system, version, metal];
}
