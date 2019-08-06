require 'test/unit'
require 'twitter'
require 'socket'
require_relative 'heckles'
require_relative 'transport'
require_relative 'engine'
require_relative 'dissident'

# Unit tests; use the fake transport for assertings
class DisTest < Test::Unit::TestCase

  def initialize(x)
    super(x)
    @target_dir = "testdata"
    @secrets = "testdata/secrets.rb"
    @engine = Engine.new()
    @transport = FakeTransport.new()
    @engine.start(@secrets, @target_dir, @transport)
  end

  def test_dont_reply_self
    assert_equal(nil, @engine.build_reply("self", "text"))
  end

  # there's a 1 in 1000 chance this test fails, so a retry
  # in that case to reduce it to 1 in 10^6.
  def test_unique heckles
    heckle = Heckles.new()
    heckle.initForUser(@target_dir, "1k")
    assert(!heckle.empty?, "empty heckles")
    h1 = heckle.heckle
    h2 = heckle.heckle
    if h1 == h2 
      # we can get a match by random, so on the first failure,
      # try again
      h2 = heckle.heckle
    end
    assert_not_equal(h1, h2, "Duplicate echoes are issued")
  end

  def test_unknown_target
    heckle = Heckles.new()
    heckle.initForUser(@target_dir, "no-such-user")
    assert(heckle.empty?)
  end

  def test_disabled_targets_arent_heckled
    heckle = Heckles.new()
    heckle.initForUser(@target_dir, "no-such-user")
    assert(heckle.heckle.nil?)
  end

  def test_engine_accessors
    assert(@engine.initialized)
    assert_equal("self", @engine.myname)
    assert(@engine.online)
  end

  def test_is_response
    assert(@engine.is_response("RT "))
    assert(!@engine.is_response("RT"))
    assert(!@engine.is_response(""))
    assert(!@engine.is_response(" RT"))
  end

  def test_say
    @engine.say("hello")
    assert(@transport.said.last == "hello")
  end

  def test_DM
    @engine.direct("alice", "hello from bob")
    assert(@transport.directed.last == "hello from bob")
  end
  
end
