# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [3.2.0] 2024-06-21

### Added

- Rails controller integration [#370](https://github.com/okuramasafumi/alba/pull/370)
- Modification API: `transform_keys!` [#372](https://github.com/okuramasafumi/alba/pull/372)

## [3.1.0] 2024-03-23

### Added

- Add the ability to change key for metadata [#362](https://github.com/okuramasafumi/alba/pull/362)

## [3.0.3] 2023-12-25

### Fixed

- Make `as_json` compatible with Rails [#350](https://github.com/okuramasafumi/alba/pull/350)
- Fix circular association for nested_attribute [#353](https://github.com/okuramasafumi/alba/pull/353)

## [3.0.2] 2023-12-05

### Fixed

- Fixed warning when `location` option is given to `render json:` in Rails [#348](https://github.com/okuramasafumi/alba/pull/348)

## [3.0.1] 2023-10-13

### Fixed

- Fixed a bug where methods such as `test` or `params` cannot be used as attribute name [#344](https://github.com/okuramasafumi/alba/pull/344)
- Remove redundant code

## [3.0.0] 2023-10-11

### IMPORTANT

**This release contains an important bug fix that can cause data corruption.**
**If you're using Ruby 3, it's highly recommended to upgrade to [v3.0.0](https://rubygems.org/gems/alba/versions/3.0.0)**
**If you're using Ruby 2, please upgrade to [v2.4.2](https://rubygems.org/gems/alba/versions/2.4.2) that contains bug fix only as soon as possible.**

### Added

- Custom type [#333](https://github.com/okuramasafumi/alba/pull/333)

### Changed

- Prefer resource method [#323](https://github.com/okuramasafumi/alba/pull/323)

### Fixed

- Multithread bug [No PR](https://github.com/okuramasafumi/alba/commit/d20ed9efbf2f99827c12b8a07308e2f5aea6ab6d)
  - This is a critical bug that can cause data corruption.

### Removed

- Drop support for Ruby 2 series [No PR](https://github.com/okuramasafumi/alba/commit/20be222555bde69c31fa9cbe4408b3f638cd7580)

## [2.4.1] 2023-08-02

#### Fixed

- Fix the bug of resource name inference for classes whose name end with "Serializer" [No PR](https://github.com/okuramasafumi/alba/commit/1695af4351981725231fd071aaef5b2e4174fb26)

## [2.4.0] 2023-08-02

### Added

- Implement helper [#322](https://github.com/okuramasafumi/alba/pull/322)
- Add `prefer_resource_method!` [#323](https://github.com/okuramasafumi/alba/pull/323)

### Fixed

- Fix the bug of resource name inference [No PR](https://github.com/okuramasafumi/alba/commit/dab7091efa4a76ce9e538e08efa7349c296a705c)

## [2.3.0] 2023-04-24

### Added

- Add compatibility option for key [#304](https://github.com/okuramasafumi/alba/pull/304)
- It now infers resource name from Serializer [#309](https://github.com/okuramasafumi/alba/pull/309)
- `Alba.serialize` is easier to use for multiple root keys [#311](https://github.com/okuramasafumi/alba/pull/311)
- Gives access to params in nested_attribute [#312](https://github.com/okuramasafumi/alba/pull/312)
  - Thank you, @GabrielErbetta

## [2.2.0] 2023-02-17

### Added

- Rails integration to set default inflector [#298](https://github.com/okuramasafumi/alba/pull/298)

### Fixed

- Fix cascade not working with association and inheritance [#300](https://github.com/okuramasafumi/alba/pull/300)

### Removed

- Drop support of Ruby 2.6

## [2.1.0] 2022-12-03

### Added

- Add `select` method for filtering attributes [#270](https://github.com/okuramasafumi/alba/pull/270)
- Allow ConditionalAttribute with 2-arity proc to reject nil attributes [#273](https://github.com/okuramasafumi/alba/pull/273)

### Fixed

- Add support for proc resource in one polymorphic associations [#281](https://github.com/okuramasafumi/alba/pull/281)

### Deprecated

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
