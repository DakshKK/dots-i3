#!/bin/bash

# Have set working directory to $dir
# dir="/home/dakksh/.config/i3/"

#########################################################
# Locking script if necessary
# Check if needed but doesn't seem necessary
#
# Stop on errors
set -e
#
# Create a lockfile
scriptname=$(basename "$0" .sh)
# Lockfile can be created in preferred lock directory /var/lock or in infoFiles directory
# lockfile="${dir}/infoFiles/${scriptname}.lock"
# If working directory is set to $dir as given above then
# lockfile="infoFiles/${scriptname}.lock"
lockfile="/var/lock/${scriptname}.lock"
#
# Unlocking the script
#
trap 'rm -rf "$lockfile"' EXIT
# Lock the file
exec 300>"$lockfile"
flock -xn 300
#
# pid=$$
# echo $pid >&300
#
#########################################################

# Setting WorkingDirectory in systemd service lets you use relative paths
# bat="$dir/infoFiles/battery"
# noti="$dir/infoFiles/notification"

bat="infoFiles/battery"
noti="infoFiles/notification"
warning="music/warning.oga"

# Need following exports if installing service for all users. That is /etc/systemd/system
# If installed in ~/.config/systemd/user the systemd user-environment-generator will generate the environment variables per user
# To make script start on boot run sudo systemctl enable battery.service for systemwide installation
# To install only for user first create ~/.config/systemd/user/ and place the service file inside it
# To enable no need for sudo. Just write systemctl enable --user battery.service
# To start it use systemctl start --user battery.service
# Depending on systemwide installation either run it as sudo previous command without user
# Or just the given command
#
# To ensure that paplay or aplay works, since XDG directory of current user is required
# Better thing for next line is /run/user/$(id -u)
# uid changes per user that's why. Installing as user will generate variables on its own.
# export XDG_RUNTIME_DIR=/run/user/1000
#
# Another method to extract DBUS_SESSION_BUS_ADDRESS
# export "$(egrep -z DBUS_SESSION_BUS_ADDRESS /proc/"$(pgrep -ou "$USER" dbus-daemon)"/environ)"
# Another alternative is DBUS_SESSION_BUS_ADDRESS=unix:path=$(XDG_RUNTIME_DIR)/bus
# export DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/1000/bus
#
# Need display for xdotool to work
# export DISPLAY=:1

# Can be used to extract battery level
# battery_level=`acpi | awk -F "%" '{print $1}' | awk '{print $NF}'`
# battery_level=`acpi | cut -d ' ' -f 4 | sed 's/[^0-9]//g'`
# battery_level=$(acpi | cut -d ' ' -f4 | grep -o '[0-9]*')
# battery_level=$(cat /sys/class/power_supply/BAT0/capacity)

# Check if acpi outputs fully charged when Fully Charged
# battery_state=`acpi | grep -Eo 'Discharging|Charging|Fully Charged'`
# battery_state=$(acpi | awk -F ", " '{print $1}' | awk '{print $NF}')
# battery_state=$(head /sys/class/power_supply/BAT0/status)
# battery_state=$(cat /sys/class/power_supply/BAT0/status)

# if on_ac_power; then
#	battery_state="Charging"
# else
#	battery_state="Discharging"
# fi

# previous_level=$(head -n1 "$bat")
# previous_state=$(tail -n1 "$bat")

# echo "$battery_level" > "$bat"

