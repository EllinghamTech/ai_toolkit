# frozen_string_literal: true

require_relative "request_builder"
require_relative "response"

module AiToolkit
  # Client for performing AI requests through a provider
  class Client
    def initialize(provider)
      @provider = provider
    end

    # Perform a request with optional automatic tool usage
    # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
    def request(auto: false)
      builder = RequestBuilder.new
      yield builder

      messages = builder.messages.dup
      system_prompt = builder.system_prompt
      tools = builder.tools

      data = @provider.call(messages: messages, system_prompt: system_prompt, tools: tools)
      response = Response.new(data)

      if auto
        iterations = 0
        while response.stop_reason == "tool_use" && iterations < 5
          iterations += 1
          response.tool_uses.each do |tu|
            tool = builder.tool_objects[tu[:name]]
            next unless tool.respond_to?(:call)

            tool_message = tool.call(tu[:input])
            messages << { role: "tool", name: tu[:name], content: tool_message }
          end
          data = @provider.call(messages: messages, system_prompt: system_prompt, tools: tools)
          response = Response.new(data)
        end
      end

      response
    end
    # rubocop:enable Metrics/MethodLength, Metrics/AbcSize
  end
end
