module Twterm
  class App
    include Singleton

    def initialize
      Config.load
      Auth.authenticate_user if Config[:screen_name].nil?

      Screen.instance

      client = Client.new(Config[:user_id], Config[:screen_name], Config[:access_token], Config[:access_token_secret])

      timeline = Tab::TimelineTab.new(client)
      TabManager.instance.add_and_show(timeline)

      mentions_tab = Tab::MentionsTab.new(client)
      TabManager.instance.add(mentions_tab)

      Screen.instance.refresh

      client.stream
      UserWindow.instance

      reset_interruption_handler
    end

    def run
      Screen.instance.wait
      Screen.instance.refresh
    end

    def register_interruption_handler(&block)
      fail ArgumentError, 'no block given' unless block_given?
      Signal.trap(:INT) do
        block.call
      end
    end

    def reset_interruption_handler
      Signal.trap(:INT) do
        exit
      end
    end
  end
end
