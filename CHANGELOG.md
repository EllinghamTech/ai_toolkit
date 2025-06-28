## [Unreleased]
### Added
- UnknownResult stores raw JSON for unrecognized message types.
- `AiToolkit::Client#request` now returns a `AiToolkit::ResponseCollection` object
### Changed
- Result classes moved to `AiToolkit::Results` namespace.

## [0.1.1] - 2025-06-26
### Fixed
- Providers are now exposed via `AiToolkit::Providers`.

## [0.1.0] - 2025-06-22
### Added
- Simple Ruby DSL for building Claude requests with `system_prompt`, `message`, and `tool` calls.
- Provider implementations for Claude and AWS Bedrock.
- Automatic tool loops via the `auto` option with termination using `StopToolLoop`.
- Configurable generation options like `temperature`, `top_k`, and `top_p`.
- Configurable `max_tokens` and `max_iterations` options for `Client#request`.
- `tool_choice` option for requests to force a specific tool.
