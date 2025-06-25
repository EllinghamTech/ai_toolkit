# frozen_string_literal: true

require "net/http"
require "json"

module AiToolkit
  module Providers
    # Provider for the Anthropic Claude API
    class Claude
      API_URL = "https://api.anthropic.com/v1/messages"

      # @param api_key [String]
      # @param model [String]
      def initialize(api_key:, model: "claude-3-opus-20240229")
        @api_key = api_key
        @model = model
      end

      # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
      # Perform the request
      # @param messages [Array<Hash>]
      # @param system_prompt [String]
      # @param tools [Array<Hash>]
      # @param max_tokens [Integer]
      #   maximum tokens allowed in the request
      # @param tool_choice [Hash, nil]
      #   optional tool selection
      # @return [Hash]
      def call(messages:, system_prompt:, tools: [], max_tokens: 1024, tool_choice: nil)
        body = {
          model: @model,
          max_tokens: max_tokens,
          messages: messages,
          tools: tools
        }
        body[:tool_choice] = tool_choice if tool_choice
        body[:system] = system_prompt if system_prompt
        uri = URI(API_URL)
        req = Net::HTTP::Post.new(uri)
        req["x-api-key"] = @api_key
        req["anthropic-version"] = "2023-06-01"
        req["content-type"] = "application/json"
        req.body = JSON.dump(body)

        res = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do |http|
          http.request(req)
        end

        raw = JSON.parse(res.body, symbolize_names: true)
        format_response(raw)
      end
      # rubocop:enable Metrics/MethodLength, Metrics/AbcSize

      private

      # Convert the API response to the common format
      # rubocop:disable Metrics/MethodLength, Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
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
      # rubocop:enable Metrics/MethodLength, Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
    end
  end
end
