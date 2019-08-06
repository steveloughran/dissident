# transport.rb
require 'rubygems'
require 'twitter'
require 'socket'
require_relative 'base'

# This is the stub transort.
class Transport < Base
  def initialize
    super
  end

  # Connect to twitter
  def start(config) 
    log "Twitter transport initialized"
  end

  # validate internal state before an operation
  def checkStarted
  end

  # Say anything on twitter
  def say(message)
    checkStarted
    log message
  end

  # send a message in reply to another tweet
  def send(status_id, status)
    checkStarted
    log "To #{status_id}: #{status}"
  end

  # send a direct message
  def direct(user, response)
    checkStarted
    log "DM: to #{user}: #{response}"
  end

  # The event stream to listen to
  def eventstream
    nil
  end

end

# This is where communications with twitter take place
# the start() method creates the rest and streaming bindings
class TwitterTransport < Transport
  def initialize
    super
  end

  # Connect to twitter
  def start(config) 
    super(config)
    @rest = Twitter::REST::Client.new(config.map)
    @streaming = Twitter::Streaming::Client.new(config.map)
  end

  # validate internal state before an operation
  def checkStarted
    super
    raise "twitter client not started" if @rest.nil? 
    raise "twitter streaming client not started" if @streaming.nil? 
  end

  # Say anything on twitter
  def say(message)
    super
    @rest.update(message)
  end

  # send a message in reply to another tweet
  def send(status_id, status)
    super
  end

  # send a direct message
  def direct(user, response)
    super
    @rest.create_direct_message(user, response)
  end

  # The event stream to listen to
  def eventstream
    checkStarted
    @streaming.user 
  end

end

# Fake transport collects messages
class FakeTransport  < Transport
  attr_accessor :said
  attr_accessor :sent
  attr_accessor :directed
  def initialize
    super
    @said =  Array.new()
    @messages =  Array.new()
    @directed =  Array.new()
  end

    # Say anything on twitter
    def say(message)
      super
      said.push(message)
    end
  
    # send a message in reply to another tweet
    def send(status_id, status)
      super
      sent.push(status)
    end
  
    # send a direct message
    def direct(user, message)
      super
      @directed.push(message)
    end
end


# Implementation of the update operation

class Updater < Base
  attr_accessor :updates
  def initialize
    @updates = 0
  end
  def update
    ""
  end

end

class GitUpdater < Updater

  # do a git update; any failure -> Log and continue
  def update
    begin
      %x{git pull}
    rescue StandardError => err
      # dubious about this
      warn(err)
      "failed"
    end
  end
    
  
end



