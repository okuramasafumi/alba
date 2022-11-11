# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Deprecations

- Deprecate `inference` related methods in favor of a unified `inflector` interface.
  Deprecated methods are: `Alba.enable_inference!`, `Alba.disable_inference!`, and `Alba.inferring`.
  Use `Alba.inflector = :active_support/:dry` or `Alba.inflector = SomeInflector` to enable.
  Use `Alba.inflector = nil` to disable.
  Use `Alba.inflector` to check if enabled.

## [2.0.1] 2022-11-02

### Fix

- the bug including key not in `within` [#262](https://github.com/okuramasafumi/alba/pull/262)
- key transformation now cascades multiple levels [#263](https://github.com/okuramasafumi/alba/pull/263)

## [2.0.0] 2022-10-21

### Breaking changes

- All Hash-related methods now return String keys instead of Symbol keys.
    This affects all users, but you can use `deep_symbolize_keys` in Rails environment if you prefer Symbol keys, or `with_indifferent_access` to support both String and Symbol keys.
    Some DSLs that take key argument such as `on_nil` and `on_error`, are also affected.
- Remove deprecated methods: `Resource#to_hash`, `Resource.ignoring`, `Alba.on_nil`, `Alba.on_error`, `Alba.enable_root_key_transformation!` and `Alba.disable_root_key_transformation!`
- If using `transform_keys`, the default inflector is no longer set by default [d02245c8](https://github.com/okuramasafumi/alba/commit/d02245c87e9df303cb20e354a81e5457ea460bdd#diff-ecd8c835d2390b8cb89e7ff75e599f0c15cdbe18c30981d6090f4a515566686f)
    To retain this functionality in Rails, add an initializer with the following:
    `Alba.enable_inference!(with: :active_support)`

### New features

- Passing an initial object to proc function in associations [#209](https://github.com/okuramasafumi/alba/pull/209)
- Allow association resource to be Proc [#213](https://github.com/okuramasafumi/alba/pull/213)
- `collection_key` to serialize collection into a Hash [#119](https://github.com/okuramasafumi/alba/pull/119)
- params is now overridable [#227](https://github.com/okuramasafumi/alba/pull/227)
- Key transformation now cascades [#232](https://github.com/okuramasafumi/alba/pull/232)
- nested attribute [#237](https://github.com/okuramasafumi/alba/pull/237)
- Implement `as_json` [#249](https://github.com/okuramasafumi/alba/pull/249)

### Bugfix

- fix the bug where nesting is empty string and invalid
- `handle_error` now raises the same error
- let Rails implicitly call `to_json`

## [1.6.0] 2022-03-16

- [Feat] Support instance method as an attribute
- [Fix] Explicitly raise error when inference is disabled
- [Improve] `enable_inference!` now takes inflector as argument
- [Improve] `transform_keys` now accepts `:snake` and `:none`
- [Deprecate] `to_hash` is special method and should not be used
- [Deprecate] `ignoring` in favor of `attributes` overriding
- [Deprecate] `Alba.on_nil`, `Alba.on_error` and `Alba.enable_root_key_transformation!`

## [1.5.0] 2021-11-28

- [Feat] Add nil handler
- [Feat] Implement layout feature
- [Improve] if option now works with Symbol
- [Improve] Add an alias for serialize
- [Improve] Deprecation warning now printed with caller

## [1.4.0] 2021-06-30

- [Feat] Add a config method to set encoder directly
- [Feat] Implement `meta` method and option for metadata
- [Feat] Add `root_key` option to `Resource#serialize`
- [Feat] Enable setting key for collection with `root_key`
- [Feat] Add `Resource.root_key` and `Resource.root_key!`
- [Feat] `Alba.serialize` now infers resource class
- [Deprecated] `Resource.key` and `Resource.key!` are deprecated

## [1.3.0] 2021-05-31

- [Perf] Improve performance for `many` [641d8f9]
  - https://github.com/okuramasafumi/alba/pull/125
- [Feat] Add custom inflector feature (#126) [ad73291]
  - https://github.com/okuramasafumi/alba/pull/126
  - Thank you @wuarmin !
- [Feat] Support params in if condition [6e9915e]
  - https://github.com/okuramasafumi/alba/pull/128
- [Fix] fundamentally broken "circular association control" [fbbc9a1]
  - https://github.com/okuramasafumi/alba/pull/130

## [1.2.0] 2021-05-09

- [Fix] multiple word key inference [6c18e73]
  - https://github.com/okuramasafumi/alba/pull/120
  - Thank you @alfonsojimenez !
- [Feat] Add `Alba.enable_root_key_transformation!` [f172839]
  - https://github.com/okuramasafumi/alba/pull/121
- [Feat] Implement type validation and auto conversion [cbe00c7]
  - https://github.com/okuramasafumi/alba/pull/122

## [1.1.0] - 2021-04-23

- [Feat] Implement circular associations control [71e1543]
- [Feat] Support :oj_rails backend [76e519e]

## [1.0.1] - 2021-04-15

- [Fix] Don't cache resource class for `Alba.serialize` [9ed5253]
- [Improve] Warn when `ActiveSupport` or `Oj` are absent [d3ab3eb]
- [Fix] Delete unreachable `to_hash` method on Association [1ba1f90]
- [Fix] Stringify key before transforming [b4eb79e]
- [Misc] Support Ruby 2.5.0 and above, not 2.5.7 and above [43f1d17]
- [Fix] Remove accidentally added `p` debug [5d0324b]

## [1.0.0] - 2021-04-07

This is the first major release of Alba and it includes so many features. To see all the features you can have a look at [README](https://github.com/okuramasafumi/alba/blob/master/README.md#features).
