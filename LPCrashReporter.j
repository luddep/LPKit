/*
 * LPErrorLogger.j
 * LPKit
 *
 * Created by Ludwig Pettersson on February 19, 2010.
 * 
 * The MIT License
 * 
 * Copyright (c) 2010 Ludwig Pettersson
 * 
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 * 
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 * 
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 * 
 */
 
@import <Foundation/CPObject.j>
@import <AppKit/CPAlert.j>
@import <LPKit/LPURLPostRequest.j>
@import <LPKit/LPMultiLineTextField.j>

var sharedErrorLoggerInstance = nil;


@implementation LPErrorLogger : CPObject
{
    CPException _exception;
}

+ (id)sharedErrorLogger
{
    if (!sharedErrorLoggerInstance)
        sharedErrorLoggerInstance = [[LPErrorLogger alloc] init];
    
    return sharedErrorLoggerInstance;
}

- (void)didCatchException:(CPException)anException
{
    if ([self shouldInterceptException])
    {
        _exception = anException;
        
        var request = [LPURLPostRequest requestWithURL:[self loggingURL]],
            content = {'name': [anException name], 'reason': [anException reason]};

        [request setContent:content];
        [CPURLConnection connectionWithRequest:request delegate:self];
        
        // Show alert
        var alert = [[CPAlert alloc] init];
        [alert setDelegate:self];
        [alert setAlertStyle:CPCriticalAlertStyle];
        [alert addButtonWithTitle:@"Reload"];
        [alert addButtonWithTitle:@"Report..."];
        [alert setMessageText:[CPString stringWithFormat:@"The application %@ crashed unexpectedly. Click Reload to load the application again or click Report to send a report to the developer.",
                                                         [[CPBundle mainBundle] objectForInfoDictionaryKey:@"CPBundleName"]]];
        [alert runModal];
    }
    else
        [anException raise];
}

- (BOOL)shouldInterceptException
{
    return YES;
}

- (CPURL)loggingURL
{
    return [CPURL URLWithString:@"/logging/"];
}

/*
    CPAlert delegate methods:
*/

- (void)alertDidEnd:(CPAlert)anAlert returnCode:(id)returnCode
{   
    switch(returnCode)
    {
        case 0: // Reload application
                location.reload();
                break;
        
        case 1: // Send report
                var reportWindow = [[LPCrashReporterReportWindow alloc] initWithContentRect:CGRectMake(0,0,460,310) styleMask:CPTitledWindowMask];
                [reportWindow setException:_exception];
                [CPApp runModalForWindow:reportWindow];
                break;
    }
}

@end


@implementation LPCrashReporterReportWindow : CPWindow
{
    CPException exception;
    LPMultiLineTextField informationTextField;
    LPMultiLineTextField descriptionTextField;
}

- (void)initWithContentRect:(CGRect)aContentRect styleMask:(id)aStyleMask
{
    if (self = [super initWithContentRect:aContentRect styleMask:aStyleMask])
    {
        var contentView = [self contentView],
            applicationName = [[CPBundle mainBundle] objectForInfoDictionaryKey:@"CPBundleName"];
        
        [self setTitle:[CPString stringWithFormat:@"Problem Report for %@", applicationName]];
        
        var informationLabel = [CPTextField labelWithTitle:@"Problem and system information:"];
        [informationLabel setFrameOrigin:CGPointMake(10,10)];
        [contentView addSubview:informationLabel];
        
        informationTextField = [LPMultiLineTextField textFieldWithStringValue:@"" placeholder:@"" width:0];
        [informationTextField setFrame:CGRectMake(10, 29, CGRectGetWidth(aContentRect) - 20, 100)];
        [contentView addSubview:informationTextField];
        
        var descriptionLabel = [CPTextField labelWithTitle:@"Please describe what you were doing when the problem happened:"];
        [descriptionLabel setFrameOrigin:CGPointMake(10,139)];
        [contentView addSubview:descriptionLabel];
        
        descriptionTextField = [LPMultiLineTextField textFieldWithStringValue:@"" placeholder:@"" width:0];
        [descriptionTextField setFrame:CGRectMake(10, CGRectGetMaxY([descriptionLabel frame]) + 1, CGRectGetWidth([informationTextField frame]), 100)];
        [contentView addSubview:descriptionTextField];
        
        var sendButton = [CPButton buttonWithTitle:[CPString stringWithFormat:@"Send to %@", applicationName]];
        [sendButton setFrameOrigin:CGPointMake(335,270)];
        [sendButton setTarget:self];
        [sendButton setAction:@selector(didClickSendButton:)];
        [contentView addSubview:sendButton];
        
        [self setDefaultButton:sendButton];
    }
    return self;
}

- (void)setException:(CPException)anException
{
    exception = anException;
    
    var informationTextValue = [CPString stringWithFormat:@"User-Agent: %@\n\nException: %@", navigator.userAgent, anException];
    [informationTextField setStringValue:informationTextValue];
}

- (void)didClickSendButton:(id)sender
{
    console.log('send!')
}

@end


@implementation CPApplication (ErrorLogging)

- (void)run
{
    try
    {
        [self finishLaunching];
    }
    catch (anException)
    {
        [[LPErrorLogger sharedErrorLogger] didCatchException:anException];
    }
}

@end