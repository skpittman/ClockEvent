.pragma library

// Lightweight iCalendar parser for VEVENT extraction
// Handles: SUMMARY, DTSTART, DTEND, DURATION, UID, DESCRIPTION, LOCATION
// Handles: all-day events (DATE vs DATE-TIME), RRULE expansion, VTIMEZONE

// Parse an iCal date/datetime string into a JS Date
// Formats: "20260228" (date only), "20260228T173000" (local), "20260228T173000Z" (UTC)
// If tzOffsets is provided and a TZID is specified, apply the offset
function parseICalDate(value, tzOffsets) {
    // Strip any TZID prefix — handled by the caller extracting params
    var str = value.trim()

    // All-day: YYYYMMDD
    if (str.length === 8) {
        var y = parseInt(str.substring(0, 4))
        var m = parseInt(str.substring(4, 6)) - 1
        var d = parseInt(str.substring(6, 8))
        return { date: new Date(y, m, d), allDay: true }
    }

    // DateTime: YYYYMMDDTHHMMSS or YYYYMMDDTHHMMSSZ
    var isUtc = str.endsWith("Z")
    str = str.replace("Z", "")

    var parts = str.split("T")
    var datePart = parts[0]
    var timePart = parts[1] || "000000"

    var year = parseInt(datePart.substring(0, 4))
    var month = parseInt(datePart.substring(4, 6)) - 1
    var day = parseInt(datePart.substring(6, 8))
    var hour = parseInt(timePart.substring(0, 2))
    var min = parseInt(timePart.substring(2, 4))
    var sec = parseInt(timePart.substring(4, 6))

    var date
    if (isUtc) {
        date = new Date(Date.UTC(year, month, day, hour, min, sec))
    } else {
        date = new Date(year, month, day, hour, min, sec)
    }

    return { date: date, allDay: false }
}

// Parse a DURATION value (e.g., "P1D", "PT1H30M", "P1DT2H")
function parseDuration(durationStr) {
    var ms = 0
    var str = durationStr.trim()
    var negative = false
    if (str.startsWith("-")) {
        negative = true
        str = str.substring(1)
    }
    str = str.substring(1) // Remove 'P'

    var timePart = ""
    var datePart = str
    var tIndex = str.indexOf("T")
    if (tIndex >= 0) {
        datePart = str.substring(0, tIndex)
        timePart = str.substring(tIndex + 1)
    }

    // Date part: W, D
    var weeks = datePart.match(/(\d+)W/)
    var days = datePart.match(/(\d+)D/)
    if (weeks) ms += parseInt(weeks[1]) * 7 * 24 * 3600000
    if (days) ms += parseInt(days[1]) * 24 * 3600000

    // Time part: H, M, S
    var hours = timePart.match(/(\d+)H/)
    var minutes = timePart.match(/(\d+)M/)
    var seconds = timePart.match(/(\d+)S/)
    if (hours) ms += parseInt(hours[1]) * 3600000
    if (minutes) ms += parseInt(minutes[1]) * 60000
    if (seconds) ms += parseInt(seconds[1]) * 1000

    return negative ? -ms : ms
}

// Unfold iCal lines (lines starting with space/tab are continuations)
function unfoldLines(text) {
    return text.replace(/\r\n[ \t]/g, "").replace(/\r/g, "")
}

// Parse RRULE string into an object
function parseRRule(rruleStr) {
    var rule = {}
    var parts = rruleStr.split(";")
    for (var i = 0; i < parts.length; i++) {
        var kv = parts[i].split("=")
        var key = kv[0]
        var val = kv[1]
        switch (key) {
            case "FREQ": rule.freq = val; break
            case "INTERVAL": rule.interval = parseInt(val); break
            case "COUNT": rule.count = parseInt(val); break
            case "UNTIL": rule.until = parseICalDate(val).date; break
            case "BYDAY": rule.byDay = val.split(","); break
            case "BYMONTHDAY": rule.byMonthDay = val.split(",").map(function(x) { return parseInt(x) }); break
            case "BYMONTH": rule.byMonth = val.split(",").map(function(x) { return parseInt(x) }); break
            case "WKST": rule.wkst = val; break
        }
    }
    if (!rule.interval) rule.interval = 1
    return rule
}

