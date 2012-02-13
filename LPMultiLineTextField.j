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
    id          _DOMTextareaElement;
    CPString    _stringValue;
    BOOL        _hideOverflow;
}

- (DOMElement)_DOMTextareaElement
{
    if (!_DOMTextareaElement)
    {
        // For now we're just hiding the inputElement that's created by
        // CPTextView, but it should eventually be replaced with the
        // _DOMTextareaElement to conserve memory.
        [self _inputElement].style.visibility = @"hidden";
        _DOMTextareaElement = document.createElement("textarea");
        _DOMTextareaElement.style.position = @"absolute";
        _DOMTextareaElement.style.background = @"none";
        _DOMTextareaElement.style.border = @"0";
        _DOMTextareaElement.style.outline = @"0";
        _DOMTextareaElement.style.zIndex = @"100";
        _DOMTextareaElement.style.resize = @"none";
        _DOMTextareaElement.style.padding = @"0";
        _DOMTextareaElement.style.margin = @"0";
        _DOMTextareaElement.style.overflow = @"auto";
        _hideOverflow = NO;
        
        _DOMTextareaElement.onblur = function(){
                [[CPTextFieldInputOwner window] makeFirstResponder:nil];
                CPTextFieldInputOwner = nil;
            };

        self._DOMElement.appendChild(_DOMTextareaElement);
    }
    
    return _DOMTextareaElement;
}

- (BOOL)isScrollable
{
   return !_hideOverflow;
}

- (void)setScrollable:(BOOL)shouldScroll
{
    _hideOverflow = !shouldScroll;
    // Make sure the textarea element is aware of its scrollable state
    if (shouldScroll = YES)
    {
      [self _DOMTextareaElement].style.overflow = @"auto";
    }
    else
    {
      [self _DOMTextareaElement].style.overflow = @"hidden";
    }
}


- (void)setEditable:(BOOL)shouldBeEditable
{
    [self _DOMTextareaElement].style.cursor = shouldBeEditable ? @"cursor" : @"default";
    // Prevent the textarea from accepting input when it should be disabled
    [self _DOMTextareaElement].disabled = !shouldBeEditable;
    [super setEditable:shouldBeEditable];
}



/**
	If we're getting a default value from a cib, this is where it will come it.
	Map the string value of the passed in object to the setStringValue of the
	receiver.
 */
- (void)setObjectValue:(id)anObject
{
	[self setStringValue:[anObject description]];
}



- (void)selectText:(id)sender
{
    [self _DOMTextareaElement].select();
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    var contentView = [self layoutEphemeralSubviewNamed:@"content-view"
                                             positioned:CPWindowAbove
                        relativeToEphemeralSubviewNamed:@"bezel-view"];
    [contentView setHidden:YES];
    
    var DOMElement = [self _DOMTextareaElement],
        contentInset = [self currentValueForThemeAttribute:@"content-inset"],
        bounds = [self bounds];

    DOMElement.style.top = contentInset.top + @"px";
    DOMElement.style.bottom = contentInset.bottom + @"px";
    DOMElement.style.left = contentInset.left + @"px";
    DOMElement.style.right = contentInset.right + @"px";
    
    DOMElement.style.width = (CGRectGetWidth(bounds) - contentInset.left - contentInset.right) + @"px";
    DOMElement.style.height = (CGRectGetHeight(bounds) - contentInset.top - contentInset.bottom) + @"px";
        
    DOMElement.style.color = [[self valueForThemeAttribute:@"text-color"]
		  cssString];
    DOMElement.style.font = [[self valueForThemeAttribute:@"font"] cssString];
 
    switch ([self currentValueForThemeAttribute:@"alignment"])
    {
        case CPLeftTextAlignment:
            DOMElement.style.textAlign = "left";
            break;        
        case CPJustifiedTextAlignment:
            DOMElement.style.textAlign = "justify"; //not supported
            break;        
        case CPCenterTextAlignment:
            DOMElement.style.textAlign = "center";
            break;
        case CPRightTextAlignment:
            DOMElement.style.textAlign = "right";
            break;
        default:
            DOMElement.style.textAlign = "left";
    }
 
    DOMElement.value = _stringValue || @"";
}

- (void)scrollWheel:(CPEvent)anEvent
{
    var DOMElement = [self _DOMTextareaElement];
    DOMElement.scrollLeft += anEvent._deltaX;
    DOMElement.scrollTop += anEvent._deltaY;
}

- (void)mouseDown:(CPEvent)anEvent
{
    if ([self isEditable] && [self isEnabled])
        [[[self window] platformWindow] _propagateCurrentDOMEvent:YES];
    else
        [super mouseDown:anEvent];
}

 - (void)mouseDragged:(CPEvent)anEvent
{
    return [[[anEvent window] platformWindow] _propagateCurrentDOMEvent:YES];
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

- (void)keyUp:(CPEvent)anEvent
{
    if (_stringValue !== [self stringValue])
    {
        _stringValue = [self stringValue];
        
        if (!_isEditing)
        {
            _isEditing = YES;
            [self textDidBeginEditing:[CPNotification notificationWithName:CPControlTextDidBeginEditingNotification object:self userInfo:nil]];
        }
 
        [self textDidChange:[CPNotification notificationWithName:CPControlTextDidChangeNotification object:self userInfo:nil]];
    }
 
    [[[self window] platformWindow] _propagateCurrentDOMEvent:YES];
}

- (BOOL)performKeyEquivalent:(CPEvent)anEvent
{
    [[[self window] platformWindow] _propagateCurrentDOMEvent:YES];
    return YES;
}

- (CPString)stringValue
{
    return (!!_DOMTextareaElement) ? _DOMTextareaElement.value : @"";
}

- (void)setStringValue:(CPString)aString
{
  _stringValue = aString;
  [self setNeedsLayout];
}




/**
	Update the placeholder string, if there is one. This is kind of hackish since
	it's depending on the placeholder attribute being recognized by the browser.
	If it's not recognized, there's no harm in setting it this way, but the user
	will not see placeholder text.
*/
- (void)setPlaceholderString:(CPString)aPlaceholder
{
  [super setPlaceholderString:aPlaceholder];
  [self _DOMTextareaElement].placeholder = aPlaceholder;
}
@end


var LPMultiLineTextFieldStringValueKey = "LPMultiLineTextFieldStringValueKey",
    LPMultiLineTextFieldScrollableKey = "LPMultiLineTextFieldScrollableKey";
    
@implementation LPMultiLineTextField (CPCoding)

- (id)initWithCoder:(CPCoder)aCoder
{
    if (self = [super initWithCoder:aCoder])
    {
        var strValue = [aCoder decodeObjectForKey:LPMultiLineTextFieldStringValueKey];
        var scrollable = [aCoder decodeBoolForKey:LPMultiLineTextFieldScrollableKey];
				// only write the string value if there is one so as to avoid
				// overwriting a value that comes from the cib
				if (strValue != nil)
				{
					[self setObjectValue:strValue];
				}

				// make sure the textarea scrollbars no inadvertantly disabled with a
				// nil value
				if (scrollable == NO)
				{
					[self setScrollable:NO];
				}
    }
    return self;
}

- (void)encodeWithCoder:(CPCoder)aCoder
{
    [super encodeWithCoder:aCoder];      
    [aCoder encodeObject:_stringValue forKey:LPMultiLineTextFieldStringValueKey];
    [aCoder encodeBool:(_hideOverflow?NO:YES) forKey:LPMultiLineTextFieldScrollableKey];
}

@end
