//
//  FiltersViewController.m
//  Yelp
//
//  Created by Florian Jourda on 2/11/15.
//  Copyright (c) 2015 codepath. All rights reserved.
//

#import "FiltersViewController.h"
#import "SwitchCell.h"

//category
//Sort by (best match, distance, highest rated)
//Distance radius (meters),
//Offering a deal (on/off).

typedef enum SectionsInTableView {
    SectionMostPopular,
    SectionDistance,
    SectionSortBy,
    SectionCategory
} SectionsInTableView;

typedef enum SortBy {
    SortByBestMatch,
    SortByDistance,
    SortByHighestRated,
} SortBy;

typedef enum Distance {
    DistanceAuto,
    DistanceTwoBlocks,
    DistanceSixBlocks,
    DistanceOneMile,
    DistanceFiveMile,
} Distance;

@interface FiltersViewController () <UITableViewDataSource, UITableViewDelegate, SwitchCellDelegate>

@property (nonatomic, readonly) NSDictionary *filters;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (nonatomic, strong) NSArray *categories;
@property (nonatomic, strong) NSMutableSet *selectedCategories;
@property (nonatomic, assign) SortBy selectedSortBy;
@property (nonatomic, assign) BOOL offeringADeal;
@property (nonatomic, assign) Distance selectedDistance;

- (void)initCategories;

@end

@implementation FiltersViewController
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];

    if (self) {
        self.selectedCategories = [NSMutableSet set];
        [self initCategories];
        self.selectedSortBy = SortByBestMatch;
        self.selectedDistance = DistanceAuto;
        self.offeringADeal = NO;
    }

    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.

    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Cancel" style:UIBarButtonItemStylePlain target:self action:@selector(onCancelButton)];

    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Apply" style:UIBarButtonItemStylePlain target:self action:@selector(onApplyButton)];

    [self setupTableView];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


#pragma mark - Table view methods

