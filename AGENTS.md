# Repository Guidelines

## Project Structure & Module Organization
Core code lives under `lib/`, with `lib/alba/` providing the serializer internals and `alba.rb` exposing the public API. Reusable tasks sit in `lib/tasks/`. Tests follow the Minitest layout in `test/**/*_test.rb`, with helpers inside `test/support/` and scenario fixtures in `test/usecases/`. Type signatures inhabit `sig/` alongside the `Steepfile`, while developer notes and docs are under `doc/` and `docs/`. Benchmarks and sandboxes (`benchmark/`, `playground.rb`, `sample.rb`) help validate performance quickly.

## Build, Test, and Development Commands
Run `bundle exec rake test` (or plain `rake`) to execute the suite for the default gemfile. When validating alternate dependency sets, prefix with `BUNDLE_GEMFILE=gemfiles/<name>.gemfile`. Lint with `bundle exec rubocop` to apply the Ruby, Rake, Markdown, Performance, and Minitest cops configured here. Use `bundle exec rake typecheck` to perform both RBS validation and Steep checks; invoke `rake rbs` or `rake steep` individually for faster loops. `bundle exec bin/console` launches an interactive console with Alba preloaded.

## Coding Style & Naming Conventions
Adhere to `.editorconfig`: UTF-8, LF endings, trailing whitespace trimmed, and two-space indentation. RuboCop targets Ruby 3.0 and governs import order, layout, and naming—accept its autofixes before committing. Predicate names such as `select` are pre-whitelisted; otherwise stick to idiomatic Ruby casing. Keep comments intentional and brief; prefer clarifying method names over inline notes.

## Testing Guidelines
Minitest powers the suite and expects file names ending in `_test.rb`. Mirror runtime namespaces when adding tests and pull helpers from `test/test_helper.rb`. SimpleCov enforces branch coverage locally and in CI, so favour assertions that drive both truth paths. Use `test/tmp/` for scratch files and keep complex data in `test/support/` to avoid noisy fixtures in unit tests.

## Commit & Pull Request Guidelines
History commonly uses bracketed prefixes such as `[Feat]`, `[Fix]`, `[Chore]`, and `[Doc]`; continue that format with a short subject. Scope each pull request to a single concern, describe behavioural impact, and reference issues or discussions when applicable. Include tests or docs for every change and confirm `rubocop`, `rake test`, and `rake typecheck` succeed before requesting review. Screenshots or JSON samples are appreciated when altering outputs.

## Static Analysis & Type Checking
Any API or type change should update the matching files in `sig/`. Run `bundle exec rake typecheck` until both Steep and RBS succeed, and call out intentional signature gaps in the pull request if they remain.
