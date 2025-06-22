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
      def initialize(model_id:, client: nil)
        @client = client || Aws::BedrockRuntime::Client.new
        @model_id = model_id
      end

      # rubocop:disable Metrics/MethodLength
      def call(messages:, system_prompt:, tools: [])
        body = {
          anthropic_version: "bedrock-2023-05-31",
          system: system_prompt,
          messages: messages,
          tools: tools,
          max_tokens: 1024
        }
        resp = @client.invoke_model(
          body: JSON.dump(body),
          model_id: @model_id,
          accept: "application/json",
          content_type: "application/json"
        )
        JSON.parse(resp.body.string, symbolize_names: true)
      end
      # rubocop:enable Metrics/MethodLength
    end
  end
end
