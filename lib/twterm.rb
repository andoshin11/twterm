$:.unshift(File.dirname(__FILE__)) unless
$:.include?(File.dirname(__FILE__)) || $:.include?(File.expand_path(File.dirname(__FILE__)))

require 'cgi'
require 'curses'
require 'forwardable'
require 'launchy'
require 'oauth'
require 'readline'
require 'singleton'
require 'set'
require 'twitter'
require 'twitter-text'
require 'yaml'

require 'twterm/app'
require 'twterm/auth'
require 'twterm/client'
require 'twterm/color_manager'
require 'twterm/completion_mamanger'
require 'twterm/config'
require 'twterm/extensions/curses/window'
require 'twterm/extensions/enumerator/lazy'
require 'twterm/extensions/integer'
require 'twterm/extensions/string'
require 'twterm/filter_query_window'
require 'twterm/filterable_list'
require 'twterm/friendship'
require 'twterm/history/base'
require 'twterm/history/hashtag'
require 'twterm/history/screen_name'
require 'twterm/list'
require 'twterm/notification/base'
require 'twterm/notification/message'
require 'twterm/notification/error'
require 'twterm/notifier'
require 'twterm/promise'
require 'twterm/screen'
require 'twterm/scheduler'
require 'twterm/status'
require 'twterm/tab_manager'
require 'twterm/tab/base'
require 'twterm/tab/dumpable'
require 'twterm/tab/exceptions'
require 'twterm/tab/scrollable'
require 'twterm/tab/key_assignments_cheatsheet'
require 'twterm/tab/new/start'
require 'twterm/tab/new/list'
require 'twterm/tab/new/search'
require 'twterm/tab/new/user'
require 'twterm/tab/statuses/base'
require 'twterm/tab/statuses/conversation'
require 'twterm/tab/statuses/favorites'
require 'twterm/tab/statuses/home'
require 'twterm/tab/statuses/list_timeline'
require 'twterm/tab/statuses/mentions'
require 'twterm/tab/statuses/search'
require 'twterm/tab/statuses/user_timeline'
require 'twterm/tab/user_tab'
require 'twterm/tab/users/base'
require 'twterm/tab/users/followers'
require 'twterm/tab/users/friends'
require 'twterm/tweetbox'
require 'twterm/user'
require 'twterm/version'

module Twterm
  class Conf
    REQUIRE_VERSION = '1.1.0.beta1'
  end
end
