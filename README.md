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

The response object exposes the raw messages, any requested tool uses and the stop reason.

Enabling automatic tool looping is as easy as:

```ruby
response = client.request(auto: true) do |c|
  c.system_prompt 'My Prompt'
  c.message :user, 'First message'
  c.tool MyToolObject
end
```

You can also override the maximum number of tokens sent to the provider and the
iteration limit used when `auto` is enabled:

```ruby
client.request(auto: true, max_tokens: 2048, max_iterations: 10) do |c|
  c.message :user, 'Hello'
end
```

See `lib/ai_toolkit/providers/claude.rb` and `lib/ai_toolkit/providers/bedrock.rb` for the provider implementations.

Run the test suite with:

```
rake test
```
