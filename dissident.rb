#!/usr/bin/env ruby -w
# Dissident


# Credits: https://github.com/sferik/twitter
# https://rudk.ws/2016/11/01/implementing-twitter-bot-using-ruby/ and https://gist.github.com/rudkovskyi/3ae5baf4850ad70293814897252914b7



require 'twitter'

class Heckles
  
  # here are the heckles for a user
  
  def init(username)
    @phrases = Array.new 
    filename = "data/#{username}.txt"
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
          puts "LINE too long"
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
  

  def reply(tweet)
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

# client.update("Dissent is a right; dissent is a duty")

  def listen
    puts "ready"

    @streaming.user do |object|
      case object
      when Twitter::Tweet
        tweet = object
        puts "tweet: #{tweet.user.screen_name}: #{tweet.text} in reply to \"#{tweet.in_reply_to_user_id}\" "
        reply(tweet)
      when Twitter::DirectMessage
        puts "It's a direct message!"
      when Twitter::Streaming::StallWarning
        warn "Falling behind!"
      end
    end
  end
  

end


Dissident.new().listen