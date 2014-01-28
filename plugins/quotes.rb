require 'cinch'
require 'yaml'

class Quotes
  include Cinch::Plugin
  @help_hash = {
      :add_quote => "Usage: !addquote Quote
Example: !addquote \"That steggybot sure is something\"",
      :quote => "Usage !quote [search]
Example: !quote whunt",
      :fortune => "Same as quote"
    }
  match /addquote (.+)/i, method: :addquote
  match /quote (.+)/i, method: :quote
  match /fortune/i, method: :quote

  def initialize(*args)
    super

    @quotes_file = config[:quotes_file]
  end

  def addquote(m, quote)
    # make the quote
    new_quote = { "quote" => quote, "added_by" => m.user.nick, "created_at" => Time.now, "deleted" => false }

    # add it to the list
    existing_quotes = get_quotes || []
    existing_quotes << new_quote

    # find the id of the new quote and set it based on where it was placed in the quote list
    new_quote_index = existing_quotes.index(new_quote)
    existing_quotes[new_quote_index]["id"] = new_quote_index + 1

    # write it to the file
    output = File.new(@quotes_file, 'w')
    output.puts YAML.dump(existing_quotes)
    output.close

    # send reply that quote was added
    m.reply "#{m.user.nick}: Quote successfully added as ##{new_quote_index + 1}."
  end

  def quote(m, search = nil)
    quotes = get_quotes.delete_if{ |q| q["deleted"] == true }
    if search.nil? # we are pulling random
      quote = quotes.sample
      m.reply "#{m.user.nick}: ##{quote["id"]} - #{quote["quote"]}"
    elsif search.to_i != 0 # then we are searching by id
      quote = quotes.find{|q| q["id"] == search.to_i }
      if quote.nil?
        m.reply "#{m.user.nick}: No quotes found."
      else
        m.reply "#{m.user.nick}: ##{quote["id"]} - #{quote["quote"]}"
      end
    else
      quotes.keep_if{ |q| q["quote"].downcase.include?(search.downcase) }
      if quotes.empty?
        m.reply "#{m.user.nick}: No quotes found."
      else
        quote = quotes.first
        m.reply "#{m.user.nick}: ##{quote["id"]} - #{quote["quote"]}"
        m.reply "The search term also matched on quote IDs: #{quotes.map{|q| q["id"]}.join(", ")}" if quotes.size > 1
      end
    end
  end

  #--------------------------------------------------------------------------------
  # Protected
  #--------------------------------------------------------------------------------

  protected

  def get_quotes
    output = File.new(@quotes_file, 'r')
    quotes = YAML.load(output.read)
    output.close

    quotes
  end

end
