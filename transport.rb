# transport.rb
# This is where communications with twitter take place
require 'rubygems'
require 'twitter'
require 'socket'
require_relative 'base'
require_relative 'heckles'

class Transport < Base

  def initialize
    super
  end

  def start(config) 
    @rest = Twitter::REST::Client.new(config)
    @streaming = Twitter::Streaming::Client.new(@config.map)
  end

  # Say anything on twitter
  def say(message)
    log message
    @rest.update(message)
  end

  # send a message in reply to another tweet
  def send(status, id)
    @rest.update(status, in_reply_to_status_id: status_id)   
  end

  # send a direct message
  def direct(user, response)
    log "Response: #{response}"
    @rest.create_direct_message(user, response)
  end

  # The event stream to listen to
  def eventstream
    @streaming.user 
  end

end
