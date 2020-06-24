#!/bin/bash
#
# Copyright (C) 2020 SebaUbuntu's HomeBot
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

parse_ota() {
	local SHRP_GENERIC_JSON="$(curl https://raw.githubusercontent.com/SHRP-Devices/device_data/master/deviceData.json | jq ".[]")"
	if echo "$1" | grep -q "-"; then
		echo "$SHRP_GENERIC_JSON" | jq "select(.codeName == [\"$1\"])"
	else
		echo "$SHRP_GENERIC_JSON" | jq "select(.codeName == \"$1\")"
	fi
}

module_device() {
	# Trim codename
	local DEVICE_CODENAME="$(tg_get_command_arguments "$@" | sed 's/[^0-9a-zA-Z_-]*//g')"
	if [ "$DEVICE_CODENAME" != "" ]; then
		local SHRP_DEVICE_JSON=$(parse_ota "$DEVICE_CODENAME")
		if [ "$SHRP_DEVICE_JSON" = "" ]; then
			# Try lowercase codename
			local DEVICE_CODENAME=$(echo $DEVICE_CODENAME | tr '[:upper:]' '[:lower:]')
			local SHRP_DEVICE_JSON=$(parse_ota "$DEVICE_CODENAME")
		fi
		if [ "$SHRP_DEVICE_JSON" = "" ]; then
			# Try uppercase codename
			local DEVICE_CODENAME=$(echo $DEVICE_CODENAME | tr '[:lower:]' '[:upper:]')
			local SHRP_DEVICE_JSON=$(parse_ota "$DEVICE_CODENAME")
		fi
		if [ "$SHRP_DEVICE_JSON" != "" ]; then
			local SHRP_DEVICE_INFO="*SkyHawk Recovery Project for $DEVICE_CODENAME*

Name: $(echo "$SHRP_DEVICE_JSON" | jq ".model" | cut -d "\"" -f 2)
Brand: $(echo "$SHRP_DEVICE_JSON" | jq ".brand" | cut -d "\"" -f 2)
Maintainer: $(echo "$SHRP_DEVICE_JSON" | jq ".maintainer" | cut -d "\"" -f 2)
Download page: [Here]($(echo "$SHRP_DEVICE_JSON" | jq ".baseURL" | cut -d "\"" -f 2 | sed -r 's/&+/%26/g'))
Latest version: $(echo "$SHRP_DEVICE_JSON" | jq ".currentVersion" | cut -d "\"" -f 2)
Download: [Here]($(echo "$SHRP_DEVICE_JSON" | jq ".latestBuild" | cut -d "\"" -f 2 | sed -r 's/&+/%26/g'))"
			tg_send_message "$(tg_get_chat_id "$@")" "$SHRP_DEVICE_INFO" "$(tg_get_message_id "$@")"
		else
			tg_send_message "$(tg_get_chat_id "$@")" "Device codename is not present in SHRP official devices list!
Please make sure you wrote it correctly" "$(tg_get_message_id "$@")"
		fi
	else
		tg_send_message "$(tg_get_chat_id "$@")" "Please write a device codename!" "$(tg_get_message_id "$@")"
	fi
}

module_devices() {
	local SHRP_DEVICES_JSON="$(curl https://raw.githubusercontent.com/SHRP-Devices/device_data/master/deviceData.json | jq ".[]")"
	local SHRP_DEVICES_MESSAGE="List of SHRP official supported devices:
"
	for device in $(echo "$SHRP_DEVICES_JSON" | jq .codeName | cut -d "\"" -f 2); do
		local SHRP_DEVICES_MESSAGE="$SHRP_DEVICES_MESSAGE
$(echo $SHRP_DEVICES_JSON | jq "select(.codeName == \"$device\") | .model" | cut -d "\"" -f 2) (\`$device\`)"
	done
	local SHRP_DEVICES_MESSAGE="$SHRP_DEVICES_MESSAGE
	
To get the last release for a device type /device <codename>"
	tg_send_message "$(tg_get_chat_id "$@")" "$SHRP_DEVICES_MESSAGE" "$(tg_get_message_id "$@")"
}