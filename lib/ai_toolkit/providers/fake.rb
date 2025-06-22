# frozen_string_literal: true

module AiToolkit
  module Providers
    # Simple provider used in tests that returns predefined responses
    class Fake
      def initialize(responses)
        @responses = responses
        @index = 0
      end

      def call(messages: nil, system_prompt: nil, tools: nil) # rubocop:disable Lint/UnusedMethodArgument
        resp = @responses[@index]
        @index += 1 if @index < @responses.length - 1
        resp
      end
    end
  end
end
