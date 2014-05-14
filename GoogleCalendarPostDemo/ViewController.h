//
//  ViewController.h
//  GoogleCalendarPostDemo
//
//  Copyright (c) 2013 Gabriel Theodoropoulos. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "GoogleOAuth.h"

@interface ViewController : UIViewController <UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate, GoogleOAuthDelegate>
@property (weak, nonatomic) IBOutlet UITableView *tblPostData;

@property (weak, nonatomic) IBOutlet UIBarButtonItem *barItemPost;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *barItemRevokeAccess;

@property (strong, nonatomic) IBOutlet UIToolbar *toolbarInputAccessoryView;

@property (strong, nonatomic) IBOutlet UIView *viewDatePicker;
@property (weak, nonatomic) IBOutlet UIDatePicker *dpDatePicker;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *barItemToggleDatePicker;

@property (strong, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicatorView;


- (IBAction)post:(id)sender;
- (IBAction)revokeAccess:(id)sender;

- (IBAction)acceptEditingEvent:(id)sender;
- (IBAction)cancelEditingEvent:(id)sender;

- (IBAction)acceptSelectedDate:(id)sender;
- (IBAction)cancelPickingDate:(id)sender;
- (IBAction)toggleDatePicker:(id)sender;

@end
