# AiToolkit

AiToolkit provides a simple Ruby DSL for interacting with Anthropic's Claude models. It can talk directly to the Claude HTTP API or via AWS Bedrock.

```ruby
client = AiToolkit::Client.new(provider)
response = client.request do |c|
  c.system_prompt 'My Prompt'
  c.message :user, 'Hello'
  c.tool :example_tool, {}
end
```

For Claude built-in server side tools, just provide the tool name and any
configuration options:

```ruby
client.request do |c|
  c.tool :web_search, max_uses: 3, allowed_domains: ['example.com']
end
```

The response object exposes the stop reason and a chronologically ordered list of
results via `#results`. Each element of this array is one of three objects:
`AiToolkit::MessageResult` for LLM messages, `AiToolkit::ToolRequest`
for tool calls requested by the LLM, and `AiToolkit::ToolResponse` for
the data returned back to the model from executed tools.

Enabling automatic tool looping is as easy as:

```ruby
response = client.request(auto: true) do |c|
  c.system_prompt 'My Prompt'
  c.message :user, 'First message'
  c.tool MyToolObject
end
```

You can also override the maximum number of tokens sent to the provider and the
iteration limit used when `auto` is enabled. A specific tool can be forced by
passing a `tool_choice` hash:

```ruby
client.request(auto: true, max_tokens: 2048, max_iterations: 10,
               tool_choice: { type: 'tool', name: 'example_tool' }) do |c|
  c.message :user, 'Hello'
end
```

When using `auto`, a tool may terminate further LLM calls by raising
`AiToolkit::StopToolLoop` from `#perform`.

See `lib/ai_toolkit/providers/claude.rb` and `lib/ai_toolkit/providers/bedrock.rb` for the provider implementations.

To use the Bedrock provider you need the [`aws-sdk-bedrockruntime`](https://github.com/aws/aws-sdk-ruby) gem. This gem is not included in `ai_toolkit`'s runtime dependencies, so install it separately when required:

```bash
gem install aws-sdk-bedrockruntime
```

When building the Docker image for testing with `docker-compose`, the gem is
installed automatically via Bundler's `docker` group:

```bash
docker-compose build
docker-compose up
```

Run the test suite with:

```
rake test
```
