//
//  MainViewController.m
//  Yelp
//
//  Created by Timothy Lee on 3/21/14.
//  Copyright (c) 2014 codepath. All rights reserved.
//

#import "MainViewController.h"
#import "YelpClient.h"
#import "Business.h"
#import "BusinessCell.h"
#import "FiltersViewController.h"
#import "MapKit/Mapkit.h"
#import "MyLocation.h"

NSString * const kYelpConsumerKey = @"vxKwwcR_NMQ7WaEiQBK_CA";
NSString * const kYelpConsumerSecret = @"33QCvh5bIF5jIHR5klQr7RtBDhQ";
NSString * const kYelpToken = @"uRcRswHFYa1VkDrGV6LAW2F8clGh5JHV";
NSString * const kYelpTokenSecret = @"mqtKIxMIR4iBtBPZCmCLEb-Dz3Y";

@interface MainViewController () <UITableViewDataSource, UITableViewDelegate, FiltersViewControllerDelegate, UISearchBarDelegate, MKMapViewDelegate>

@property (nonatomic, strong) YelpClient *client;
@property (nonatomic, strong) NSMutableArray *businesses;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (strong, nonatomic) UISearchBar *searchBar;
@property (assign, nonatomic) NSInteger lastRequestIndex;
@property (nonatomic, assign) NSString* query;
@property (nonatomic, assign) NSDictionary* params;
@property (nonatomic, assign) NSInteger offset;
@property (nonatomic, assign) BOOL hasLoadedAllBusinesses;
@property (nonatomic, strong) UIView *tableFooterView;
@property (weak, nonatomic) IBOutlet MKMapView *mapView;
@property (nonatomic, assign) BOOL showingMapView;

- (void)fetchNewBusinessesWithQuery:(NSString*)query params:(NSDictionary *)params;

@end

@implementation MainViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // You can register for Yelp API keys here: http://www.yelp.com/developers/manage_api_keys
        self.client = [[YelpClient alloc] initWithConsumerKey:kYelpConsumerKey consumerSecret:kYelpConsumerSecret accessToken:kYelpToken accessSecret:kYelpTokenSecret];
        self.offset = 0;
        self.hasLoadedAllBusinesses = NO;
        [self fetchNewBusinessesWithQuery:@"Restaurants" params:nil];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self setupSearchBar];
    [self setupTableView];
    self.title = @"Yelp";
    [self setupNavigationAppearance:self.navigationController];
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Filter" style:UIBarButtonItemStylePlain target:self action:@selector(onFiltersButton)];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Map" style:UIBarButtonItemStylePlain target:self action:@selector(onMapButton)];
    self.lastRequestIndex = 0;
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent];


    self.tableFooterView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, 50)];
    UIActivityIndicatorView *loadingView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    [loadingView startAnimating];
    loadingView.center = self.tableFooterView.center;
    [self.tableFooterView addSubview:loadingView];
    self.tableView.tableFooterView = self.tableFooterView;

    [self setupMapView];
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (void)setupNavigationAppearance:(UINavigationController *)navigationController {
    navigationController.navigationBar.tintColor = [UIColor whiteColor];
    UIColor *yelpColor = [UIColor colorWithRed:198.0f/255.0f
                                         green:18.0f/255.0f
                                          blue:0.0f/255.0f
                                         alpha:1.0f];
    navigationController.navigationBar.barTintColor = yelpColor;
    navigationController.navigationBar.translucent = NO;
}


#pragma mark - SearchBar

- (void)setupSearchBar {
    self.searchBar = [[UISearchBar alloc] initWithFrame:CGRectMake(0, 0, 320, 44)];
    self.searchBar.delegate = self;
    self.navigationItem.titleView = self.searchBar;
    [self.searchBar sizeToFit];
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar {
    [self handleSearch:searchBar];
}

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText {
    [self handleSearch:searchBar];
}

- (void)handleSearch:(UISearchBar *)searchBar {
    [self fetchNewBusinessesWithQuery:searchBar.text params:self.params];
}

#pragma mark - Filter delegate methods

- (void)filtersViewController:(FiltersViewController *)filtersViewController didChangeFilters:(NSDictionary *)filters {
    NSLog(@"fire %@", filters);

    [self fetchNewBusinessesWithQuery:@"Restaurants" params:filters];
}

#pragma mark - MapView methods

- (void)setupMapView {
    //self.mapView.delegate = self;
    
    self.showingMapView = false;
    self.mapView.hidden = !self.showingMapView;

    // Do any additional setup after loading the view from its nib.
    // 1
    CLLocationCoordinate2D zoomLocation;
    zoomLocation.latitude = 37.774866;
    zoomLocation.longitude= -122.394556;

    // 2
    MKCoordinateRegion viewRegion = MKCoordinateRegionMakeWithDistance(zoomLocation, 5000, 5000);

    // 3
    [_mapView setRegion:viewRegion animated:YES];
}

- (void)addDataToMap {
    [self.mapView removeAnnotations:self.mapView.annotations];
    for (Business *business in self.businesses) {
        MyLocation *annotation = [[MyLocation alloc] initWithName:business.name address:business.address coordinate:business.coordinate] ;
        [self.mapView addAnnotation:annotation];

        dispatch_async(dispatch_get_main_queue(), ^{
            [self.mapView addAnnotation:annotation];
        });
    }
}

- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id <MKAnnotation>)annotation {
    static NSString *identifier = @"MyLocation";
    if ([annotation isKindOfClass:[MyLocation class]]) {

        MKAnnotationView *annotationView = (MKAnnotationView *) [self.mapView dequeueReusableAnnotationViewWithIdentifier:identifier];
        if (annotationView == nil) {
            annotationView = [[MKAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:identifier];
            annotationView.enabled = YES;
            annotationView.canShowCallout = YES;
            annotationView.image = [UIImage imageNamed:@"redpin"];
        } else {
            annotationView.annotation = annotation;
        }

        return annotationView;
    }

    return nil;
}

#pragma mark - Private methods

- (void)onFiltersButton {
    FiltersViewController *viewController = [[FiltersViewController alloc] init];
    viewController.delegate = self;
    UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:viewController];
    [self setupNavigationAppearance:navigationController];
    [self presentViewController:navigationController animated:YES completion:nil];
}

