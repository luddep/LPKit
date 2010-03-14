/*
 * LPCrashReporter.j
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


@implementation LPCrashReporter : CPObject
{
    CPException _exception @accessors(property=exception);
}

+ (id)sharedErrorLogger
{
    if (!sharedErrorLoggerInstance)
        sharedErrorLoggerInstance = [[LPCrashReporter alloc] init];
    
    return sharedErrorLoggerInstance;
}

- (void)didCatchException:(CPException)anException
{
    if ([self shouldInterceptException])
    {
        if (_exception)
            return;
        
        _exception = anException;
        
        var overlayWindow = [[LPCrashReporterOverlayWindow alloc] initWithContentRect:CGRectMakeZero() styleMask:CPBorderlessBridgeWindowMask];
        [overlayWindow setLevel:CPNormalWindowLevel];
        [overlayWindow makeKeyAndOrderFront:nil];
        
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
    {
        shouldCatchExceptions = NO;
        [anException raise];
    }
}

- (BOOL)shouldInterceptException
{
    return YES;
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
                var reportWindow = [[LPCrashReporterReportWindow alloc] initWithContentRect:CGRectMake(0,0,460,309) styleMask:CPTitledWindowMask | CPResizableWindowMask];
                [CPApp runModalForWindow:reportWindow];
                break;
    }
}

@end


@implementation LPCrashReporterOverlayWindow : CPWindow
{
    
}

- (void)initWithContentRect:(CGRect)aContentRect styleMask:(id)aStyleMask
{
    if (self = [super initWithContentRect:aContentRect styleMask:aStyleMask])
    {
        [[self contentView] setBackgroundColor:[CPColor colorWithWhite:0 alpha:0.4]];
    }
    return self;
}

@end


@implementation LPCrashReporterReportWindow : CPWindow
{
    CPTextField informationLabel;
    LPMultiLineTextField informationTextField;
    
    CPTextField descriptionLabel;
    LPMultiLineTextField descriptionTextField;
    
    CPButton sendButton;
    CPButton cancelButton;
    
    CPTextField sendingLabel;
}

- (void)initWithContentRect:(CGRect)aContentRect styleMask:(id)aStyleMask
{
    if (self = [super initWithContentRect:aContentRect styleMask:aStyleMask])
    {
        var contentView = [self contentView],
            applicationName = [[CPBundle mainBundle] objectForInfoDictionaryKey:@"CPBundleName"];
        
        [self setMinSize:aContentRect.size];
        [self setTitle:[CPString stringWithFormat:@"Problem Report for %@", applicationName]];
        
        informationLabel = [CPTextField labelWithTitle:@"Problem and system information:"];
        [informationLabel setFrameOrigin:CGPointMake(12,12)];
        [contentView addSubview:informationLabel];
        
        var informationTextValue = [CPString stringWithFormat:@"User-Agent: %@\n\nException: %@",
                                                              navigator.userAgent, [[LPCrashReporter sharedErrorLogger] exception]];
        informationTextField = [LPMultiLineTextField textFieldWithStringValue:informationTextValue placeholder:@"" width:0];
        [informationTextField setEditable:NO];
        [informationTextField setFrame:CGRectMake(12, 31, CGRectGetWidth(aContentRect) - 24, 100)];
        [informationTextField setAutoresizingMask:CPViewWidthSizable];
        [contentView addSubview:informationTextField];
        
        descriptionLabel = [CPTextField labelWithTitle:@"Please describe what you were doing when the problem happened:"];
        [descriptionLabel setFrameOrigin:CGPointMake(12,141)];
        [contentView addSubview:descriptionLabel];
        
        descriptionTextField = [LPMultiLineTextField textFieldWithStringValue:@"" placeholder:@"" width:0];
        [descriptionTextField setFrame:CGRectMake(CGRectGetMinX([informationTextField frame]), CGRectGetMaxY([descriptionLabel frame]) + 1, CGRectGetWidth([informationTextField frame]), 100)];
        [descriptionTextField setAutoresizingMask:CPViewWidthSizable | CPViewHeightSizable];
        [contentView addSubview:descriptionTextField];
        
        sendButton = [CPButton buttonWithTitle:[CPString stringWithFormat:@"Send to %@", applicationName]];
        [sendButton setFrameOrigin:CGPointMake(CGRectGetWidth(aContentRect) - CGRectGetWidth([sendButton frame]) - 15, 270)];
        [sendButton setAutoresizingMask:CPViewMinXMargin | CPViewMinYMargin];
        [sendButton setTarget:self];
        [sendButton setAction:@selector(didClickSendButton:)];
        [contentView addSubview:sendButton];
        [self setDefaultButton:sendButton];
        
        cancelButton = [CPButton buttonWithTitle:@"Cancel"];
        [cancelButton setFrameOrigin:CGPointMake(CGRectGetMinX([sendButton frame]) - CGRectGetWidth([cancelButton frame]) - 12, CGRectGetMinY([sendButton frame]))];
        [cancelButton setAutoresizingMask:CPViewMinXMargin | CPViewMinYMargin];
        [cancelButton setTarget:self];
        [cancelButton setAction:@selector(didClickCancelButton:)];
        [contentView addSubview:cancelButton];
        
        sendingLabel = [CPTextField labelWithTitle:@"Sending Report..."];
        [sendingLabel setFont:[CPFont boldSystemFontOfSize:11]];
        [sendingLabel sizeToFit];
        [sendingLabel setFrameOrigin:CGPointMake(12, CGRectGetMaxY(aContentRect) - 35)];
        [sendingLabel setHidden:YES];
        [contentView addSubview:sendingLabel];
    
    }
    return self;
}

- (void)orderFront:(id)sender
{
    [super orderFront:sender];
    [self makeFirstResponder:descriptionTextField];
}

- (void)didClickSendButton:(id)sender
{
    [informationTextField setEnabled:NO];
    [descriptionTextField setEnabled:NO];
    [sendButton setEnabled:NO];
    [cancelButton setEnabled:NO];
    [informationLabel setAlphaValue:0.5];
    [descriptionLabel setAlphaValue:0.5];
    
    [sendingLabel setHidden:NO];
    
    var loggingURL = [CPURL URLWithString:[[CPBundle mainBundle] objectForInfoDictionaryKey:@"LPCrashReporterLoggingURL"] || @"/"],
        request = [LPURLPostRequest requestWithURL:loggingURL],
        exception = [[LPCrashReporter sharedErrorLogger] exception],
        content = {'name': [exception name], 'reason': [exception reason],
                   'userAgent': navigator.userAgent, 'description': [descriptionTextField stringValue]};

    [request setContent:content];
    [CPURLConnection connectionWithRequest:request delegate:self];
}

- (void)didClickCancelButton:(id)sender
{
    // Make the behaviour the same as if you click reload
    // on the initial alert.
    [[LPCrashReporter sharedErrorLogger] alertDidEnd:nil returnCode:0];
}

/*
    CPURLConnection delegate methods:
*/

- (void)connection:(CPURLConnection)aConnection didReceiveData:(id)aData
{
    [CPApp stopModal];
    [self orderOut:nil];
    
    var alert = [[CPAlert alloc] init];
    [alert setDelegate:[LPCrashReporter sharedErrorLogger]];
    [alert setAlertStyle:CPInformationalAlertStyle];
    [alert addButtonWithTitle:@"Thanks!"];
    [alert setMessageText:@"Your report has been sent."];
    [alert runModal];
}

@end

/*
    Let the monkey patching begin
*/

var original_objj_msgSend = objj_msgSend,
    shouldCatchExceptions = YES;

objj_msgSend = function()
{
    if (!shouldCatchExceptions)
        return original_objj_msgSend.apply(this, arguments);
    
    try
    {
        return original_objj_msgSend.apply(this, arguments);
    }
    catch (anException)
    {
        [[LPCrashReporter sharedErrorLogger] didCatchException:anException];
        return nil;
    }
}