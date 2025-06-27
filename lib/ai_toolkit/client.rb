# frozen_string_literal: true

require_relative "request_builder"
require_relative "response"

module AiToolkit
  # Client for performing AI requests through a provider
  # rubocop:disable Metrics/ClassLength
  class Client
    # @param provider [#call]
    #   object that responds to `call`
    def initialize(provider)
      @provider = provider
    end

    # Register or retrieve a before request hook
    #
    # The block receives the request Hash as its first argument and may mutate
    # it before it is sent to the provider. The model and provider names are
    # yielded via keyword arguments.
    #
    # @yieldparam req [Hash] request parameters
    # @yieldparam model [String, nil] model name
    # @yieldparam provider [String] provider name
    # @return [Proc, nil]
    def before_request(&block)
      @before_request = block if block_given?
      @before_request
    end

    # Register or retrieve an after request hook
    #
    # The block receives the request Hash and raw response data. Errors raised
    # inside the block are caught and will stop the auto loop but still return
    # the current response.
    #
    # @yieldparam req [Hash] request parameters
    # @yieldparam res [Hash] raw response
    # @yieldparam model [String, nil] model name
    # @yieldparam provider [String] provider name
    # @return [Proc, nil]
    def after_request(&block)
      @after_request = block if block_given?
      @after_request
    end

    # Perform a request with optional automatic tool usage
    # rubocop:disable Metrics/MethodLength, Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
    # @param auto [Boolean] whether to automatically use tools
    # @param max_tokens [Integer] maximum tokens allowed in the provider call
    # @param max_iterations [Integer] maximum tool iterations when auto mode is enabled
    # @param tool_choice [Hash, nil] tool selection sent to the provider
    # @yield [RequestBuilder] builder for the request
    # @param temperature [Float, nil] randomness of generation
    # @param top_k [Integer, nil] candidates considered at each step
    # @param top_p [Float, nil] probability mass for nucleus sampling
    # @return [Array<Response>]
    # rubocop:disable Metrics/ParameterLists
    def request(auto: false, max_tokens: 1024, max_iterations: 5, tool_choice: nil,
                temperature: nil, top_k: nil, top_p: nil)
      builder = RequestBuilder.new
      yield builder

      messages = builder.messages.dup
      system_prompt = builder.system_prompt
      tools = builder.tools

      response, hook_err = perform_call(
        messages: messages,
        system_prompt: system_prompt,
        tools: tools,
        max_tokens: max_tokens,
        tool_choice: tool_choice,
        temperature: temperature,
        top_k: top_k,
        top_p: top_p
      )
      responses = [response]

      if auto && !hook_err
        iterations = 0
        while %w[tool_use pause_turn].include?(response.stop_reason) && iterations < max_iterations
          iterations += 1
          stop_loop = false

          response.tool_uses.each do |tu|
            tool = builder.tool_objects[tu[:name]]

            messages << {
              role: "assistant",
              content: [
                {
                  type: "tool_use",
                  id: tu[:id],
                  name: tu[:name],
                  input: tu[:input]
                }
              ]
            }

            begin
              tool_message = tool.call(tu[:input])
            rescue StopToolLoop => e
              # Tool requests termination of the auto loop.
              tool_message = e.message
              stop_loop = true
            end
            messages << {
              role: "user",
              content: [
                {
                  type: "tool_result",
                  tool_use_id: tu[:id],
                  content: tool_message
                }
              ]
            }
            response.results << Results::ToolResponse.new(tool_use_id: tu[:id], content: tool_message)

            break if stop_loop
          end

          if stop_loop
            response = Response.new({ stop_reason: "tool_stop", messages: [], tool_uses: [] }, results: [])
            responses << response
            break
          end

          response, hook_err = perform_call(
            messages: messages,
            system_prompt: system_prompt,
            tools: tools,
            max_tokens: max_tokens,
            tool_choice: tool_choice,
            temperature: temperature,
            top_k: top_k,
            top_p: top_p
          )
          responses << response
          break if hook_err
        end
      end
      responses
    end
    # rubocop:enable Metrics/MethodLength, Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity, Metrics/ParameterLists

    private

    # Build request Hash, invoke hooks and provider
    # @param args [Hash] parameters for provider
    # @return [Array(Response, Boolean)] response object and hook error flag
    def perform_call(**args)
      @before_request&.call(args, model: model_name, provider: provider_name)
      data = @provider.call(**args)
      hook_err = false
      begin
        @after_request&.call(args, data, model: model_name, provider: provider_name)
      rescue StandardError
        hook_err = true
      end
      [data, hook_err]
    end

    # @return [String]
    def provider_name
      @provider.class.name
    end

    # Attempt to fetch a model identifier from the provider
    # @return [String, nil]
    def model_name
      if @provider.respond_to?(:model)
        @provider.model
      elsif @provider.respond_to?(:model_id)
        @provider.model_id
      elsif @provider.respond_to?(:model_name)
        @provider.model_name
      end
    end
  end
end
# rubocop:enable Metrics/ClassLength
