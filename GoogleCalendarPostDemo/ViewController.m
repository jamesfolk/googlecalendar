//
//  ViewController.m
//  GoogleCalendarPostDemo
//
//  Copyright (c) 2013 Gabriel Theodoropoulos. All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()

// The string that contains the event description.
// Its value is set every time the event description gets edited and its
// value is displayed on the table view.
@property (nonatomic, strong) NSString *strEvent;

// The string that contains the date of the event.
// This is the value that is displayed on the table view.
@property (nonatomic, strong) NSString *strEventDate;

// This string is composed right before posting the event on the calendar.
// It's actually the quick-add string and contains the date data as well.
@property (nonatomic, strong) NSString *strEventTextToPost;

// The selected event date from the date picker.
@property (nonatomic, strong) NSDate *dtEvent;

// The textfield that is appeared on the table view for editing the event description.
@property (nonatomic, strong) UITextField *txtEvent;

// This array is one of the most important properties, as it contains
// all the calendars as NSDictionary objects.
@property (nonatomic, strong) NSMutableArray *arrGoogleCalendars;

// This dictionary contains the currently selected calendar.
// It's the one that appears on the table view when the calendar list
// is collapsed.
@property (nonatomic, strong) NSDictionary *dictCurrentCalendar;

// A GoogleOAuth object that handles everything regarding the Google.
@property (nonatomic, strong) GoogleOAuth *googleOAuth;

// This flag indicates whether the event description is being edited or not.
@property (nonatomic) BOOL isEditingEvent;

// It indicates whether the event is a full-day one.
@property (nonatomic) BOOL isFullDayEvent;

// It simply indicates whether the calendar list is expanded or not on the table view.
@property (nonatomic) BOOL isCalendarListExpanded;


-(void)setupEventTextfield;
-(NSString *)getStringFromDate:(NSDate *)date;
-(void)showOrHideActivityIndicatorView;

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    
    // Set self as the delegate and datasource of the table view.
    [_tblPostData setDelegate:self];
    [_tblPostData setDataSource:self];
    
    // Set the initial values of the following private properties.
    _strEvent = @"";
    _strEventDate = @"Pick a date...";
    _isEditingEvent = NO;
    _isFullDayEvent = NO;
    _isCalendarListExpanded = NO;
    
    // Initialize the googleOAuth object.
    // Pay attention so as to initialize it with the initWithFrame: method, not just init.
    _googleOAuth = [[GoogleOAuth alloc] initWithFrame:self.view.frame];
    // Set self as the delegate.
    [_googleOAuth setGOAuthDelegate:self];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


#pragma mark - IBAction method implementation

