# frozen_string_literal: true

begin
  require "aws-sdk-bedrockruntime"
rescue LoadError
  # aws-sdk-bedrockruntime is optional
end
require "json"

module AiToolkit
  module Providers
    # Provider for Anthropic models via AWS Bedrock
    class Bedrock
      # @param model_id [String]
      # @param client [Aws::BedrockRuntime::Client, nil]
      def initialize(model_id:, client: nil)
        @client = client || Aws::BedrockRuntime::Client.new
        @model_id = model_id
      end

      # rubocop:disable Metrics/MethodLength
      # Perform the request
      # @param messages [Array<Hash>]
      # @param system_prompt [String]
      # @param tools [Array<Hash>]
      # @param max_tokens [Integer]
      #   maximum tokens allowed in the request
      # @return [Hash]
      def call(messages:, system_prompt:, tools: [], max_tokens: 1024)
        body = {
          anthropic_version: "bedrock-2023-05-31",
          messages: messages,
          tools: tools,
          max_tokens: max_tokens
        }
        body[:system] = system_prompt if system_prompt
        resp = @client.invoke_model(
          body: JSON.dump(body),
          model_id: @model_id,
          accept: "application/json",
          content_type: "application/json"
        )
        raw = JSON.parse(resp.body.string, symbolize_names: true)
        format_response(raw)
      end
      # rubocop:enable Metrics/MethodLength

      private

      # Convert the API response to the common format
      # rubocop:disable Metrics/MethodLength, Metrics/AbcSize, Metrics/CyclomaticComplexity
      # @param data [Hash]
      # @return [Hash]
      def format_response(data)
        out = { stop_reason: data[:stop_reason], messages: [], tool_uses: [] }
        if data[:messages]
          out[:messages] = data[:messages]
          if data[:tool_uses]
            out[:tool_uses] = data[:tool_uses]
          else
            data[:messages].each do |m|
              next unless m[:tool_use]

              tu = m[:tool_use]
              out[:tool_uses] << { id: tu[:id], name: tu[:name], input: tu[:input] }
            end
          end
        elsif data[:content]
          data[:content].each do |item|
            case item[:type]
            when "text"
              out[:messages] << { role: data[:role] || "assistant", content: item[:text] }
            when "tool_use"
              out[:tool_uses] << { id: item[:id], name: item[:name], input: item[:input] }
            end
          end
        end
        out
      end
      # rubocop:enable Metrics/MethodLength, Metrics/AbcSize, Metrics/CyclomaticComplexity
    end
  end
end
