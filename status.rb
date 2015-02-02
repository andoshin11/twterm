require 'time'

class Status
  attr_reader :id, :text, :created_at, :retweet_count, :favorite_count, :in_reply_to_status_id, :favorited, :retweeted, :user, :retweeted_by, :urls, :media
  alias_method :favorited?, :favorited
  alias_method :retweeted?, :retweeted

  @@instances = []

  def self.new(tweet)
    @@instances.each do |instance|
      next unless instance.id == tweet.id
      return instance.update!(tweet)
    end
    super
  end

  def initialize(tweet)
    unless tweet.retweeted_status.is_a? Twitter::NullObject
      @retweeted_by = User.new(tweet.user)
      tweet = tweet.retweeted_status
    end

    @id = tweet.id
    @text = CGI.unescapeHTML(tweet.full_text.dup)
    @created_at = (tweet.created_at.is_a?(String) ? Time.parse(tweet.created_at) : tweet.created_at.dup).localtime
    @retweet_count = tweet.retweet_count
    @favorite_count = tweet.favorite_count
    @in_reply_to_status_id = tweet.in_reply_to_status_id

    @retweeted = tweet.retweeted?
    @favorited = tweet.favorited?

    @media = tweet.media
    @urls = tweet.urls

    @user = User.new(tweet.user)

    @splitted_text = {}

    expand_url!

    @@instances << self
  end

  def update!(tweet)
    @retweet_count = tweet.retweet_count
    @favorite_count = tweet.favorite_count
    @retweeted = tweet.retweeted?
    @favorited = tweet.favorited?
    self
  end

  def date
    format = Time.now - @created_at < 86_400 ? '%H:%M:%S' : '%Y-%m-%d %H:%M:%S'
    @created_at.strftime(format)
  end

  def expand_url!
    @media.each { |medium| @text.sub!(medium.url, medium.display_url) }
    @urls.each { |url| @text.sub!(url.url, url.display_url) }
  end

  def favorite!
    @favorited = true
  end

  def unfavorite!
    @favorited = false
  end

  def retweet!
    @retweeted = true
  end

  def split(width)
    @splitted_text[:width] ||= @text.split_by_width(width)
  end

  def ==(other)
    return false unless other.is_a? Status
    id == other.id
  end
end
