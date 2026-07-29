#import "SporeImportViewController.h"

#import <UniformTypeIdentifiers/UniformTypeIdentifiers.h>

#import "RuntimeReadinessProbe.h"

#include <filesystem>
#include <string>

#include "spore_install_validator.h"

namespace {

NSString* NSStringFromPath(const std::filesystem::path& path) {
  return [NSString stringWithUTF8String:path.string().c_str()];
}

NSString* NSStringFromString(const std::string& value) {
  return [NSString stringWithUTF8String:value.c_str()];
}

}  // namespace

@interface SporeImportViewController () <UIDocumentPickerDelegate>
@property(nonatomic, strong) UILabel* statusLabel;
@property(nonatomic, strong) UIButton* importButton;
@property(nonatomic, strong) UIButton* runtimeProbeButton;
@property(nonatomic, strong) UIActivityIndicatorView* activityIndicator;
@end

@implementation SporeImportViewController

- (void)viewDidLoad {
  [super viewDidLoad];

  self.title = @"Spore iOS Test";
  self.view.backgroundColor = UIColor.systemBackgroundColor;

  UILabel* heading = [[UILabel alloc] init];
  heading.translatesAutoresizingMaskIntoConstraints = NO;
  heading.text = @"Import your original game";
  heading.font = [UIFont preferredFontForTextStyle:UIFontTextStyleTitle1];
  heading.adjustsFontForContentSizeCategory = YES;
  heading.textAlignment = NSTextAlignmentCenter;

  UILabel* explanation = [[UILabel alloc] init];
  explanation.translatesAutoresizingMaskIntoConstraints = NO;
  explanation.text =
      @"Choose the top-level folder from your purchased Windows copy. "
       @"Files stay on this device. This test does not include any EA assets.";
  explanation.font = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
  explanation.adjustsFontForContentSizeCategory = YES;
  explanation.numberOfLines = 0;
  explanation.textAlignment = NSTextAlignmentCenter;

  self.statusLabel = [[UILabel alloc] init];
  self.statusLabel.translatesAutoresizingMaskIntoConstraints = NO;
  self.statusLabel.font =
      [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
  self.statusLabel.adjustsFontForContentSizeCategory = YES;
  self.statusLabel.numberOfLines = 0;
  self.statusLabel.textAlignment = NSTextAlignmentCenter;

  self.importButton = [UIButton buttonWithType:UIButtonTypeSystem];
  self.importButton.translatesAutoresizingMaskIntoConstraints = NO;
  [self.importButton setTitle:@"Choose Spore folder"
                     forState:UIControlStateNormal];
  self.importButton.titleLabel.font =
      [UIFont preferredFontForTextStyle:UIFontTextStyleHeadline];
  self.importButton.configuration =
      [UIButtonConfiguration filledButtonConfiguration];
  [self.importButton addTarget:self
                        action:@selector(chooseFolder)
              forControlEvents:UIControlEventTouchUpInside];

  self.runtimeProbeButton = [UIButton buttonWithType:UIButtonTypeSystem];
  self.runtimeProbeButton.translatesAutoresizingMaskIntoConstraints = NO;
  [self.runtimeProbeButton setTitle:@"Run runtime readiness test"
                           forState:UIControlStateNormal];
  self.runtimeProbeButton.titleLabel.font =
      [UIFont preferredFontForTextStyle:UIFontTextStyleHeadline];
  self.runtimeProbeButton.configuration =
      [UIButtonConfiguration tintedButtonConfiguration];
  self.runtimeProbeButton.enabled = NO;
  [self.runtimeProbeButton addTarget:self
                              action:@selector(runRuntimeReadinessProbe)
                    forControlEvents:UIControlEventTouchUpInside];

  self.activityIndicator = [[UIActivityIndicatorView alloc]
      initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleLarge];
  self.activityIndicator.translatesAutoresizingMaskIntoConstraints = NO;
  self.activityIndicator.hidesWhenStopped = YES;

  UILabel* runtimeStatus = [[UILabel alloc] init];
  runtimeStatus.translatesAutoresizingMaskIntoConstraints = NO;
  runtimeStatus.text =
      @"Runtime status: device probe available; Boxedwine interpreter next.";
  runtimeStatus.font =
      [UIFont preferredFontForTextStyle:UIFontTextStyleFootnote];
  runtimeStatus.textColor = UIColor.secondaryLabelColor;
  runtimeStatus.numberOfLines = 0;
  runtimeStatus.textAlignment = NSTextAlignmentCenter;

  UIStackView* stack = [[UIStackView alloc]
      initWithArrangedSubviews:@[
        heading, explanation, self.importButton, self.runtimeProbeButton,
        self.activityIndicator, self.statusLabel, runtimeStatus
      ]];
  stack.translatesAutoresizingMaskIntoConstraints = NO;
  stack.axis = UILayoutConstraintAxisVertical;
  stack.alignment = UIStackViewAlignmentFill;
  stack.spacing = 18.0;

  [self.view addSubview:stack];
  UILayoutGuide* guide = self.view.safeAreaLayoutGuide;
  [NSLayoutConstraint activateConstraints:@[
    [stack.leadingAnchor constraintEqualToAnchor:guide.leadingAnchor
                                        constant:28.0],
    [stack.trailingAnchor constraintEqualToAnchor:guide.trailingAnchor
                                         constant:-28.0],
    [stack.centerYAnchor constraintEqualToAnchor:guide.centerYAnchor],
    [self.importButton.heightAnchor constraintGreaterThanOrEqualToConstant:52.0],
    [self.runtimeProbeButton.heightAnchor
        constraintGreaterThanOrEqualToConstant:52.0],
  ]];

  [self reportExistingImport];
}

- (void)chooseFolder {
  UIDocumentPickerViewController* picker =
      [[UIDocumentPickerViewController alloc]
          initForOpeningContentTypes:@[ UTTypeFolder ]
                             asCopy:NO];
  picker.delegate = self;
  picker.allowsMultipleSelection = NO;
  [self presentViewController:picker animated:YES completion:nil];
}

- (NSURL*)importDestinationURL {
  NSURL* documents = [NSFileManager.defaultManager
      URLsForDirectory:NSDocumentDirectory
             inDomains:NSUserDomainMask]
                         .firstObject;
  return [documents URLByAppendingPathComponent:@"ImportedSpore"
                                    isDirectory:YES];
}

- (void)reportExistingImport {
  NSURL* destination = [self importDestinationURL];
  BOOL isDirectory = NO;
  if (![NSFileManager.defaultManager
          fileExistsAtPath:destination.path
               isDirectory:&isDirectory] ||
      !isDirectory) {
    self.runtimeProbeButton.enabled = NO;
    self.statusLabel.text =
        @"No installation imported yet. Extract any ZIP in Files first, then "
         @"choose the complete game folder.";
    return;
  }

  const auto report = sporebridge::validate_installation(
      std::filesystem::path(destination.fileSystemRepresentation));
  self.runtimeProbeButton.enabled = report.valid;
  self.statusLabel.text =
      report.valid
          ? [NSString
                stringWithFormat:
                    @"Imported installation ready: %@. The Windows runtime "
                     @"still needs to be attached before the game can launch.",
                    NSStringFromString(
                        sporebridge::edition_name(report.edition))]
          : NSStringFromString(report.message);
}

- (void)documentPicker:(UIDocumentPickerViewController*)controller
    didPickDocumentsAtURLs:(NSArray<NSURL*>*)urls {
  (void)controller;
  NSURL* selectedURL = urls.firstObject;
  if (selectedURL == nil) {
    return;
  }

  BOOL scoped = [selectedURL startAccessingSecurityScopedResource];
  self.importButton.enabled = NO;
  self.runtimeProbeButton.enabled = NO;
  [self.activityIndicator startAnimating];
  self.statusLabel.text = @"Checking the selected installation…";

  dispatch_async(
      dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0), ^{
        const auto sourceReport = sporebridge::validate_installation(
            std::filesystem::path(selectedURL.fileSystemRepresentation));

        if (!sourceReport.valid) {
          if (scoped) {
            [selectedURL stopAccessingSecurityScopedResource];
          }
          dispatch_async(dispatch_get_main_queue(), ^{
            [self finishWithMessage:NSStringFromString(sourceReport.message)];
          });
          return;
        }

        NSURL* destination = [self importDestinationURL];
        NSError* copyError = nil;
        BOOL alreadyExists = [NSFileManager.defaultManager
            fileExistsAtPath:destination.path];
        if (!alreadyExists) {
          [NSFileManager.defaultManager copyItemAtURL:selectedURL
                                                toURL:destination
                                                error:&copyError];
        }

        if (scoped) {
          [selectedURL stopAccessingSecurityScopedResource];
        }

        if (alreadyExists) {
          dispatch_async(dispatch_get_main_queue(), ^{
            [self
                finishWithMessage:
                    @"An installation is already present. Remove "
                     @"ImportedSpore from this app’s folder in Files before "
                     @"importing a replacement."];
            self.runtimeProbeButton.enabled = YES;
          });
          return;
        }

        if (copyError != nil) {
          dispatch_async(dispatch_get_main_queue(), ^{
            [self
                finishWithMessage:
                    [NSString stringWithFormat:@"Import failed: %@",
                                               copyError.localizedDescription]];
          });
          return;
        }

        const auto copiedReport = sporebridge::validate_installation(
            std::filesystem::path(destination.fileSystemRepresentation));
        if (!copiedReport.valid) {
          dispatch_async(dispatch_get_main_queue(), ^{
            [self finishWithMessage:
                      @"The folder copied, but its contents did not pass the "
                       @"final validation check."];
          });
          return;
        }

        NSDictionary* manifest = @{
          @"edition" :
              NSStringFromString(
                  sporebridge::edition_name(copiedReport.edition)),
          @"executable" : NSStringFromPath(
              std::filesystem::relative(copiedReport.executable,
                                        copiedReport.root)),
          @"dataDirectory" : NSStringFromPath(
              std::filesystem::relative(copiedReport.data_directory,
                                        copiedReport.root)),
          @"packageCount" : @(copiedReport.package_count),
          @"runtimeAttached" : @NO,
          @"runtimeProbeAvailable" : @YES,
          @"projectVersion" : @"0.2.0",
        };
        NSData* manifestData =
            [NSJSONSerialization dataWithJSONObject:manifest
                                            options:NSJSONWritingPrettyPrinted
                                              error:nil];
        [manifestData
            writeToURL:[destination
                           URLByAppendingPathComponent:@"sporebridge-import.json"]
               options:NSDataWritingAtomic
                 error:nil];

        dispatch_async(dispatch_get_main_queue(), ^{
          self.runtimeProbeButton.enabled = YES;
          [self
              finishWithMessage:
                  [NSString
                      stringWithFormat:
                          @"Import successful: %@. The files are ready for "
                           @"the Boxedwine runtime milestone.",
                          NSStringFromString(sporebridge::edition_name(
                              copiedReport.edition))]];
        });
      });
}

