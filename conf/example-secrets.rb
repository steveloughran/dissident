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
