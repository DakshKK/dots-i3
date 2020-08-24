#!/bin/bash

WRKSP=$1

case $1 in
	all)
		# List active workspaces
		# After that list applications in said workspace
		WRKSP=`i3-msg -t get_workspaces | jq -r '.[].name' | dmenu -i -l 3 -fn 'Quintessential-13'`
		;;
	app)
		# Take user input and list applications with given name
		WRKSP=`dmenu -p 'Application Name: ' -fn 'Quintessential-14' <&-`
		app=`i3-msg -t get_tree | jq -r --arg app "$WRKSP" 'recurse(.nodes[]) | recurse(.floating_nodes[].nodes[]) | select(.window) | select(.name | test($app; "i")) | .name'`
		if [[ $app ]]; then
			:
		else
			notify-send Error "No applications with given name open"
			exit 0
		fi
		;;
esac

winName=`i3-msg -t get_tree | jq -r --arg wrksp "$WRKSP" 'recurse(.nodes[]) | select(.name) | select(.name | test($wrksp; "i")) | recurse(.nodes[]) | recurse(.floating_nodes[].nodes[]) | select(.window) | .name' | dmenu -i -p "$WRKSP" -l 4 -fn 'Quintessential-13'`

winID=`wmctrl -lp | fgrep "$winName" | awk '{print $1}'`

i3-msg "[id=$winID] focus"
