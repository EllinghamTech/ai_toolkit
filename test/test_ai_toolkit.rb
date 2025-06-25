# frozen_string_literal: true

require "test_helper"

# rubocop:disable Metrics/ClassLength
class TestAiToolkit < Minitest::Test
  class EchoTool < AiToolkit::Tool
    input_schema(
      {
        type: "object",
        properties: { text: { type: "string" } },
        required: ["text"]
      }
    )

    # @return [String]
    def name
      "echo"
    end

    # @return [String]
    def description
      "Echoes the provided text back"
    end

    # @param params [Hash]
    # @return [String]
    def perform(params)
      params[:text]
    end
  end

  class CaptureProvider
    attr_reader :last_args

    # @param response [Hash]
    #   canned response to return
    def initialize(response)
      @response = response
    end

    # Capture arguments and return the canned response.
    # @param args [Hash]
    #   arguments passed from the client
    # @return [Hash]
    def call(**args)
      @last_args = args
      @response
    end
  end

  # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
  # Test simple request
  # @return [void]
  def test_request_returns_response
    provider = AiToolkit::Providers::Fake.new([
                                                { stop_reason: "end_turn",
                                                  messages: [{ role: "assistant", content: "hi" }] }
                                              ])
    client = AiToolkit::Client.new(provider)

    resp = client.request do |c|
      c.system_prompt "Hello"
      c.message :user, "hi"
      c.tool :echo, {}
    end

    assert_equal "end_turn", resp.stop_reason
    assert_equal "hi", resp.messages.first[:content]
    assert_equal 1, resp.results.length
    assert_instance_of AiToolkit::MessageResult, resp.results.first
  end
  # rubocop:enable Metrics/MethodLength, Metrics/AbcSize

  # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
  # Test auto tool loop
  # @return [void]
  def test_auto_tool_loop
    provider = AiToolkit::Providers::Fake.new([
                                                { stop_reason: "tool_use",
                                                  tool_uses: [{ name: "echo", input: "world" }] },
                                                { stop_reason: "end_turn",
                                                  messages: [{ role: "assistant", content: "done" }] }
                                              ])
    client = AiToolkit::Client.new(provider)

    resp = client.request(auto: true) do |c|
      c.message :user, "start"
      c.tool EchoTool.new
    end

    assert_equal "end_turn", resp.stop_reason
    assert_equal "done", resp.messages.first[:content]
    assert_equal 3, resp.results.length
    assert_instance_of AiToolkit::ToolRequest, resp.results[0]
    assert_instance_of AiToolkit::ToolResponse, resp.results[1]
    assert_instance_of AiToolkit::MessageResult, resp.results[2]
  end
  # rubocop:enable Metrics/MethodLength, Metrics/AbcSize

  # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
  # @return [void]
  def test_max_iterations_limit
    provider = AiToolkit::Providers::Fake.new([
                                                { stop_reason: "tool_use",
                                                  tool_uses: [{ name: "echo", input: "one" }] },
                                                { stop_reason: "tool_use",
                                                  tool_uses: [{ name: "echo", input: "two" }] },
                                                { stop_reason: "end_turn",
                                                  messages: [{ role: "assistant", content: "done" }] }
                                              ])
    client = AiToolkit::Client.new(provider)

    resp = client.request(auto: true, max_iterations: 1) do |c|
      c.message :user, "start"
      c.tool EchoTool.new
    end

    assert_equal "tool_use", resp.stop_reason
    assert_equal 3, resp.results.length
    assert_instance_of AiToolkit::ToolRequest, resp.results[0]
    assert_instance_of AiToolkit::ToolResponse, resp.results[1]
    assert_instance_of AiToolkit::ToolRequest, resp.results[2]
  end
  # rubocop:enable Metrics/MethodLength, Metrics/AbcSize

  # @return [void]
  def test_passes_max_tokens
    provider = CaptureProvider.new({ stop_reason: "end_turn", messages: [] })
    client = AiToolkit::Client.new(provider)

    client.request(max_tokens: 55) do |c|
      c.message :user, "hi"
    end

    assert_equal 55, provider.last_args[:max_tokens]
  end

  # @return [void]
  def test_passes_tool_choice
    provider = CaptureProvider.new({ stop_reason: "end_turn", messages: [] })
    client = AiToolkit::Client.new(provider)

    client.request(tool_choice: { type: "tool", name: "echo" }) do |c|
      c.message :user, "hi"
    end

    assert_equal({ type: "tool", name: "echo" }, provider.last_args[:tool_choice])
  end

  # @return [void]
  def test_builtin_tool_with_options
    provider = CaptureProvider.new({ stop_reason: "end_turn", messages: [] })
    client = AiToolkit::Client.new(provider)

    client.request do |c|
      c.message :user, "hi"
      c.tool :web_search, nil, max_uses: 2, allowed_domains: ["example.com"]
    end

    assert_equal [{ name: "web_search", max_uses: 2,
                    allowed_domains: ["example.com"] }], provider.last_args[:tools]
  end

  # @return [void]
  def test_passes_generation_options
    provider = CaptureProvider.new({ stop_reason: "end_turn", messages: [] })
    client = AiToolkit::Client.new(provider)

    client.request(temperature: 0.5, top_k: 3, top_p: 0.8) do |c|
      c.message :user, "hi"
    end

    assert_equal 0.5, provider.last_args[:temperature]
    assert_equal 3, provider.last_args[:top_k]
    assert_equal 0.8, provider.last_args[:top_p]
  end

  class StopTool < AiToolkit::Tool
    input_schema({ type: "object" })

    # @return [String]
    def name
      "stop"
    end

    # @return [String]
    def description
      "stop desc"
    end

    # @param _params [Hash]
    # @return [void]
    def perform(_params)
      raise AiToolkit::StopToolLoop, "done"
    end
  end

  # @return [void]
  # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
  def test_tool_can_end_loop
    provider = AiToolkit::Providers::Fake.new([
                                                { stop_reason: "tool_use",
                                                  tool_uses: [{ name: "stop", input: {} }] }
                                              ])
    client = AiToolkit::Client.new(provider)

    resp = client.request(auto: true) do |c|
      c.message :user, "hi"
      c.tool StopTool.new
    end

    assert_equal "tool_stop", resp.stop_reason
    assert_equal 2, resp.results.length
    assert_instance_of AiToolkit::ToolRequest, resp.results[0]
    assert_instance_of AiToolkit::ToolResponse, resp.results[1]
  end
  # rubocop:enable Metrics/MethodLength, Metrics/AbcSize

  # Ensure pause_turn responses trigger another provider call
  # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
  # @return [void]
  def test_pause_turn_continues_loop
    provider = AiToolkit::Providers::Fake.new([
                                                { stop_reason: "pause_turn",
                                                  messages: [{ role: "assistant", content: "one" }] },
                                                { stop_reason: "pause_turn",
                                                  messages: [{ role: "assistant", content: "two" }] },
                                                { stop_reason: "end_turn",
                                                  messages: [{ role: "assistant", content: "done" }] }
                                              ])
    client = AiToolkit::Client.new(provider)

    resp = client.request(auto: true) do |c|
      c.message :user, "hi"
    end

    assert_equal "end_turn", resp.stop_reason
    assert_equal "done", resp.messages.first[:content]
    assert_equal 3, resp.results.length
    expected = %w[one two done]
    resp.results.each_with_index do |r, i|
      assert_instance_of AiToolkit::MessageResult, r
      assert_equal expected[i], r.content
    end
  end

  # Ensure additional message types are preserved
  # @return [void]
  def test_additional_message_types
    provider = AiToolkit::Providers::Fake.new([
                                                {
                                                  stop_reason: "end_turn",
                                                  messages: [
                                                    { role: "assistant",
                                                      content: { type: "server_tool_use", id: "1", name: "web_search",
                                                                 input: { query: "ruby" } } },
                                                    { role: "assistant",
                                                      content: { type: "web_search_tool_result", tool_use_id: "1",
                                                                 content: "result" } }
                                                  ]
                                                }
                                              ])
    client = AiToolkit::Client.new(provider)

    resp = client.request do |c|
      c.message :user, "hi"
    end

    assert_equal 2, resp.results.length
    assert_equal({ type: "server_tool_use", id: "1", name: "web_search", input: { query: "ruby" } },
                 resp.results[0].content)
    assert_equal({ type: "web_search_tool_result", tool_use_id: "1", content: "result" }, resp.results[1].content)
  end
  # rubocop:enable Metrics/MethodLength, Metrics/AbcSize
end
# rubocop:enable Metrics/ClassLength
