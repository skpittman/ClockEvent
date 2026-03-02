.pragma library

.import "icalparser.js" as ICalParser

// Fetch all enabled calendars, parse events, merge and sort
// callback receives a sorted array of event objects
function fetchAllCalendars(calendarSourcesJson, daysAhead, callback, statusCallback) {
    if (!statusCallback) statusCallback = function() {}
    var sources
    try {
        sources = JSON.parse(calendarSourcesJson)
    } catch (e) {
        statusCallback("JSON parse error: " + e)
        callback([])
        return
    }

    if (!sources || sources.length === 0) {
        statusCallback("No sources configured")
        callback([])
        return
    }

    var enabledSources = sources.filter(function(s) { return s.enabled && s.url })
    if (enabledSources.length === 0) {
        statusCallback("No enabled sources with URLs")
        callback([])
        return
    }

    statusCallback("Fetching " + enabledSources.length + " calendar(s)...")

    var now = new Date()
    var windowStart = new Date(now.getFullYear(), now.getMonth(), now.getDate())
    var windowEnd = new Date(windowStart.getTime() + daysAhead * 86400000)

    var pending = enabledSources.length
    var allEvents = []

    for (var i = 0; i < enabledSources.length; i++) {
        fetchSingle(enabledSources[i], windowStart, windowEnd, function(events) {
            allEvents = allEvents.concat(events)
            pending--
            if (pending === 0) {
                // Sort by start time
                allEvents.sort(function(a, b) {
                    return a.startTime.getTime() - b.startTime.getTime()
                })

                // Filter out events that have already ended today
                var filtered = allEvents.filter(function(ev) {
                    if (ev.allDay) return true
                    return ev.endTime > now
                })

                callback(filtered)
            }
        }, statusCallback)
    }
}

function fetchSingle(source, windowStart, windowEnd, callback, statusCallback) {
    if (!statusCallback) statusCallback = function() {}
    var xhr = new XMLHttpRequest()

    xhr.onreadystatechange = function() {
        if (xhr.readyState === XMLHttpRequest.DONE) {
            if (xhr.status === 200) {
                statusCallback("Got " + xhr.responseText.length + " bytes from " + source.label + ", parsing...")
                try {
                    var events = ICalParser.parse(xhr.responseText, windowStart, windowEnd)
                    for (var j = 0; j < events.length; j++) {
                        events[j].calendarLabel = source.label || ""
                        events[j].calendarColor = source.color || "#1d99f3"
                    }
                    statusCallback("Parsed " + events.length + " events from " + source.label)
                    callback(events)
                } catch (e) {
                    statusCallback("Parse error (" + source.label + "): " + e)
                    callback([])
                }
            } else {
                statusCallback("HTTP " + xhr.status + " from " + source.label)
                callback([])
            }
        }
    }

    xhr.open("GET", source.url)
    xhr.send()
}
