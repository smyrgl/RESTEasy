//
//  TGPetTableViewController.m
//  RESTEasyApp
//
//  Created by John Tumminaro on 4/28/14.
//  Copyright (c) 2014 Tiny Little Gears. All rights reserved.
//

#import "TGPetTableViewController.h"
#import <SVProgressHUD.h>
#import "TGRESTEasyAPI.h"

@interface TGPetTableViewController ()

@property (nonatomic, copy) NSArray *pets;

@end

@implementation TGPetTableViewController

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
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self refreshPage];
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
    [[TGRESTEasyAPI sharedClient] GET:[NSString stringWithFormat:@"/people/%@/pets", self.owner.id]
                           parameters:nil
                              success:^(NSURLSessionDataTask *task, id responseObject) {
                                  [SVProgressHUD dismiss];
                                  NSMutableArray *petArr = [NSMutableArray new];
                                  for (NSDictionary *petDict in responseObject) {
                                      Pet *newPet = [Pet new];
                                      [newPet setValuesForKeysWithDictionary:petDict];
                                      [petArr addObject:newPet];
                                  }
                                  weakSelf.pets = [petArr sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"name" ascending:YES]]];
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
    return self.pets.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"petCell" forIndexPath:indexPath];
    
    Pet *aPet = self.pets[indexPath.row];
    cell.textLabel.text = aPet.name;
    cell.detailTextLabel.text = aPet.breed;
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

@end
