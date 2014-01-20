//
//  ViewController.m
//  BusTrajectory
//
//  Created by Renan Camargo de Castro on 05/11/13.
//  Copyright (c) 2013 BEPiD. All rights reserved.
//

#import "ViewController.h"
#import <CoreLocation/CoreLocation.h>
#import "TFHpple.h"
#define SERVERIP @"http://127.0.0.1:8000"
#define SERVERCOUNT [NSURL URLWithString:[NSString stringWithFormat:@"%@/count",SERVERIP]]

@interface ViewController ()
@property (nonatomic) CLLocationManager *locationManager;
@property (atomic) NSMutableArray*	bus;
@property (atomic) NSMutableArray* busLines;
@property (atomic) NSMutableArray* busPoints;
@property (weak, nonatomic) IBOutlet UITextField *textField;
@property (nonatomic) NSOperationQueue* queue;

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
	self.queue = [[NSOperationQueue alloc] init];
	self.locationManager = [[CLLocationManager alloc] init];
	UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(dismissKeyboard:)];
	[self.view addGestureRecognizer:tap];
}
-(IBAction)dismissKeyboard:(id)sender{
	[self.textField resignFirstResponder];
}
- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)getCurrentLocation:(id)sender {
	self.locationManager.delegate = self;
    self.locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters;
    [self.locationManager startUpdatingLocation];

}


#pragma mark - CLLocationManagerDelegate

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error
{
    NSLog(@"didFailWithError: %@", error);
    UIAlertView *errorAlert = [[UIAlertView alloc]
							   initWithTitle:@"Error" message:@"Failed to Get Your Location" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
    [errorAlert show];
}


-(NSMutableDictionary*) getBusStopsWithArrayOfStops:(NSArray*)stops closeToPoint:(CLLocation*) point withDistance:(double) distance{
	NSMutableArray* points = [[NSMutableArray alloc]init];
	NSMutableDictionary* dic = [[NSMutableDictionary alloc]init];
	for (NSArray* a in stops) {
		for (CLLocation* b in a) {
			if ([point distanceFromLocation:b] <= distance) {
				[points addObject:b];
			}

		}
		if ([points count] > 0) {
			[dic setObject:points forKey:[NSNumber numberWithInt:[stops indexOfObject:a]]];
		}
		points = [[NSMutableArray alloc] init];
	}
	return dic;
}


/**	Retorna um dicionário com as informações do json
 */
-(NSDictionary*) parseBusJsonWithName:(NSString*)name{
	NSError *jsonParsingError = nil;
	NSString *path = [[NSBundle mainBundle] pathForResource:name ofType:@"json"];
	NSData *data = [NSData dataWithContentsOfFile:path];
	
	NSDictionary *dicionarioDoJson = [NSJSONSerialization JSONObjectWithData:data
																	 options:0 error:&jsonParsingError];
	NSArray *tempPolylineIda, *tempPolylineVolta, *tempMarks;
	NSMutableArray  *marks, *polylineIda, *polylineVolta;
	marks= [[NSMutableArray alloc] init];
	polylineIda = [[NSMutableArray alloc] init];
	polylineVolta = [[NSMutableArray alloc] init];
	NSString * nome = dicionarioDoJson[@"name"];
	tempPolylineIda = dicionarioDoJson[@"polyline_ida"];;
	tempPolylineVolta = dicionarioDoJson[@"polyline_volta"];
	tempMarks = dicionarioDoJson[@"pontos"];
	
	//Initialize marks array
	for (NSDictionary* point in tempMarks) {
		CLLocation *locA = [[CLLocation alloc] initWithLatitude:[[point objectForKey:@"lat"] doubleValue] longitude:[[point objectForKey:@"lng"] doubleValue]];
		[marks addObject:locA];
	}
	//Initialize polyline array
	for (NSDictionary* point in tempPolylineIda) {
		CLLocation *locA = [[CLLocation alloc] initWithLatitude:[[point objectForKey:@"lat"] doubleValue] longitude:[[point objectForKey:@"lng"] doubleValue]];
		[polylineIda addObject:locA];
	}
	for (NSDictionary* point in tempPolylineVolta) {
		CLLocation *locA = [[CLLocation alloc] initWithLatitude:[[point objectForKey:@"lat"] doubleValue] longitude:[[point objectForKey:@"lng"] doubleValue]];
		[polylineVolta addObject:locA];
	}
	
	return @{@"nome" : nome, @"ida": polylineIda, @"volta" : polylineVolta, @"marks" : marks};
}


-(void) getBusWithLocation:(CLLocation*)currentLocation{
	
	if (!self.busLines && !self.busPoints) {
			self.busLines = [[NSMutableArray alloc]init];
			self.busPoints = [[NSMutableArray alloc]init];
			NSString *c =[NSString stringWithContentsOfURL:[NSURL URLWithString:@"http://127.0.0.1:8000/count"] encoding:NSUTF8StringEncoding error:nil];
			int count = c.integerValue;
			NSDictionary* busLine;
			for (int i = 1; i <count; i++) {
				busLine = [self parseBusJsonWithName:[NSString stringWithFormat:@"line_%d", i]];
				[self.busLines addObject:busLine];
				[self.busPoints addObject:busLine[@"marks"]];
			}
	}
	
	NSMutableDictionary* dic = [self getBusStopsWithArrayOfStops:self.busPoints closeToPoint:currentLocation withDistance:[[self.distance text] floatValue]];
	NSLog(@"%d",[dic count]);
	NSLog(@"%@",dic);

	for (NSNumber* number in dic) {
		for (CLLocation* point in [dic objectForKey:number]) {
			MKPointAnnotation *annotationPoint = [[MKPointAnnotation alloc] init];
			annotationPoint.coordinate = point.coordinate;
			annotationPoint.title = [NSString stringWithFormat:@"%@",number];

			int index = [[self.mapVIew annotations] indexOfObjectPassingTest:^BOOL(MKPointAnnotation* obj, NSUInteger idx, BOOL *stop) {
				if (obj.coordinate.latitude == point.coordinate.latitude && obj.coordinate.longitude == point.coordinate.longitude) {
					obj.title = [NSString stringWithFormat:@"%@, %@",obj.title, number];
					*stop = YES;
					return YES;
				}
				return NO;
			}];
			if (index == NSNotFound) {
				[self.mapVIew addAnnotation:annotationPoint];
			}
		}
	}
	
	

	
}

- (void)locationManager:(CLLocationManager *)manager didUpdateToLocation:(CLLocation *)newLocation fromLocation:(CLLocation *)oldLocation
{
    NSLog(@"didUpdateToLocation: %@", newLocation);
    CLLocation *currentLocation = newLocation;
	
	
    // Stop Location Manager
    [self.locationManager stopUpdatingLocation];
	
	[self getBusWithLocation:currentLocation];
	
	
}

@end

