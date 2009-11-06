# LPKit
A collection of different generic views & utilities for [Cappuccino](http://cappuccino.org/), extracted from the up-coming cappuccino port of [Observer](http://observerapp.com/).

A running example app will be up, soon.

## Installation

Place the entire LPKit folder in your Frameworks folder, or any directory that you add using `OBJJ_INCLUDE_PATHS`.

# What's inside

## Slide view

LPSlideVie lets you slide between different subviews. Only one subview will be visible, and the sliding only shows the relevant subviews - no matter how many other views might be between them.

## Calendar view

![calendar view](http://dl.getdropbox.com/u/24582/github/LPKit/calendarview.png)

LPCalendarView is a calendar view based on the iPhone calendar app, with the same sliding when changing months. Currently supports selecting days & weeks, also marking a special day as highlighted - such as the current day or week.

**IMPORTANT:** Calendar view currently does not have a default theme, but an example ThemeDescriptors.j can be found in Examples/.
When compiling your theme, make sure to symlink LPKit to the Frameworks folder of the objj narwhal package. (Located at **/usr/local/share/narwhal/packages/objj/lib/Frameworks** in my case)

**NOTE:** The sliding isn't yet 100% totally awesome, and there will be improvements, eventually.

## Sparkline

![calendar view](http://dl.getdropbox.com/u/24582/github/LPKit/sparkline.png)

A simple sparkline chart, comparable to the Google Chart sparklines - but using CoreGraphics rather than an image.

## Utilities

### LPEmail

A simple object which lets you validate emails, for now. **NOTE:** the current regexp is broken, needs to be replaced with one that     actually works.