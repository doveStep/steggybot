require 'cinch'

class WhoAreThesePeople
  include Cinch::Plugin

  listen_to :channel
  match /addwho ([\w-]+) (.+)/i, method: :add
  match /removewho ([\w-]+)/i, method: :remove

  def initialize(*args)
    super
    @identities = config[:identities]
  end

  def add (m, username, real_name)
    # add it to the list
    existing_ids = get_identities || {}

    if existing_ids[username.downcase] && (existing_ids[username.downcase][:added_by] == username.downcase)
      if m.user.nick.downcase == username.downcase
        existing_ids[username.downcase] = {:name => real_name, :added_by => m.user.nick.downcase, :updated_at => DateTime.now}
      else
        m.reply "#{m.user.nick}: Can't override a user's self-definition."
        return
      end
    else
      existing_ids[username.downcase] = {:name => real_name, :added_by => m.user.nick.downcase, :updated_at => DateTime.now}
    end

    # write it to the file
    output = File.new(@identities, 'w')
    output.puts YAML.dump(existing_ids)
    output.close

    m.reply "#{m.user.nick}: #{username} successfully added as '#{real_name}'."
  end

  def remove(m, username)
    existing_ids = get_identities || {}

    unless existing_ids[username]
      m.reply "#{m.user.nick}: #{username} not in identities list."
      return
    end

    if (m.user.nick.downcase == username.downcase) || (m.user.nick.downcase == existing_ids[username][:added_by])
      existing_ids.delete(username)
      # write it to the file
      output = File.new(@identities, 'w')
      output.puts YAML.dump(existing_ids)
      output.close

      m.reply "#{m.user.nick}: #{username} removed from identities list."
    else
      m.reply "#{m.user.nick}: Only the identity creator or subject can remove an identity from the list."
    end
  end

  def listen(m)
    match = /who *is (\w+)/i.match(m.message)
    if match
      user = match[1]
      if get_identities[user.downcase]
        m.reply "#{m.user.nick}: #{user} is #{get_identities[user.downcase][:name]}"
      end
    end
  end

  protected

  def get_identities
    output = File.new(@identities, 'r')
    ids = YAML.load(output.read)
    output.close

    ids
  end
end
