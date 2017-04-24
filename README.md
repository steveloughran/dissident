# Dissident

Dissident: ruby based twitter dissident bot

This is something designed to listen to a Twitter account and heckle. If enough people run this and set it
to heckle from their accounts, we can have a nice set of dissenters out there ready to respond fast to any post by the
party members.





## Setup

### Software

There's a gemfile set up for ruby dependencies; `bundle install` will
handle that

### Getting up and running

1. Get a Twitter API credential set.
1. copy `conf/example-secrets.rb` to `conf/secrets.rb`. That is marked as gitignored.
1. Start the bot: `ruby dissident.rb`


### How to heckle

For every user you wish to heckle

1. Follow the target user from the account.
1. Add a file `data/$user.txt`, where `$user` is the username. The example `data/conservatives.txt` does
this for the conservative's twitter account.
1. Add entries in the text file for every user: one per line. Keep the text short enough that the username + message is < 140 chars. You don't need to include the target name in the message.
1. Twitter does throttle clients; there's a limit to how often you can heckle per minute. Focus, or create new accounts.

You do not need to restart the bot to add/remove users, or to change the messages. The directory is scanned
for a user, and their message file read, *for every tweet*. It's easier to do this than implement some kind
of cache data structure.


## References

* [Temboo Twitter Library](https://temboo.com/library/Library/Twitter/)
* https://github.com/sferik/twitter
* https://rudk.ws/2016/11/01/implementing-twitter-bot-using-ruby/ 
* https://gist.github.com/rudkovskyi/3ae5baf4850ad70293814897252914b7

