//
//  OpenCVWrapper.m
//  Eaze
//
//  Created by John Silvester on 11/2/16.
//  Copyright © 2016 Hangar42. All rights reserved.
//

#import "OpenCVWrapper.h"
#import <opencv2/opencv.hpp>
#import "opencv2/highgui/ios.h"


@implementation OpenCVWrapper

CvVideoCamera* videoCamera;

+(NSString *)openCVVersionString
{
    return [NSString stringWithFormat:@"Version %s",CV_VERSION];
    
}

+(UIImage *) makeGrayFromImage:(UIImage *)image
{
    //transform UIIamge to cv:Mat
    cv::Mat imageMat;
    
    UIImageToMat(image, imageMat);
    
    //If the image was already in greyscale --> return
    if(imageMat.channels() == 1) return image;
    
    //otherwise transform the cv:Mat color image to gray
    cv::Mat grayMat;
   // cv::cvtColor(imageMat, grayMat, CV_BGR2GRAY);
    
    return MatToUIImage(grayMat);
    
}

+(void)startVideoWithView :(UIImageView*)imageView
{
    
    
    
    videoCamera = [[CvVideoCamera alloc] initWithParentView:imageView];
    videoCamera.defaultAVCaptureDevicePosition = AVCaptureDevicePositionFront;
    videoCamera.defaultAVCaptureSessionPreset = AVCaptureSessionPreset352x288;
    videoCamera.defaultAVCaptureVideoOrientation = AVCaptureVideoOrientationPortrait;
    videoCamera.defaultFPS = 30;
    videoCamera.grayscaleMode = NO;
    videoCamera.delegate = self;
   
}



+(void)cameraStart
{
     [videoCamera start];
}




@end
