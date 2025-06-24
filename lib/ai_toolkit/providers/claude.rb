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

      # rubocop:disable Metrics/MethodLength
      # Perform the request
      # @param messages [Array<Hash>]
      # @param system_prompt [String]
      # @param tools [Array<Hash>]
      # @return [Hash]
      def call(messages:, system_prompt:, tools: [], max_tokens: 1024)
        body = {
          model: @model,
          max_tokens: max_tokens,
          system: system_prompt,
          messages: messages,
          tools: tools
        }
        uri = URI(API_URL)
        req = Net::HTTP::Post.new(uri)
        req["x-api-key"] = @api_key
        req["anthropic-version"] = "2023-06-01"
        req["content-type"] = "application/json"
        req.body = JSON.dump(body)
        res = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do |http|
          http.request(req)
        end
        JSON.parse(res.body, symbolize_names: true)
      end
      # rubocop:enable Metrics/MethodLength
    end
  end
end
