# Dissident

Dissident: Twitter dissident bot implemented in Ruby

This is something designed to listen to a Twitter account and heckle. If enough people run this and set it
to heckle from their accounts, we can have a nice set of dissenters out there ready to respond fast to any post by the party members.

It has a primitive Direct Message management API, and can have the targets and messages to send dynamically changed while running.

![This is me!](/images/dissidentbot.png)

And it's lightweight enough for this all to work on a Raspberry Pi, which is where it runs.


## Setup

### Software


Install Ruby 2.4 on your system. This takes a while to [build for a Pi](https://gist.github.com/blacktm/8302741), but can be done, at least on the second attempt.

For MacOs, use [rbenv](https://github.com/rbenv/rbenv) to get to a modern ruby version, then `gem install bundle`

There's a gemfile set up for Ruby dependencies; `bundle install` will handle that.


### Getting up and running

1. Get a Twitter Appliciation API credential set from [Twitter Application Management](https://apps.twitter.com/). You need your own so you can do your own thing, not throttle other people's work, exercise your right to modify the code, etc.
1. Ask for Read, Write and Direct Message permissions, then generate the consumer and access tokens and secrets.
1. Copy `conf/example-secrets.rb` to `conf/secrets.rb`. That is marked as gitignored, so doesn't get checked in unles you try very hard.
1. Configure `secrets.rb` with your secrets. That file is loaded via `eval()` BTW.
1. Add your user/bot name to the `:myname` entry in `conf/secrets.rb`
1. Start the bot:

        ruby dissident.rb start


**Running as a daemon**

This doesn't work right, somehow the logs are getting lost and the daemon stops. Help needed!

```bash
mkdir logs
nohup ruby dissident.rb start < /dev/null > logs/log.txt 2>&1 &
```

The plan here is actually to have "`dissident start`" run to `stdout`, but `nohup dissident daemon&` to set the logger to log to a file in `logs`; that way: the logging should at least be collected.


## How to heckle

For every user you wish to heckle

1. Follow the target user from the account.
1. Add a file `data/$user.txt`, where `$user` is the username. The example `data/conservatives.txt` does
this for the conservative's twitter account.
1. Add entries in the text file for every user: one per line. Keep the text short enough that the username + message is < 140 chars. You don't need to include the target name in the message.
1. Twitter does throttle clients; there's a limit to how often you can heckle per minute. Focus, or create new accounts.

You do not need to restart the bot to add/remove users, or to change the messages. The `data/` directory is scanned
for a user, and their message file read, *for every tweet*. It's easier to do this than implement some kind
of cache data structure.

### Configuration

The file `conf/secrets.rb` must contain the configuration data. The 

```ruby
 # Example secrets
 # Fill in the core details from Twitter
 # the myname value is used in the bot itself to stop loopbacks and to recognise conversational openers

config = {
  # name used to detect loops and not reply to self
  myname: "dissidentbot",
  
  # †witter config options
  consumer_key:   "",
  consumer_secret: "",
  access_token:  "",
  access_token_secret: "",
  
  # probability of responding as a percentage: 100 = always, 0 = never
  reply_probability: 75,
  # sleeptime range, in seconds; 10s is always added to this
  sleeptime: 20
}

```

### The Admin Interface

Anyone who can DM the bot can send admin commands. 


To use these: have the bot follow you, then DM it.

`usage`

    usage: status | targets | reload | exit 

`status` or `?`

send a status update, such as

    piball: started 2017-04-27 17:47:15 +0100; targets 7; sent: 0; dropped 0; ignored: 1

`targets`

lists the target files; it could be improved

`reload`

Reloads from `secrets.rb` configuration options. Not the twitter binding data, but everything else.

    dogbert: reply_probability=75; sleeptime=20

`update` or `pull`

triggers a `git pull` to update the state from git. This doesn't update the software, but it will mean that all updated entries in `data/` which you have pushed up to your git repo will then be pulled down. It lets you update your bot's heckles without having to `ssh` in to the box.

`exit`

Have the bot shut down

This means that anyone whom your bot is hecking can shut it down. If that becomes an issue, a new config option could be added to list the admin user. For now though it relies on Boris Johnson being commuter illiterate as well as an utter twat.

Future idea: allow the list of people who can control the bot to be restricted.

### Replying to mentions

The bot will reply to any message with its handle it, picking a message from `data/self.txt`

* Replies are ignored, only simple tweets. This stops loops
* You need to configure the name of the bot in secrets.rb, in the field `:myname`.

If you don't want the bot to reply, delete the `self.txt` file. Or comment out the values with a `#` at the start of each line.


### Debugging

Run `irb --simple-prompt` then read in the file

```ruby
source("./dissident.rb")
```

This instantiates and configures the bot instance, but doesn't start it running. You can refer to it in the variable `bot`

```ruby
bot.say("hello, world")
bot.build_direct_message "status"
bot.build_reply("borisjohnson", "jolly good!")

# Go live
bot.start()
```


I've tried to split up the message parse/response generation logic from the actual IO, to help debug what's going on.

#### Twitter's Spam Detector

Twitter users hate spam; twitter hates spam. And abuse. Don't.

Twitter's spam filters try to detect the behaviour of robots spamming people, and can often confuse "exercising your democratic right to dissent" with "spamming people"

* Including Links in your messages triggers blockage; better to leave out.
* There's hard-coded probability of responding and a sleep time before response, to make your bot less annoying
* Don't heckle lots of people.
* The more actual followers you have, the more Twitter *may* let you post to others.
* The more people you have heckling the same politicians with different messages, the more you can pull back your own heckle rate, so behave more sociably.

Abuse is an issue too: people will complain, you will have a warning, then your account destroyed. Don't do it: it is not constructive. Your goal should be to have the bot respond early to politicians posts, flagging up their hypocricy and lies, rather than just calling them out for being wankers breaking the country for their own selfish career goals, no matter what you feel about Boris.

## Nice future features

No plans to sit down and do these but....

* Posting images (issue: probably triggers spamwall)
* Fixing the logging
* Tests
* Keywords for every heckle, something like:

			chaos, boris => Boris is a source of chaos
			boris => Boris should have stuck to bike lanes
			scotland => How you claim to represent the UK when a whole country hates you?
* Variables in messages: our name, sender, time,

Contributions welcome as pull requests.

## Acknowledgements

* The initial bot code is derived from an example by `@rrubyist`.
* Everyone used to help debug this code by acting as test subjects is appreciated for their contribution. That includes the `@Conservatives` account.
* Sorry to anyone who accidentally got tweeted during the development of this. Especially `@self`.

## References

* [Temboo Twitter Library](https://temboo.com/library/Library/Twitter/)
* https://github.com/sferik/twitter
* [Implementing Twitter Bot using Ruby](https://rudk.ws/2016/11/01/implementing-twitter-bot-using-ruby/)
* [Sample bot code](https://gist.github.com/rudkovskyi/3ae5baf4850ad70293814897252914b7)


