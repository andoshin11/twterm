require 'twterm/event/screen/resize'
require 'twterm/subscriber'

module Twterm
  class SearchQueryWindow
    include Curses
    include Singleton
    include Subscriber

    class CancelInput < StandardError; end

    attr_reader :last_query

    def initialize
      @window = stdscr.subwin(1, stdscr.maxx, stdscr.maxy - 1, 0)
      @searching_downward = true
      @str = ''
      @last_query = SearchQuery.new('')

      subscribe(Event::Screen::Resize, :resize)
    end

    def input
      @str = ''
      render_current_string

      Curses.timeout = 10
      raw

      chars = []

      loop do
        char = getch

        if char.nil?
          case chars.first
          when 3, 27 # cancel with <C-c> / Esc
            raise CancelInput
          when 4 # cancel with <C-d> when query is empty
            raise CancelInput if @str.empty?
          when 10 # submit with <C-j>
            @str = last_query.to_s if @str.empty?
            break
          when 127 # backspace
            raise CancelInput if @str.empty?

            @str.chop!
            render_current_string
          when 0..31
            # ignore control codes (\x00 - \x1f)
          else
            next if chars.empty?
            @str << chars
              .map { |x| x.is_a?(String) ? x.ord : x }
              .pack('c*')
              .force_encoding('utf-8')
            render_current_string
          end

          chars = []
        else
          chars << char
        end
      end

      @last_query = SearchQuery.new(@str) unless @str.empty?
      last_query
    rescue CancelInput
      @str = ''
      clear
    ensure
      Curses.timeout = -1
      cbreak
    end

    def clear
      window.clear
      window.refresh
    end

    def render_last_query
      render(last_query.query) unless last_query.empty?
    end

    def searching_backward!
      @searching_forward = false
    end

    def searching_backward?
      !@searching_forward
    end

    def searching_downward!
      @searching_downward = true
    end

    def searching_downward?
      @searching_downward
    end

    def searching_forward!
      @searching_forward = true
    end

    def searching_forward?
      @searching_forward
    end

    def searching_upward!
      @searching_downward = false
    end

    def searching_upward?
      !@searching_downward
    end

    private

    attr_reader :window

    def resize(event)
      window.resize(1, stdscr.maxx)
      window.move(stdscr.maxy - 1, 0)
    end

    def render(str)
      window.clear
      window.setpos(0, 0)
      window.addstr("#{symbol}#{str}")
      window.refresh
    end

    def render_current_string
      render(@str)
    end

    def symbol
      searching_downward? ^ searching_forward? ? '?' : '/'
    end
  end
end