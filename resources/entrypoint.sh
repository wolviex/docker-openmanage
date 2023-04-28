#!/bin/bash

# Print system information, serial number, etc
dmidecode -t1

# Run any passed commands
if [ "$#" -gt 0 ]; then
    # Use eval instead of exec so this script remains PID 1
    eval "$@"
fi
