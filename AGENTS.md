# Repository Guidelines

## Project Structure & Module Organization

This repository is the `afipws` Ruby gem, a client for AFIP web services. Public entry points and service implementations live in `lib/`: `lib/afipws.rb` loads the gem, while files such as `wsfe.rb`, `wsaa.rb`, and `persona_service_a100.rb` implement individual services. Shared errors and extensions belong in `lib/afipws/errors/` and `lib/afipws/core_ext/`.

RSpec tests mirror production paths under `spec/afipws/` (for example, `lib/afipws/client.rb` maps to `spec/afipws/client_spec.rb`). Keep recorded SOAP XML and WSDL inputs in the corresponding `spec/fixtures/` service directory. `examples/` contains runnable usage samples; update these when a public API change needs illustration.

## Build, Test, and Development Commands

Use mise to select Ruby 3.3.4 and run the supported development tasks:

```sh
mise install          # install the configured Ruby runtime
mise run setup        # bundle install
mise run test         # run the complete RSpec suite through Rake
mise run console      # start an interactive console with lib/ loaded
bundle exec guard     # rerun affected specs while editing
```

CI performs `bundle install` followed by `bundle exec rake`; run the same test command before submitting changes.

## Coding Style & Naming Conventions

Follow the existing Ruby style: two-space indentation, `snake_case` methods/files, `CamelCase` classes/modules, and namespaced implementation under `Afipws`. Keep service classes and fixture paths descriptive and aligned (for example, `WSFE` and `spec/fixtures/wsfe/`). Prefer the project’s established RSpec should-style assertions when editing nearby specs.

Rubocop configuration is in `.rubocop.yml`: line length is limited to 120 characters, and several modern-style cops are intentionally disabled to preserve the existing codebase style. Do not reformat unrelated files.

## Testing Guidelines

Add or update a `*_spec.rb` for every behavior change. Tests must not call live AFIP endpoints: use Savon mocks and XML fixtures via `fixture('service/action/result')`. Cover successful responses, SOAP/HTTP failures, and retry behavior when relevant. Run `mise run test` after fixture or service changes.

## Commit & Pull Request Guidelines

Use short, imperative commit subjects, as in `Add examples`, `Update ruby`, or `Handle Savon::HTTPError`; dependency updates use `Bump <gem> from <old> to <new>`. Keep commits focused. Pull requests should explain the service/API impact, list tests run, link the relevant issue when available, and include sanitized request/response examples when changing SOAP behavior. Never commit production certificates, private keys, or tokens.
