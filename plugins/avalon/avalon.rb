require 'cinch'
require 'yaml'

class Avalon
  include Cinch::Plugin

  # TODO: figure out how to send/receive PMs

  match /avalon (.+)/i, method: :dispatch

  def initialize(*args)
    super
    @db = config[:db]
  end

  def dispatch(m, message)
    state = State.new(@db, m.channel.name)
    case message.strip
    when "start"
      # todo make sure no other sessions are running in this room/channel
      state.reset
      state.save
      m.reply "New game started for #{state.room}. Players, join in!"
    else
      m.reply "unkown command: #{message}"
    end
  end

  # the state of the game
  class State

    attr_reader :data
    attr_reader :room

    def initialize(db, room)
      @db = db
      @room = room
      loaded_db = YAML.load_file(@db)
      @data = loaded_db[room]
    end

    #overwrites state inside this room
    def save
      current = YAML.load_file(@db)
      current[@room] = @data

      File.open(@db, 'w') do |file|
        file.puts YAML.dump(current)
      end
    end

    def reset
      @data = { 
        players: [],
        features: [],
        king: nil,
        hammer: nil,
        log: [],
        mode: :setup,
        votes: [],
        chalices: [],
        team: [] 
      }
    end

  end

end
