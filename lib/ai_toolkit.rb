# frozen_string_literal: true

require_relative "ai_toolkit/version"
require_relative "ai_toolkit/client"
require_relative "ai_toolkit/request_builder"
require_relative "ai_toolkit/response"
require_relative "ai_toolkit/results/result_item"
require_relative "ai_toolkit/results/tool_request"
require_relative "ai_toolkit/results/tool_response"
require_relative "ai_toolkit/results/message_result"
require_relative "ai_toolkit/results/unknown_result"
require_relative "ai_toolkit/tool"
require_relative "ai_toolkit/providers"

module AiToolkit
  class Error < StandardError; end
end
