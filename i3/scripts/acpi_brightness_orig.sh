#!/bin/bash -

#Get working directory, and change to brightness directory

P=$PWD
cd /sys/class/backlight
DEST_DIR=$PWD/*/brightness

# Next command to be used when script can be run as sudo without passwd
# sudo chown dakksh $DEST_DIR

# Get current brightness

CURR_BRIGHTNESS=$(<$DEST_DIR)

case $1 in
	-inc)
		# Calculate x% where x is a multiple of 10
		# Example
		# 204 = 80%
		# After calculation we get 90% brightness
		CURR_BRIGHTNESS=$((++CURR_BRIGHTNESS * 2 / 51))
		CURR_BRIGHTNESS=$((++CURR_BRIGHTNESS * 51 / 2))
		if [ $CURR_BRIGHTNESS -gt 255 ]; then
			CURR_BRIGHTNESS=255
		fi
		;;
	-dec)
		# Calculate x% where x is a multiple of 10
		# Example
		# 204 = 80%
		# After calculation we get 70% brightness
		CURR_BRIGHTNESS=$((--CURR_BRIGHTNESS * 2 / 51))
		CURR_BRIGHTNESS=$((CURR_BRIGHTNESS * 51 / 2))
		;;
	-change)
		case $3 in
			1)
				# Change brightness to any given value
				CURR_BRIGHTNESS=$2
				if [ $CURR_BRIGHTNESS -gt 255 ]; then
					CURR_BRIGHTNESS=255
				elif [ $CURR_BRIGHTNESS -lt 0 ]; then
					CURR_BRIGHTNESS=0
				fi
				;;
			0)
				# Change brightness to any given x%
				CURR_BRIGHTNESS=$(($2 * 51 / 20))
				if [ $CURR_BRIGHTNESS -gt 255 ]; then
					CURR_BRIGHTNESS=255
				elif [ $CURR_BRIGHTNESS -lt 0 ]; then
					CURR_BRIGHTNESS=0
				fi
				;;
		esac
		;;
	-offset)
		# Change to any value of brightness % + an offset
		# Example
		# input gives $2 = 1, $3 = 5
		# 1% = 2
		# Hence brightness is set as 7
		# User can set brightness with value 4 using this
		CURR_BRIGHTNESS=$(($2 * 51 / 20 + ${3:-0}))
		if [ $CURR_BRIGHTNESS -gt 255 ]; then
			CURR_BRIGHTNESS=255
		elif [ $CURR_BRIGHTNESS -lt 0 ]; then
			CURR_BRIGHTNESS=0
		fi
		;;
esac

# Changing brightness

echo $CURR_BRIGHTNESS > $DEST_DIR

# This command to be used when we can run sudo without passwd
# sudo chown root $DEST_DIR

# Since brightness is to be used by i3status only

echo "💡 `echo $(brightnessctl) | awk -F '[()]' '{print $2}'`" > ~/.config/i3/infoFiles/brightness && killall -SIGUSR1 i3status

# Changing to original directory

cd $P
