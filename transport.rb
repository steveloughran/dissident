# transport.rb
# This is where communications with twitter take place
require 'rubygems'
require 'twitter'
require 'socket'
require 'logger'
require_relative 'base'

require_relative 'heckles'
class Transport

  def initialize config
    @log = Logger.new(STDOUT)
    @log.level = Logger::DEBUG
    @rest = Twitter::REST::Client.new(config)
    @streaming = Twitter::Streaming::Client.new(@config.map)
    
  end
  # Say anything on twitter
  def say(message)
    log message
    @rest.update(message)
  end
  
  def send(status, id)
    @rest.update(status, in_reply_to_status_id: status_id)   
  end

  def direct(user, response)
    log "Response: #{response}"
    @rest.create_direct_message(user, response)
  end

  def eventstream
    @streaming.user 
  end

end
