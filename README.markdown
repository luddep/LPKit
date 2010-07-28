# LPKit
A collection of different generic views & utilities for [Cappuccino](http://cappuccino.org/), extracted from the up-coming cappuccino port of [Observer](http://observerapp.com/).

A demo is available at <http://luddep.se/static/LPKit-Examples/>, with the source code in the [LPKit-Examples repository](https://github.com/luddep/LPKit-Examples).

LPKit requires a version higher than 0.7.1 to run, which at the time of writing is only available as the master (or jake) trunk.

## Installation

Place the entire LPKit folder in your Frameworks folder, or any directory that you add using `OBJJ_INCLUDE_PATHS`.

# What's inside

## Slide view

LPSlideView lets you slide between different subviews. Only one subview will be visible, and the sliding only shows the relevant subviews - no matter how many other views might be between them.

## Calendar view

![calendar view](http://dl.getdropbox.com/u/24582/github/LPKit/calendarview.png)

LPCalendarView is a calendar view based on the iPhone calendar app, with the same sliding when changing months. Currently supports selecting days & weeks, also marking a special day as highlighted - such as the current day or week.

## Sparkline

![sparkline](http://dl.getdropbox.com/u/24582/github/LPKit/sparkline.png)

A simple sparkline chart, comparable to the Google Chart sparklines - but using CoreGraphics rather than an image.

## Switch control

![switch control](http://dl.getdropbox.com/u/24582/github/LPKit/switch.png)

A port of the UISwitch from the iPhone SDK, with the same behavior and feel.

## Utilities

### LPEmail

A simple object which lets you validate emails, for now. **NOTE:** the current regexp is broken, needs to be replaced with one that actually works.

### LPURLPostRequest

A wrapper around `CPURLRequest` to make working with post requests a bit simpler.
Rather than manually settings the HTTPBody & Content-Type, you pass it a javascript object with key value pairs of strings which you want to send as a POST request.

Example:

    var request = [LPURLPostRequest requestWithURL:[CPURL URLWithString:@"/my-url/"]],
        content = {
                      'name': 'Lorem ipsum',
                      'age': '18'
                  };
    
    [request setContent:content]
    [CPURLConnection connectionWithRequest:request delegate:self];

### LPCookieController

A utility class to work with document.cookie, without the tedious stuff.

Example:

    var cookieController = [LPCookieController sharedCookieController];
    
    // Set a session, which will be deleted when the browser closes.
    [cookieController setValue:@"My value" forKey:@"MyKey"];
    
    // Set a cookie which won't be flushed
    [cookieController setValue:@"My value" forKey:@"MyOtherKey" expirationDate:[CPDate distantFuture]];
    
    // Get the value of the session
    console.log('value for MyKey: ' + [cookieController valueForKey:@"MyKey"]);

# Themes

LPKit makes heavy use of the theme API in Cappuccino.
An example on how to use themes with LPKit is available in in the [LPKit-Examples repository](https://github.com/luddep/LPKit-Examples) which has a demo theme with an Aristo inspired look.

# Contributors
* [Ludwig Pettersson](http://github.com/luddep)
* [Alexander Ljungberg](http://github.com/aljungberg)
* [Klaas Pieter Annema](http://github.com/klaaspieter)
* [Dimitris Tsitses](http://github.com/dtsitses)