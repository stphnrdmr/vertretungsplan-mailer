require 'rubygems'
require 'bundler/setup'
Bundler.require
Dotenv.load
require 'open-uri'

def html_mail_data(content, link)
  data = {}
  data[:from] = "Vertretung <vertretung@#{ENV['MAILDOMAIN']}>"
  data[:to] = ENV['MAIL_TO']
  data[:subject] = 'Vertretungsplan-Änderung!'
  data[:text] = "Änderungen im Vertretungsplan, siehe #{link}"
  data[:html] = content
  data
end

def send_html_mail(content, link)
  RestClient.post "https://api:#{ENV['MAILGUN_KEY']}@api.mailgun.net/v2/"\
                  "#{ENV['MAILDOMAIN']}/messages",
                  html_mail_data(content, link)
  rescue => e
    puts e.response
end

def tomorrow
  week_day = Time.now.wday
  week_day == 6 ? 0 : week_day + 1
end

def week_number
  number = DateTime.now.cweek
  tomorrow == 1 ? number + 1 : number
end

def prepare_and_send_mail
  table_utf8 = @table.to_s.encode('UTF-8')
  css_magic = "<link rel=\"stylesheet\" href=\"#{@base_url}/untisinfo.css\">"\
              "<div id=\"vertretung\">"
  html_content = Nokogiri::HTML(css_magic + table_utf8).to_s
  content = Premailer.new(html_content, with_html_string: true).to_inline_css
  send_html_mail content, @timetable_url
end

@base_url = 'http://stundenplan.mmbbs.de/plan1011/ver_kla'
@timetable_url = "#{@base_url}/#{week_number}/w/w00040.htm"
doc = Nokogiri::HTML(open(@timetable_url))
table_xpath = "//div[contains(@id, 'vertretung')]//"\
              "a[contains(@name, #{tomorrow})]/following::table"
@table = doc.xpath(table_xpath).first

prepare_and_send_mail if @table.to_s.include? "tr class=\"list\""
