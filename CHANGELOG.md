# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

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
