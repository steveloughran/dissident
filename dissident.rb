#!/usr/bin/env ruby -w
# to run: dissident start

require 'twitter'
require 'socket'
require 'logger'


# here are the heckles for a user
# designed so that they can be isolated/persisted if need be
class Heckles
  def init(username)
    @phrases = Array.new
    log = Logger.new(STDOUT)
    log.level = Logger::DEBUG
    filename = "data/#{username}.txt".downcase
    if not File.file?(filename) 
      log.info "No data file #{filename}"
      return false
    end
    log.info "Reading #{filename}"
    File.open(filename).readlines.each do | line |
      line.strip!
      if not line.empty? and not line.start_with?("\#")
        log.debug "#{line.length}: #{line}"
        if line.length < 140
          @phrases << line
        else
          log.debug "**LINE too long**"
        end
      end     
    end
    log.info "Found #{@phrases.length} entries"
    return true
  end
  
  def heckle
    return @phrases.sample
  end
  
  def empty?
    return @phrases.length == 0
  end
end

# This is the class which does all the work
class Dissident

  # startup: inits the clients. It does not attempt to talk to Twitter though,
  # so invalid credentials are not picked up
  def initialize
    @log = Logger.new(STDOUT)
    @log.level = Logger::DEBUG
    reload
    @rest = Twitter::REST::Client.new(@config)
    @streaming = Twitter::Streaming::Client.new(@config)
    log "my name is \"#{@myname}\""
    @started = Time.now.utc
    @start_local_time = @started.getlocal
    @sent_count = 0
    @dropped_count = 0
    @ignored_count = 0
    @hostname = shortname()
    @shouldExit = false
  end
  
  def reload
    @config = eval(File.open('conf/secrets.rb') {|f| f.read })
    @log.debug "config is #{@config}"
    @myname = @config[:myname]
    if @myname.nil? or @myname.length == 0
      @log.warn "Configuration doesn't include :myname entry"
      @myname = "dissidentbot"
    end
    @reply_probability = int_option(:reply_probability, 75)
    @sleeptime = int_option(:sleeptime, 15)
  end
  
  
  def int_option(opt, defval)
    r = @config[opt]
    return r.nil? ? defval : r
  end
  
  # Log at info
  def log(message)
    @log.info(message)
  end

  # Generate a reply for the given user, if they are targeted and it is not a reply
  # the latter keeps the noise down, and avoids loops.
  def reply(tweet)
    sender = tweet.user.screen_name.downcase
    text = tweet.text    
    log "incoming tweet: #{tweet.user.screen_name}: #{text} in reply to \"#{tweet.in_reply_to_user_id}\" "
    if tweet.in_reply_to_status_id.is_a?(Twitter::NullObject)
      status = build_reply(sender, text)
    else
      status = nil
    end
    
    # probability filter
    status = nil if not should_reply
    
    if not status.nil? 
      hecklename = build_target(tweet.user.screen_name, text)
      heckles = Heckles.new()
      heckles.init(hecklename)
      if heckles.empty? 
        @ignored_count += 1
      else
        sleep_slightly
        reply_to(tweet.id, status)
      end
    else
      @ignored_count += 1
    end
  end

  # Generate a reply for the given user, if they are targeted and it is not a reply
  # the latter keeps the noise down, and avoids loops.
  # (snder: String, text: String) -> String or nul
  def build_reply(sender, text)
    if not sender.eql?@myname
      hecklename = build_target(sender, text)
      heckles = Heckles.new()
      heckles.init(hecklename)
      if not heckles.empty? 
        return "@#{sender} #{heckles.heckle}"
      end
    end
    return nil
  end

  
  # there's a bug here, if you look hard, but it doesn't matter until
  # someone creates the account @dissidentbot2
  def build_target(username, text)
    username = username.downcase
    username = "self" if not text.index("@#{@myname}").nil?
    return username
  end
  
  # should the bot reply at all?  
  def should_reply()
    return rand(100) <= @reply_probability
  end
  
  # add some jitter
  def sleep_slightly()
    sleeptime = 10 + rand(@sleeptime)
    log "sleeping for #{sleeptime}s before posting"
    sleep sleeptime
  end
  
  # reply if the generated message is valid  
  def reply_to(status_id, status)
    if status.length > 140
      @log.warn "Reply too long at #{status.length}: #{status}"
      @dropped_count += 1
    else
      log "tweeting #{status}"
      @sent_count += 1
      @rest.update(status, in_reply_to_status_id: status_id)      
    end
  end
  
  # process the command and send a message back to the caller
  def build_direct_message(command)
    command = command.downcase.strip
    s = "#{@hostname}: "
    case command
    when "status", "?"
      s = s + "started #{@start_local_time}; targets #{target_count};" + 
        " sent: #{@sent_count}; dropped #{@dropped_count}; ignored: #{@ignored_count}"
    when "targets"
      s = s + targets.join(", ")      
    when "exit"
      s = s + "Exiting"
      @shouldExit = true
    when "reload"
      reload
      s = s + "reply_probability=#{@reply_probability}; sleeptime=#{@sleeptime}"
    else
      s = s + "usage: status | targets | reload | exit "
    end
    return s
  end
  
  # incoming direct message
  def on_direct_message(event)
    user = event.sender
    username = user.screen_name.downcase
    return if username.eql?@myname
    log "Direct message from #{user.screen_name}: #{event.text}"
    response = build_direct_message(event.text)
    log "Response: #{response}"
#    sleep_slightly()
    @rest.create_direct_message(user, response)
  end

  # get the shortname of this host for reporting
  def shortname
    return Socket.gethostname.split(".")[0]
  end
  
  # the list of targets
  def targets
    return Dir["data/*.txt"]
  end
  
  # get a count of targets
  def target_count
    return targets().length
  end
    
  # Say anything on twitter
  def say(message)
    log message
    @rest.update(message)
  end
  
  # Build the startup message
  def startup_message
    return "#{@myname} dissenting from #{target_count} accounts on #{@hostname} @ #{@start_local_time}"
  end
      
  # process a tweet or other event. 
  def process(event) 
    case event
    when Twitter::Tweet
      reply(event)
    when Twitter::DirectMessage
      on_direct_message(event)
    when Twitter::Streaming::StallWarning
      @log.warn "Falling behind!"
    else
      log "Other event #{event}"
    end
  end

  # Listen to streaming events and process them
  def listen
    log "starting to listen"
    lives = 10
    say(startup_message())
    begin
      @streaming.user do |event|
         process(event)
         break if @shouldExit
      end
    rescue StandardError => err
      # dubious about this
      @log.warn(err)
      lives = lives - 1
      retry if lives > 0
    ensure
      say("#{@hostname} shutting down")
    end
  end

  # main() entry point
  def main(args)
    log "dissident booting as @#{@myname}"
    usage = "Usage: dissident start"
    if args.length == 0
      log usage
    else
      command = args[0]
      if (command == "start") 
        listen
      else
        log "Unknown action #{command}"
        log usage
      end
    end
  end
  
end

# this is where the work is started
# split so that irb sessions have access to the dissident instances without it starting to listen
bot = Dissident.new()
bot.main(ARGV)
