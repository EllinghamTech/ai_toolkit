# frozen_string_literal: true

module AiToolkit
  module Providers
    # Simple provider used in tests that returns predefined responses
    class Fake
      # @param responses [Array<Hash>]
      def initialize(responses)
        @responses = responses
        @index = 0
      end

      # Return the next response
      # @return [Hash]
      def call(messages: nil, system_prompt: nil, tools: nil, max_tokens: nil, tool_choice: nil) # rubocop:disable Lint/UnusedMethodArgument
        resp = @responses[@index]
        @index += 1 if @index < @responses.length - 1
        resp
      end
    end
  end
end
