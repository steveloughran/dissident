require 'test/unit'
require 'twitter'
require 'socket'
require_relative 'heckles'
require_relative 'transport'
require_relative 'engine'
require_relative 'dissident'


class DisTest < Test::Unit::TestCase

  def initialize(x)
    super(x)
    @target_dir = "testdata"
    @secrets = "testdata/secrets.rb"
    @engine = Engine.new()
    @engine.start(@secrets, @target_dir, Transport.new())
  end

  def test_dont_reply_self
    assert_equal(nil, @engine.build_reply("self", "text"))
  end


  # there's a 1 in 10K chance this test fails.
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

  def test_unknown_user
    heckle = Heckles.new()
    heckle.initForUser(@target_dir, "no-such-user")
    assert(heckle.empty?)
  end

  #def test_simple
  #  assert_equal(4, SimpleNumber.new(2).add(2) )
  #  assert_equal(6, SimpleNumber.new(2).multiply(3) )
  #end


end
