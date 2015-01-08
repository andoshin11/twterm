require 'singleton'
require 'bundler'
Bundler.require

class Screen
  include Singleton
  include Curses

  def initialize
    @screen = init_screen
    noecho
    cbreak
    curs_set(0)
    stdscr.keypad(true)

    start_color
    init_pair 1, COLOR_WHITE, COLOR_CYAN
    init_pair 2, COLOR_BLACK, COLOR_GREEN
    init_pair 3, COLOR_BLACK, COLOR_YELLOW
    init_pair 4, COLOR_GREEN, COLOR_BLACK
    init_pair 5, COLOR_WHITE, COLOR_MAGENTA
  end

  def wait
    case getch
    when 'f'
      Timeline.instance.favorite
    when 'g', Key::HOME
      Timeline.instance.move_to_top
    when 'G', Key::END
      Timeline.instance.move_to_bottom
    when 'j', 14, Key::DOWN
      Timeline.instance.move_down
    when 'k', 16, Key::UP
      Timeline.instance.move_up
    when 'n'
      Notifier.instance.show_message 'Compose new tweet'
      Tweetbox.instance.compose
      return
    when 'q'
      exit
    when 'r'
      Timeline.instance.reply
    when 'u'
      # show user
    when 4
      Timeline.instance.move_down(10)
    when 21
      Timeline.instance.move_up(10)
    when '/'
      # filter
    else
    end
  end
end
