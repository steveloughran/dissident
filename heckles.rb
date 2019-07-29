require_relative 'base'

# here are the heckles for a user
# designed so that they can be isolated/persisted if need be
class Heckles < Base

  # Initialise: pass in username
  # return true iff there is data
  def initForUser(username)
    filename = "data/#{username}.txt".downcase
    initFromFile(filename)
  end

  # Initialise: pass in username
  # return true iff there is data
  def initFromFile(filename)
    @phrases = Array.new
    @disabled = false
    if not File.file?(filename) 
      log "No data file #{filename}"
      return false
    end
    log "Reading #{filename}"
    File.open(filename).readlines.each do | line |
      line.strip!
      if line.start_with?("\#DISABLED")
        log "This account is disabled"
        return false
      end
      if not line.empty? and not line.start_with?("\#")
        debug "#{line.length}: #{line}"
        if line.length < 140
          @phrases << line
        else
          debug "**LINE too long**"
        end
      end     
    end
    log "Found #{@phrases.length} entries"
    true
  end
  
  def heckle
    @phrases.sample
  end
  
  def empty?
    @phrases.length == 0
  end
end
