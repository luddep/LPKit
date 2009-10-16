# LPKit
A collection of different generic views & utilities for [Cappuccino](http://cappuccino.org/), extracted from the up-coming cappuccino port of [Observer](http://observerapp.com/).

# What's inside

## Views

### Slide view

LPSlideVie lets you slide between different subviews. Only one subview will be visible, and the sliding only shows the relevant subviews - no matter how many other views might be between them.

### Calendar view

LPCalendarView is a calendar view based on the iPhone calendar app, with the same sliding when changing months. Currently supports selecting days & weeks, also marking a special day as highlighted - such as the current day or week.

### Sparkline

A simple sparkline chart, comparable to the Google Chart sparklines - but using CoreGraphics rather than an image.

## Utilities

### LPEmail

A simple object which lets you validate emails, for now. *NOTE:* the current regexp is broken, needs to be replaced with one that actually works.