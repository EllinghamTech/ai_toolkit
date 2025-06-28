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
    attr_reader :last_args, :model, :call_count

    # @param response [Hash, Array<Hash>]
    #   canned response or list of responses to return
    # @param model [String]
    #   model identifier
    # @return [void]
    def initialize(response, model: "test-model")
      @responses = response.is_a?(Array) ? response : [response]
      @model = model
      @call_count = 0
    end

    # Capture arguments and return the canned response.
    # @param args [Hash]
    #   arguments passed from the client
    # @return [AiToolkit::Response]
    def call(**args)
      @last_args = args
      resp = @responses[@call_count] || @responses.last
      @call_count += 1
      return resp if resp.is_a?(AiToolkit::Response)

      results = (resp[:messages] || []).map do |m|
        AiToolkit::Results::MessageResult.new(role: m[:role], content: m[:content])
      end
      (resp[:tool_uses] || []).each do |tu|
        results << AiToolkit::Results::ToolRequest.new(id: tu[:id], name: tu[:name], input: tu[:input])
      end

      AiToolkit::Response.new(
        resp,
        results: results,
        execution_time: 0.001,
        input_tokens: resp[:input_tokens],
        output_tokens: resp[:output_tokens]
      )
    end
  end

  # Test simple request
  # @return [void]
  def test_request_returns_response
    provider = AiToolkit::Providers::Fake.new([
                                                { stop_reason: "end_turn",
                                                  messages: [{ role: "assistant", content: "hi" }] }
                                              ])
    client = AiToolkit::Client.new(provider)

    resps = client.request do |c|
      c.system_prompt "Hello"
      c.message :user, "hi"
      c.tool :echo, {}
    end
    assert_equal 1, resps.length
    resp = resps.first
    assert_equal "end_turn", resp.stop_reason
    assert_equal "hi", resp.messages.first[:content]
    assert_equal 1, resp.results.length
    assert_instance_of AiToolkit::Results::MessageResult, resp.results.first
    assert resp.execution_time.is_a?(Numeric)
    assert resps.total_execution_time.positive?
  end

  # rubocop:disable Metrics/AbcSize
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

    resps = client.request(auto: true) do |c|
      c.message :user, "start"
      c.tool EchoTool.new
    end
    assert_equal 2, resps.length
    assert_equal "end_turn", resps.last.stop_reason
    assert_equal "done", resps.last.messages.first[:content]
    assert_equal 2, resps.first.results.length
    assert_instance_of AiToolkit::Results::ToolRequest, resps.first.results[0]
    assert_instance_of AiToolkit::Results::ToolResponse, resps.first.results[1]
    assert_equal 1, resps.last.results.length
    assert_instance_of AiToolkit::Results::MessageResult, resps.last.results[0]
    assert resps.total_execution_time.positive?
  end
  # rubocop:enable Metrics/AbcSize

  # rubocop:disable Metrics/AbcSize
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

    resps = client.request(auto: true, max_iterations: 1) do |c|
      c.message :user, "start"
      c.tool EchoTool.new
    end
    assert_equal 2, resps.length
    assert_equal "tool_use", resps.last.stop_reason
    assert_equal 2, resps.first.results.length
    assert_instance_of AiToolkit::Results::ToolRequest, resps.first.results[0]
    assert_instance_of AiToolkit::Results::ToolResponse, resps.first.results[1]
    assert_equal 1, resps.last.results.length
    assert_instance_of AiToolkit::Results::ToolRequest, resps.last.results[0]
    assert resps.total_execution_time.positive?
  end
  # rubocop:enable Metrics/AbcSize

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

  # Ensure before hooks can modify requests
  # @return [void]
  def test_before_hook_modifies_request
    provider = CaptureProvider.new({ stop_reason: "end_turn", messages: [] }, model: "m1")
    client = AiToolkit::Client.new(provider)
    captured = nil
    client.before_request do |req, model:, provider:|
      captured = [req[:max_tokens], model, provider]
      req[:max_tokens] = 20
    end

    client.request(max_tokens: 5) do |c|
      c.message :user, "hi"
    end

    assert_equal [5, "m1", "TestAiToolkit::CaptureProvider"], captured
    assert_equal 20, provider.last_args[:max_tokens]
  end

  # Ensure after hook errors stop the auto loop
  # @return [void]
  def test_after_hook_error_stops_loop
    responses = [
      { stop_reason: "tool_use", tool_uses: [{ name: "echo", input: "hi" }] },
      { stop_reason: "end_turn", messages: [{ role: "assistant", content: "done" }] }
    ]
    provider = CaptureProvider.new(responses)
    client = AiToolkit::Client.new(provider)
    client.after_request do |_req, _res, **_|
      raise "boom"
    end

    resps = client.request(auto: true) do |c|
      c.tool EchoTool.new
      c.message :user, "go"
    end
    assert_equal 1, provider.call_count
    assert_equal 1, resps.length
    resp = resps.first
    assert_equal "tool_use", resp.stop_reason
    assert_equal 1, resp.results.length
    assert_instance_of AiToolkit::Results::ToolRequest, resp.results.first
    assert resps.total_execution_time.positive?
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
  def test_tool_can_end_loop
    provider = AiToolkit::Providers::Fake.new([
                                                { stop_reason: "tool_use",
                                                  tool_uses: [{ name: "stop", input: {} }] }
                                              ])
    client = AiToolkit::Client.new(provider)

    resps = client.request(auto: true) do |c|
      c.message :user, "hi"
      c.tool StopTool.new
    end
    assert_equal 2, resps.length
    assert_equal "tool_stop", resps.last.stop_reason
    assert_equal 2, resps.first.results.length
    assert_instance_of AiToolkit::Results::ToolRequest, resps.first.results[0]
    assert_instance_of AiToolkit::Results::ToolResponse, resps.first.results[1]
    assert resps.total_execution_time.positive?
  end

  # Ensure pause_turn responses trigger another provider call
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

    resps = client.request(auto: true) do |c|
      c.message :user, "hi"
    end
    assert_equal 3, resps.length
    assert_equal "end_turn", resps.last.stop_reason
    assert_equal "done", resps.last.messages.first[:content]
    expected = %w[one two done]
    resps.each_with_index do |r, i|
      assert_instance_of AiToolkit::Results::MessageResult, r.results.first
      assert_equal expected[i], r.results.first.content
    end
    assert resps.total_execution_time.positive?
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

    resps = client.request do |c|
      c.message :user, "hi"
    end
    assert_equal 1, resps.length
    resp = resps.first
    assert_equal 2, resp.results.length
    assert_equal({ type: "server_tool_use", id: "1", name: "web_search", input: { query: "ruby" } },
                 resp.results[0].content)
    assert_equal({ type: "web_search_tool_result", tool_use_id: "1", content: "result" }, resp.results[1].content)
    assert resps.total_execution_time.positive?
  end
end
# rubocop:enable Metrics/ClassLength
