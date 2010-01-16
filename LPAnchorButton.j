/*
 * LPAnchorButton.j
 * LPKit
 *
 * Created by Ludwig Pettersson on November 9, 2009.
 * 
 * The MIT License
 * 
 * Copyright (c) 2009 Ludwig Pettersson
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

LPAnchorButtonNoUnderline     = 0;
LPAnchorButtonNormalUnderline = 1;
LPAnchorButtonHoverUnderline  = 2;


@implementation LPAnchorButton : CPButton
{
    unsigned _underlineMask @accessors(property=underlineMask);
    
    CPURL URL;
    id _DOMAnchorElement;
}

- (id)init
{
    if (self = [super init])
    {
        // Set default underline mask
        _underlineMask = LPAnchorButtonNormalUnderline | LPAnchorButtonHoverUnderline;
        
        // Reset min-size
        [self setValue:CGSizeMake(0,0) forThemeAttribute:@"min-size"];
        
        // Remove bezels
        [self setBordered:NO];
    }
    return self;
}

- (void)openURLOnClick:(CPURL)aURL
{   
    URL = aURL;
    
    [self setNeedsLayout];
}

- (void)setTextColor:(CPColor)aColor
{
    [self setValue:aColor forThemeAttribute:@"text-color"];
}

- (void)setTextHoverColor:(CPColor)aColor
{
    [self setValue:aColor forThemeAttribute:@"text-color" inState:CPThemeStateHighlighted];
}

- (void)mouseEntered:(CPEvent)anEvent
{
    [self setThemeState:CPThemeStateHighlighted];
}

- (void)mouseExited:(CPEvent)anEvent
{
    [self unsetThemeState:CPThemeStateHighlighted];
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    // Set up anchor element if needed
    if (URL)
    {
        if (!_DOMAnchorElement)
        {
            var _DOMAnchorElement = document.createElement("a");
        	_DOMAnchorElement.target = @"_blank";
        	_DOMAnchorElement.style.position = "absolute";
        	_DOMAnchorElement.style.zIndex = "100";

            self._DOMElement.appendChild(_DOMAnchorElement)
        }
        
    	_DOMAnchorElement.href = [URL absoluteString];
    	_DOMAnchorElement.style.width = CGRectGetWidth([self bounds]) + @"px";
    	_DOMAnchorElement.style.height = CGRectGetHeight([self bounds]) + @"px";
    }
    
    // Hack to make the underline use the same color as the text.
    self._DOMElement.style.setProperty(@"color", [[self currentValueForThemeAttribute:@"text-color"] cssString], null);
    
    var themeState = [self themeState],
        cssTextDecoration = @"none";
    
    // Check if we should underline
    if (((themeState === CPThemeStateNormal || themeState === CPThemeStateSelected) && (_underlineMask & LPAnchorButtonNormalUnderline)) ||
        ((themeState & CPThemeStateHighlighted) && (_underlineMask & LPAnchorButtonHoverUnderline)))
    {
        cssTextDecoration = @"underline";
    }
    
    // Set it
    self._DOMElement.style.setProperty(@"text-decoration", cssTextDecoration, null);
}

@end


var LPAnchorButtonUnderlineMaskKey = @"LPAnchorButtonUnderlineMaskKey";

@implementation LPAnchorButton (CPCoding)
 
- (id)initWithCoder:(CPCoder)aCoder
{
    if (self = [super initWithCoder:aCoder])
    {
        _underlineMask = [aCoder decodeIntForKey:LPAnchorButtonUnderlineMaskKey] || LPAnchorButtonNoUnderline;
    }
 
    return self;
}
 
- (void)encodeWithCoder:(CPCoder)aCoder
{
    [super encodeWithCoder:aCoder];
    
    if (_underlineMask !== LPAnchorButtonNoUnderline)
        [aCoder encodeInt:_underlineMask forKey:LPAnchorButtonUnderlineMaskKey];
}
 
@end