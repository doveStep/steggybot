require 'cinch'
require 'yaml'

class PlusPlus
  include Cinch::Plugin
  @help_hash = {
    :person => "Usage: !person NAME
Example: !person steggybot
Returns the plusplus values from all other users about user NAME",
    :persons_feelings => "Usage: !persons_feelings NAME
Example !persons_feelings steggybot
Returns the a hash of the people that that NAME has plusplus'ed, and the number of times."
  }
  match /karma (.*)/i, method: :lookup_sum
  listen_to :channel
  match /persons_feelings (.*)/i, method: :lookup_feelings
  match /person (.*)/i, method: :lookup

  # lookup looks up someone's name and replies with their karma in the
  # form:
  # czhang's karma: {"czhan.g"=>1}, {"skimbre.l"=>1}
  def lookup(m, name)
    values = plusplus_file
    values = values.keys.map { |key| [key, values[key][name]] if values[key][name] }.compact
    m.reply("#{name}'s karma: #{format_scores(values)}")
  end

  # This looks up someone's karma and replies with the total sum in
  # the form:
  # whunt: 9001
  def lookup_sum(m, name)
    values = plusplus_file
    values = values.keys.map { |key| {mangle_string(key) => values[key][name]} if values[key][name] }.compact
    if values.empty?
      m.reply("no results for #{name}")
    else
      total = values.map(&:values).flatten.inject(:+)
      m.reply("#{name}'s total karma: #{total}")
    end
  end

  # This looks up the people that someone has given karma to. It
  # replies in the form:
  # {"skimbre.l"=>-1, "czhan.g" => 1}
  def lookup_feelings(m, name)
    m.reply(format_scores(plusplus_file[name]))
  end

  def format_scores(scores)
    return "no results" unless scores && scores.any?

    pairs = scores.sort_by { |(item, score)| score }.reverse

    pairs.map { |(item, score)| "#{mangle_string(item)} (#{score})" }.join(" / ")
  end

  # This mangles a name by inserting a '.'
  # It is used so this bot does not ping people multiple times
  def mangle_string(string)
    "#{string[0]}.#{string[1..-1]}"
  end

  def initialize(*args)
    super
    @plusplus_file = config[:plusplus]
  end

  def listen(m)
    plusplus = %r{(?<to>(.*))\+\+$}.match m.message
    minusminus  = %r{(?<to>(.*))\-\-$}.match m.message
    change(m.user.nick, plusplus[:to], :+) if plusplus
    change(m.user.nick, minusminus[:to], :-) if minusminus
  end

  def plusplus_file()
    file = File.new(@plusplus_file, 'r')
    values = YAML.load(file.read)
    file.close
    values
  end

  def change(from, to, function)
    values = plusplus_file || {}
    froms_feelings = (values.keys.include? from) ? values[from] : Hash.new { |hash, key| hash[key] = 0 }
    p froms_feelings
    p to
    froms_feelings[to] = 0 if froms_feelings[to].nil?
    froms_feelings[to] = froms_feelings[to].send(function, 1)
    froms_feelings.delete(to) if froms_feelings[to] == 0
    values[from] = froms_feelings
    File.open(@plusplus_file, 'w') { |f| f.write (YAML.dump values) }
  end
end
