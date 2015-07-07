module Twterm
  module Tab
    module New
      class Search
        include Base
        include Readline

        def ==(other)
          other.is_a?(self.class)
        end

        def initialize
          super

          @title = 'New tab'
        end

        def invoke_input
          resetter = proc do
            reset_prog_mode
            sleep 0.1
            Screen.instance.refresh
          end

          input_thread = Thread.new do
            close_screen
            CompletionManager.instance.set_default_mode!
            puts "\ninput search query"
            query = (readline('> ') || '').strip
            resetter.call

            tab = query.nil? || query.empty? ? Tab::New::Start.new : Tab::SearchTab.new(query)
            TabManager.instance.switch(tab)
          end

          App.instance.register_interruption_handler do
            input_thread.kill
            resetter.call
            tab = Tab::New::Start.new
            TabManager.instance.switch(tab)
          end

          input_thread.join
        end

        def respond_to_key(_)
          false
        end

        private

        def update; end
      end
    end
  end
end
