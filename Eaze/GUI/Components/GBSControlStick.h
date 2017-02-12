#import <UIKit/UIKit.h>

//! Project version number for GBSControlStick.
FOUNDATION_EXPORT double GBSControlStickVersionNumber;

//! Project version string for GBSControlStick.
FOUNDATION_EXPORT const unsigned char GBSControlStickVersionString[];


@protocol GBSControlStickDelegate <NSObject>

@optional
- (void)didUpdateValuesX:(CGFloat)x andY:(CGFloat)y withTag:(CGFloat)tag;
- (void)didUpdateValuesX:(CGFloat)x andY:(CGFloat)y;
- (void)didUpdateValuesTopLeft:(CGFloat)tl lowLeft:(CGFloat)ll lowRight:(CGFloat)lr topRight:(CGFloat)tr;

@end


@interface GBSControlStick : UIView

@property(nonatomic, strong) id<GBSControlStickDelegate> delegate;

@property(nonatomic) bool isThrottle;

@property(nonatomic) bool isPosHold;

@property(nonatomic) CGFloat xValue;
@property(nonatomic) CGFloat yValue;

- (id)initAtPoint:(CGPoint)point withDelegate:(id)delegate;

-(void)resetStickView;


@end


