#!/usr/bin/bash

data=$(curl 'https://publicapi.txdpsscheduler.com/api/AvailableLocation'  -H 'Origin: https://public.txdpsscheduler.com'  -H 'accept: application/json, */*' --data-raw '{"TypeId":21,"ZipCode":"78729","CityName":"","PreferredDay":0}')

currentMonth=$(date +%m)

dps=$(echo "$data" | jq --raw-output --arg month "$currentMonth" 'min_by(.NextAvailableDate) | select(.NextAvailableDate | startswith($month)) | "\(.NextAvailableDate), \(.Distance)m, \(.Address), \(.MapUrl)"')

if [ -n "$dps" ]; then
	echo "$currentMonth, $dps"
    echo -e "Subject: DPS Appointment Available\n\n$currentMonth, $dps" | ssmtp YOUR_EMAIL@gmail.com
fi
