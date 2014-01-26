require 'cinch'
require 'time'
require 'RevCal'

class FrenchRevCal
  include Cinch::Plugin

  match /revcal/, method: :today
  def today(m)
    date = RevDate.fromGregorian(Date.today)
    m.reply("#{date} - #{date.daySymbol}")
  end
end