// Day-of-week mapping for BYDAY
var dayMap = { "SU": 0, "MO": 1, "TU": 2, "WE": 3, "TH": 4, "FR": 5, "SA": 6 }

// Expand a recurring event into individual occurrences within [windowStart, windowEnd]
function expandRRule(rule, dtStart, dtEnd, exDates, windowStart, windowEnd, maxOccurrences) {
    if (!maxOccurrences) maxOccurrences = 500
    var occurrences = []
    var duration = dtEnd.getTime() - dtStart.getTime()
    var count = 0

    var endBound = windowEnd
    if (rule.until && rule.until < endBound) endBound = rule.until

    // Build a set of excluded dates for fast lookup (compare date only for robustness)
    var exDateSet = {}
    if (exDates) {
        for (var e = 0; e < exDates.length; e++) {
            var ex = exDates[e]
            exDateSet[ex.getFullYear() + "-" + ex.getMonth() + "-" + ex.getDate()] = true
        }
    }

    function isExcluded(d) {
        return exDateSet[d.getFullYear() + "-" + d.getMonth() + "-" + d.getDate()] === true
    }

    // For weekly recurrence with BYDAY, we need to track week boundaries
    // to correctly apply INTERVAL (e.g., every 2nd week)
    var startDay = dtStart.getDay()
    var startTime = { h: dtStart.getHours(), m: dtStart.getMinutes(), s: dtStart.getSeconds() }

    switch (rule.freq) {
        case "DAILY":
            expandDaily(rule, dtStart, startTime, duration, endBound, windowStart, exDateSet, occurrences, maxOccurrences)
            break
        case "WEEKLY":
            expandWeekly(rule, dtStart, startTime, duration, endBound, windowStart, exDateSet, occurrences, maxOccurrences)
            break
        case "MONTHLY":
            expandMonthly(rule, dtStart, startTime, duration, endBound, windowStart, exDateSet, occurrences, maxOccurrences)
            break
        case "YEARLY":
            expandYearly(rule, dtStart, startTime, duration, endBound, windowStart, exDateSet, occurrences, maxOccurrences)
            break
    }

    return occurrences
}

function makeOccDate(year, month, day, startTime) {
    return new Date(year, month, day, startTime.h, startTime.m, startTime.s)
}

function isExcludedDate(d, exDateSet) {
    return exDateSet[d.getFullYear() + "-" + d.getMonth() + "-" + d.getDate()] === true
}

function addOccurrence(occ, d, duration, windowStart, exDateSet, occurrences) {
    if (d > windowStart || (d.getTime() + duration) > windowStart.getTime()) {
        if (!isExcludedDate(d, exDateSet)) {
            occurrences.push({ start: new Date(d.getTime()), end: new Date(d.getTime() + duration) })
        }
    }
}

function expandDaily(rule, dtStart, startTime, duration, endBound, windowStart, exDateSet, occurrences, max) {
    var count = 0
    var cur = new Date(dtStart.getTime())
    while (cur <= endBound && count < max) {
        if (rule.count !== undefined && count >= rule.count) break
        addOccurrence(null, cur, duration, windowStart, exDateSet, occurrences)
        count++
        // Advance by interval days, preserving time-of-day
        var next = new Date(cur.getFullYear(), cur.getMonth(), cur.getDate() + rule.interval,
                            startTime.h, startTime.m, startTime.s)
        cur = next
    }
}

