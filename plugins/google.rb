require 'cinch'
require 'open-uri'
require 'nokogiri'
require 'cgi'
require 'json'
class Google
  include Cinch::Plugin
  match /google (.+)/, method: :execute
  match /image (.+)/, method: :image

  @help_hash = {
    :google => "Usage: !google THING
Example !google Syria
Returns the first google hit for THING"
  }

  def image(m, query)
    url = "https://ajax.googleapis.com/ajax/services/search/images?v=1.0&q=#{CGI.escape(query)}"
    res = JSON.parse(Nokogiri::HTML(open(url)))
    m.reply(res["responseData"]["results"].slice(0,9).sample["unescapedUrl"])
  end
  def search(query)
    url = "http://www.google.com/search?q=#{CGI.escape(query)}"
    res = Nokogiri::HTML(open(url)).at("h3.r")

    title = res.text
    link = res.at('a')[:href]
    desc = res.at("./following::div").children.first.text
    CGI.unescape_html "#{title} - #{desc} (#{link})"
  rescue
    "No results found"
  end

  def execute(m, query)
    m.reply(search(query))
  end
end
