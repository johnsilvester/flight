//
//  OpenCVWrapper.h
//  Eaze
//
//  Created by John Silvester on 11/2/16.
//  Copyright © 2016 Hangar42. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>



@interface OpenCVWrapper : NSObject

//define here interface with openCv

+(NSString *) openCVVersionString;

//function to convert an image to grayscale
+(UIImage *) makeGrayFromImage: (UIImage *) image;

//function for video capture
+(void)startVideoWithView :(UIImageView*)imageView;

//function for starting capture
+(void)cameraStart;


//properties
//@property (nonatomic, retain) CvVideoCamera* videoCamera;


@end