function expandWeekly(rule, dtStart, startTime, duration, endBound, windowStart, exDateSet, occurrences, max) {
    var count = 0

    // Which days of the week does this event occur?
    var daysOfWeek
    if (rule.byDay) {
        daysOfWeek = []
        for (var d = 0; d < rule.byDay.length; d++) {
            var dayStr = rule.byDay[d].replace(/^-?\d+/, "")
            if (dayMap[dayStr] !== undefined) daysOfWeek.push(dayMap[dayStr])
        }
        daysOfWeek.sort()
    } else {
        // No BYDAY: recur on the same day-of-week as dtStart
        daysOfWeek = [dtStart.getDay()]
    }

    // Start from the week of dtStart
    // Find the Monday (or WKST) of dtStart's week
    var wkstDay = rule.wkst ? dayMap[rule.wkst] : 1 // default Monday
    if (wkstDay === undefined) wkstDay = 1

    // Walk week by week, applying interval
    var weekStart = new Date(dtStart.getFullYear(), dtStart.getMonth(), dtStart.getDate())
    // Rewind to the start-of-week containing dtStart
    var daysSinceWkst = (weekStart.getDay() - wkstDay + 7) % 7
    weekStart.setDate(weekStart.getDate() - daysSinceWkst)

    while (weekStart <= endBound && count < max) {
        if (rule.count !== undefined && count >= rule.count) break

        for (var i = 0; i < daysOfWeek.length; i++) {
            if (rule.count !== undefined && count >= rule.count) break

            var dow = daysOfWeek[i]
            var daysFromWkst = (dow - wkstDay + 7) % 7
            var occDate = makeOccDate(weekStart.getFullYear(), weekStart.getMonth(),
                                      weekStart.getDate() + daysFromWkst, startTime)

            if (occDate > endBound) break
            if (occDate < dtStart) continue

            addOccurrence(null, occDate, duration, windowStart, exDateSet, occurrences)
            count++
        }

        // Advance by interval weeks
        weekStart = new Date(weekStart.getFullYear(), weekStart.getMonth(),
                             weekStart.getDate() + 7 * rule.interval)
    }
}

function expandMonthly(rule, dtStart, startTime, duration, endBound, windowStart, exDateSet, occurrences, max) {
    var count = 0
    var monthOffset = 0

    while (count < max) {
        if (rule.count !== undefined && count >= rule.count) break

        var year = dtStart.getFullYear()
        var month = dtStart.getMonth() + monthOffset

        // Normalize month/year
        year += Math.floor(month / 12)
        month = month % 12
        if (month < 0) { month += 12; year-- }

        if (rule.byMonthDay) {
            for (var i = 0; i < rule.byMonthDay.length; i++) {
                if (rule.count !== undefined && count >= rule.count) break
                var day = rule.byMonthDay[i]
                if (day < 0) {
                    // Negative: count from end of month
                    var lastDay = new Date(year, month + 1, 0).getDate()
                    day = lastDay + day + 1
                }
                if (day < 1) continue
                var d = makeOccDate(year, month, day, startTime)
                if (d > endBound) return
                if (d >= dtStart) {
                    addOccurrence(null, d, duration, windowStart, exDateSet, occurrences)
                    count++
                }
            }
        } else if (rule.byDay) {
            // BYDAY in monthly context: e.g., "2TU" = 2nd Tuesday
            for (var i = 0; i < rule.byDay.length; i++) {
                if (rule.count !== undefined && count >= rule.count) break
                var match = rule.byDay[i].match(/^(-?\d+)?([A-Z]{2})$/)
                if (!match) continue
                var nth = match[1] ? parseInt(match[1]) : 0
                var dow = dayMap[match[2]]
                if (dow === undefined) continue

                var dates = nthDayOfMonth(year, month, dow, nth)
                for (var j = 0; j < dates.length; j++) {
                    if (rule.count !== undefined && count >= rule.count) break
                    var d = makeOccDate(year, month, dates[j], startTime)
                    if (d > endBound) return
                    if (d >= dtStart) {
                        addOccurrence(null, d, duration, windowStart, exDateSet, occurrences)
                        count++
                    }
                }
            }
        } else {
            // No BYDAY/BYMONTHDAY: same day-of-month as dtStart
            var day = dtStart.getDate()
            var lastDay = new Date(year, month + 1, 0).getDate()
            if (day <= lastDay) {
                var d = makeOccDate(year, month, day, startTime)
                if (d > endBound) return
                if (d >= dtStart) {
                    addOccurrence(null, d, duration, windowStart, exDateSet, occurrences)
                    count++
                }
            }
        }

        monthOffset += rule.interval
    }
}