- (void)setupTableView {
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    [self.tableView registerNib:[UINib nibWithNibName:@"SwitchCell" bundle:nil] forCellReuseIdentifier:@"SwitchCell"];
    self.tableView.rowHeight = UITableViewAutomaticDimension;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 4;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    switch (section) {
        case SectionCategory: return @"Category";
        case SectionDistance: return @"Distance";
        case SectionMostPopular: return @"Most Popular";
        case SectionSortBy: return @"Sort By"; // (best match, distance, highest rated)
        default: return nil;
    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    switch (section) {
        case SectionCategory: return self.categories.count;
        case SectionDistance: return 5;
        case SectionMostPopular: return 1;
        case SectionSortBy: return 3;
        default: return 0;
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:true];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    SwitchCell *cell;
    NSString *cellTitle;
    switch (indexPath.section) {
        case SectionCategory:
            cell = [tableView dequeueReusableCellWithIdentifier:@"SwitchCell"];
            cell.on = [self.selectedCategories containsObject:self.categories[indexPath.row]];
            cell.titleLabel.text = self.categories[indexPath.row][@"name"];
            cell.delegate = self;
            return cell;
        case SectionDistance:
            switch (indexPath.row) {
                case DistanceAuto: cellTitle = @"Auto"; break;
                case DistanceTwoBlocks: cellTitle = @"2 blocks"; break;
                case DistanceSixBlocks: cellTitle = @"6 blocks"; break;
                case DistanceOneMile: cellTitle = @"1 mile"; break;
                case DistanceFiveMile: cellTitle = @"5 miles"; break;
            }
            cell = [tableView dequeueReusableCellWithIdentifier:@"SwitchCell"];
            cell.on = ((NSInteger)self.selectedDistance == indexPath.row);
            cell.titleLabel.text = cellTitle;
            cell.delegate = self;
            return cell;
        case SectionMostPopular:
            cell = [tableView dequeueReusableCellWithIdentifier:@"SwitchCell"];
            cell.on = self.offeringADeal;
            cell.titleLabel.text = @"Offering a deal";
            cell.delegate = self;
            return cell;
        case SectionSortBy:
            switch (indexPath.row) {
                case SortByBestMatch: cellTitle = @"Best Match"; break;
                case SortByDistance: cellTitle = @"Distance"; break;
                case SortByHighestRated: cellTitle = @"Highest Rated"; break;
            }
            cell = [tableView dequeueReusableCellWithIdentifier:@"SwitchCell"];
            cell.on = ((NSInteger)self.selectedSortBy == indexPath.row);
            cell.titleLabel.text = cellTitle;
            cell.delegate = self;
            return cell;
        default:
            return nil;
    }
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

#pragma mark - Switch cell delegate methods

- (void)switchCell:(SwitchCell *)switchCell didUpdateValue:(Boolean)value {
    NSIndexPath *indexPath = [self.tableView indexPathForCell:switchCell];
    switch (indexPath.section) {
        case SectionCategory:
            if (value) {
                [self.selectedCategories addObject:self.categories[indexPath.row]];
            } else {
                [self.selectedCategories removeObject:self.categories[indexPath.row]];
            }
            return;
        case SectionDistance:
            if (value) {
                self.selectedDistance = (Distance)indexPath.row;
            } else {
                self.selectedDistance = DistanceAuto;
            }
            [self.tableView reloadData];
            return;
        case SectionMostPopular:
            self.offeringADeal = value;
            return;
        case SectionSortBy: {
            if (value) {
                self.selectedSortBy = (SortBy)indexPath.row;
            } else {
                self.selectedSortBy = SortByBestMatch;
            }
            //[UIView animateWithDuration:0.5 animations:^{
            [self.tableView reloadData];
            //}];
            return;
        }
        default:
            return;
    }
}

#pragma mark - Private methods

- (NSDictionary *)filters {
    NSMutableDictionary *filters = [NSMutableDictionary dictionary];
    if (self.selectedCategories.count > 0) {
        NSMutableArray *names = [NSMutableArray array];
        for (NSDictionary *category in self.selectedCategories) {
            [names addObject:category[@"code"]];
        }
        NSString *categoryFilter = [names componentsJoinedByString:@", "];
        [filters setObject:categoryFilter forKey:@"category_filter"];
    }

    filters[@"sort"] = @(self.selectedSortBy);

    filters[@"deals_filter"] = @(self.offeringADeal);

    NSInteger radius;
    switch (self.selectedDistance) {
        case DistanceTwoBlocks:
            radius = 200;
            break;
        case DistanceSixBlocks:
            radius = 600;
            break;
        case DistanceOneMile:
            radius = 1609;
            break;
        case DistanceFiveMile:
            radius = 8047;
            break;
        case DistanceAuto:
            radius = 0;
    }
    if (radius > 0) {
        filters[@"radius_filter"] = @(radius);
    }

    return filters;
}

- (void)onCancelButton {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)onApplyButton {
    [self.delegate filtersViewController:self didChangeFilters:self.filters];
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)initCategories {
    self.categories = @[
        @{@"name" : @"Afghan", @"code": @"afghani" },
        @{@"name" : @"African", @"code": @"african" },
        @{@"name" : @"American, New", @"code": @"newamerican" },
        @{@"name" : @"American, Traditional", @"code": @"tradamerican" },
        @{@"name" : @"Arabian", @"code": @"arabian" },
        @{@"name" : @"Argentine", @"code": @"argentine" },
        @{@"name" : @"Armenian", @"code": @"armenian" },
        @{@"name" : @"Asian Fusion", @"code": @"asianfusion" },
        @{@"name" : @"Asturian", @"code": @"asturian" },
        @{@"name" : @"Australian", @"code": @"australian" },
        @{@"name" : @"Austrian", @"code": @"austrian" },
        @{@"name" : @"Baguettes", @"code": @"baguettes" },
        @{@"name" : @"Bangladeshi", @"code": @"bangladeshi" },
        @{@"name" : @"Barbeque", @"code": @"bbq" },
        @{@"name" : @"Basque", @"code": @"basque" },
        @{@"name" : @"Bavarian", @"code": @"bavarian" },
        @{@"name" : @"Beer Garden", @"code": @"beergarden" },
        @{@"name" : @"Beer Hall", @"code": @"beerhall" },
        @{@"name" : @"Beisl", @"code": @"beisl" },
        @{@"name" : @"Belgian", @"code": @"belgian" },
        @{@"name" : @"Bistros", @"code": @"bistros" },
        @{@"name" : @"Black Sea", @"code": @"blacksea" },
        @{@"name" : @"Brasseries", @"code": @"brasseries" },
        @{@"name" : @"Brazilian", @"code": @"brazilian" },
        @{@"name" : @"Breakfast & Brunch", @"code": @"breakfast_brunch" },
        @{@"name" : @"British", @"code": @"british" },
        @{@"name" : @"Buffets", @"code": @"buffets" },
        @{@"name" : @"Bulgarian", @"code": @"bulgarian" },
        @{@"name" : @"Burgers", @"code": @"burgers" },
        @{@"name" : @"Burmese", @"code": @"burmese" },
        @{@"name" : @"Cafes", @"code": @"cafes" },
        @{@"name" : @"Cafeteria", @"code": @"cafeteria" },
        @{@"name" : @"Cajun/Creole", @"code": @"cajun" },
        @{@"name" : @"Cambodian", @"code": @"cambodian" },
        @{@"name" : @"Canadian", @"code": @"New)" },
        @{@"name" : @"Canteen", @"code": @"canteen" },
        @{@"name" : @"Caribbean", @"code": @"caribbean" },
        @{@"name" : @"Catalan", @"code": @"catalan" },
        @{@"name" : @"Chech", @"code": @"chech" },
        @{@"name" : @"Cheesesteaks", @"code": @"cheesesteaks" },
        @{@"name" : @"Chicken Shop", @"code": @"chickenshop" },
        @{@"name" : @"Chicken Wings", @"code": @"chicken_wings" },
        @{@"name" : @"Chilean", @"code": @"chilean" },
        @{@"name" : @"Chinese", @"code": @"chinese" },
        @{@"name" : @"Comfort Food", @"code": @"comfortfood" },
        @{@"name" : @"Corsican", @"code": @"corsican" },
        @{@"name" : @"Creperies", @"code": @"creperies" },
        @{@"name" : @"Cuban", @"code": @"cuban" },
        @{@"name" : @"Curry Sausage", @"code": @"currysausage" },
        @{@"name" : @"Cypriot", @"code": @"cypriot" },
        @{@"name" : @"Czech", @"code": @"czech" },
        @{@"name" : @"Czech/Slovakian", @"code": @"czechslovakian" },
        @{@"name" : @"Danish", @"code": @"danish" },
        @{@"name" : @"Delis", @"code": @"delis" },
        @{@"name" : @"Diners", @"code": @"diners" },
        @{@"name" : @"Dumplings", @"code": @"dumplings" },
        @{@"name" : @"Eastern European", @"code": @"eastern_european" },
        @{@"name" : @"Ethiopian", @"code": @"ethiopian" },
        @{@"name" : @"Fast Food", @"code": @"hotdogs" },
        @{@"name" : @"Filipino", @"code": @"filipino" },
        @{@"name" : @"Fish & Chips", @"code": @"fishnchips" },
        @{@"name" : @"Fondue", @"code": @"fondue" },
        @{@"name" : @"Food Court", @"code": @"food_court" },
        @{@"name" : @"Food Stands", @"code": @"foodstands" },
        @{@"name" : @"French", @"code": @"french" },
        @{@"name" : @"French Southwest", @"code": @"sud_ouest" },
        @{@"name" : @"Galician", @"code": @"galician" },
        @{@"name" : @"Gastropubs", @"code": @"gastropubs" },
        @{@"name" : @"Georgian", @"code": @"georgian" },
        @{@"name" : @"German", @"code": @"german" },
        @{@"name" : @"Giblets", @"code": @"giblets" },
        @{@"name" : @"Gluten-Free", @"code": @"gluten_free" },
        @{@"name" : @"Greek", @"code": @"greek" },
        @{@"name" : @"Halal", @"code": @"halal" },
        @{@"name" : @"Hawaiian", @"code": @"hawaiian" },
        @{@"name" : @"Heuriger", @"code": @"heuriger" },
        @{@"name" : @"Himalayan/Nepalese", @"code": @"himalayan" },
        @{@"name" : @"Hong Kong Style Cafe", @"code": @"hkcafe" },
        @{@"name" : @"Hot Dogs", @"code": @"hotdog" },
        @{@"name" : @"Hot Pot", @"code": @"hotpot" },
        @{@"name" : @"Hungarian", @"code": @"hungarian" },
        @{@"name" : @"Iberian", @"code": @"iberian" },
        @{@"name" : @"Indian", @"code": @"indpak" },
        @{@"name" : @"Indonesian", @"code": @"indonesian" },
        @{@"name" : @"International", @"code": @"international" },
        @{@"name" : @"Irish", @"code": @"irish" },
        @{@"name" : @"Island Pub", @"code": @"island_pub" },
        @{@"name" : @"Israeli", @"code": @"israeli" },
        @{@"name" : @"Italian", @"code": @"italian" },
        @{@"name" : @"Japanese", @"code": @"japanese" },
        @{@"name" : @"Jewish", @"code": @"jewish" },
        @{@"name" : @"Kebab", @"code": @"kebab" },
        @{@"name" : @"Korean", @"code": @"korean" },
        @{@"name" : @"Kosher", @"code": @"kosher" },
        @{@"name" : @"Kurdish", @"code": @"kurdish" },
        @{@"name" : @"Laos", @"code": @"laos" },
        @{@"name" : @"Laotian", @"code": @"laotian" },
        @{@"name" : @"Latin American", @"code": @"latin" },
        @{@"name" : @"Live/Raw Food", @"code": @"raw_food" },
        @{@"name" : @"Lyonnais", @"code": @"lyonnais" },
        @{@"name" : @"Malaysian", @"code": @"malaysian" },
        @{@"name" : @"Meatballs", @"code": @"meatballs" },
        @{@"name" : @"Mediterranean", @"code": @"mediterranean" },
        @{@"name" : @"Mexican", @"code": @"mexican" },
        @{@"name" : @"Middle Eastern", @"code": @"mideastern" },
        @{@"name" : @"Milk Bars", @"code": @"milkbars" },
        @{@"name" : @"Modern Australian", @"code": @"modern_australian" },
        @{@"name" : @"Modern European", @"code": @"modern_european" },
        @{@"name" : @"Mongolian", @"code": @"mongolian" },
        @{@"name" : @"Moroccan", @"code": @"moroccan" },
        @{@"name" : @"New Zealand", @"code": @"newzealand" },
        @{@"name" : @"Night Food", @"code": @"nightfood" },
        @{@"name" : @"Norcinerie", @"code": @"norcinerie" },
        @{@"name" : @"Open Sandwiches", @"code": @"opensandwiches" },
        @{@"name" : @"Oriental", @"code": @"oriental" },
        @{@"name" : @"Pakistani", @"code": @"pakistani" },
        @{@"name" : @"Parent Cafes", @"code": @"eltern_cafes" },
        @{@"name" : @"Parma", @"code": @"parma" },
        @{@"name" : @"Persian/Iranian", @"code": @"persian" },
        @{@"name" : @"Peruvian", @"code": @"peruvian" },
        @{@"name" : @"Pita", @"code": @"pita" },
        @{@"name" : @"Pizza", @"code": @"pizza" },
        @{@"name" : @"Polish", @"code": @"polish" },
        @{@"name" : @"Portuguese", @"code": @"portuguese" },
        @{@"name" : @"Potatoes", @"code": @"potatoes" },
        @{@"name" : @"Poutineries", @"code": @"poutineries" },
        @{@"name" : @"Pub Food", @"code": @"pubfood" },
        @{@"name" : @"Rice", @"code": @"riceshop" },
        @{@"name" : @"Romanian", @"code": @"romanian" },
        @{@"name" : @"Rotisserie Chicken", @"code": @"rotisserie_chicken" },
        @{@"name" : @"Rumanian", @"code": @"rumanian" },
        @{@"name" : @"Russian", @"code": @"russian" },
        @{@"name" : @"Salad", @"code": @"salad" },
        @{@"name" : @"Sandwiches", @"code": @"sandwiches" },
        @{@"name" : @"Scandinavian", @"code": @"scandinavian" },
        @{@"name" : @"Scottish", @"code": @"scottish" },
        @{@"name" : @"Seafood", @"code": @"seafood" },
        @{@"name" : @"Serbo Croatian", @"code": @"serbocroatian" },
        @{@"name" : @"Signature Cuisine", @"code": @"signature_cuisine" },
        @{@"name" : @"Singaporean", @"code": @"singaporean" },
        @{@"name" : @"Slovakian", @"code": @"slovakian" },
        @{@"name" : @"Soul Food", @"code": @"soulfood" },
        @{@"name" : @"Soup", @"code": @"soup" },
        @{@"name" : @"Southern", @"code": @"southern" },
        @{@"name" : @"Spanish", @"code": @"spanish" },
        @{@"name" : @"Steakhouses", @"code": @"steak" },
        @{@"name" : @"Sushi Bars", @"code": @"sushi" },
        @{@"name" : @"Swabian", @"code": @"swabian" },
        @{@"name" : @"Swedish", @"code": @"swedish" },
        @{@"name" : @"Swiss Food", @"code": @"swissfood" },
        @{@"name" : @"Tabernas", @"code": @"tabernas" },
        @{@"name" : @"Taiwanese", @"code": @"taiwanese" },
        @{@"name" : @"Tapas Bars", @"code": @"tapas" },
        @{@"name" : @"Tapas/Small Plates", @"code": @"tapasmallplates" },
        @{@"name" : @"Tex-Mex", @"code": @"tex-mex" },
        @{@"name" : @"Thai", @"code": @"thai" },
        @{@"name" : @"Traditional Norwegian", @"code": @"norwegian" },
        @{@"name" : @"Traditional Swedish", @"code": @"traditional_swedish" },
        @{@"name" : @"Trattorie", @"code": @"trattorie" },
        @{@"name" : @"Turkish", @"code": @"turkish" },
        @{@"name" : @"Ukrainian", @"code": @"ukrainian" },
        @{@"name" : @"Uzbek", @"code": @"uzbek" },
        @{@"name" : @"Vegan", @"code": @"vegan" },
        @{@"name" : @"Vegetarian", @"code": @"vegetarian" },
        @{@"name" : @"Venison", @"code": @"venison" },
        @{@"name" : @"Vietnamese", @"code": @"vietnamese" },
        @{@"name" : @"Wok", @"code": @"wok" },
        @{@"name" : @"Wraps", @"code": @"wraps" },
        @{@"name" : @"Yugoslav", @"code": @"yugoslav" }
    ];
}

@end
