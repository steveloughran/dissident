#!/usr/bin/env ruby -w
# to run: dissident start

require_relative 'base'
require_relative 'heckles'
require_relative 'engine'
require_relative 'transport'

# Entry point and REPL loop.
class Dissident < Base 
  
  attr_accessor :online
  attr_reader   :started
  attr_reader   :hostname
  attr_reader   :config
  attr_accessor :admin
  attr_accessor :reply_probability
  attr_accessor :self_reply_probability
  
  # startup: inits the clients. It does not attempt to talk to Twitter though,
  # so invalid credentials are not picked up
  def initialize
    super
    @engine = Engine.new()
    reload
  end

  # Start the engine.
  # secrets_file: path to the secrets.
  # target_dir: directories of targets
  def start(secrets_file, target_dir, transport)
    @engine.start(secrets_file, target_dir, TwitterTransport.new())
  end

  # engine to reload everything  
  def reload
    @engine.reload
  end
  

  # Listen to streaming events and process them
  def listen
    if engine.initialized.nil?
      error("Not initialized")
      return
    end
    log "starting to listen"
    log status_report
    lives = 10
    say(@engine.startup_message())
    begin
      @engine.eventstream do |event|
        @engine.process(event)
         break if @engine.shouldExit
      end
    rescue StandardError => err
      # something went wrong
      warn(err)
      # sleep before a retry to handle throttling/transient
      lives = lives - 1
      if lives > 0
        log "Remaining lives #{lives}"
        sleep_slightly
        retry 
      else
        error "Too many failures, shutting down"
      end
    ensure
      say("#{@hostname} shutting down")
    end
  end

  # main() entry point
  def main(args)
    start('conf/secrets.rb', "data/*.txt")
    if @initialized.nil?
      error "Not initialized"
      return
    end
    log "dissident booting as '#{@myname}'"
    usage = "Usage: dissident start"
    if args.length == 0
      log usage
    else
      command = args[0]
      if (command == "start") 
        listen
      else
        warn "Unknown action #{command}"
        log usage
      end
    end
  end
  
  def start()
    main(["start"])
  end
  
end

# this is where the work is started
# split so that irb sessions have access to the dissident instances without it starting to listen
#bot = Dissident.new()
#bot.main(ARGV)
