#!/bin/env bash

function getDevice {
	if [[ -n $MIC_MUTE ]]; then
		echo "microphone"
	elif (bluetoothctl info >/dev/null); then
		echo "headphone"
	elif [[ $(amixer -c 1 sget Speaker) =~ \[0%\] ]]; then
		echo "earphone"
	else
		echo "speaker"
	fi
}

function getIcon {
	icon="volume/$(getDevice)"
	if [[ $icon =~ microphone ]]; then
		if [[ $(amixer -D pulse sget Capture) =~ \[on\] ]]; then
			icon="${icon}/unmute"
		else
			icon="${icon}/mute"
		fi
	else
		local data
		data=$(amixer -D pulse sget Master)
		if [[ "$data" =~ \[off\] ]]; then
			icon="${icon}/mute"
		elif [[ $icon =~ speaker ]]; then
			local volume
			volume=$(echo "$data" | awk -F '[][%]' 'END {print $2}')
			if [[ $volume -ge 65 ]]; then
				icon="${icon}/high"
			elif [[ $volume -ge 35 ]]; then
				icon="${icon}/mid"
			else
				icon="${icon}/low"
			fi
		else
			icon="${icon}/unmute"
		fi
	fi
}

function notify {
	getIcon

	local summary body
	local category
	if [[ -z $MIC_MUTE ]]; then
		local volume
		volume=$(amixer -D pulse sget Master | awk -F '[][%]' 'END {print $2}')

		summary=$(seq -s "─" $((volume / 5 + 1)) | sed 's/[0-9]//g')
		body="<span color='#6f7b96'>$(seq -s "─" $((21 - volume / 5)) | sed 's/[0-9]//g')</span>"

		if [[ $icon =~ /mute ]]; then
			category="volume-notify-mute"
			body="<span font='16' color='#6184c2'>⬢</span>${body}"
		else
			category="volume-notify"
			body="<span font='16' color='#4eb3c7'>⬢</span>${body}"
		fi
	else
		if [[ $icon =~ /mute ]]; then
			summary="Microphone Muted"
			category="volume-notify-mute"
		else
			summary="Microphone Unmuted"
			category="volume-notify"
		fi
	fi

	# ﻿ is the unicode character U+FEFF which is an invisible character
	# ​ is the unicode character U+200B which is an invisible character
	# Let's you send an empty summary
	# If you prefer you can also use the gdbus call by using the notification function above
	paplay ~/.config/i3/music/audio-volume-change.oga
	notify-send "﻿$summary" "${body}" -i "$icon" -c "$category"
}

function volumeChange {
	# Use the pactl lines if you have pulse, or can not use amixer
	# amixer offers a limit without any checks hence I prefer that
	# amixer is for ALSA device otherwise
	case $1 in
		-u|--up)
			# pactl set-sink-volume @DEFAULT_SINK@ +5%
			amixer -D pulse sset Master 5%+
			;;
		-d|--down)
			# pactl set-sink-volume @DEFAULT_SINK@ -5%
			amixer -D pulse sset Master 5%-
			;;
		-t|--toggle)
			# pactl set-sink-volume @DEFAULT_SINK@ toggle
			amixer -D pulse sset Master toggle
			;;
		-m|--mic-mute)
			# pactl set-source-mute @DEFAULT_SOURCE@ toggle
			amixer -D pulse sset Capture toggle
			MIC_MUTE=1
			;;
		# -h|--help)
			# usage
			# ;;
	esac
	notify
	killall -SIGUSR1 i3status
}

volumeChange "$@"
