require 'cinch'

class Contributors
    include Cinch::Plugin

    @help_hash = {
        :contributors => "Usage: !contributors\n Returns a list of people who have contributed to this IRC bot"
    }

    match "contributors", method: :list_contributors

    def list_contributors(m)
        s = "Contributors:\n"
        File.open('CONTRIBUTORS').each do |line|
            s += line + "\n"
        end
        m.reply(s)
    end
end

