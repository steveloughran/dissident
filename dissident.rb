#!/usr/bin/env ruby -w
# to run: dissident start

require 'twitter'
require 'socket'


# here are the heckles for a user
# designed so that they can be isolated/persisted if need be
class Heckles
  
  def init(username)
    @phrases = Array.new
    username = username.downcase
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

class Dissident

  def initialize
    config = eval(File.open('conf/secrets.rb') {|f| f.read })
    @rest = Twitter::REST::Client.new(config)
    @streaming = Twitter::Streaming::Client.new(config)
    @myname = "dissidentbot"
  end
  

  # Generate a reply for the given user, if they are targeted and it is not a reply
  # the latter keeps the noise down, and avoids loops.
  def reply(tweet)
    puts "incoming tweet: #{tweet.user.screen_name}: #{tweet.full_text} in reply to \"#{tweet.in_reply_to_user_id}\" "
    
    return unless tweet.in_reply_to_status_id.is_a?(Twitter::NullObject)
    username = tweet.user.screen_name
    return if username.eql?@myname
    heckles = Heckles.new()
    heckles.init(username)
    return if heckles.empty?
    status = "@#{username} #{heckles.heckle}"
    if status.length > 140
      puts "Reply too long at #{status.length}: #{status}"
    else
      puts "tweeting #{status}"
      @rest.update(status, in_reply_to_status_id: tweet.id)
    end
  end

  # get the shortname of this host for reporting
  def shortname
    fqdn = Socket.gethostname
    elements = fqdn.split(".")
    return elements[0]
  end
  
  def targets
    return Dir["data/*.txt"]
  end
  
  # get a count of targets
  def target_count
    return targets().length
  end
    
  def say(message)
    @rest.update(message)
  end
  
  def startup_message()
    t = Time.now.utc
    return "Dissenting from #{target_count} accounts on host #{shortname} at #{t.getlocal}"
  end
      
  # process a tweet *or other event*. 
  def process(event) 
    case event
    when Twitter::Tweet
      reply(event)
    when Twitter::DirectMessage
      puts "Direct message from #{event.user.screen_name}: #{event.full_text}"
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
