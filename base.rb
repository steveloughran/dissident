# base.rb

# general base class with some common methods for
# setup and logging

class Base
  def initialize
    @log = Logger.new(STDOUT)
    @log.level = Logger::DEBUG
  end
end

# Configuration with accessors;
# it can load from a file
class ConfigMap < Base

  def initialize
    super
    @config = Hash.new
  end

  def load(path)
    @config = eval(File.open(path) {|f| f.read })
    @log.debug "config is #{@config}"

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

  # get the actual map to pass along
  def map
    @config
  end

end
