require 'spec_helper'
require File.dirname(__FILE__) + "/../avalon.rb"

describe Avalon do
  before(:all) do
    bot = new_test_bot do |c|
      c.plugins.options[Avalon] = {
        :db => 'db/avalon.test.yml'
      }
    end

    @avalon = Avalon.new(bot)
  end

  it 'starts a game' do
    @message = mock :user => (mock :nick => 'doveStep'), 
                    :channel => (mock :name => 'csuavalon')

    @message.should_receive :reply do |reply|
      reply.should include('Players, join in!')
    end

    @avalon.dispatch(@message, 'start')
  end
end
