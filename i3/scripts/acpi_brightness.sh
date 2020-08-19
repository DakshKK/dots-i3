#!/bin/env bash

# This script works because of the udev rule provided in rules - 90-brightness.rules
# Place it under /etc/udev/rules.d

function getIcon {
	icon="brightness/"

	if [[ $1 -le 25 ]]; then
		icon="${icon}/moon"
	elif [[ $1 -le 50 ]]; then
		icon="${icon}/moon-crescent-small"
	elif [[ $1 -le 75 ]]; then
		icon="${icon}/moon-crescent-large"
	else
		icon="${icon}/sun"
	fi
}

function notify {
	getIcon $1

	local summary body

	summary=$(seq -s "─" $(($1 / 5 + 1)) | sed 's/[0-9]//g')
	body="<span color='#6f7b96'>$(seq -s "─" $((21 - $1 / 5)) | sed 's/[0-9]//g')</span>"

	body="<span font='16' color='#4eb3c7'>⬢</span>${body}"

	# ﻿ is the unicode character U+FEFF which is an invisible character
	# ​ is the unicode character U+200B which is an invisible character
	# Let's you send an empty summary
	# If you prefer you can also use the gdbus call by using the notification function above
	# paplay ~/.config/i3/music/audio-volume-change.oga
	notify-send "﻿$summary" "${body}" -i "$icon" -c "brightness-notify"
}

function change {
	local file value
	file="/sys/class/backlight/*/brightness"

	value=$(< ${file})
	value=$(( ( value + 1 ) * 100 / 255 ))
	case $1 in
		-u|--up)
			value=$(( ( value + 5 ) * 255 / 100))
			;;
		-d|--down)
			value=$(( ( value - 5 ) * 255 / 100))
			;;
	esac

	if [[ $value -gt 255 ]]; then
		value=255
	elif [[ $value -lt 0 ]]; then
		value=0
	fi

	echo $value > ${file}

	value=$(( ( value + 1 ) * 100 / 255 ))
	notify ${value}

	file=".config/i3/infoFiles/brightness"

	echo "💡 ${value}%" > ${file}
	killall -SIGUSR1 i3status
}

change "$1"
