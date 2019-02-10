require_relative 'dissident'
require 'test/unit'
require 'twitter'
require 'socket'
require 'logger'


class DisTest < Test::Unit::TestCase


  def setup
    @bot = Dissident.new()
    @bot.myname = "boris"
  end

  def test_dont_reply_self
    assert_equal(nil,
      @bot.build_reploy("boris", "text"))
  end


  #def test_simple
  #  assert_equal(4, SimpleNumber.new(2).add(2) )
  #  assert_equal(6, SimpleNumber.new(2).multiply(3) )
  #end


end