// Find the Nth occurrence of a day-of-week in a month
// nth > 0: 1st, 2nd, etc. nth < 0: last, 2nd-to-last, etc. nth == 0: all occurrences
function nthDayOfMonth(year, month, dow, nth) {
    var lastDay = new Date(year, month + 1, 0).getDate()
    var matches = []
    for (var d = 1; d <= lastDay; d++) {
        if (new Date(year, month, d).getDay() === dow) matches.push(d)
    }
    if (nth === 0) return matches
    if (nth > 0) return nth <= matches.length ? [matches[nth - 1]] : []
    // negative
    var idx = matches.length + nth
    return idx >= 0 ? [matches[idx]] : []
}

function expandYearly(rule, dtStart, startTime, duration, endBound, windowStart, exDateSet, occurrences, max) {
    var count = 0
    var yearOffset = 0

    while (count < max) {
        if (rule.count !== undefined && count >= rule.count) break
        var year = dtStart.getFullYear() + yearOffset

        var months = rule.byMonth ? rule.byMonth.map(function(m) { return m - 1 }) : [dtStart.getMonth()]

        for (var mi = 0; mi < months.length; mi++) {
            if (rule.count !== undefined && count >= rule.count) break
            var month = months[mi]

            if (rule.byMonthDay) {
                for (var i = 0; i < rule.byMonthDay.length; i++) {
                    if (rule.count !== undefined && count >= rule.count) break
                    var d = makeOccDate(year, month, rule.byMonthDay[i], startTime)
                    if (d > endBound) return
                    if (d >= dtStart) {
                        addOccurrence(null, d, duration, windowStart, exDateSet, occurrences)
                        count++
                    }
                }
            } else if (rule.byDay) {
                for (var i = 0; i < rule.byDay.length; i++) {
                    if (rule.count !== undefined && count >= rule.count) break
                    var match = rule.byDay[i].match(/^(-?\d+)?([A-Z]{2})$/)
                    if (!match) continue
                    var nth = match[1] ? parseInt(match[1]) : 0
                    var dow = dayMap[match[2]]
                    if (dow === undefined) continue
                    var dates = nthDayOfMonth(year, month, dow, nth)
                    for (var j = 0; j < dates.length; j++) {
                        if (rule.count !== undefined && count >= rule.count) break
                        var d = makeOccDate(year, month, dates[j], startTime)
                        if (d > endBound) return
                        if (d >= dtStart) {
                            addOccurrence(null, d, duration, windowStart, exDateSet, occurrences)
                            count++
                        }
                    }
                }
            } else {
                var d = makeOccDate(year, month, dtStart.getDate(), startTime)
                if (d > endBound) return
                if (d >= dtStart) {
                    addOccurrence(null, d, duration, windowStart, exDateSet, occurrences)
                    count++
                }
            }
        }

        yearOffset += rule.interval
    }
}

// Extract a property value and its parameters from a line
// e.g., "DTSTART;TZID=America/Chicago:20260228T170000" -> { value: "20260228T170000", params: { TZID: "America/Chicago" } }
function parseProperty(line) {
    var colonIdx = line.indexOf(":")
    if (colonIdx === -1) return { key: line, value: "", params: {} }

    var left = line.substring(0, colonIdx)
    var value = line.substring(colonIdx + 1)
    var params = {}

    var semiIdx = left.indexOf(";")
    var key = left
    if (semiIdx >= 0) {
        key = left.substring(0, semiIdx)
        var paramStr = left.substring(semiIdx + 1)
        var paramParts = paramStr.split(";")
        for (var i = 0; i < paramParts.length; i++) {
            var eq = paramParts[i].indexOf("=")
            if (eq >= 0) {
                params[paramParts[i].substring(0, eq)] = paramParts[i].substring(eq + 1)
            }
        }
    }

    return { key: key, value: value, params: params }
}