- (void)onMapButton {
    self.showingMapView = !self.showingMapView;
    self.navigationItem.rightBarButtonItem.title = (self.showingMapView) ? @"List" : @"Map";
    [UIView transitionWithView:self.view
                      duration:1.0
                       options:UIViewAnimationOptionTransitionFlipFromLeft
                    animations:^{
                        self.mapView.hidden   = !self.showingMapView;
                        self.tableView.hidden = self.showingMapView;
                    } completion:nil
     ];
}

- (void)fetchNewBusinessesWithQuery:(NSString *)query params:(NSDictionary *)params {
    self.businesses = [NSMutableArray array];
    self.offset = 0;
    self.hasLoadedAllBusinesses = NO;
    self.tableView.tableFooterView = self.tableFooterView;
    [self reloadData];
    [self fetchBusinessesWithQuery:query params:params];
    self.tableView.contentOffset = CGPointMake(0, 0);
}

- (void)fetchMoreBusinessesWithQuery {
    //NSLog(@"fetchMoreBusinessesWithQuery");
    self.offset = self.businesses.count;
    if (self.hasLoadedAllBusinesses) {
        return;
    }
    [self fetchBusinessesWithQuery:self.query params:self.params];
}

- (void)fetchBusinessesWithQuery:(NSString *)query params:(NSDictionary *)params {
    self.lastRequestIndex += 1;
    NSInteger requestIndex = self.lastRequestIndex;

    self.query = query;
    self.params = params;

    NSMutableDictionary *paramsWithOffset;
    if (params == nil) {
        paramsWithOffset = [NSMutableDictionary dictionary];
    } else {
        paramsWithOffset = [params mutableCopy];
    }
    paramsWithOffset[@"offset"] = @(self.offset);

    [self.client searchWithTerm:query params:paramsWithOffset success:^(AFHTTPRequestOperation *operation, id response) {
        // Since it seems we cannot cancel request, let's ignore response that are not from the last request
        if (requestIndex < self.lastRequestIndex) {
            return;
        }
        //NSLog(@"response: %@", response);
        NSArray *businessDictionaries = response[@"businesses"];
        NSInteger limit = 20;
        if (businessDictionaries.count < limit) {
            //NSLog(@"hasLoadedAllBusinesses");
            self.hasLoadedAllBusinesses = YES;
            self.tableView.tableFooterView = nil;
        }
        [self.businesses addObjectsFromArray: [Business businessesWithDictionaries:businessDictionaries]];
        //NSLog(@"businesses: %d", self.businesses.count);
        [self reloadData];
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"error: %@", [error description]);
    }];
}

- (void)reloadData{
    [self.tableView reloadData];
    [self addDataToMap];
}

#pragma mark - Table view methods

- (void)setupTableView {
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    [self.tableView registerNib:[UINib nibWithNibName:@"BusinessCell" bundle:nil] forCellReuseIdentifier:@"BusinessCell"];
    self.tableView.rowHeight = UITableViewAutomaticDimension;
    self.tableView.estimatedRowHeight = 85;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.businesses.count;
}

//- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
//    return 40;
//}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    BusinessCell *cell = [tableView dequeueReusableCellWithIdentifier:@"BusinessCell"];
    cell.business = self.businesses[indexPath.row];

    // Infinite Scrolling
    if (indexPath.row == self.businesses.count - 1) {
       [self fetchMoreBusinessesWithQuery];
    }
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:true];
}

-(void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([cell respondsToSelector:@selector(setSeparatorInset:)]) {
        [cell setSeparatorInset:UIEdgeInsetsZero];
    }

    if ([cell respondsToSelector:@selector(setLayoutMargins:)]) {
        [cell setLayoutMargins:UIEdgeInsetsZero];
    }
}

-(void)viewDidLayoutSubviews
{
    if ([self.tableView respondsToSelector:@selector(setSeparatorInset:)]) {
        [self.tableView setSeparatorInset:UIEdgeInsetsZero];
    }

    if ([self.tableView respondsToSelector:@selector(setLayoutMargins:)]) {
        [self.tableView setLayoutMargins:UIEdgeInsetsZero];
    }
}

@end
