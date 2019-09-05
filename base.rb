# base.rb
require 'logger'

# general base class with some common methods for
# setup and logging

class Base
  def initialize
    @log = Logger.new(STDOUT)
    @log.level = Logger::DEBUG
  end

  # Log at info
  def log(message)
    @log.info(message)
  end

  # Log at info
  def debug(message)
    @log.debug(message)
  end

  # Log at warn
  def warn(message)
    @log.warn(message)
  end

  # Log at error
  def error(message)
    @log.error(message)
  end

end

# Configuration with accessors;
# it can load from a file
class ConfigMap < Base

  attr_reader :config

  def initialize
    super
    @config = Hash.new
  end

  def load(path)
    raise "no file to open" if path.nil?
    
    @config = eval(File.open(path) {|f| f.read })
    # log "config is #{@config}"
  end

  # load an integer option; if the default value is missing or negative, use the default
  def int_option(opt, defval)
    r = @config[opt]
    (r.nil? or r < 0) ? defval : r
  end

  # String opt will leave "" as a valid number
  def string_option(opt, defval)
    r = @config[opt]
    r.nil? ? defval : r
  end

  # lookup
  def get(val)
    @config[val]
  end

  def map
    @config
  end

end