// Main parse function: takes raw iCal text and a date window, returns event array
function parse(icalText, windowStart, windowEnd) {
    var text = unfoldLines(icalText)
    var lines = text.split("\n")

    var events = []
    var inEvent = false
    var currentEvent = null
    var exDates = []

    for (var i = 0; i < lines.length; i++) {
        var line = lines[i].trim()
        if (!line) continue

        if (line === "BEGIN:VEVENT") {
            inEvent = true
            currentEvent = {}
            exDates = []
            continue
        }

        if (line === "END:VEVENT") {
            inEvent = false
            if (currentEvent && currentEvent.summary) {
                processEvent(currentEvent, exDates, events, windowStart, windowEnd)
            }
            currentEvent = null
            continue
        }

        if (!inEvent) continue

        var prop = parseProperty(line)

        switch (prop.key) {
            case "SUMMARY":
                currentEvent.summary = prop.value.replace(/\\n/g, "\n").replace(/\\,/g, ",").replace(/\\\\/g, "\\")
                break
            case "DTSTART":
                currentEvent.dtStartRaw = prop.value
                currentEvent.dtStartTzid = prop.params.TZID || null
                var startParsed = parseICalDate(prop.value)
                currentEvent.dtStart = startParsed.date
                currentEvent.allDay = startParsed.allDay
                if (prop.params.VALUE === "DATE") currentEvent.allDay = true
                break
            case "DTEND":
                currentEvent.dtEndRaw = prop.value
                var endParsed = parseICalDate(prop.value)
                currentEvent.dtEnd = endParsed.date
                break
            case "DURATION":
                currentEvent.duration = prop.value
                break
            case "UID":
                currentEvent.uid = prop.value
                break
            case "DESCRIPTION":
                currentEvent.description = prop.value.replace(/\\n/g, "\n").replace(/\\,/g, ",").replace(/\\\\/g, "\\")
                break
            case "LOCATION":
                currentEvent.location = prop.value.replace(/\\n/g, "\n").replace(/\\,/g, ",").replace(/\\\\/g, "\\")
                break
            case "RRULE":
                currentEvent.rrule = prop.value
                break
            case "EXDATE":
                var exParsed = parseICalDate(prop.value)
                exDates.push(exParsed.date)
                break
        }
    }

    return events
}

// Process a single parsed VEVENT into one or more event occurrences
function processEvent(ev, exDates, events, windowStart, windowEnd) {
    if (!ev.dtStart) return

    // Calculate end time
    if (!ev.dtEnd) {
        if (ev.duration) {
            ev.dtEnd = new Date(ev.dtStart.getTime() + parseDuration(ev.duration))
        } else if (ev.allDay) {
            // All-day events with no end default to 1 day
            ev.dtEnd = new Date(ev.dtStart.getTime() + 86400000)
        } else {
            // Default to same as start
            ev.dtEnd = new Date(ev.dtStart.getTime())
        }
    }

    if (ev.rrule) {
        // Recurring event: expand occurrences
        var rule = parseRRule(ev.rrule)
        var occurrences = expandRRule(rule, ev.dtStart, ev.dtEnd, exDates, windowStart, windowEnd)
        for (var j = 0; j < occurrences.length; j++) {
            events.push(makeEvent(ev, occurrences[j].start, occurrences[j].end))
        }
    } else {
        // Single event: check if it falls within the window
        if (ev.dtEnd >= windowStart && ev.dtStart <= windowEnd) {
            events.push(makeEvent(ev, ev.dtStart, ev.dtEnd))
        }
    }
}

function makeEvent(ev, start, end) {
    return {
        summary: ev.summary || "",
        startTime: start,
        endTime: end,
        allDay: ev.allDay || false,
        uid: ev.uid || "",
        description: ev.description || "",
        location: ev.location || ""
    }
}
