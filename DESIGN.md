# ClockEvent Plasmoid — Design Document

## Overview

ClockEvent is a KDE Plasma 6 desktop widget (plasmoid) that displays a clock with
the current time and date, followed by a scrollable list of upcoming calendar events
pulled from Google Calendar via iCal/ICS feeds. The layout is inspired by Android's
"next events" widget.

## Target Environment

- KDE Plasma 6 (tested on 6.5.x, Fedora/Nobara)
- QML with Qt 6
- Plasmoid API: Plasma 6 (org.kde.plasma.plasmoid)

## Layout

The widget is a single resizable panel with a dark background that follows the
system KDE theme. From top to bottom:

```
+-------------------------------+
|         5:30 PM               |  <- Large clock text
|        Sat Feb 28             |  <- Date subtitle
+-------------------------------+
|  February                 [+] |  <- Month header + add button
|                               |
|  S   | Event Title            |
|  28  | 8 – 9 PM              |  <- Event row
|                               |
|  March                        |  <- Month header
|                               |
|  Sun | Event Title            |
|   1  | 11 AM – 12 PM         |  <- Event row
|                               |
|  ... (scrollable)             |
+-------------------------------+
```

### Clock Section

- Time displayed in large, bold text (top line)
- Configurable 12-hour (with AM/PM) or 24-hour format
- Date displayed below in smaller text: `Day-of-week Mon DD` (e.g., "Sat Feb 28")
- Updates every minute

### Month Headers

- When events span multiple months, a month name header appears as a section
  divider (e.g., "February", "March")
- The `[+]` button appears on the first visible month header and opens Google
  Calendar's event creation page in the default browser

### Event Rows

Each event row contains:

- **Left side — Date circle/badge:** Abbreviated day-of-week on top (e.g., "S",
  "Sun"), day number below (e.g., "28", "1"). If multiple consecutive events fall
  on the same date, only the first event shows the date badge; subsequent events
  on the same date leave the left side blank.
- **Right side — Event block:** A rounded rectangle containing the event title
  (bold) and the time range below it (e.g., "8 – 9 PM"). All-day events display
  "All day" instead of a time range.

### Styling

- Follows the KDE system/Plasma theme (colors, fonts, border radius)
- Event blocks are a slightly lighter shade against the widget background
  (e.g., light grey blocks on a darker background), using theme-appropriate
  contrast
- No per-calendar or per-event color coding (future enhancement)
- The widget border, spacing, and typography should feel native to Plasma

## Data Source

### iCal/ICS Feeds

Events are fetched from Google Calendar using the "Secret address in iCal format"
URL that Google provides per calendar. Users configure one or more iCal URLs in
the widget's settings dialog.

- Standard iCalendar (RFC 5545) parsing
- Fetches via HTTPS GET
- No authentication required (secret URL acts as access token)

### Refresh

- Events are refreshed every 15 minutes (configurable in settings)
- A manual refresh option should be available (e.g., right-click context menu)

### Event Window

- Fetch and display events from today through 30 days out (configurable)
- Past events from today that have already ended should be hidden
- Events are sorted chronologically across all calendars

## Configuration Dialog

Accessible via the standard plasmoid config (right-click > Configure).

### Calendars Tab

- List of configured iCal URLs, each with:
  - A user-defined label (e.g., "Work", "Personal")
  - The iCal URL (text field, paste-friendly)
  - A toggle to show/hide that calendar
- Add / Remove buttons for managing the list

### Appearance Tab

- Clock format: 12-hour / 24-hour toggle
- Number of days to look ahead (default: 30)

### General Tab

- Refresh interval in minutes (default: 15, min: 5)

## Interactions

| Action                     | Result                                              |
|----------------------------|-----------------------------------------------------|
| Click on an event          | Opens the event in Google Calendar (browser) for editing |
| Click `[+]` button         | Opens Google Calendar's "new event" page in browser |
| Resize widget              | More/fewer events visible; event list scrolls       |
| Right-click widget         | Standard Plasma context menu (Configure, Remove, etc.) |
| Scroll event list          | Scrolls through upcoming events                     |

### Event URL Construction

Google Calendar event edit URLs follow this pattern:
`https://calendar.google.com/calendar/event?eid=<encoded_event_id>`

The event UID from the iCal feed can be used to construct this link. If the UID
doesn't map cleanly to a Google URL, fall back to opening the calendar day view:
`https://calendar.google.com/calendar/r/day/YYYY/MM/DD`

## Technical Architecture

### File Structure

```
com.github.libra.clockevent/
  metadata.json              # Plasmoid metadata (KDE plugin info)
  contents/
    ui/
      main.qml               # Root component, layout container
      ClockSection.qml        # Clock + date display
      EventList.qml           # Scrollable event list
      EventRow.qml            # Single event row (date badge + event block)
      MonthHeader.qml         # Month section divider
      ConfigGeneral.qml       # Config dialog: general settings
      ConfigCalendars.qml     # Config dialog: calendar URL management
      ConfigAppearance.qml    # Config dialog: appearance settings
    code/
      calendarfetcher.js      # iCal fetch + parse logic
```

### Key Implementation Details

**iCal Parsing:**
- Use a lightweight JavaScript iCal parser (e.g., ical.js / hand-rolled for the
  subset we need: VEVENT with SUMMARY, DTSTART, DTEND, UID, RRULE)
- Handle recurring events (RRULE) by expanding occurrences within the display
  window
- Handle VTIMEZONE and timezone conversions to local time

**Data Flow:**
1. On startup and every refresh interval, fetch all enabled iCal URLs
2. Parse each feed, extract events within the display window
3. Merge events from all calendars into a single sorted list
4. Group events by month for display
5. Expose as a ListModel to QML for rendering

**Clock:**
- Use a QML Timer with 1-second or 1-minute interval
- Format time using Qt.formatDateTime()

**Scrolling:**
- QML ListView with section delegates for month headers
- Flickable / scroll behavior native to Plasma

## Future Enhancements (Not In Scope)

- Google Calendar API integration (OAuth) for per-event colors and richer data
- Per-calendar or per-event color coding via tags
- Multiple Google account support
- CalDAV support for non-Google calendars
- Desktop notifications for upcoming events
- Compact/minimal mode for smaller widget sizes
