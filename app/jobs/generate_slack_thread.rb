# frozen_string_literal: true

require "open-uri"

class GenerateSlackThread < ApplicationJob
  queue_as :default

  def perform(date)
    @puzzle = Puzzle.find_or_create_by(date:)

    if @puzzle.title ||= title_scraped
      post_message
      @puzzle.slack_url = save_permalink
      @puzzle.save
    else
      post_message("Title not found for day ##{@puzzle.date.day}", "#aoc-dev")
    end
  end

  private

  def client
    @client ||= Slack::Web::Client.new
  end

  def post_message(text = title, channel = ENV.fetch("SLACK_CHANNEL"))
    # https://api.slack.com/methods/chat.postMessage
    @message = client.chat_postMessage(as_user: true, channel:, text:)
  end

  def save_permalink
    # https://api.slack.com/methods/chat.getPermalink
    slack_thread = client.chat_getPermalink(
      channel: @message["channel"],
      message_ts: @message["message"]["ts"]
    )

    slack_thread[:permalink] || "https://lewagon-alumni.slack.com/archives/C02PN711H09/p1700598449505399"
  end

  def title_scraped
    @title_scraped ||= begin
      html = URI.parse(@puzzle.url).open
      doc = Nokogiri::HTML(html)
      titles = doc.css("h2").map(&:text)
      raw_title = titles.find { |title| title.match?(/--- Day \d+:/) }

      "`SPOILER` <#{@puzzle.url}|#{raw_title.gsub('---', '').strip}>" if raw_title.present?
    rescue OpenURI::HTTPError
      nil
    end
  end
end
