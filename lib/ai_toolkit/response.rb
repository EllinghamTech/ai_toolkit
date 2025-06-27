# frozen_string_literal: true

require_relative "results/result_item"
require_relative "results/tool_request"
require_relative "results/tool_response"
require_relative "results/message_result"

module AiToolkit
  # Structured response returned from the provider
  class Response
    attr_reader :stop_reason, :messages, :tool_uses
    attr_accessor :results, :execution_time

    # @param data [Hash]
    #   raw response data
    # @param results [Array<Results::ResultItem>]
    #   ordered list of results from all requests
    # @param [Object] execution_time
    def initialize(data, results: [], execution_time: nil)
      @stop_reason = data[:stop_reason]
      @messages = data[:messages] || []
      @tool_uses = data[:tool_uses] || []
      @results = results
      @execution_time = execution_time
    end
  end
end
