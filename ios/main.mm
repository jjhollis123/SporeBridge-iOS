#import <UIKit/UIKit.h>

#include <SDL_main.h>

#import "SporeImportViewController.h"

@interface SporeBridgeAppDelegate : UIResponder <UIApplicationDelegate>
@property(nonatomic, strong) UIWindow* window;
@end

@implementation SporeBridgeAppDelegate

- (BOOL)application:(UIApplication*)application
    didFinishLaunchingWithOptions:(NSDictionary*)launchOptions {
  (void)application;
  (void)launchOptions;

  self.window = [[UIWindow alloc] initWithFrame:UIScreen.mainScreen.bounds];
  SporeImportViewController* controller =
      [[SporeImportViewController alloc] init];
  self.window.rootViewController =
      [[UINavigationController alloc] initWithRootViewController:controller];
  [self.window makeKeyAndVisible];
  return YES;
}

@end

int main(int argc, char* argv[]) {
  // SporeBridge owns the UIKit lifecycle instead of SDLUIKitDelegate.
  SDL_SetMainReady();
  @autoreleasepool {
    return UIApplicationMain(argc, argv, nil,
                             NSStringFromClass(
                                 [SporeBridgeAppDelegate class]));
  }
}
