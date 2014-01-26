require 'cinch'
require './lib/markov'
require './lib/util'

require 'thread'

class YaBish
  include Cinch::Plugin

  @help_string = "YaBish listens in the channel, waiting for someone to say its name, and then replying with a markov-generated sentence"
  listen_to :channel, :method => :channel
  listen_to :private, :method => :private

  def initialize(*)
    super
    @markov_mutex = Mutex.new
    @limit_mutex = Mutex.new
    @db = Markov::DB.new(config[:db])
    @markov = @db.load
    @limits = {}
    @rate_limit_max, @rate_limit_interval = (config[:rate_limit] || [10, 600])
    @random_ratio = config[:random_ratio] || 1.0/80
  end

  def channel(m)
    # reply only if steggybot's name or `ya bish` is mentioned
    seed = get_seed(m.message, m.bot.nick)
    seed = '' if reply_randomly?

    if seed
      rate_limit(m.channel) {
        m.reply generate_mangled(seed, m.channel)
      }
    else
      # learn from every message and save every once in a while
      @markov_mutex.synchronize {
        @markov.train!(m.message)
        @markov.persist(@db)
      }
    end
  end

  def private(m)
    seed = get_seed(m.message, m.bot.nick) || m.message
    m.reply @markov.generate_sentence(seed)
  end

private
  def reply_randomly?
    rand < @random_ratio
  end

  def generate_mangled(seed, channel)
    Util.escape_nicks @markov.generate_sentence(seed), channel
  end

  def get_seed(message, nick)
    message =~ /\b(ya\s+bish)/ and return $`
    message =~ /\b#{nick}/ and return ''
  end

  def rate_limit(channel, &b)
    return yield unless channel

    now = Time.now.to_i / @rate_limit_interval

    @limit_mutex.synchronize {
      cache = @limits[channel] ||= {}

      if now != cache[:last_interval]
        cache[:last_interval] = now
        cache[:limit_count] = 1
      else
        cache[:limit_count] += 1
      end

      yield if cache[:limit_count] < @rate_limit_max
    }
  end
end
