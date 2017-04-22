#!/usr/bin/env ruby -w
# Dissident


# Credits: https://github.com/sferik/twitter
# https://rudk.ws/2016/11/01/implementing-twitter-bot-using-ruby/ and https://gist.github.com/rudkovskyi/3ae5baf4850ad70293814897252914b7



require 'twitter'


class Heckles
  # here are the heckles for a user
  
  def init(file)
    @last = -1
    raw = IO.read(file)
    raw.delete_if {|l| l.empty? or l.startswith("\#") }
  
end

class Dissident

  def initialize
    config = eval(File.open('conf/secrets.rb') {|f| f.read })
    @client = Twitter::REST::Client.new(config)
    @streaming = Twitter::Streaming::Client.new(config)
    @myname = "dissidentbot"
    
    # @phrases = [
    #       'The president lost the popular vote by three million votes',
    #       'Today, the amount of carbon dioxide in the atmosphere is higher than at any time in the last 650,000 years',
    #       'Burning one gallon of gasoline puts nearly 20lbs of carbon dioxide into our atmosphere. #climate',
    #       'Flipside of the atmosphere; ocean acidity has increased 30% since the industrial revolution. #climate',
    #       'The pre-industrial concentration of carbon dioxide in the atmosphere was 280 ppm. As of December 2016, 404.93 ppm'
    #     ]

  @phrases = [
    #    1        10        20        30        40        50         60        70         80         90         100       110       120
        'No party with Boris Johnson in cabinet can accuse other parties of chaos. #dissent',
        'Crush the Saboteurs! Especially remain voters in your own party! #dissent',
        'Your hard Brexit plans mean you can\'t use the "chaos and economic disaster" threats this year. Please Upgrade. #dissent',
        'What is it about Jeremy Corbyn that makes #AskTheresaMay scared to debate him? #dissent',
        'The leave campaign didn\'t just lie, they broke the law? http://www.bbc.co.uk/news/uk-politics-39672956 #dissent',
        'Why no manifesto promise of £350M/week for the NHS? #dissent',
#        '',
      ]


  end
  

  def reply(tweet, message)
    return unless tweet.in_reply_to_status_id.is_a?(Twitter::NullObject)
    return if tweet.user.screen_name.eql?@myname
    return if tweet.user.screen_name.eql?@myname and 
    status = "@#{tweet.user.screen_name} #{message}"
    puts "tweeting #{status}"
    @client.update(status, in_reply_to_status_id: tweet.id)
  end


# client.update("Dissent is a right; dissent is a duty")

  def listen
    puts "ready"

    @streaming.user do |object|
      case object
      when Twitter::Tweet
        tweet = object
        puts "tweet: #{tweet.user.screen_name}: #{tweet.text} in reply to \"#{tweet.in_reply_to_user_id}\" "
        reply(tweet, @phrases.sample)
      when Twitter::DirectMessage
        puts "It's a direct message!"
      when Twitter::Streaming::StallWarning
        warn "Falling behind!"
      end
    end
  end

end


Dissident.new().listen