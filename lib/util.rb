module Util
  module_function

  def escape_nicks(str, channel)
    str = str.dup
    nicks = channel.users.keys.map(&:nick)

    nicks.each do |nick|
      str.gsub!(/\b#{nick}\b/i, mangle_nick(nick))
    end

    str
  end

  def mangle_nick(nick)
    "#{nick[0]}.#{nick[1..-1]}"
  end
end