- (void)runRuntimeReadinessProbe {
  self.importButton.enabled = NO;
  self.runtimeProbeButton.enabled = NO;
  [self.activityIndicator startAnimating];
  self.statusLabel.text = @"Testing this iPad’s runtime capabilities…";

  dispatch_async(
      dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0), ^{
        NSMutableDictionary<NSString*, id>* report =
            [SporeBridgeRunRuntimeReadinessProbe() mutableCopy];
        report[@"projectVersion"] = @"0.2.0";

        NSURL* importURL = [self importDestinationURL];
        NSURL* manifestURL =
            [importURL URLByAppendingPathComponent:@"sporebridge-import.json"];
        NSData* manifestData = [NSData dataWithContentsOfURL:manifestURL];
        if (manifestData != nil) {
          NSDictionary* manifest =
              [NSJSONSerialization JSONObjectWithData:manifestData
                                              options:0
                                                error:nil];
          if ([manifest isKindOfClass:NSDictionary.class]) {
            report[@"importedEdition"] =
                manifest[@"edition"] ?: @"unknown";
            report[@"targetExecutable"] =
                manifest[@"executable"] ?: @"unknown";
          }
        }

        NSError* directoryError = nil;
        NSURL* documents = [NSFileManager.defaultManager
            URLsForDirectory:NSDocumentDirectory
                   inDomains:NSUserDomainMask]
                               .firstObject;
        NSURL* diagnostics =
            [documents URLByAppendingPathComponent:@"SporeBridgeDiagnostics"
                                       isDirectory:YES];
        BOOL directoryReady = [NSFileManager.defaultManager
            createDirectoryAtURL:diagnostics
     withIntermediateDirectories:YES
                      attributes:nil
                           error:&directoryError];

        NSError* serialisationError = nil;
        NSData* data =
            [NSJSONSerialization dataWithJSONObject:report
                                            options:(NSJSONWritingPrettyPrinted |
                                                     NSJSONWritingSortedKeys)
                                              error:&serialisationError];
        NSError* writeError = nil;
        BOOL written =
            directoryReady && data != nil &&
            [data writeToURL:
                      [diagnostics
                          URLByAppendingPathComponent:@"runtime-readiness.json"]
                    options:NSDataWritingAtomic
                      error:&writeError];

        NSString* summary = SporeBridgeRuntimeReadinessSummary(report);
        NSString* message = nil;
        if (written) {
          message = [summary
              stringByAppendingString:
                  @" Report saved in Files → SporeBridge → "
                   @"SporeBridgeDiagnostics → runtime-readiness.json."];
        } else {
          NSError* error = writeError ?: serialisationError ?: directoryError;
          message = [NSString
              stringWithFormat:@"%@ The report could not be saved: %@",
                               summary,
                               error.localizedDescription ?: @"unknown error"];
        }

        dispatch_async(dispatch_get_main_queue(), ^{
          [self.activityIndicator stopAnimating];
          self.importButton.enabled = YES;
          self.runtimeProbeButton.enabled = YES;
          self.statusLabel.text = message;
        });
      });
}

- (void)documentPickerWasCancelled:
    (UIDocumentPickerViewController*)controller {
  (void)controller;
  self.statusLabel.text = @"Import cancelled.";
}

- (void)finishWithMessage:(NSString*)message {
  [self.activityIndicator stopAnimating];
  self.importButton.enabled = YES;
  self.statusLabel.text = message;
}

@end
