#!/bin/sh
set -e

# Selective update.sh run
Update_Plugins=0 \
Update_Customizations=0 \
Update_Packages=0 \
Update_Credentials=0 \
Update_Clouds=1 \
Update_Nodes=0 \
Update_Projects=0 \
Update_Views=0 \
Build_Triggers=0 \
  ./update.sh "$@"

