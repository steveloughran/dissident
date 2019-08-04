# Example secrets
# Fill in the core details from Twitter
# the myname value is used in the bot itself to stop loopbacks and to recognise conversational openers
config = {
  # name used to detect loops and not reply to self
  myname: "self",
  
  # †witter config options
  consumer_key:   "",
  consumer_secret: "",
  access_token:  "",
  access_token_secret: "",
  
  # probability of responding as a percentage: 100 = always, 0 = never
  reply_probability: 100,

  # Probability (0-100) of replying to a message referring to dissidentbot.
  # Keep < 100 to avoid infinite loops
  self_reply_probability: 90,

  # minimum sleep time, seconds
  # all heckles wait this time + the random time < :sleeptime
  minsleeptime: 0,

  # sleeptime range, in seconds, used to generate a random delay affter the minimum sleep time
  sleeptime: 0,
  
  # Name of the administrator. If unset: anyone @dissidentbot follows can issue commands
  admin: "boris"
}
