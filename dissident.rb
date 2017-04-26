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
        log.info "#{line.length}: #{line}"
        if line.length < 140
          @phrases << line
        else
          log.info "**LINE too long**"
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
    config = eval(File.open('conf/secrets.rb') {|f| f.read })
    @rest = Twitter::REST::Client.new(config)
    @streaming = Twitter::Streaming::Client.new(config)
    @myname = "dissidentbot"
    @started = Time.now.utc
    @start_local_time = @started.getlocal
    @sent_count = 0
    @hostname = shortname()
    @log = Logger.new(STDOUT)
    @log.level = Logger::INFO
  end
  
  def log(message)
    @log.info(message)
  end

  # Generate a reply for the given user, if they are targeted and it is not a reply
  # the latter keeps the noise down, and avoids loops.
  def reply(tweet)
    sender = tweet.user.screen_name.downcase
    text = tweet.text    
    log "incoming tweet: #{tweet.user.screen_name}: #{text} in reply to \"#{tweet.in_reply_to_user_id}\" "
    return unless tweet.in_reply_to_status_id.is_a?(Twitter::NullObject)
    return if sender.eql?@myname
    hecklename = build_target(tweet.user.screen_name, text)
    heckles = Heckles.new()
    heckles.init(hecklename)
    return if heckles.empty? 
    status = "@#{sender} #{heckles.heckle}"
    reply_to(tweet.id, status)
  end
  
  # there's a bug here, if you look hard
  def build_target(username, text)
    username = username.downcase
    username = "self" if not text.index("@#{@myname}").nil?
    return username
  end
    
  def reply_to(status_id, status)
    if status.length > 140
      @log.warn "Reply too long at #{status.length}: #{status}"
    else
      log "tweeting #{status}"
      @sent_count = @sent_count + 1
      @rest.update(status, in_reply_to_status_id: status_id)      
    end
  end
  
  def build_direct_message(command)
    command.downcase.strip!
    s = "#{@hostname}: "
    case command
    when "status"
      s = s + "started #{@start_local_time}; targets #{target_count}; sent: #{@sent_count}"
    when "targets"
      s = s + targets.join(", ")
    else
      s = s + "usage: status | targets"
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
    return "Dissenting from #{target_count} accounts on host #{@hostname} at #{@start_local_time}"
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
    log "dissidentbot booting"
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
d = Dissident.new()
d.main(ARGV)
