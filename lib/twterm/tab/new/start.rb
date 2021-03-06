require 'twterm/tab/base'
require 'twterm/tab/direct_message/conversation_list'

module Twterm
  module Tab
    module New
      class Start < Base
        include Scrollable

        def ==(other)
          other.is_a?(self.class)
        end

        def drawable_item_count
          (window.maxy - 1).div(2)
        end

        def items
          %i(
            direct_messages
            list_tab
            search_tab
            user_tab
            key_assignments_cheatsheet
          ).freeze
        end

        def initialize
          super
          refresh
        end

        def respond_to_key(key)
          return true if scroller.respond_to_key(key)

          case key
          when 'D'
            open_direct_messages
          when 10
            perform_selected_action
          when 'L'
            open_list_tab
          when 'S'
            open_search_tab
          when 'U'
            open_user_tab
          else
            return false
          end
          true
        end

        def title
          'New tab'.freeze
        end

        private

        def open_direct_messages
          switch(Tab::DirectMessage::ConversationList.new)
        end

        def open_list_tab
          switch(Tab::New::List.new)
        end

        def open_search_tab
          switch(Tab::New::Search.new)
        end

        def open_user_tab
          tab = Tab::New::User.new
          switch(tab)
          tab.invoke_input
        end

        def open_key_assignments_cheatsheet
          switch(Tab::KeyAssignmentsCheatsheet.new)
        end

        def perform_selected_action
          case current_item
          when :direct_messages
            open_direct_messages
          when :list_tab
            open_list_tab
          when :search_tab
            open_search_tab
          when :user_tab
            open_user_tab
          when :key_assignments_cheatsheet
            open_key_assignments_cheatsheet
          end
        end

        def switch(tab)
          TabManager.instance.switch(tab)
        end

        def update
          window.setpos(2, 3)
          window.bold { window.addstr('Open new tab') }

          drawable_items.each.with_index(0) do |item, i|
            line = 4 + i * 2
            window.setpos(line, 5)

            case item
            when :direct_messages
              window.addstr('[D] Direct messages')
              window.setpos(line, 6)
              window.bold { window.addch(?D) }
            when :list_tab
              window.addstr('[L] List tab')
              window.setpos(line, 6)
              window.bold { window.addch(?L) }
            when :search_tab
              window.addstr('[S] Search tab')
              window.setpos(line, 6)
              window.bold { window.addch(?S) }
            when :user_tab
              window.addstr('[U] User tab')
              window.setpos(line, 6)
              window.bold { window.addch(?U) }
            when :key_assignments_cheatsheet
              window.addstr('[?] Key assignments cheatsheet')
              window.setpos(line, 6)
              window.bold { window.addch(??) }
            end

            window.with_color(:black, :magenta) do
              window.setpos(line, 3)
              window.addch(' ')
            end if scroller.current_item?(i)
          end
        end
      end
    end
  end
end