- (IBAction)post:(id)sender {
    // Before posting the event, check if the event description is empty or a date has not been selected.
    if ([_strEvent isEqualToString:@""]) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@""
                                                        message:@"Please enter an event description."
                                                       delegate:self
                                              cancelButtonTitle:nil
                                              otherButtonTitles:@"Okay", nil];
        [alert show];
        return;
    }
    
    if ([_strEventDate isEqualToString:@"Pick a date..."]) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@""
                                                        message:@"Please select a date for the event."
                                                       delegate:self
                                              cancelButtonTitle:nil
                                              otherButtonTitles:@"Okay", nil];
        [alert show];
        return;
    }
    
    // Create the URL string of API needed to quick-add the event into the Google calendar.
    // Note that we specify the id of the selected calendar.
    NSString *apiURLString = [NSString stringWithFormat:@"https://www.googleapis.com/calendar/v3/calendars/%@/events/quickAdd",
                              [_dictCurrentCalendar objectForKey:@"id"]];

    // Build the event text string, composed by the event description and the date (and time) that should happen.
    // Break the selected date into its components.
    NSDateComponents *dateComponents = [[NSDateComponents alloc] init];
    dateComponents = [[NSCalendar currentCalendar] components:NSDayCalendarUnit|NSMonthCalendarUnit|NSYearCalendarUnit|NSHourCalendarUnit|NSMinuteCalendarUnit
                                                     fromDate:_dtEvent];
    
    if (_isFullDayEvent) {
        // If a full-day event was selected (meaning without specific time), then add at the end of the string just the date.
        _strEventTextToPost = [NSString stringWithFormat:@"%@ %d/%d/%d", _strEvent, [dateComponents month], [dateComponents day], [dateComponents year]];
    }
    else{
        // Otherwise, append both the date and the time that the event should happen.
        _strEventTextToPost = [NSString stringWithFormat:@"%@ %d/%d/%d at %d.%d", _strEvent, [dateComponents month], [dateComponents day], [dateComponents year], [dateComponents hour], [dateComponents minute]];
    }

    // Show the activity indicator view.
    [self showOrHideActivityIndicatorView];
    
    // Call the API and post the event on the selected Google calendar.
    // Visit https://developers.google.com/google-apps/calendar/v3/reference/events/quickAdd for more information about the quick-add event API call.
    [_googleOAuth callAPI:apiURLString
           withHttpMethod:httpMethod_POST
       postParameterNames:[NSArray arrayWithObjects:@"calendarId", @"text", nil]
      postParameterValues:[NSArray arrayWithObjects:[_dictCurrentCalendar objectForKey:@"id"], _strEventTextToPost, nil]];
}


- (IBAction)revokeAccess:(id)sender {
    // Revoke the access token.
    [_googleOAuth revokeAccessToken];
}


- (IBAction)acceptEditingEvent:(id)sender {
    // If the strEvent property is already initialized then set its value to nil
    // as it's going to be re-allocated right after.
    if (_strEvent) {
        _strEvent = nil;
    }
    
    // Keep the text entered in the textfield.
    _strEvent = [[NSString alloc] initWithString:[_txtEvent text]];

    // Indicate that no longer the event description is being edited.
    _isEditingEvent = NO;
    
    // Resign the first responder and make the textfield nil.
    [_txtEvent resignFirstResponder];
    [_txtEvent removeFromSuperview];
    _txtEvent = nil;

    
    // Reload the row of the first section of the table view.
    [_tblPostData reloadRowsAtIndexPaths:[NSArray arrayWithObject:[NSIndexPath indexPathForRow:0 inSection:0]]
                        withRowAnimation:UITableViewRowAnimationAutomatic];
}

- (IBAction)cancelEditingEvent:(id)sender {
    // Indicate that no longer the event description is being edited.
    _isEditingEvent = NO;
    
    // Resign the first responder.
    [_txtEvent resignFirstResponder];
    [_txtEvent removeFromSuperview];
    _txtEvent = nil;
    
    // Reload the first row of the first section of the table view.
    [_tblPostData reloadRowsAtIndexPaths:[NSArray arrayWithObject:[NSIndexPath indexPathForRow:0 inSection:0]]
                        withRowAnimation:UITableViewRowAnimationAutomatic];
}

- (IBAction)acceptSelectedDate:(id)sender {
    // Keep the selected date as a NSDate object.
    _dtEvent = [_dpDatePicker date];
    // Also, convert it to a string properly formatted depending on whether the event is a full-day one or not
    // by calling the getStringFromDate: method.
    _strEventDate = [[NSString alloc] initWithString:[self getStringFromDate:[_dpDatePicker date]]];
    
    // Remove the view with the date picker from the self.view.
    [_viewDatePicker removeFromSuperview];
    
    // Reload the row of the second section of the table view to reflect the selected date.
    [_tblPostData reloadRowsAtIndexPaths:[NSArray arrayWithObject:[NSIndexPath indexPathForRow:0 inSection:1]]
                        withRowAnimation:UITableViewRowAnimationAutomatic];
}

- (IBAction)cancelPickingDate:(id)sender {
    // Just remove the view with the date picker from the superview.
    [_viewDatePicker removeFromSuperview];
}

