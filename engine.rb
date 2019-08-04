#!/usr/bin/env ruby -w
# to run: dissident start

require 'twitter'
require 'socket'
require_relative 'base'
require_relative 'heckles'
require_relative 'transport'


# This is the class which does all the work
class Engine < Base 
  
  attr_accessor :admin
  attr_reader   :config
  attr_reader   :hostname
  attr_reader   :initialized
  attr_reader   :myname
  attr_reader   :online
  attr_accessor :reply_probability
  attr_accessor :self_reply_probability
  attr_reader   :started
  attr_reader   :start_local_time
  attr_reader   :transport
  attr_reader   :updater

  # all the metrics
  attr_reader   :reload_count 
  attr_reader   :sent_count
  attr_reader   :update_count

  # startup: inits the clients. It does not attempt to talk to Twitter though,
  # so invalid credentials are not picked up
  def initialize
    super
    @initialized = false
    @dropped_count = 0
    @ignored_count = 0
    @reload_count = 0
    @sent_count = 0
    @update_count = 0
  end

  # Start the engine.
  # secrets_file: path to the secrets.
  # target_dir: directories of targets
  # transport: Twitter transport.
  def start(secrets_file, target_dir, transport)
    raise 'already initialized' if @initialized
    @initialized = true
    @secrets_file = secrets_file
    @target_dir = target_dir
    @transport = transport
    # this loads the config map
    reload

    @transport.start(@config) 
    @started = Time.now.utc
    @start_local_time = @started.getlocal
    @hostname = shortname()
    @online = true
    log "Hello, my name is \"#{@myname}\" -prepare to dissent"
  end
  
  def reload
    @config = ConfigMap.new
    @config.load(@secrets_file)
    @myname = @config.get(:myname)
    if @myname.nil? or @myname.length == 0
      warn "Configuration doesn't include :myname entry"
      @myname = "dissidentbot"
    end
    @myname = @myname.downcase
    @reply_probability = @config.int_option(:reply_probability, 75)
    @self_reply_probability = @config.int_option(:self_reply_probability, @reply_probability)
    @sleeptime = @config.int_option(:sleeptime, 15)
    @minsleeptime = @config.int_option(:minsleeptime, 30)
    @admin = @config.string_option(:admin, "")

    # check the target dir, even though we aren't going to load it
    raise "Not a directory: \"#{@target_dir}\"" if not File.directory?(@target_dir)
  end
  
  # given a tweet, identify its sender
  # returns the sender screen name in lower case.
  def tweet_sender(tweet)
     tweet.user.screen_name.downcase
  end

  # is this message a response
  def is_response(text) 
    text.include? "RT "
  end

  # Generate a reply for the given user, if they are targeted and it is not a reply
  # the latter keeps the noise down, and avoids loops.
  def reply(tweet)
    sender = tweet_sender(tweet)
    text = tweet.text    
    log "incoming tweet: #{sender}: \"#{text}\" in reply to \"#{tweet.in_reply_to_user_id}\" "
    
    if not @online
      # we are offline; ignore the message
      log "dissidentbot is offline: ignoring"
      @ignored_count += 1
      return
    end
    
    # build a reply if this is not a reply of someone else's
    response = nil
    reply_id = tweet.in_reply_to_status_id
    if reply_id.is_a?(Twitter::NullObject)
      if is_response(text)
        log "Message is Retweet; ignoring"
      else
        response = build_reply(sender, text)
      end
    else
      log "tweet is in reply to #{reply_id}; ignoring"
    end
    
    isNotification = is_notification_message(text)
    if not response.nil? 
      if should_reply(isNotification)
        # something to say and its not being dropped.
        # sleep if its a heckle (and not a reply)
        log "about to reply after a possible sleep"
        sleep_slightly if not isNotification
        # then issue the reply
        reply_to(tweet, response)
      else
        # ignoring
        log "Prepared message #{response} but chose not to reply"
        @ignored_count += 1
      end
    else
      log "No response generated; ignoring"
      # ignoring
      @ignored_count += 1
    end
  end

  
  # Generate a reply for the given user, if they are targeted and it is not a reply
  # the latter keeps the noise down, and avoids loops.
  # (sender: String, text: String) -> String or nul
  def build_reply(sender, text)
    if not sender.eql? @myname
      hecklename = build_target(sender, text)
      heckles = Heckles.new()
      heckles.initForUser(@target_dir, hecklename)
      if not heckles.empty? 
        return "@#{sender} #{heckles.heckle}"
      end
    else
      log "sender is me; ignoring"
    end
    nil
  end

  # is this a notification message?
  def is_notification_message(text)
    not text.index("@#{@myname}").nil?
  end
  
  # there's a bug here, if you look hard, but it doesn't matter until
  # someone creates the account @dissidentbot2
  def build_target(username, text)
    is_notification_message(text) ? "self" : username.downcase
  end
  
  # should the bot reply at all?
  def should_reply(isNotification)
    rand(100) <= (isNotification ? @self_reply_probability : @reply_probability)
  end
  
  # add some jitter
  def sleep_slightly()
    sleeptime = @minsleeptime + rand(@sleeptime)
    log "sleeping for #{sleeptime}s"
    sleep sleeptime
  end
  
  # reply if the generated message is valid  
  def reply_to(tweet, status)
    status_id = tweet.id
    sender = tweet_sender(tweet)
    if not sender.eql? @myname
      if status.length > 140
        warn "Reply too long at #{status.length}: #{status}"
        @dropped_count += 1
      else
        log "tweeting #{status} to #{status_id}"
        @sent_count += 1
        @transport.send(status_id, status)      
      end
    else
      log "Dropping loopback message"
      @dropped_count += 1
    end
  end
  
  def status_report()
    "started #{@start_local_time}; online=#{@online} targets #{target_count};" + 
        " sent: #{@sent_count}; dropped #{@dropped_count}; ignored: #{@ignored_count}" +
        " P(reply)=#{@reply_probability}; P(self_reply)=#{@self_reply_probability}"
  end
  
  # process the command and send a message back to the caller
  def process_direct_message(command)
    command = command.downcase.strip
    log "DM command #{command}"
    s = "#{@hostname}: "
    case command
    when "status", "?"
      st = status_report
      log st
      s = s + st
    when "targets"
      s = s + targets.join(", ")      
    when "exit"
      log "Exiting"
      s = s + "Exiting"
      @shouldExit = true
    when "reload"
      reload
      s = s + status_report
    when "update", "pull"
      s +=  update
    when "online"
      log "Going online"
      @online = true
      s = s + status_report
    when "offline"
      log "Going offline"
      @online = false
      s = s + status_report
    else
      s = s + "usage: status | ? | targets | reload | update | pull | online | offline | exit "
    end
    s
  end
  
  # incoming direct message
  def on_direct_message(event)
    user = event.sender
    username = user.screen_name.downcase
    return if username.eql? @myname
    log "Direct message from #{user.screen_name}: #{event.text}"
    if @admin.eql? "" or @admin.eql? username
      response = process_direct_message(event.text)
    else
      log "Ignoring message from #{username} as not #{@admin}"
      response = "Not admin user: rejected"
    end
    # issue the message
    @transport.direct(user, response)
  end

  # get the shortname of this host for reporting
  def shortname
    Socket.gethostname.split(".")[0]
  end
  
  # the list of targets
  def targets
    Dir[@target_dir]
  end
  
  # get a count of targets
  def target_count
    targets().length
  end
  
  # do a git update; any failure -> Log and continue
  def update
    @updater.update
  end
    
  def is_initialized
    @initialized
  end

  # The event stream to listen to
  def eventstream
    @transport.eventstream
  end

  # process a tweet or other event. 
  def process(event) 
    case event
    when Twitter::Tweet
      reply(event)
    when Twitter::DirectMessage
      on_direct_message(event)
    when Twitter::Streaming::StallWarning
      warn "Falling behind!"
    else
      log "Other event #{event}"
    end
  end
    
  # Say anything on twitter
  def say(message)
    log message
    @transport.say(message)
  end
  
  # Build the startup message
  def startup_message
    "#{@myname} dissenting from #{target_count} accounts on #{@hostname} @ #{@start_local_time}; admin=#{@admin}"
  end

  
end

