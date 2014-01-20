//
//  ViewController.h
//  BusTrajectory
//
//  Created by Renan Camargo de Castro on 05/11/13.
//  Copyright (c) 2013 BEPiD. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreLocation/CoreLocation.h>
#import <MapKit/MapKit.h>

@interface ViewController : UIViewController <CLLocationManagerDelegate>
@property (weak, nonatomic) IBOutlet UITextField *distance;
@property (weak, nonatomic) IBOutlet MKMapView *mapVIew;

@end
