require 'cinch'
Dir.glob("plugins/*.rb").each {|x| require_relative x}
Dir.glob("plugins/*/*.rb").each {|x| require_relative x}

bot = Cinch::Bot.new do
  configure do |c|
    c.server = "irc.freenode.net"
    c.nick = "steppybot"

    c.channels = ["#csuatest", "##csua"] #  "#csua", 
    c.plugins.plugins = [Google, UrbanDictionary, TitleGrabber, Quotes, Pokedex,
                         Youtube, YaBish, Roll, WhoAreThesePeople, PlusPlus, 
                         Pazudora, FeatureRequest]
    c.plugins.plugins << Help

    c.channels = ["#csua", "#csuatest"]
#    c.channels = ["#csuatest"]
    c.plugins.plugins = [Google, UrbanDictionary, TitleGrabber, Quotes, Pokedex, Youtube, 
                         Roll, WhoAreThesePeople, PlusPlus, Pazudora, Contributors, Countdown,
                         FrenchRevCal, FeatureRequestPlugin]
    c.plugins.plugins << Help
    c.plugins.options[YaBish] = {
      :db => 'db/ya_bish',
      :rate_limit => [10, 600], # 10 replies every 600 seconds (10 min.)
      :random_ratio => (1.0/80), # reply randomly with a 1/80 probability
    }
    c.plugins.options[Quotes] = {
      :quotes_file => "db/quotes.yml"
    }
    c.plugins.options[Pokedex] = {
      :pokedex => "db/pokedex.json"
    }
    c.plugins.options[WhoAreThesePeople] = {
      :identities => "db/identities.yml"
    }
    c.plugins.options[PlusPlus] = {
      :plusplus => "db/plusplus.yml"
    }
    c.plugins.options[Pazudora] = {
      :pddata => "db/pddata.yml"
    }
    c.plugins.options[FeatureRequestPlugin] = {
      :requests => "db/requests.yml"
    }
  end
end

bot.start
