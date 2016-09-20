#!/bin/sh
set -e


Update_Plugins=0 \
Update_Customizations=0 \
Update_Packages=0 \
Update_Credentials=0 \
Update_Clouds=0 \
Update_Nodes=0 \
Update_Projects=1 \
Update_Views=0 \
Build_Triggers=1 \
  ./update.sh "$@"

