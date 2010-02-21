/*
 * LPMultiLineTextField.j
 *
 * Created by Ludwig Pettersson on January 22, 2010.
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
@import <AppKit/CPTextField.j>

var CPTextFieldInputOwner = nil;

@implementation LPMultiLineTextField : CPTextField
{
    id _DOMTextareaElement;
    CPString oldValue;
    CPString _stringValue;
}
 
- (id)initWithFrame:(CGRect)aFrame
{
    if (self = [super initWithFrame:aFrame])
    {
        _DOMTextareaElement = document.createElement("textarea");
        _DOMTextareaElement.style.position = @"absolute";
        _DOMTextareaElement.style.background = @"none";
        _DOMTextareaElement.style.border = @"0";
        _DOMTextareaElement.style.outline = @"0";
        _DOMTextareaElement.style.zIndex = @"100";
        _DOMTextareaElement.style.resize = @"none";
        
        _DOMTextareaElement.onblur = function(){
                [[CPTextFieldInputOwner window] makeFirstResponder:nil];
                CPTextFieldInputOwner = nil;
            };
        
        self._DOMElement.appendChild(_DOMTextareaElement);
    }
    return self;
}

- (void)setEditable:(BOOL)shouldBeEditable
{
    [super setEditable:shouldBeEditable];
    
    _DOMTextareaElement.style.cursor = shouldBeEditable ? @"cursor" : @"default";
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    var contentView = [self layoutEphemeralSubviewNamed:@"content-view"
                                             positioned:CPWindowAbove
                        relativeToEphemeralSubviewNamed:@"bezel-view"];
    [contentView setHidden:YES];
    
    var contentInset = [self currentValueForThemeAttribute:@"content-inset"];
    
    _DOMTextareaElement.style.color = [[self currentValueForThemeAttribute:@"text-color"] cssString];
    _DOMTextareaElement.style.font = [[self currentValueForThemeAttribute:@"font"] cssString];
    _DOMTextareaElement.style.top = contentInset.top / 2 + @"px";
    _DOMTextareaElement.style.bottom = contentInset.bottom / 2 + @"px";
    _DOMTextareaElement.style.left = contentInset.left / 2 + @"px";
    _DOMTextareaElement.style.right = contentInset.right / 2 + @"px";
    
    _DOMTextareaElement.value = _stringValue || @"";
}

- (void)mouseDown:(CPEvent)anEvent
{
    if ([self isEditable] && [self isEnabled])
        [[[self window] platformWindow] _propagateCurrentDOMEvent:YES];
    else
        [super mouseDown:anEvent];
}

- (void)keyDown:(CPEvent)anEvent
{
    if ([anEvent keyCode] === CPTabKeyCode)
    {
        if ([anEvent modifierFlags] & CPShiftKeyMask)
            [[self window] selectPreviousKeyView:self];
        else
            [[self window] selectNextKeyView:self];
 
        if ([[[self window] firstResponder] respondsToSelector:@selector(selectText:)])
            [[[self window] firstResponder] selectText:self];
 
        [[[self window] platformWindow] _propagateCurrentDOMEvent:NO];
    }
    else
        [[[self window] platformWindow] _propagateCurrentDOMEvent:YES];
    
    [[CPRunLoop currentRunLoop] limitDateForMode:CPDefaultRunLoopMode];
}

- (void)selectText:(id)sender
{
    _DOMTextareaElement.select();
}

- (void)keyUp:(CPEvent)anEvent
{
    if (oldValue !== [self stringValue])
    {
        _stringValue = _DOMTextareaElement.value;
        
        if (!_isEditing)
        {
            _isEditing = YES;
            [self textDidBeginEditing:[CPNotification notificationWithName:CPControlTextDidBeginEditingNotification object:self userInfo:nil]];
        }
 
        [self textDidChange:[CPNotification notificationWithName:CPControlTextDidChangeNotification object:self userInfo:nil]];
    }
 
    [[[self window] platformWindow] _propagateCurrentDOMEvent:YES];
}

- (BOOL)becomeFirstResponder
{
    oldValue = [self stringValue];
    
    [self setThemeState:CPThemeStateEditing];
    
    setTimeout(function(){
        _DOMTextareaElement.focus();
        CPTextFieldInputOwner = self;
    }, 0.0);
    
    [self textDidFocus:[CPNotification notificationWithName:CPTextFieldDidFocusNotification object:self userInfo:nil]];
    
    return YES;
}

- (BOOL)resignFirstResponder
{
    [self unsetThemeState:CPThemeStateEditing];
    
    _DOMTextareaElement.blur();

    //post CPControlTextDidEndEditingNotification
    if (_isEditing)
    {
        _isEditing = NO;
        [self textDidEndEditing:[CPNotification notificationWithName:CPControlTextDidEndEditingNotification object:self userInfo:nil]];

        if ([self sendsActionOnEndEditing])
            [self sendAction:[self action] to:[self target]];
    }
    
    [self textDidBlur:[CPNotification notificationWithName:CPTextFieldDidBlurNotification object:self userInfo:nil]];
    
    return YES;
}

- (CPString)stringValue
{
    return (_DOMTextareaElement) ? _DOMTextareaElement.value : @"";
}

- (void)setStringValue:(CPString)aString
{
    _stringValue = aString;
    [self setNeedsLayout];
}

@end