#import "FIRSegmentationComponent.h"

#import <FirebaseCore/FIRAppInternal.h>
#import <FirebaseCore/FIRComponentContainer.h>
#import <FirebaseCore/FIROptionsInternal.h>
#import <FirebaseSegmentation/Sources/Private/FIRSegmentationInternal.h>

#ifndef FIRSegmentation_VERSION
#error "FIRSegmentation_VERSION is not defined: \
add -DFIRSegmentation_VERSION=... to the build invocation"
#endif

#define STR(x) STR_EXPAND(x)
#define STR_EXPAND(x) #x

NSString *const kFirebaseSegmentationErrorDomain = @"com.firebase.segmentation";

@implementation FIRSegmentationComponent

/// Default method for retrieving a Segmentation instance, or creating one if it doesn't exist.
- (FIRSegmentation *)segmentation {
  // Validate the required information is available.
  FIROptions *options = self.app.options;
  NSString *errorPropertyName;
  if (options.googleAppID.length == 0) {
    errorPropertyName = @"googleAppID";
  } else if (options.GCMSenderID.length == 0) {
    errorPropertyName = @"GCMSenderID";
  }

  if (errorPropertyName) {
    [NSException
         raise:kFirebaseSegmentationErrorDomain
        format:@"%@",
               [NSString
                   stringWithFormat:
                       @"Firebase Segmentation is missing the required %@ property from the "
                       @"configured FirebaseApp and will not be able to function properly. Please "
                       @"fix this issue to ensure that Firebase is correctly configured.",
                       errorPropertyName]];
  }

  FIRSegmentation *instance = self.segmentationInstance;
  if (!instance) {
    instance = [[FIRSegmentation alloc] initWithAppName:self.app.name FIROptions:self.app.options];
    self.segmentationInstance = instance;
  }

  return instance;
}

/// Default initializer.
- (instancetype)initWithApp:(FIRApp *)app {
  self = [super init];
  if (self) {
    _app = app;
    _segmentationInstance = nil;
  }
  return self;
}

#pragma mark - Lifecycle

+ (void)load {
  // Register as an internal library to be part of the initialization process. The name comes from
  // go/firebase-sdk-platform-info.
  [FIRApp registerInternalLibrary:self
                         withName:@"fire-seg"
                      withVersion:[NSString stringWithUTF8String:STR(FIRSegmentation_VERSION)]];
}

#pragma mark - Interoperability

+ (NSArray<FIRComponent *> *)componentsToRegister {
  FIRComponent *segProvider = [FIRComponent
      componentWithProtocol:@protocol(FIRSegmentationProvider)
        instantiationTiming:FIRInstantiationTimingAlwaysEager
               dependencies:@[]
              creationBlock:^id _Nullable(FIRComponentContainer *container, BOOL *isCacheable) {
                // Cache the component so instances of Segmentation are cached.
                *isCacheable = YES;
                return [[FIRSegmentationComponent alloc] initWithApp:container.app];
              }];
  return @[ segProvider ];
}

@synthesize instances;

@end
