#!/usr/bin/env ruby

require 'oauth'
require './auth'
require './config'
require './screen'
require './tweetbox'
require './notifier'
require './status'
require './client_manager'
require './user'
require './user_window'
require './extentions'
require './color_manager'
require './tab_manager'
require './tab/base'
require './tab/statuses_tab'
require './tab/timeline_tab'
require './tab/mentions_tab'
require './tab/user_tab'
require 'bundler'
Bundler.require

class App
  include Singleton

  def initialize
    Auth.authenticate_user if Config[:screen_name].nil?

    Screen.instance

    client = Client.create(Config[:access_token], Config[:access_token_secret])

    timeline = Tab::TimelineTab.new(client)
    timeline.connect_stream
    TabManager.instance.add_and_show(timeline)

    client.home.reverse.each do |status|
      TabManager.instance.current_tab.push(status)
    end
    TabManager.instance.current_tab.move_to_top

    mentions_tab = Tab::MentionsTab.new(client)
    mentions_tab.fetch
    TabManager.instance.add(mentions_tab)

    Notifier.instance.show_message ''
    UserWindow.instance

    reset_interruption_handler
  end

  def run
    t = Thread.new do
      loop do
        Screen.instance.wait
      end
    end
    t.join
  end

  def register_interruption_handler(&block)
    fail ArgumentError, 'no block given' unless block_given
    Signal.trap(:INT) do
      block.call
    end
  end

  def reset_interruption_handler
    Signal.trap(:INT) do
      exit
    end
  end
end

App.instance.run
