#!/usr/bin/env bash
# bot.sh
# run as: source bot.sh
echo "lauching dissidentbot"
nohup ruby dissident.rb start < /dev/null > logs/log.txt 2>&1 &
echo "Lauched in the background"
