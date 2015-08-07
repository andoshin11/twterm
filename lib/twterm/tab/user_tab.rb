module Twterm
  module Tab
    class UserTab
      include Base
      include Dumpable
      include Scrollable

      attr_reader :user_id

      def ==(other)
        other.is_a?(self.class) && user_id == other.user_id
      end

      def dump
        user_id
      end

      def drawable_item_count
        (window.maxy - 11 - bio_height).div(2)
      end

      def fetch
        update
      end

      def initialize(user_id)
        super()

        self.title = 'Loading...'.freeze
        @user_id = user_id

        User.find_or_fetch(user_id).then do |user|
          Client.current.lookup_friendships
          self.title = "@#{user.screen_name}"
        end
      end

      def items
        items = %i(
          open_timeline_tab
          show_friends
          show_followers
          show_favorites
        )
        items << :open_website  unless user.website.nil?
        items << :toggle_follow unless myself?
        items << :toggle_mute   unless myself?
        items << :toggle_block  unless myself?

        items
      end

      def respond_to_key(key)
        return true if scroller.respond_to_key(key)

        case key
        when ?F
          follow
        when 10
          perform_selected_action
        when ?t
          open_timeline_tab
        when ?W
          open_website
        else
          return false
        end

        true
      end

      private

      def bio_height
        320.div(window.maxx - 6) + 1
      end

      def block
        Client.current.block(user_id).then do |users|
          refresh

          user = users.first
          msg = "Blocked @#{user.screen_name}"
          Notifier.instance.show_message msg
        end
      end

      def blocking?
        user.blocked_by?(Client.current.user_id)
      end

      def follow
        Client.current.follow(user_id).then do |users|
          refresh

          user = users.first
          msg = "Followed @#{user.screen_name}"
          Notifier.instance.show_message msg
        end
      end

      def following?
        user.followed_by?(Client.current.user_id)
      end

      def followed?
        user.followed_by?(Client.current.user_id)
      end

      def mute
        Client.current.mute(user_id).then do |users|
          refresh

          user = users.first
          msg = "Muted @#{user.screen_name}"
          Notifier.instance.show_message msg
        end
      end

      def muting?
        user.muted_by?(Client.current.user_id)
      end

      def myself?
        user_id == Client.current.user_id
      end

      def open_timeline_tab
        tab = Tab::Statuses::UserTimeline.new(user_id)
        TabManager.instance.add_and_show(tab)
      end

      def open_website
        return if user.website.nil?

        Launchy.open(user.website)
      rescue Launchy::CommandNotFoundError
        Notifier.instance.show_error 'Browser not found'
      end

      def perform_selected_action
        case scroller.current_item
        when :open_timeline_tab
          open_timeline_tab
        when :open_website
          open_website
        when :show_favorites
          show_favorites
        when :show_followers
          show_followers
        when :show_friends
          show_friends
        when :toggle_block
          user.blocked_by?(Client.current.user_id) ? unblock : block
        when :toggle_follow
          user.followed_by?(Client.current.user_id) ? unfollow : follow
        when :toggle_mute
          user.muted_by?(Client.current.user_id) ? unmute : mute
        end
      end

      def show_favorites
        tab = Tab::Statuses::Favorites.new(user_id)
        TabManager.instance.add_and_show(tab)
      end

      def show_followers
        tab = Tab::Users::Followers.new(user_id)
        TabManager.instance.add_and_show(tab)
      end

      def show_friends
        tab = Tab::Users::Friends.new(user_id)
        TabManager.instance.add_and_show(tab)
      end

      def unblock
        Client.current.unblock(user_id).then do |users|
          refresh

          user = users.first
          msg = "Unblocked @#{user.screen_name}"
          Notifier.instance.show_message msg
        end
      end

      def unfollow
        Client.current.unfollow(user_id).then do |users|
          refresh

          user = users.first
          msg = "Unfollowed @#{user.screen_name}"
          Notifier.instance.show_message msg
        end
      end

      def unmute
        Client.current.unmute(user_id).then do |users|
          refresh

          user = users.first
          msg = "Unmuted @#{user.screen_name}"
          Notifier.instance.show_message msg
        end
      end

      def update
        if user.nil?
          User.find_or_fetch(user_id).then { update }
          return
        end

        window.setpos(2, 3)
        window.bold { window.addstr(user.name) }
        window.addstr(" (@#{user.screen_name})")

        window.with_color(:yellow) { window.addstr(' [protected]') } if user.protected?
        window.with_color(:cyan) { window.addstr(' [verified]') } if user.verified?

        window.setpos(5, 4)
        if myself?
          window.with_color(:yellow) { window.addstr(' [your account]') }
        else
          window.with_color(:green) { window.addstr(' [following]') } if following?
          window.with_color(:white) { window.addstr(' [not following]') } if !following? && !blocking?
          window.with_color(:cyan) { window.addstr(' [follows you]') } if followed?
          window.with_color(:red) { window.addstr(' [muting]') } if muting?
          window.with_color(:red) { window.addstr(' [blocking]') } if blocking?
        end

        user.description.split_by_width(window.maxx - 6).each.with_index(7) do |line, i|
          window.setpos(i, 5)
          window.addstr(line)
        end

        window.setpos(8 + bio_height, 5)
        window.addstr("Location: #{user.location}") unless user.location.nil?

        current_line = 11 + bio_height

        drawable_items.each.with_index(0) do |item, i|
          if scroller.current_item? i
            window.setpos(current_line, 3)
            window.with_color(:black, :magenta) { window.addch(' ') }
          end

          window.setpos(current_line, 5)
          case item
          when :toggle_block
            if blocking?
              window.addstr('    Unblock this user')
            else
              window.addstr('    Block this user')
            end
          when :toggle_follow
            if following?
              window.addstr('    Unfollow this user')
            else
              window.addstr('[ ] Follow this user')
              window.setpos(current_line, 6)
              window.bold { window.addch(?F) }
            end
          when :toggle_mute
            if muting?
              window.addstr('    Unmute this user')
            else
              window.addstr('    Mute this user')
            end
          when :open_timeline_tab
            window.addstr("[ ] #{user.statuses_count.format} tweets")
            window.setpos(current_line, 6)
            window.bold { window.addch(?t) }
          when :open_website
            window.addstr("[ ] Open website (#{user.website})")
            window.setpos(current_line, 6)
            window.bold { window.addch(?W) }
          when :show_favorites
            window.addstr("    #{user.favorites_count.format} favorites")
          when :show_followers
            window.addstr("    #{user.followers_count.format} followers")
          when :show_friends
            window.addstr("    #{user.friends_count.format} following")
          end

          current_line += 2
        end
      end

      def user
        User.find(user_id)
      end
    end
  end
end
