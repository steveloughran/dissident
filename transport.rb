# transport.rb
require 'rubygems'
require 'twitter'
require 'socket'
require_relative 'base'

# This is where communications with twitter take place
# the start() method creates the rest and streaming bindings
class Transport < Base

  # Connect to twitter
  def start(config) 
    @rest = Twitter::REST::Client.new(config.map)
    @streaming = Twitter::Streaming::Client.new(config.map)
    log "Twitter transport initialized"
  end

  # validate internal state before an operation
  def checkStarted
    raise "twitter client not started" if @rest.nil? 
    raise "twitter streaming client not started" if @streaming.nil? 
  end

  # Say anything on twitter
  def say(message)
    checkStarted
    log message
    @rest.update(message)
  end

  # send a message in reply to another tweet
  def send(status, id)
    checkStarted
    log message
    @rest.update(status, in_reply_to_status_id: status_id)   
  end

  # send a direct message
  def direct(user, response)
    checkStarted
    log "Response: #{response}"
    @rest.create_direct_message(user, response)
  end

  # The event stream to listen to
  def eventstream
    checkStarted
    @streaming.user 
  end

end
