# frozen_string_literal: true

module AiToolkit
  # Collection of Response objects returned from a Client request.
  # Provides aggregate usage stats and behaves like an Array.
  class ResponseCollection
    include Enumerable

    attr_reader :total_input_tokens, :total_output_tokens,
                :total_execution_time, :all_results

    # @param responses [Array<AiToolkit::Response>]
    def initialize(responses)
      @responses = responses
      @total_input_tokens = @responses.map(&:input_tokens).compact.sum
      @total_output_tokens = @responses.map(&:output_tokens).compact.sum
      @total_execution_time = @responses.map(&:execution_time).compact.sum
      @all_results = @responses.flat_map(&:results)
    end

    # Iterate over each response
    # @yieldparam response [AiToolkit::Response]
    def each(&block)
      @responses.each(&block)
    end

    # @return [AiToolkit::Response]
    def [](index)
      @responses[index]
    end

    # @return [AiToolkit::Response]
    def first
      @responses.first
    end

    # @return [AiToolkit::Response]
    def last
      @responses.last
    end

    # @return [Integer]
    def length
      @responses.length
    end
    alias size length
  end
end
