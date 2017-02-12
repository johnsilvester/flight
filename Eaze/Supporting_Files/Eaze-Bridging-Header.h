//
//  Use this file to import your target's public headers that you would like to expose to Swift.
//

#import "MRProgressOverlayView.h"
#import "GBSControlStick.h"
#import "OpenCVWrapper.h"


@interface Detector: NSObject

- (id)init;
- (UIImage *)recognizeFace:(UIImage *)image;
-(CGRect)grabImage;

@end
