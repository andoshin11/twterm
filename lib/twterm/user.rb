module Twterm
  class User
    attr_reader :blocking, :color, :description, :followed, :followers_count,
                :following, :friends_count, :id, :location, :muting, :name,
                :protected, :screen_name, :statuses_count, :touched_at,
                :verified, :website
    alias_method :blocking?, :blocking
    alias_method :followed?, :followed
    alias_method :following?, :following
    alias_method :muting?, :muting
    alias_method :protected?, :protected
    alias_method :verified?, :verified

    MAX_CACHED_TIME = 3600
    COLORS = [:red, :blue, :green, :cyan, :yellow, :magenta]

    @@instances = {}

    def block!
      @blocking = true
      self
    end

    def follow!
      @following = true
      self
    end

    def followed!
      @followed = true
      self
    end

    def initialize(user)
      @id = user.id
      update!(user)
      @color = COLORS[@id % 6]
      touch!

      @@instances[@id] = self
    end

    def matches?(query)
      [name, screen_name, description, website].any? { |x| x.to_s.downcase.include? query.downcase }
    end

    def mute!
      @muting = true
      self
    end

    def touch!
      @touched_at = Time.now
    end

    def unblock!
      @blocking = false
      self
    end

    def unfollow!
      @following = false
      self
    end

    def unfollowed!
      @followed = false
      self
    end

    def unmute!
      @muting = false
      self
    end

    def update!(user)
      @name = user.name
      @screen_name = user.screen_name
      @description = user.description || ''
      @location = user.location.is_a?(Twitter::NullObject) ? '' : user.location
      @website = user.website
      @following = user.following?
      @protected = user.protected?
      @statuses_count = user.statuses_count
      @friends_count = user.friends_count
      @followers_count = user.followers_count
      @verified = user.verified?

      History::ScreenName.instance.add(user.screen_name)

      self
    end

    def self.all
      @@instances.values
    end

    def self.find(id)
      @@instances[id]
    end

    def self.find_or_fetch(id)
      Promise.new do |resolve, reject|
        instance = find(id)
        (resolve.(instance) && next) if instance

        Client.current.show_user(id).then do |user|
          resolve.(user)
        end
      end
    end

    def self.cleanup
      referenced_users = Status.all.map(&:user)
      referenced_users.each(&:touch!)

      cond = -> (user) { user.touched_at > Time.now - MAX_CACHED_TIME }
      users = all.select(&cond)
      user_ids = users.map(&:id)
      @@instances = user_ids.zip(users).to_h
    end

    def self.new(user)
      instance = find(user.id)
      instance.nil? ? super : instance.update!(user)
    end
  end
end
