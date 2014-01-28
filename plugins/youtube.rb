require 'cinch'
require 'nokogiri'
require 'open-uri'

class Youtube
  include Cinch::Plugin
  listen_to :channel

  def listen(m)
    urls = URI.extract(m.message, "http")
    urls += URI.extract(m.message, "https")
    urls = urls.select{|url| url.include? "youtube.com"}
    page_info = urls.map{|url| get_page_info(url)}.compact
    unless page_info.empty?
      m.reply page_info.join("\n")
    end
  end

  def get_page_info(url)
    page = Nokogiri::HTML(open(url))
    return_string = "Title: " + page.title + ",
Top Comments: \t"
    page.css("div.content-container > div.content > div.comment-text")[0..2].each_with_index{|comment, index| return_string += index.to_s + " " + comment.text.strip+ "\n" }

    return_string += " With count: " + page.css("div[@id=watch-actions] span.watch-view-count > strong").text
  end
end

