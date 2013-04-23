require 'spec_helper'
require File.dirname(__FILE__) + "/../avalon.rb"

describe Avalon do
  before(:all) do
    @avalon = Avalon.new(new_test_bot)
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
