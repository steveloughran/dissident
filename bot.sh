# bot.sh
# run as: source bot.sh
nohup ruby dissident.rb start < /dev/null > logs/log.txt 2>&1 &