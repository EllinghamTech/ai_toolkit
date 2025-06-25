# frozen_string_literal: true

require_relative "request_builder"
require_relative "response"

module AiToolkit
  # Client for performing AI requests through a provider
  class Client
    # @param provider [#call]
    #   object that responds to `call`
    def initialize(provider)
      @provider = provider
    end

    # Perform a request with optional automatic tool usage
    # rubocop:disable Metrics/MethodLength, Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
    # @param auto [Boolean] whether to automatically use tools
    # @param max_tokens [Integer] maximum tokens allowed in the provider call
    # @param max_iterations [Integer] maximum tool iterations when auto mode is enabled
    # @param tool_choice [Hash, nil] tool selection sent to the provider
    # @yield [RequestBuilder] builder for the request
    # @return [Response]
    def request(auto: false, max_tokens: 1024, max_iterations: 5, tool_choice: nil)
      builder = RequestBuilder.new
      yield builder

      messages = builder.messages.dup
      system_prompt = builder.system_prompt
      tools = builder.tools

      data = @provider.call(
        messages: messages,
        system_prompt: system_prompt,
        tools: tools,
        max_tokens: max_tokens,
        tool_choice: tool_choice
      )
      response = Response.new(data)

      results = response.messages.map do |msg|
        Response::MessageResult.new(role: msg[:role], content: msg[:content])
      end

      if auto
        iterations = 0
        final_stop_reason = nil
        while response.stop_reason == "tool_use" && iterations < max_iterations
          iterations += 1
          stop_loop = false

          # rubocop:disable Metrics/BlockLength
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

            results << Response::ToolRequest.new(id: tu[:id], name: tu[:name], input: tu[:input])

            begin
              tool_message = tool.call(tu[:input])
            rescue StopToolLoop => e
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

            results << Response::ToolResponse.new(tool_use_id: tu[:id], content: tool_message)

            break if stop_loop
          end
          # rubocop:enable Metrics/BlockLength

          if stop_loop
            final_stop_reason = "tool_stop"
            break
          end

          data = @provider.call(
            messages: messages,
            system_prompt: system_prompt,
            tools: tools,
            max_tokens: max_tokens,
            tool_choice: tool_choice
          )

          response = Response.new(data)

          response.messages.each do |msg|
            results << Response::MessageResult.new(role: msg[:role], content: msg[:content])
          end
        end
      end

      unless response.tool_uses.empty? || final_stop_reason
        response.tool_uses.each do |tu|
          results << Response::ToolRequest.new(id: tu[:id], name: tu[:name], input: tu[:input])
        end
      end

      stop_reason = final_stop_reason || response.stop_reason
      Response.new({ stop_reason: stop_reason, messages: response.messages, tool_uses: response.tool_uses },
                   results: results)
    end
    # rubocop:enable Metrics/MethodLength, Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
  end
end
