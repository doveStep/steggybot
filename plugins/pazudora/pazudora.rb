require 'cinch'
require 'nokogiri'

class Pazudora
  include Cinch::Plugin
  
  PUZZLEMON_BASE_URL = "http://www.puzzledragonx.com/en/"
  
  match /pazudora ([\w-]+) *(.+)*/i, method: :pazudora
  match /stupidpuzzledragonbullshit ([\w-]+) *(.+)*/i, method: :pazudora
  match /stupiddragonpuzzlebullshit ([\w-]+) *(.+)*/i, method: :pazudora
  match /p&d ([\w-]+) *(.+)*/i, method: :pazudora
  match /pad ([\w-]+) *(.+)*/i, method: :pazudora
  match /puzzlemon ([\w-]+) *(.+)*/i, method: :pazudora
  match /puzzledex (.+)*/i, method: :pazudora_lookup
  
  @help_string = <<-eos
  Puzzle and Dragons (on iOS and Android) utility functions. Mostly collects friend codes and tracks the daily dungeon.
  Its commands are aliased to pazudora, p&d, pad,  and puzzlemon.
  eos
  @help_hash = {
    :add => "Usage: !puzzlemon add NAME CODE
Example: !puzzlemon add steggybot 123,456,789
Adds user's code to the list of friend codes",
    :group => "Usage: !puzzlemon group NAME
Example !puzzlemon group steggybot
Returns the daily dungeon group that the user belongs to.",
    :dailies => "Usage: !puzzlemon dailies
Example !puzzlemon dailies
Returns the times (and type) of today's daily dungeons, split by group. If called by
a registered player, also reminds them of their group id.",
    :lookup => "Usage: !(puzzlemon lookup|puzzledex) (NAME|ID)
Example !puzzlemon lookup horus, !puzzledex 603
Returns a description of the puzzlemon. If none is found, returns a pseudorandom (hashed) one.",
    :list => "Usage: !puzzlemon list
Example !puzzlemon list
Returns a list of everyone's friends codes.",
    :level => "Usage: !(puzzlemon level NAME CURRENTEXP TARGETLEVEL
Example !puzzlemon level Sapphire Carbuncle 0 10
Returns the required amount of experience left to level your puzzlemon from its current experience total to the desired level."
  }
  
  def initialize(*args)
    super
    @pddata = config[:pddata]
  end
  
  #Any public method named pazudora_[something] is external and
  #can be accessed by the user using the construction "!puzzlemon something [args]".
  def pazudora (m, cmd, args)
    subr = cmd.downcase.chomp
    begin
      if args
        self.send("pazudora_#{subr}", m, args)
      else
        self.send("pazudora_#{subr}", m, "")
      end
    rescue NoMethodError
      puts "Pazudora called with invalid command #{subr}."
    end
  end
  
  def pazudora_add (m, args)
    pargs = args.split
    username = pargs[0]
    friend_code = pargs[1]
    
    # add it to the list
    friend_codes = load_data || {}
    if friend_code =~ /[0-9]{9}/
      friend_code = friend_code.reverse.gsub(/(\d{3})(?=\d)/, '\\1,').reverse
    end 
    if friend_codes[username.downcase] && (friend_codes[username.downcase][:added_by] == username.downcase)
      if m.user.nick.downcase == username.downcase
        friend_codes[username.downcase] = {:friend_code => friend_code, :added_by => m.user.nick.downcase, :updated_at => DateTime.now}
      else
        m.reply "#{m.user.nick}: Can't override a user's self-definition."
        return
      end
    else
      friend_codes[username.downcase] = {:friend_code => friend_code, :added_by => m.user.nick.downcase, :updated_at => DateTime.now}
    end
    # write it to the file
    output = File.new(@pddata, 'w')
    output.puts YAML.dump(friend_codes)
    output.close
      
    m.reply "#{m.user.nick}: #{mangle(username)} successfully added as '#{friend_code}'."
  end
  
  def pazudora_remove(m, args)
    pargs = args.split
    username = pargs[0]
    friend_codes = load_data || {}
    
    if ! friend_codes[username]
      m.reply "#{m.user.nick}: #{mangle(username)} not in friend code list."
      return
    end
    
    if (m.user.nick.downcase == username.downcase) || (m.user.nick.downcase == friend_codes[username][:added_by])
      friend_codes.delete(username)
      # write it to the file
      output = File.new(@pddata, 'w')
      output.puts YAML.dump(friend_codes)
      output.close
      
      m.reply "#{m.user.nick}: #{mangle(username)} removed from friend code list."
    else
      m.reply "#{m.user.nick}: Only the identity creator or subject can remove a friend code from the list."
    end
  end
  
  def pazudora_who(m,args)
    pargs = args.split
    username = pargs[0]
    if load_data[username.downcase]
      m.reply "#{m.user.nick}: #{mangle(username)}'s friend code is #{load_data[username.downcase][:friend_code]}"
    end
  end
  
  def pazudora_list(m,args)
    friend_codes = load_data || {}
    friend_codes.keys.each_slice(3).with_index { |users, i| 
      r = i == 0 ? "#{m.user.nick}: " : ""
      users.each{ |user| r=r+"#{mangle(user)}:#{friend_codes[user][:friend_code]} " }
      m.reply r
    }
  end
  
  def pazudora_group(m,args)
    pargs = args.split
    username = pargs[0]
    if username.nil?
      username = m.user.nick
    end
    if load_data[username.downcase]
      friend_code = load_data[username.downcase][:friend_code]
      group = (Integer(friend_code.split(",")[0][2]) % 5 + 65).chr
      m.reply "#{m.user.nick}: #{mangle(username)}'s group is #{group}"
    else
      m.reply "#{m.user.nick}: #{mangle(username)}'s friend code is not listed. Please use the add command to add it."
    end
  end
  
  def pazudora_dailies(m, args)
    daily_url = PUZZLEMON_BASE_URL + "option.asp?utc=-8"
    
    username = args.split[0] || m.user.nick
    friend_code = load_data[username.downcase][:friend_code] rescue nil
    group_num = friend_code ? group_number_from_friend_code(friend_code) : nil
    
    unless @daily_timestamp == Time.now.strftime("%m-%d-%y")
      @daily_page = nil
      @daily_timestamp = Time.now.strftime("%m-%d-%y")
    end
    
    @daily_page ||= Nokogiri::HTML(open(daily_url))
    event_data = @daily_page.css(".event3")
    event_rewards = @daily_page.css(".limiteddragon")
    
    rewards = parse_daily_dungeon_rewards(event_rewards, group_num || 0)
    m.reply "Dungeons today are: #{rewards.join(', ')}"
    
    (0..4).each do |i|
      m.reply "Group #{(i + 65).chr}: #{event_data[i].text}, #{event_data[i + 5].text}, #{event_data[i + 10].text}"
    end
    
    if group_num
      m.reply "User #{username} is in group #{(group_num + 65).chr}"
    end
  end
  
  def pazudora_lookup(m, args)
    identifier = args
    info = get_puzzlemon_info(URI.encode(identifier))
    
    #Bypass puzzledragonx's "default to meteor dragon if you can't find the puzzlemon" mechanism to
    #get a pseudorandom puzzlemon (up to the max currently released puzzlemon) instead.
    meteor_dragon_id = "211"
    highest_puzzledex_id = 603
    
    if info.css(".name").children.first.text == "Meteor Volcano Dragon" && !(identifier.start_with?("Meteor") || identifier == meteor_dragon_id)
      num = (identifier.hash % highest_puzzledex_id) + 1
      info = get_puzzlemon_info(URI.encode(num.to_s))
    end
    
    desc = info.css("meta [name=description]").first.attributes["content"].text
    desc.gsub!(/&amp;/, "&")
    m.reply desc
  end

  def pazudora_level(m, args)
    if args == ""
      return
    end
    pargs = args.partition(/[0-9]+/) # Split args around central number.
    identifier = pargs[0].strip
    curexp = pargs[1]
    targetlvl = pargs[2].strip
    info = get_puzzlemon_info(URI.encode(identifier))
    curve = get_expcurve_from_info(info)
    targetexp = curve / 100000 * ((pargs[2].to_f - 1) * 50 / 49) ** 2.5 
    neededexp = targetexp - curexp.to_f
    m.reply "To level #{info.css(".name").children.first.text} to level #{targetlvl}, you need #{neededexp.round} more experience."
  end
  
  protected
  
  def mangle(s)
    s.chop + "." + s[-1]
  end
  
  def load_data
    datafile = File.new(@pddata, 'r')
    friend_codes = YAML.load(datafile.read)
    datafile.close
    return friend_codes
  end
  
  def group_number_from_friend_code(friend_code)
    return Integer(friend_code.split(",")[0][2]) % 5
  end
  
  def parse_daily_dungeon_rewards(rewards, group_num)
    puzzlemon_numbers = [
    rewards[0 + group_num].children.first.attributes["src"].
      value.match(/thumbnail\/(\d+).png/)[1],
    rewards[5 + group_num].children.first.attributes["src"].
      value.match(/thumbnail\/(\d+).png/)[1],
    rewards[10 + group_num].children.first.attributes["src"].
      value.match(/thumbnail\/(\d+).png/)[1]]
    
    puzzlemon_numbers.map{|x| 
      get_puzzlemon_info(x).css(".name").children.first.text rescue "Unrecognized Name" }
  end
  
  def get_puzzlemon_info(name_or_number)
    search_url = PUZZLEMON_BASE_URL + "monster.asp?n=#{name_or_number}"
    puzzlemon_info = Nokogiri::HTML(open(search_url))
  end
  
  def get_expcurve_from_info(info)
    return Integer(info.xpath('//*[@id="tablestat"][4]/tr[3]/td[2]/a/text()').first().content())
  end

end