- (IBAction)toggleDatePicker:(id)sender {
    if ([_dpDatePicker datePickerMode] == UIDatePickerModeDateAndTime) {
        // If the date picker currently shows both date and time, then set it to show only date
        // and change the title of the barItemToggleDatePicker item.
        // In this case the user selects to make a full-day event.
        [_dpDatePicker setDatePickerMode:UIDatePickerModeDate];
        [_barItemToggleDatePicker setTitle:@"Specific time"];
    }
    else{
        // Otherwise, if only date is shown on the date picker, set it to show time too.
        // The event is no longer a full-day one.
        [_dpDatePicker setDatePickerMode:UIDatePickerModeDateAndTime];
        [_barItemToggleDatePicker setTitle:@"All-day event"];
    }
    
    // Change the flag that indicates whether is a full-day event or not.
    _isFullDayEvent = !_isFullDayEvent;
}


#pragma mark - UITableView Delegate & Datasource method implementation

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    return 3;
}


-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{    
    if (section != 2) {
        return 1;
    }
    else{
        // Depending on whether the calendars are listed in the table view,
        // the respective section will have either one row, or as many as the calendars are.
        if (!_isCalendarListExpanded) {
            return 1;
        }
        else{
            return [_arrGoogleCalendars count];
        }
    }
}


-(NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section{
    // Set the footer title depending on the section value.
    NSString *footerTitle = @"";
    if (section == 0) {
        footerTitle = @"Event short description";
    }
    else if (section == 1){
        footerTitle = @"Event date";
    }
    else{
        footerTitle = @"Google Calendar";
    }
    
    return footerTitle;
}


-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier: CellIdentifier];
    
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
        
        [cell setSelectionStyle:UITableViewCellSelectionStyleGray];
        [cell setAccessoryType:UITableViewCellAccessoryNone];
     
        // Set a font for the cell textLabel.
        [[cell textLabel] setFont:[UIFont fontWithName:@"Trebuchet MS" size:15.0]];
    }
    
    // Set each cell's value depending on the section.
    if ([indexPath section] == 0) {
        if (!_isEditingEvent) {
            // If currently the event description is not being edited then just show
            // the value of the strEvent string and let the cell contain a disclosure indicator accessory view.
            // Also, set the gray as the selection style.
            [[cell textLabel] setText:_strEvent];
            [cell setAccessoryType:UITableViewCellAccessoryDisclosureIndicator];
            [cell setSelectionStyle:UITableViewCellSelectionStyleGray];
        }
        else{
            // If the event description is being edited, then empty the textLabel text so as to avoid
            // having text behind the textfield.
            // Add the textfield as a subview to the cell's content view and turn the selection style to none.
            [[cell textLabel] setText:@""];
            [[cell contentView] addSubview:_txtEvent];
            [cell setSelectionStyle:UITableViewCellSelectionStyleNone];
        }
    }
    else if ([indexPath section] == 1){
        // In the event date cell just show the strEventDate string which either prompts the user
        // to pick a date, or contains the selected date as a string.
        // Also, add a disclosure indicator view.
        [[cell textLabel] setText:_strEventDate];
        [cell setAccessoryType:UITableViewCellAccessoryDisclosureIndicator];
    }
    else if ([indexPath section] == 2){
        // This is the case where either the selected calendar is shown, or a list with all of them.
        if (!_isCalendarListExpanded) {
            // If the calendar list is not expanded and only the selected calendar is shown,
            // then if the arrGoogleCalendars array is nil or it doesn't have any contents at all prompt
            // the user to download them now.
            // Otherwise show the summary (title) of the selected calendar along with a disclosure indicator.
            if (![_arrGoogleCalendars count] || [_arrGoogleCalendars count] == 0) {
                [[cell textLabel] setText:@"Download calendars..."];
            }
            else{
                [[cell textLabel] setText:[_dictCurrentCalendar objectForKey:@"summary"]];
            }
            
            [cell setAccessoryType:UITableViewCellAccessoryDisclosureIndicator];
        }
        else{
            // This is the case where all the calendars should be listed.
            // Note that each calendar is represented as a NSDictionary which is read from the
            // arrGoogleCalendars array.
            // If the calendar that is shown in the current cell is the already selected one,
            // then add the checkmark accessory type to the cell, otherwise set the accessory type to none.
            NSDictionary *tempDict = [_arrGoogleCalendars objectAtIndex:[indexPath row]];
            [[cell textLabel] setText:[tempDict objectForKey:@"summary"]];
            
            if ([tempDict isEqual:_dictCurrentCalendar]) {
                [cell setAccessoryType:UITableViewCellAccessoryCheckmark];
            }
            else{
                [cell setAccessoryType:UITableViewCellAccessoryNone];
            }
        }
    }
    
    return cell;
}


