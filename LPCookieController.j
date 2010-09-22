/*
 * LPCookieController.j
 * LPKit
 *
 * Created by Ludwig Pettersson on October 11, 2009.
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

@import <Foundation/CPObject.j>
@import <Foundation/CPRange.j>

var sharedCookieControllerInstance = nil;

@implementation LPCookieController : CPObject
{
}

+ (id)sharedCookieController
{
    if (!sharedCookieControllerInstance)
        sharedCookieControllerInstance = [[self alloc] init];
    
    return sharedCookieControllerInstance;
}

- (void)setValue:(CPString)aValue forKey:(CPString)aKey
{
    return [self setValue:aValue forKey:aKey expirationDate:nil];
}

- (void)setValue:(CPString)aValue forKey:(CPString)aKey expirationDate:(CPDate)anExpirationDate
{
    return [self setValue:aValue forKey:aKey expirationDate:anExpirationDate path:nil];
}

- (void)setValue:(CPString)aValue forKey:(CPString)aKey expirationDate:(CPDate)anExpirationDate path:(CPString)aPath
{
    return [self setValue:aValue forKey:aKey expirationDate:anExpirationDate path:aPath domain:nil];
}


- (void)setValue:(CPString)aValue forKey:(CPString)aKey expirationDate:(CPDate)anExpirationDate path:(CPString)aPath domain:(CPString)aDomain
{
    return [self setValue:aValue forKey:aKey expirationDate:anExpirationDate path:aPath domain:nil escape:YES];
}

- (void)setValue:(CPString)aValue forKey:(CPString)aKey expirationDate:(CPDate)anExpirationDate path:(CPString)aPath domain:(CPString)aDomain escape:(BOOL)shouldEscape
{
    var cookieString = @"";
    
    // Add key value pair
    cookieString += [CPString stringWithFormat:@"%s=%s; ", aKey, shouldEscape ? escape(aValue) : aValue];
    
    // Add expiration date
    if (anExpirationDate)
        cookieString += [CPString stringWithFormat:@"expires=%s; ", anExpirationDate.toUTCString()];
    
    // Add path
    cookieString += [CPString stringWithFormat:@"path=%s; ", aPath || @"/"];
    
    // Add domain
    if (aDomain)
        cookieString += [CPString stringWithFormat:@"domain=%s; ", aDomain];
        
    // Remove trailing '; '
    cookieString = [cookieString substringToIndex:[cookieString length] - 2];
    
    // Set the cookie
    document.cookie = cookieString;
}

- (id)valueForKey:(CPString)aKey
{
    var cookies = [document.cookie componentsSeparatedByString:@";"];
    
    for(var i = 0; i < [cookies count]; i++)
    {
        var cookie = [cookies objectAtIndex:i],
            range = [cookie rangeOfString:[CPString stringWithFormat:@"%s=", aKey] options:CPCaseInsensitiveSearch];
        
        if (range.length > 0)
            return [cookie substringFromIndex:CPMaxRange(range)];
    }
    
    return nil;
}

- (void)removeValueForKey:(CPString)aKey
{
    [self setValue:@"" forKey:aKey expirationDate:[CPDate distantPast]];
}

@end