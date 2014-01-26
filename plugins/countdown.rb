require 'cinch'

class Countdown
  include Cinch::Plugin
  match /countdown/

  def execute(m)
    end_date = Date.new(2014, 2, 28)
    days_remaining = (end_date - Date.today).to_i
    m.reply "#{days_remaining} days until steggy can return to civilization."
  end
end
