require_relative 'dissident'
require_relative 'heckles'
require 'test/unit'
require 'twitter'
require 'socket'
require 'logger'


class DisTest < Test::Unit::TestCase


  def test_dont_reply_self
    @bot = Dissident.new()
#    @bot.myname = "boris"
#    assert_equal(nil, @bot.build_reply("boris", "text"))
  end


  def test_boris_heckles
    heckle = Heckles.new()
    heckle.init("borisjohnson")
    assert(!heckle.empty?, "empty heckles")
    h1 = heckle.heckle
    h2 = heckle.heckle
    assert_not_equal(h1, h2, "Duplicate echoes are issued")

  end
  #def test_simple
  #  assert_equal(4, SimpleNumber.new(2).add(2) )
  #  assert_equal(6, SimpleNumber.new(2).multiply(3) )
  #end


end
