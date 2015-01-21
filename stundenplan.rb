require 'rubygems'
require 'bundler/setup'
Bundler.require
Dotenv.load
require 'open-uri'

# This programs sends mail when there is a relevant
# schedule entry for the next day
# Author:: Stephan Rodemeier
# Copyright:: Copyright (c) 2014 Stephan Rodemeier
# License:: MIT License
class VertretungsMailer
  attr_reader :base_url, :schedule_url, :table

  def initialize(
    base_url_string = nil,
    schedule_url_string = nil,
    table_xpath_string = nil
  )
    @base_url       = base_url_string || default_base_url
    @schedule_url  = schedule_url_string || default_schedule_url
    table_xpath     = table_xpath_string || default_table_xpath
    doc             = Nokogiri::HTML(open(@schedule_url))
    @table          = doc.xpath(table_xpath).first
    initialize_features
  end

  def go
    return false unless table_has_relevant_entry?
    content = prepare_mail_content
    send_notifications content
  end

  private

  def initialize_features
    repo = Feature::Repository::YamlRepository.new('feature.yml')
    Feature.set_repository repo
  end

  def default_base_url
    'http://stundenplan.mmbbs.de/plan1011/ver_kla'
  end

  def default_schedule_url
    "#{base_url}/#{week_number}/w/w00040.htm"
  end

  def default_table_xpath
    "(//table[@class='subst'])[#{tomorrow}]"
  end

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
    puts 'mail sent'
  rescue => e
    puts e.response
  end

  def slack_data(link)
    data = {}
    data[:text] = 'Neuer Vertretungsplan! '\
                  "<#{link}##{tomorrow}|Hier klicken> für Infos!"
    data[:username] = ENV['SLACK_NAME']
    data[:icon_emoji] = ':heavy_exclamation_mark:'
    data[:channel] = ENV['SLACK_CHANNEL']
    data.to_json
  end

  def send_slack(link)
    RestClient.post "https://hooks.slack.com/services/#{ENV['SLACK_KEY']}",
                    slack_data(link), content_type: :json, accept: :json
    puts 'slack sent'
  rescue => e
    puts e.response
  end

  def tomorrow
    DateTime.tomorrow.wday
  end

  def week_number
    if DateTime.now.wday.between?(1, 4)
      DateTime.tomorrow.cweek.to_s.rjust(2,'0')
    else
      (DateTime.tomorrow.cweek + 1).to_s.rjust(2,'0')
    end
  end

  def table_has_relevant_entry?
    table.to_s.include? "tr class=\"list\""
  end

  def prepare_mail_content
    table_utf8 = table.to_s.encode('UTF-8')
    css_magic = "<link rel=\"stylesheet\" href=\"#{base_url}/untisinfo.css\">"\
      "<div id=\"vertretung\">"
    prepare_html_for_mail(Nokogiri::HTML(css_magic + table_utf8).to_s)
  end

  def prepare_html_for_mail(html_content)
    Premailer.new(html_content, with_html_string: true).to_inline_css
  end

  def send_notifications(mail_content)
    Feature.with(:send_mail) do
      send_html_mail(mail_content, schedule_url)
    end

    Feature.with(:send_slack) do
      send_slack(schedule_url)
    end
  end
end

if __FILE__ == $PROGRAM_NAME
  mailer = VertretungsMailer.new
  mailer.go
end