-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    return 50.0;
}


-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    // At first, remove the selection from the tapped cell.
    [[_tblPostData cellForRowAtIndexPath:indexPath] setSelected:NO];
    
    if ([indexPath section] == 0) {
        // If the row of the first section is tapped, check whether the event description is being edited or not.
        // If not, then setup and show the textfield on the cell.
        if (!_isEditingEvent) {
            [self setupEventTextfield];
        }
        else{
            return;
        }
        
        // Change the value of the isEditingEvent flag.
        _isEditingEvent = !_isEditingEvent;
        // Reload the selected row.
        [_tblPostData reloadRowsAtIndexPaths:[NSArray arrayWithObject:indexPath]
                            withRowAnimation:UITableViewRowAnimationAutomatic];
        
        // If the textfield has been added as a subview to the cell,
        // then make it the first responder and show the keyboard.
        if (_isEditingEvent) {
            [_txtEvent becomeFirstResponder];
        }
    }
    else if ([indexPath section] == 1){
        // If the row of the second section is tapped, just show the view that contains the date picker.
        [self.view addSubview:_viewDatePicker];
    }
    else if ([indexPath section] == 2){
        if (_arrGoogleCalendars == nil || [_arrGoogleCalendars count] == 0) {
            // If the arrGoogleCalendars array is nil or contains nothing, then the calendars should be
            // downloaded from Google.
            // So, show the activity indicator view and authorize the user by calling the the next
            // method of our custom-made class.            
            [self showOrHideActivityIndicatorView];
            [_googleOAuth authorizeUserWithClienID:@"813506780157-ko5f1v2qb0h6ib2i76clgta1cl6jca89.apps.googleusercontent.com"
                                   andClientSecret:@"Is6dIBv1G_zR1brvxCz9YBi0"
                                     andParentView:self.view
                                         andScopes:[NSArray arrayWithObject:@"https://www.googleapis.com/auth/calendar"]];
        }
        else{
            // In this case the calendars exist in the arrGoogleCalendars array.
            if (_isCalendarListExpanded) {
                // If the calendar list is shown on the table view, then the tapped one shoule become the selected calendar.
                // Re-initialize the dictCurrentCalendar dictionary so it contains the information regarding the selected one.
                _dictCurrentCalendar = nil;
                _dictCurrentCalendar = [[NSDictionary alloc] initWithDictionary:[_arrGoogleCalendars objectAtIndex:[indexPath row]]];
            }
            
            // Change the value of the isCalendarListExpanded which indicates whether only the selected calendar is shown, or the
            // whole list.
            _isCalendarListExpanded = !_isCalendarListExpanded;

            // Finally, reload the section.
            [_tblPostData reloadSections:[NSIndexSet indexSetWithIndex:2]
                        withRowAnimation:UITableViewRowAnimationAutomatic];
        }
    }
    
}


#pragma mark - Private method implementation

