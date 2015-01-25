module Tab
  module StatusesTab
    include Base
    include Scrollable

    def initialize
      super

      @statuses = []
    end

    def push(status)
      fail unless status.is_a? Status

      @statuses << status
      status.split(@window.maxx - 4)
      refresh
    end

    def reply
      Notifier.instance.show_message "Reply to @#{highlighted_status.user.screen_name}"
      Tweetbox.instance.compose(highlighted_status)
    end

    def favorite
      if highlighted_status.favorited?
        ClientManager.instance.current.unfavorite(highlighted_status) do
          refresh
        end
      else
        ClientManager.instance.current.favorite(highlighted_status) do
          refresh
        end
      end
    end

    def retweet
      ClientManager.instance.current.retweet(highlighted_status) do
        refresh
      end
    end

    def delete_status(status_id)
      @statuses.delete_if do |status|
        status.id == status_id
      end
      refresh
    end

    def show_user
      user = highlighted_status.user
      user_tab = Tab::UserTab.new(user)
      TabManager.instance.add_and_show(user_tab)
    end

    def update
      current_line = 0

      @window.clear

      @statuses.reverse.drop(offset).each.with_index(offset) do |status, i|
        formatted_lines = status.split(@window.maxx - 4).count
        if current_line + formatted_lines + 3 > @window.maxy
          @last = i
          break
        end

        posy = current_line

        if index == i
          @window.with_color(:black, :magenta) do
            (formatted_lines + 1).times do |j|
              @window.setpos(posy + j, 0)
              @window.addch(' ')
            end
          end
        end

        @window.setpos(current_line, 2)

        @window.bold do
          @window.addstr(status.user.name)
        end

        @window.addstr(" (@#{status.user.screen_name}) [#{status.date}] ")

        if status.favorited?
          @window.with_color(:black, :yellow) do
            @window.addch(' ')
          end

          @window.addch(' ')
        end

        if status.retweeted?
          @window.with_color(:black, :green) do
            @window.addch(' ')
          end
          @window.addch(' ')
        end

        if status.favorite_count > 0
          @window.with_color(:yellow) do
            @window.addstr("#{status.favorite_count}fav#{status.favorite_count > 1 ? 's' : ''}")
          end
          @window.addch(' ')
        end

        if status.retweet_count > 0
          @window.with_color(:green) do
            @window.addstr("#{status.retweet_count}RT#{status.retweet_count > 1 ? 's' : ''}")
          end
          @window.addch(' ')
        end

        status.split(@window.maxx - 4).each do |line|
          current_line += 1
          @window.setpos(current_line, 2)
          @window.addstr(line)
        end

        current_line += 2
      end

      draw_scroll_bar

      @window.refresh

      UserWindow.instance.update(highlighted_status.user) unless highlighted_status.nil?
      show_help
    end

    def respond_to_key(key)
      return true if super

      case key
      when 'f'
        favorite
      when 'r'
        reply
      when 'R'
        retweet
      when 'u'
        show_user
      else
        return false
      end
      true
    end

    private

    def highlighted_status
      @statuses[count - index - 1]
    end

    def count
      @statuses.count
    end

    def offset_from_bottom
      return @offset_from_bottom unless @offset_from_bottom.nil?

      height = 0
      @statuses.each.with_index(-1) do |status, i|
        height += status.split(@window.maxx - 4).count + 2
        if height >= @window.maxy
          @offset_from_bottom = i
          return i
        end
      end
    end

    def show_help
      Notifier.instance.show_help '[n] Compose  [r] Reply  [f] Favorite  [R] Retweet  [u] Show user  [w] Close tab  [q] Quit'
    end
  end
end
