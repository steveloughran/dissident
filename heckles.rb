require 'logger'

# here are the heckles for a user
# designed so that they can be isolated/persisted if need be
class Heckles

  # Initialise: pass in username
  # return true iff there is data
  def init(username)
    @phrases = Array.new
    @disabled = false
    log = Logger.new(STDOUT)
    log.level = Logger::DEBUG
    filename = "data/#{username}.txt".downcase
    if not File.file?(filename) 
      log.info "No data file #{filename}"
      return false
    end
    log.info "Reading #{filename}"
    File.open(filename).readlines.each do | line |
      line.strip!
      if line.start_with?("\#DISABLED")
        log.info "This account is disabled"
        return false
      end
      if not line.empty? and not line.start_with?("\#")
        log.debug "#{line.length}: #{line}"
        if line.length < 140
          @phrases << line
        else
          log.debug "**LINE too long**"
        end
      end     
    end
    log.info "Found #{@phrases.length} entries"
    true
  end
  
  def heckle
    @phrases.sample
  end
  
  def empty?
    @phrases.length == 0
  end
end
