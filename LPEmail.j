/*
 * LPEmail.j
 * LPKit
 *
 * Created by Ludwig Pettersson on September 30, 2009.
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

var emailPattern = new RegExp("^[a-zA-Z0-9._-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,4}$");

@implementation LPEmail : CPObject
{
    CPString email;
}

+ (id)emailWithString:(CPString)anEmail
{
    return [[self alloc] initWithString:anEmail];
}

+ (BOOL)emailWithStringIsValid:(CPString)anEmail
{
    return emailPattern.test(anEmail);
}

- (void)initWithString:(CPString)anEmail
{
    if (self = [super init])
    {
        email = anEmail;
    }
    return self;
}

- (void)stringValue
{
    return email;
}

- (BOOL)isValidEmail
{
    return [LPEmail emailWithStringIsValid:email];
}

- (BOOL)isEqualToEmail:(LPEmail)anEmail
{
    return [[self stringValue] isEqualToString:[anEmail stringValue]];
}

@end


var LPEmailKey = @"LPEmailKey";

@implementation LPEmail (CPCoding)
 
- (id)initWithCoder:(CPCoder)aCoder
{
    if (self)
    {
        email = [aCoder decodeObjectForKey:LPEmailKey];
    }
 
    return self;
}
 
- (void)encodeWithCoder:(CPCoder)aCoder
{
    [aCoder encodeObject:email forKey:LPEmailKey];
}
 
@end