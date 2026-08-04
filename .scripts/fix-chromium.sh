#!/bin/bash
# Kill any stuck/windowless chromium and clear its profile lock, then relaunch.
pkill -9 -f '/usr/lib/chromium/chromium'
sleep 1
rm -f "$HOME/.config/chromium/Singleton"*
chromium &
disown
