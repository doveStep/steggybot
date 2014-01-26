#To run the test suite, run "bundle exec rspec plugins/*/spec/"

def mock_message(opts={})
  m = mock()
  
  m.stub(:message) { opts[:message] } if opts[:message]
  m.stub(:user) { mock(:nick => opts[:nick]) } if opts[:nick]
  m.stub(:reply)
  return m
end

#Configures a bot for testing on, set to not try to reconnect after fail. 
#Adds options if any passed in. Use with SteggyMocker to mock dependencies.
def new_test_bot(opts={}, &b)
  cinch_bot = Cinch::Bot.new do
    configure do |c|
      c.nick = "steggybot_testbot"
      c.server = nil
      c.channels = []
      c.plugins.plugins = opts[:plugins] if opts[:plugins]
      c.reconnect = false
      b and b.call(c)
    end
  end

  cinch_bot
end


module SteggyMocker
  def SteggyMocker.mock_irc
    Cinch::IRC.any_instance.stub(:connect).and_return(false)
  end
end