-(void)setupEventTextfield{
    // Initialize the textfield by setting the following properties.
    // Add or remove properties depending on your demand.
    if (!_txtEvent) {
        _txtEvent = [[UITextField alloc] initWithFrame:CGRectMake(10.0, 10.0,
                                                                  [[_tblPostData cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]] contentView].frame.size.width - 20.0,
                                                                  30.0)];
        [_txtEvent setBorderStyle:UITextBorderStyleRoundedRect];
        [_txtEvent setText:_strEvent];
        [_txtEvent setInputAccessoryView:_toolbarInputAccessoryView];
        [_txtEvent setDelegate:self];
    }
}


-(NSString *)getStringFromDate:(NSDate *)date{
    // Create a NSDateFormatter object to handle the date.
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    
    if (!_isFullDayEvent) {
        // If it's not a full-day event, then set the date format in a way that contains the time too.
        [formatter setDateFormat:@"EEE, MMM dd, yyyy, HH:mm"];
    }
    else{
        // Otherwise keep just the date.
        [formatter setDateFormat:@"EEE, MMM dd, yyyy"];
    }
    
    // Return the formatted date as a string value.
    return [formatter stringFromDate:date];
}


-(void)showOrHideActivityIndicatorView{
    // If the activity indicator view is not currently animating (spinning),
    // then set its view center equal to self view's center, add it as a subview and start animating.
    // Otherwise stop animating and remove it from the superview.
    if (![_activityIndicatorView isAnimating]) {
        [_activityIndicatorView setCenter:self.view.center];
        [self.view addSubview:_activityIndicatorView];
        [_activityIndicatorView startAnimating];
    }
    else{
        [_activityIndicatorView stopAnimating];
        [_activityIndicatorView removeFromSuperview];
    }

}


#pragma mark - GoogleOAuth class delegate method implementation

-(void)authorizationWasSuccessful{
    // If user authorization is successful, then make an API call to get the calendar list.
    // For more infomation about this API call, visit:
    // https://developers.google.com/google-apps/calendar/v3/reference/calendarList/list
    [_googleOAuth callAPI:@"https://www.googleapis.com/calendar/v3/users/me/calendarList"
           withHttpMethod:httpMethod_GET
       postParameterNames:nil
      postParameterValues:nil];
}


