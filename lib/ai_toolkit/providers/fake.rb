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
      # rubocop:disable Lint/UnusedMethodArgument, Metrics/ParameterLists
      def call(messages: nil, system_prompt: nil, tools: nil, max_tokens: nil, tool_choice: nil,
               temperature: nil, top_k: nil, top_p: nil)
        resp = @responses[@index]
        @index += 1 if @index < @responses.length - 1
        resp
      end
      # rubocop:enable Lint/UnusedMethodArgument, Metrics/ParameterLists
    end
  end
end
