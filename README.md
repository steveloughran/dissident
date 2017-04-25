# Dissident

Dissident: ruby based twitter dissident bot

This is something designed to listen to a Twitter account and heckle. If enough people run this and set it
to heckle from their accounts, we can have a nice set of dissenters out there ready to respond fast to any post by the party members.


## Setup

### Software

There's a gemfile set up for ruby dependencies; `bundle install` will
handle that

### Getting up and running

1. Get a Twitter Appliciation API credential set from [Twitter Application Management](https://apps.twitter.com/). You need your own so you can do your own thing, not throttle other people's work, exercise your right to modify the code, etc.
1. Get a 
1. Copy `conf/example-secrets.rb` to `conf/secrets.rb`. That is marked as gitignored, so doesn't get checked in unles you try very hard.
1. Configure `secrets.rb` with your secrets. That file is loaded via `eval()` BTW.
1. Start the bot: `ruby dissident.rb`


### How to heckle

For every user you wish to heckle

1. Follow the target user from the account.
1. Add a file `data/$user.txt`, where `$user` is the username. The example `data/conservatives.txt` does
this for the conservative's twitter account.
1. Add entries in the text file for every user: one per line. Keep the text short enough that the username + message is < 140 chars. You don't need to include the target name in the message.
1. Twitter does throttle clients; there's a limit to how often you can heckle per minute. Focus, or create new accounts.

You do not need to restart the bot to add/remove users, or to change the messages. The `data/` directory is scanned
for a user, and their message file read, *for every tweet*. It's easier to do this than implement some kind
of cache data structure.

## Nice future features

* Linking to images
* keywords for every heckle, something like:

			chaos, boris => Boris is a source of chaos
			boris => Boris should have stuck to bike lanes
			scotland => How you claim to represent the UK when a whole country hates you?


## Acknowledgements

* The initial bot code is derived from an example by `@rrubyist`.
* Everyone used to help debug this code by acting as test subjects is appreciated for their contribution. That includes the `@Conservatives` account.

## References

* [Temboo Twitter Library](https://temboo.com/library/Library/Twitter/)
* https://github.com/sferik/twitter
* [Implementing Twitter Bot using Ruby](https://rudk.ws/2016/11/01/implementing-twitter-bot-using-ruby/)
* + [Sample bot code](https://gist.github.com/rudkovskyi/3ae5baf4850ad70293814897252914b7)


