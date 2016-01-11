require 'twterm/user'
require 'twterm/utils'

module Twterm
  class DirectMessage
    attr_reader :id, :created_at, :recipient, :sender, :text

    @@instances = {}

    def initialize(message)
      @id = message.id
      update!(message)

      @@instances[id] = self
    end

    def ==(other)
      other.is_a?(self.class) && id == other.id
    end

    def update!(message)
      @created_at = message.created_at.dup.localtime
      @recipient = User.new(message.recipient)
      @sender = User.new(message.sender)
      @text = message.text

      self
    end

    class Conversation
      include Utils

      attr_reader :collocutor, :messages

      def initialize(collocutor)
        check_type User, collocutor

        @collocutor = collocutor
        @messages = []
      end

      def <<(message)
        @messages << message if messages.find { |m| m == message }.nil?
        @messages.sort_by!(&:created_at).reverse!

        self
      end

      def preview
        messages.sort_by(&:created_at).last.text.gsub("\n", ' ')
      end

      def updated_at
        updated_at = @messages.map(&:created_at).max

        format = Time.now - updated_at < 86_400 ? '%H:%M:%S' : '%Y-%m-%d %H:%M:%S'
        updated_at.strftime(format)
      end
    end
  end
end
