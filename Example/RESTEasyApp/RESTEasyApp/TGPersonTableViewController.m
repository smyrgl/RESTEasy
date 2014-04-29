//
//  TGPersonTableViewController.m
//  RESTEasyApp
//
//  Created by John Tumminaro on 4/28/14.
//  Copyright (c) 2014 Tiny Little Gears. All rights reserved.
//

#import "TGPersonTableViewController.h"
#import <SVProgressHUD.h>
#import "TGRESTEasyAPI.h"
#import "TGPetTableViewController.h"

@interface TGPersonTableViewController ()

@property (nonatomic, copy) NSArray *people;
@property (nonatomic, strong) Person *selectedPerson;

@end

@implementation TGPersonTableViewController

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self refreshPage];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    self.selectedPerson = nil;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)refreshPage
{
    [SVProgressHUD show];
    __weak typeof(self) weakSelf = self;
    [[TGRESTEasyAPI sharedClient] GET:@"/people"
                           parameters:nil
                              success:^(NSURLSessionDataTask *task, id responseObject) {
                                  [SVProgressHUD dismiss];
                                  NSMutableArray *peopleArr = [NSMutableArray new];
                                  for (NSDictionary *personDict in responseObject) {
                                      Person *newPerson = [Person new];
                                      [newPerson setValuesForKeysWithDictionary:personDict];
                                      [peopleArr addObject:newPerson];
                                  }
                                  weakSelf.people = [peopleArr sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"name" ascending:YES]]];
                                  [weakSelf.tableView reloadData];
                              }
                              failure:^(NSURLSessionDataTask *task, NSError *error) {
                                  [SVProgressHUD showErrorWithStatus:error.localizedDescription];
                              }];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.people.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"personCell" forIndexPath:indexPath];
    
    Person *person = self.people[indexPath.row];
    cell.textLabel.text = person.name;
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    self.selectedPerson = self.people[indexPath.row];
    [self performSegueWithIdentifier:@"pushPet" sender:self];
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark - Navigation

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    TGPetTableViewController *dest = (TGPetTableViewController *)segue.destinationViewController;
    dest.owner = self.selectedPerson;
}

- (IBAction)refreshTapped:(id)sender
{
    [self refreshPage];
}
@end
