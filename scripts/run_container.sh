#!/bin/bash
docker run -d --rm -v octoprint --device /dev/ttyUSB0:/dev/ttyUSB0 -e ENABLE_MJPG_STREAMER=false -p 80:80 --name octoprint octoprint-klipper
