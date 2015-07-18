module Twterm
  module Tab
    module Statuses
      class UserTimeline
        include Base
        include Dumpable

        attr_reader :user

        def ==(other)
          other.is_a?(self.class) && user == other.user
        end

        def close
          @auto_reloader.kill if @auto_reloader
          super
        end

        def dump
          @user.id
        end

        def fetch
          Client.current.user_timeline(@user.id) do |statuses|
            statuses.reverse.each(&method(:prepend))
            sort
            yield if block_given?
          end
        end

        def initialize(user_id)
          super()

          User.find_or_fetch(user_id) do |user|
            @user = user
            TabManager.instance.refresh_window

            fetch { scroller.move_to_top }
            @auto_reloader = Scheduler.new(120) { fetch }
          end
        end

        def title
          @user.nil? ? 'Loading...' : "@#{@user.screen_name} timeline"
        end
      end
    end
  end
end
