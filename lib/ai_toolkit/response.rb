# frozen_string_literal: true

require_relative "results/result_item"
require_relative "results/tool_request"
require_relative "results/tool_response"
require_relative "results/message_result"

module AiToolkit
  # Structured response returned from the provider
  class Response
    attr_reader :stop_reason, :messages, :tool_uses
    attr_accessor :results, :execution_time, :input_tokens, :output_tokens

    # @param data [Hash]
    #   raw response data
    # @param results [Array<Results::ResultItem>]
    #   ordered list of results from all requests
    # @param [Object] execution_time
    # @param [Object] input_tokens
    # @param [Object] output_tokens
    def initialize(data, results: [], execution_time: nil, input_tokens: nil, output_tokens: nil)
      @stop_reason = data[:stop_reason]
      @messages = data[:messages] || []
      @tool_uses = data[:tool_uses] || []
      @results = results
      @execution_time = execution_time
      @input_tokens = input_tokens || data[:input_tokens]
      @output_tokens = output_tokens || data[:output_tokens]
    end
  end
end
