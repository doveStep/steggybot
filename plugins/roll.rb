require 'cinch'

class Roll
  include Cinch::Plugin
  match /roll (.+)[D|d](.+)/, method: :roll
  @help_hash = {
    :roll => "Usage: !roll xDy
Example: !roll 5d20
Returns the values of the dice rolled, as well as their sum"
  }

  def roll(m, num_dice, range)
    results = []
    values = num_dice.to_i.times {results << (1..range.to_i).to_a.sample}
    m.reply "#{m.user.nick}, you got #{results}, sums to #{results.inject(0, :+)}"
  end
end
