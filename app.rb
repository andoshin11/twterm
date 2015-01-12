#!/usr/bin/env ruby

require './auth'
require './config'
require './screen'
require './timeline'
require './tweetbox'
require './notifier'
require './status'
require './client_manager'
require './user'
require './user_window'
require './extentions'
require 'bundler'
Bundler.require

class App
  include Singleton

  def initialize
    @exit_enabled = true

    UserWindow.instance

    Twterm::Auth.authenticate_user if Twterm::Config[:screen_name].nil?

    client = Client.create(Twterm::Config[:access_token], Twterm::Config[:access_token_secret])

    client.home.reverse.each do |status|
      Timeline.instance.push(status)
    end
    Timeline.instance.move_to_top

    Notifier.instance.show_message ''

    client.stream(Timeline.instance)
  end

  def start
    t = Thread.new do
      loop do
        Screen.instance.wait
      end
    end
    t.join
  end

  def enable_exit
    @exit_enabled = true
  end

  def disable_exit
    @exit_enabled = false
  end

  def exit_enabled?
    @exit_enabled
  end

  def register_interruption_handler(&block)
    fail ArgumentError, 'Block must be passed' unless block_given?
    Signal.trap(:INT) do
      yield
    end
  end

  def reset_interruption_handler
    Signal.trap(:INT) do
      exit if App.instance.exit_enabled?
    end
  end
end

App.instance.reset_interruption_handler
App.instance.start
