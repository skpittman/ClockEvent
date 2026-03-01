# ClockEvent

A KDE Plasma 6 desktop widget that displays a clock and upcoming Google Calendar
events, inspired by Android's "next events" widget.

## Features

- Large clock display with date (12h/24h configurable)
- Upcoming events pulled from Google Calendar via iCal/ICS feeds
- Events grouped by month with date badges
- Scrollable, resizable widget
- Click events to open in Google Calendar
- Quick-add button to create new events
- Follows your KDE system theme
- 15-minute auto-refresh (configurable)

## Setup

1. Install the plasmoid (instructions TBD)
2. Add the widget to your desktop
3. Right-click > Configure
4. For each Google Calendar you want to display:
   - Open Google Calendar > Settings > (select calendar) > "Secret address in iCal format"
   - Copy the URL and paste it into the widget config
5. Done

## Requirements

- KDE Plasma 6
- Internet connection (for fetching iCal feeds)

## Building

TBD

## License

TBD
