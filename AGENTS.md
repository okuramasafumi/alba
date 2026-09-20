# Repository Guidelines

- Keep changes scoped and preserve unrelated worktree changes.
- For regression fixes, verify the test fails before the fix and passes after.
- Update `sig/` when changing APIs or types.
- Run checks appropriate to the change:
  - `bundle exec rake test`
  - `bundle exec rubocop`
  - `bundle exec rake typecheck` (Ruby 3.3+, `type` group installed)
  - `bundle exec rake typecheck:examples` for affected examples.
- Report blocked or skipped checks explicitly.
