require 'bundler'
Bundler.require

class Client
  private_class_method :new

  def initialize(token, secret)
    @rest_client = Twitter::REST::Client.new do |config|
      config.consumer_key        = 'vLNSVFgXclBJQJRZ7VLMxL9lA'
      config.consumer_secret     = 'OFLKzrepRG2p1hq0nUB9j2S9ndFQoNTPheTpmOY0GYw55jGgS5'
      config.access_token        = token
      config.access_token_secret = secret
    end

    TweetStream.configure do |config|
      config.consumer_key       = 'vLNSVFgXclBJQJRZ7VLMxL9lA'
      config.consumer_secret    = 'OFLKzrepRG2p1hq0nUB9j2S9ndFQoNTPheTpmOY0GYw55jGgS5'
      config.oauth_token        = token
      config.oauth_token_secret = secret
      config.auth_method        = :oauth
    end

    @stream_client = TweetStream::Client.new
  end

  def stream(timeline)
    @stream_client.on_timeline_status do |status|
      timeline.push(Status.new(status))
    end

    @stream_client.on_delete do |status_id|
      timeline.delete_status(status_id)
    end

    @stream_client.on_event(:favorite) do |event|
      message = "@#{event[:source][:screen_name]} has favorited your tweet: #{event[:target_object][:text]}"
      Notifier.instance.show_message(message)
    end

    Thread.new do
      @stream_client.userstream
    end
  end

  def post(text, in_reply_to = nil)
    Thread.new do
      if in_reply_to.is_a? Status
        text = "@#{in_reply_to.user.screen_name} #{text}"
        @rest_client.update(text, in_reply_to_status_id: in_reply_to.id)
      else
        @rest_client.update(text)
      end
    end
  end

  def home
    @rest_client.home_timeline.map do |tweet|
      Status.new(tweet)
    end
  end

  def mentions
    @rest_client.mentions.map do |tweet|
      Status.new(tweet)
    end
  end

  def user_timeline(user_id)
    @rest_client.user_timeline(user_id).map do |tweet|
      Status.new(tweet)
    end
  end

  def favorite(status, &block)
    return false unless status.is_a? Status

    Thread.new do
      @rest_client.favorite(status.id)
      status.favorite!
      yield status if block_given?
    end
  end

  def unfavorite(status)
    fail ArgumentError, 'no status given' unless status.is_a? Status

    Thread.new do
      @rest_client.unfavorite(status.id)
      status.unfavorite!
      yield status if block_given?
    end
  end

  def retweet(status, &block)
    return false unless status.is_a? Status

    Thread.new do
      begin
        @rest_client.retweet!(status.id)
        status.retweet!
        yield status if block_given?
      rescue Twitter::Error::AlreadyRetweeted, Twitter::Error::NotFound
        Notifier.instance.show_error 'Retweet attempt failed'
      end
    end
  end

  def self.create(token, secret)
    client = new(token, secret)
    ClientManager.instance.push(client)
    client
  end
end