-(void)responseFromServiceWasReceived:(NSString *)responseJSONAsString andResponseJSONAsData:(NSData *)responseJSONAsData{
    NSError *error;
    
    if ([responseJSONAsString rangeOfString:@"calendarList"].location != NSNotFound) {
        // If the response from Google contains the "calendarList" literal, then the calendar list
        // has been downloaded.
        
        // Get the JSON data as a dictionary.
        NSDictionary *calendarInfoDict = [NSJSONSerialization JSONObjectWithData:responseJSONAsData options:NSJSONReadingMutableContainers error:&error];
        
        if (error) {
            // This is the case that an error occured during converting JSON data to dictionary.
            // Simply log the error description.
            NSLog(@"%@", [error localizedDescription]);
        }
        else{
            // Get the calendars info as an array.
            NSArray *calendarsInfo = [calendarInfoDict objectForKey:@"items"];

            // If the arrGoogleCalendars array is nil then initialize it so to store each calendar as a NSDictionary object.
            if (_arrGoogleCalendars == nil) {
                _arrGoogleCalendars = [[NSMutableArray alloc] init];
            }
            
            // Make a loop and get the next data of each calendar.
            for (int i=0; i<[calendarsInfo count]; i++) {
                // Store each calendar in a temporary dictionary.
                NSDictionary *currentCalDict = [calendarsInfo objectAtIndex:i];
                                
                
                // Create an array which contains only the desired data.
                NSArray *values = [NSArray arrayWithObjects:[currentCalDict objectForKey:@"id"],
                                   [currentCalDict objectForKey:@"summary"],
                                   nil];
                // Create an array with keys regarding the values on the previous array.
                NSArray *keys = [NSArray arrayWithObjects:@"id", @"summary", nil];
                
                // Add key-value pairs in a dictionary and then add this dictionary into the arrGoogleCalendars array.
                [_arrGoogleCalendars addObject:
                 [[NSMutableDictionary alloc] initWithObjects:values forKeys:keys]];
            }
            
            // Set the first calendar as the selected one.
            _dictCurrentCalendar = [[NSDictionary alloc] initWithDictionary:[_arrGoogleCalendars objectAtIndex:0]];
            
            // Enable the post and the sign out bar button items.
            [_barItemPost setEnabled:YES];
            [_barItemRevokeAccess setEnabled:YES];
            
            // Stop the activity indicator view.
            [self showOrHideActivityIndicatorView];
            
            // Reload the table view section.
            [_tblPostData reloadRowsAtIndexPaths:[NSArray arrayWithObject:[NSIndexPath indexPathForRow:0 inSection:2]]
                                withRowAnimation:UITableViewRowAnimationAutomatic];
        }
    }
    else if ([responseJSONAsString rangeOfString:@"calendar#event"].location != NSNotFound){
        // If the Google response contains the "calendar#event" literal then the event has been added to the selected calendar
        // and Google returns data related to the new event.
        
        // Get the response JSON as a dictionary.
        NSDictionary *eventInfoDict = [NSJSONSerialization JSONObjectWithData:responseJSONAsData options:NSJSONReadingMutableContainers error:&error];
        
        if (error) {
            // This is the case that an error occured during converting JSON data to dictionary.
            // Simply log the error description.
            NSLog(@"%@", [error localizedDescription]);
            return;
        }
        
        // An alert view with some information regarding the just added event will be shown.
        // Keep only the information that will be shown to the alert view.
        // Look at the https://developers.google.com/google-apps/calendar/v3/reference/events#resource for a complete list of the
        // data fields that Google returns.
        NSString *eventID = [eventInfoDict objectForKey:@"id"];
        NSString *created = [eventInfoDict objectForKey:@"created"];
        NSString *summary = [eventInfoDict objectForKey:@"summary"];
        
        // Build the alert message.
        NSString *alertMessage = [NSString stringWithFormat:@"ID: %@\n\nCreated:%@\n\nSummary:%@", eventID, created, summary];
        
        // Stop the activity indicator view.
        [self showOrHideActivityIndicatorView];
        
        // Show the alert view.
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"New event"
                                                        message:alertMessage
                                                       delegate:self
                                              cancelButtonTitle:nil
                                              otherButtonTitles:@"Great", nil];
        [alert show];
    }
}


-(void)accessTokenWasRevoked{
    // Remove all calendars from the array.
    [_arrGoogleCalendars removeAllObjects];
    _arrGoogleCalendars = nil;
    
    // Disable the post and sign out bar button items.
    [_barItemPost setEnabled:NO];
    [_barItemRevokeAccess setEnabled:NO];
    
    // Reload the Google calendars section.
    [_tblPostData reloadSections:[NSIndexSet indexSetWithIndex:2] withRowAnimation:UITableViewRowAnimationAutomatic];
}


-(void)errorOccuredWithShortDescription:(NSString *)errorShortDescription andErrorDetails:(NSString *)errorDetails{
    // Just log the error messages.
    NSLog(@"%@", errorShortDescription);
    NSLog(@"%@", errorDetails);
}


-(void)errorInResponseWithBody:(NSString *)errorMessage{
    // Just log the error message.
    NSLog(@"%@", errorMessage);
}


#pragma mark - UITextfield Delegate method implementation

-(BOOL)textFieldShouldReturn:(UITextField *)textField{
    // In case the Return button on the keyboard is tapped, call the acceptEditingEvent: method
    // to handle it.
    [self acceptEditingEvent:nil];
    return YES;
}

@end
