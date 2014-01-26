require 'open-uri'
require 'cinch'
require 'nokogiri'
require 'pdf-reader'

class TitleGrabber
  include Cinch::Plugin
  @help_string = "Titlegrabber simply sits in the channel watching for HTTP links. When it sees one, it will grab the title, and print it in the channel"
  listen_to :channel

  def grab(url)
    doc = open(url)

    case doc.content_type
    when "application/pdf"
      grab_pdf_title(doc)
    else
      grab_html_title(doc)
    end

  rescue OpenURI::HTTPError
    nil
  end

  def grab_html_title(doc)
    page = Nokogiri::HTML(doc)
    return nil if page.css("title").empty?
    return page.css("title").first.text
  end

  def grab_pdf_title(doc)
    pdf = PDF::Reader.new(doc)
    return pdf.info ? pdf.info[:Title] : nil
  end

  def listen(m)
    urls = URI.extract(m.message, "http")
    urls.reject! {|url| url.include? "youtube.com"}
    titles = urls.map { |url| grab(url) }.compact
    unless titles.empty?
      m.reply titles.join(", ")
    end
  end
end
