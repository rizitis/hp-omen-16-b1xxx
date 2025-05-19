#!/bin/bash
pactl set-default-sink alsa_output.usb-AlfaPlus_Semiconductor_MPOW_Wireless_Gaming_Headset-03.iec958-stereo
sleep 3          # wait 3 seconds for PipeWire to settle
killall kmix     # stop any running kmix instance
kstart5 kmix &   # start kmix in background
