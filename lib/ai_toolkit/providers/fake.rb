# frozen_string_literal: true

require_relative "../response"
require_relative "../results/message_result"
require_relative "../results/tool_request"

module AiToolkit
  module Providers
    # Simple provider used in tests that returns predefined responses
    class Fake
      attr_reader :model

      # @param responses [Array<Hash, AiToolkit::Response>]
      # @param model [String]
      def initialize(responses, model: "fake")
        @responses = responses
        @index = 0
        @model = model
      end

      # Return the next response
      # @return [AiToolkit::Response]
      # rubocop:disable Lint/UnusedMethodArgument, Metrics/ParameterLists
      def call(messages: nil, system_prompt: nil, tools: nil, max_tokens: nil, tool_choice: nil,
               temperature: nil, top_k: nil, top_p: nil)
        start_time = Process.clock_gettime(Process::CLOCK_MONOTONIC)
        resp = @responses[@index]
        @index += 1 if @index < @responses.length - 1

        if resp.is_a?(AiToolkit::Response)
          resp.execution_time ||= Process.clock_gettime(Process::CLOCK_MONOTONIC) - start_time
          return resp
        end

        results = (resp[:messages] || []).map do |msg|
          Results::MessageResult.new(role: msg[:role], content: msg[:content])
        end
        (resp[:tool_uses] || []).each do |tu|
          results << Results::ToolRequest.new(id: tu[:id], name: tu[:name], input: tu[:input])
        end

        exec_time = Process.clock_gettime(Process::CLOCK_MONOTONIC) - start_time
        Response.new(resp, results: results, execution_time: exec_time)
      end
      # rubocop:enable Lint/UnusedMethodArgument, Metrics/ParameterLists
    end
  end
end
