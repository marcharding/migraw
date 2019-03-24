#!/usr/bin/env bash

COLOR_CYAN='\e[0;36m'
COLOR_NC='\e[0m'

MIGRAW="/opt/migraw"
mkdir -p $MIGRAW
curl -s -H 'Cache-Control: no-cache' "https://raw.githubusercontent.com/marcharding/migraw/master/install.sh?$(date +%s)" --output "$MIGRAW/migraw"
ln -rsf $MIGRAW/migraw.sh $MIGRAW/migraw

echo -e "\n${COLOR_CYAN}Downloaded migraw.${COLOR_NC}"
echo -e "\nTo complete the instalation just add the following path to your \$PATH:"
echo -e "\n$MIGRAW"
echo -e "\nFor Example:"
echo -e "\nPATH=$MIGRAW:\$PATH"
echo -e "export PATH=$MIGRAW:\$PATH\n"
