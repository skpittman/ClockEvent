#!/bin/bash
cd "$(dirname "$0")"

# Install or upgrade the package
if kpackagetool6 --type Plasma/Applet --show org.kde.plasma.clockevent &>/dev/null; then
    kpackagetool6 --type Plasma/Applet --upgrade .
else
    kpackagetool6 --type Plasma/Applet --install .
fi

# Restart plasmashell to pick up changes
kquitapp6 plasmashell && kstart plasmashell
