require 'cinch'
Dir.glob("plugins/*.rb").each {|x| require_relative x}
Dir.glob("plugins/*/*.rb").each {|x| require_relative x}

bot = Cinch::Bot.new do
  configure do |c|
    c.server = "irc.freenode.net"
    c.nick = "steggybot"
    c.channels = ["#csua", "#csuatest", "##csua"]
    c.plugins.plugins = [Google, UrbanDictionary, TitleGrabber, Quotes, Pokedex,
                         Youtube, YaBish, Roll, WhoAreThesePeople, PlusPlus, 
                         Pazudora, FeatureRequest]
    c.plugins.plugins << Help

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
    c.plugins.options[FeatureRequest] = {
      :task_list => "feature_requests.yml"
    }
  end
end

bot.start