checkBatteryLevel() {
	if [[ ! -f "$bat" && ! -f "$noti" ]]; then
		touch "$bat" "$noti"
		# echo "$battery_level" > "$bat"
		echo "$battery_state" > "$bat"
		echo 0 > "$noti"
		exit
	fi

	local battery_level
	battery_level=$(< /sys/class/power_supply/BAT0/capacity)

	battery_state=$(< /sys/class/power_supply/BAT0/status)
	previous_state=$(< "$bat")
	echo "$battery_state" > "$bat"

	if [[ $battery_state != "$previous_state" ]]; then
		checkBatteryState
		sleep 2
	fi

	if on_ac_power && [[ $battery_level -gt 92 ]]; then
		notify-send "FULL" "Stop wasting electricity cunt." -u normal -t 4000
		paplay "$warning"
		while on_ac_power; do
			:
		done
	elif on_ac_power || [[ $battery_level -gt 15 ]]; then
		:
	else
		if [[ $battery_level -le 9 ]]; then
			notify-send "Warning" "Your system is going to be suspended if you don't connect in 10 secs." -u critical
			echo 4 > "$noti"
			paplay "$warning"
			sleep 10
			if on_ac_power; then
				xdotool key Ctrl+space
			else
				xdotool key Ctrl+space
				systemctl suspend
			fi
			#
			# Check how to restart the service, only then use the next line
			# Can use StopWhenUnneeded in service file. To halt the service, on suspend if user level
			# If installed as user unit, you could also use the alternate method of sending your own user level sleep.target
			# If installed as system unit, you can use the system suspend.target or sleep.target to resume the file on resume from suspend
			# Once hibernate issue is fixed, can also be used for hibernate
			# Check instructions.txt to see how to restart on the basis of sleep.target
			# That is the following line will only work for a system unit, or if used as user unit, then need to send custom sleep.target so you can use the above instructions
			# Another thing you can do is check out the /lib/systemd/systemd-sleep hack. But again it only works for system unit files and not user unit files
			# systemctl stop --user battery.service
			#
			# Script was unable to suspend due to systemctl auth issue
			# To solve following methods can be used
			#
			# Pass password from stdin using -S
			# battery.sh command
			# echo "Your password" | sudo -S systemctl suspend
			#
			# battery.service
			# ExecStart=/bin/sudo ~/.config/i3/scripts/battery.sh
			# sudo visudo line
			# dakksh ALL=(ALL) NOPASSWD: /home/dakksh/.config/i3/scripts/battery.sh
			# battery.sh command
			# systemctl suspend
			#
			# Another way to achieve this is give my user sudo permission for systemctl suspend using
			# battery.service
			# ExecStart=/bin/bash ~/.config/i3/scripts/battery.sh
			# sudo visudo line
			# dakksh ALL=(ALL) NOPASSWD: /bin/systemctl suspend
			# battery.sh command
			# sudo systemctl suspend
			#
			# The best method till now since it also locks the screen, and no changes to sudo visudo
			# We can also emulate Shift+F6, i3 config key bind for suspend
			# battery.service
			# ExecStart=/bin/bash ~/.config/i3/scripts/battery.sh
			# battery.sh command
			# xdotool key Shift+F6
			#
			# All sudo visudo lines to be written below the %sudo line
			#
		elif [[ $battery_level -le 11 ]] && [[ $(head "$noti") -lt 3 ]]; then
			notify-send "Low Battery" "Your computer will suspend soon unless plugged into a power outlet." -u critical
			echo 3 > "$noti"
			paplay "$warning"
			sleep 4
		elif [[ $battery_level -le 13 ]] && [[ $(head "$noti") -lt 2 ]]; then
			notify-send "Low Battery" "Your computer will suspend soon unless plugged into a power outlet." -u critical
			echo 2 > "$noti"
			paplay "$warning"
			sleep 4
		elif [[ $battery_level -le 15 ]] && [[ $(head "$noti") -lt 1 ]]; then
			notify-send "Low Battery" "${battery_level}% (${battery_time}) of battery remaining." -u normal
			echo 1 > "$noti"
			paplay "$warning"
		fi
	fi
}

checkBatteryState() {
	sleep 4
	battery_time=$(acpi | grep -Eo '[0-9:]{4,}' | sed 's/:\w\w$/ mins/' | sed 's/:/h /')

	if [[ ${previous_state} == Discharging ]] && [[ ${battery_state} == Charging ]]; then
		notify-send "Charging" "${battery_time} till full charge." -u normal
	elif [[ ${previous_state} == Charging ]] && [[ ${battery_state} == Discharging ]]; then
		notify-send "Discharging" "${battery_time} till empty." -u normal
	fi
	# aplay -t wav "$dir/music/warning.wav"
	# paplay "$dir/music/warning.oga"
	paplay "$warning"
	# "$dir/scripts/sound.sh"
	echo 0 > "$noti"
}

# {
#	flock -x 300 || exit 1
#	checkBatteryState
#	checkBatteryLevel
# } 300>"$lockfile"

# checkBatteryState
checkBatteryLevel

exec 300>&-
