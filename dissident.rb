#!/usr/bin/env ruby -w
# to run: dissident start

require 'twitter'
require 'socket'


# here are the heckles for a user
# designed so that they can be isolated/persisted if need be
class Heckles
  
  def init(username)
    @phrases = Array.new
    filename = "data/#{username}.txt".downcase
    if not File.file?(filename) 
      puts "No data file #{filename}"
      return false
    end
    
    puts "Reading #{filename}"
    File.open(filename).readlines.each do | line |
      line.strip!
      if not line.empty? and not line.start_with?("\#")
        puts "#{line.length}: #{line}"
        if line.length < 140
          @phrases << line
        else
          puts "**LINE too long**"
        end
      end     
    end
    puts "Found #{@phrases.length} entries"
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
    @sent_count = 0
    @hostname = shortname()
  end

  # Generate a reply for the given user, if they are targeted and it is not a reply
  # the latter keeps the noise down, and avoids loops.
  def reply(tweet)
    puts "incoming tweet: #{tweet.user.screen_name}: #{tweet.text} in reply to \"#{tweet.in_reply_to_user_id}\" "
    
    return unless tweet.in_reply_to_status_id.is_a?(Twitter::NullObject)
    username = tweet.user.screen_name.downcase
    return if username.eql?@myname
    heckles = Heckles.new()
    heckles.init(username)
    return if heckles.empty?
    status = "@#{username} #{heckles.heckle}"
    if status.length > 140
      puts "Reply too long at #{status.length}: #{status}"
    else
      puts "tweeting #{status}"
      @started = @started + 1
      @rest.update(status, in_reply_to_status_id: tweet.id)      
    end
  end
  
  def build_direct_message(command)
    command.downcase.strip!
    s = "#{@hostname}: "
    case command
    when "status"
      s = s + "started #{@started}; targets #{target_count}; sent: #{@sent_count}"
    when "targets"
      s = s + targets.join(", ")
    else
      s = s + "usage: status | targets"
    end
    return s
  end
  
  # incoming is 
  def on_direct_message(event)
    user = event.sender
    username = user.screen_name.downcase
    return if username.eql?@myname
    puts "Direct message from #{user.screen_name}: #{event.text}"
    response = build_direct_message(event.text)
    @rest.create_direct_message(user, response)
  end
  

  # get the shortname of this host for reporting
  def shortname
    fqdn = Socket.gethostname
    elements = fqdn.split(".")
    return elements[0]
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
    @rest.update(message)
  end
  
  # Build the startup message
  def startup_message()
    t = Time.now.utc
    return "Dissenting from #{target_count} accounts on host #{@hostname} at #{t.getlocal}"
  end
      
  # process a tweet *or other event*. 
  def process(event) 
    case event
    when Twitter::Tweet
      reply(event)
    when Twitter::DirectMessage
      on_direct_message(event)
    when Twitter::Streaming::StallWarning
      warn "Falling behind!"
    end
  end

  # Listen to streaming events and process them
  def listen
    message = startup_message
    puts message
    say(message)
    
    @streaming.user do |event|
       process(event)
    end
  end

  # main() entry point
  def main(args)
    usage = "Usage: dissident start"
    if args.length == 0
      puts usage
    else
      command = args[0]
      if (command == "start") 
        listen
      else
        puts "Unknown action #{command}"
        puts usage
      end
    end
  end
  
end

# this is where the work is started
# split so that irb sessions have access to the dissident
d = Dissident.new()
d.main(ARGV)
