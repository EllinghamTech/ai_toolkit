# frozen_string_literal: true

require "net/http"
require "json"

module AiToolkit
  module Providers
    # Provider for the Anthropic Claude API
    class Claude
      API_URL = "https://api.anthropic.com/v1/messages"

      def initialize(api_key:, model: "claude-3-opus-20240229")
        @api_key = api_key
        @model = model
      end

      # rubocop:disable Metrics/MethodLength
      def call(messages:, system_prompt:, tools: [])
        body = {
          model: @model,
          max_tokens: 1024,
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
