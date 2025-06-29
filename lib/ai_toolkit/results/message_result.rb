# frozen_string_literal: true

require_relative "result_item"

module AiToolkit
  module Results
    # Represents a normal message from the LLM.
    class MessageResult < ResultItem
      attr_reader :role, :content

      # @param role [String]
      # @param content [String]
      def initialize(role:, content:)
        super()
        @role = role
        @content = content
      end
    end
  end
end
