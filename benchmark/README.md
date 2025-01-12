## Benchmark for json serializers

This directory contains a few different benchmark scripts.

## How to run

```
bundle install

# with `Oj.optimize_rails`
bundle exec ruby collection.rb

# without `Oj.optimize_rails`
NO_OJ_OPTIMIZE_RAILS=1 bundle exec ruby collection.rb

# with `Oj.optimize_rails` and YJIT
YJIT=1 bundle exec ruby collection.rb

# with YJIT and without `Oj.optimize_rails`
YJIT=1 NO_OJ_OPTIMIZE_RAILS=1 bundle exec ruby collection.rb
```

## Result

As a reference, here's the benchmark result run in my (@okuramasafumi) machine.

Machine spec:

|Key|Value|
|---|---|
|OS|macOS 15.2|
|CPU|Apple M1 Pro|
|RAM|16GB|
|Ruby|ruby 3.4.1 (2024-12-25 revision 48d4efcb85) +PRISM [arm64-darwin23]|

Library versions:

|Library|Version|
|---|---|
|alba|3.5.0|
|blueprinter|1.1.0|
|fast_serializer_ruby|0.6.9|
|jserializer|0.2.1|
|oj|3.16.6|
|simple_ams|0.2.6|
|representable|3.2.0|
|turbostreamer|1.11.0|
|jbuilder|2.13.0|
|panko_serializer|0.8.2|
|active_model_serializers|0.10.14|

`benchmark-ips` with `Oj.optimize_rails`:

```
Comparison:
               panko:      455.2 i/s
         jserializer:      171.5 i/s - 2.65x  slower
       turbostreamer:      170.4 i/s - 2.67x  slower
alba_with_transformation:      159.9 i/s - 2.85x  slower
                alba:      148.0 i/s - 3.08x  slower
     fast_serializer:       99.0 i/s - 4.60x  slower
               rails:       82.4 i/s - 5.53x  slower
         blueprinter:       70.9 i/s - 6.42x  slower
         alba_inline:       50.5 i/s - 9.02x  slower
       representable:       43.8 i/s - 10.38x  slower
          simple_ams:       39.1 i/s - 11.64x  slower
                 ams:       15.0 i/s - 30.45x  slower
```

`benchmark-ips` without `Oj.optimize_rails`:

```
Comparison:
               panko:      446.0 i/s
         jserializer:      168.9 i/s - 2.64x  slower
       turbostreamer:      168.8 i/s - 2.64x  slower
alba_with_transformation:      166.0 i/s - 2.69x  slower
                alba:      155.8 i/s - 2.86x  slower
     fast_serializer:       98.6 i/s - 4.52x  slower
               rails:       75.7 i/s - 5.89x  slower
         blueprinter:       71.5 i/s - 6.24x  slower
         alba_inline:       50.5 i/s - 8.83x  slower
       representable:       43.8 i/s - 10.19x  slower
          simple_ams:       36.4 i/s - 12.27x  slower
                 ams:       14.4 i/s - 30.99x  slower
```

`benchmark-ips` with `Oj.optimize_rails` and YJIT:

```
Comparison:
               panko:      677.8 i/s
       turbostreamer:      338.7 i/s - 2.00x  slower
         jserializer:      267.7 i/s - 2.53x  slower
alba_with_transformation:      262.8 i/s - 2.58x  slower
                alba:      243.7 i/s - 2.78x  slower
     fast_serializer:      192.9 i/s - 3.51x  slower
               rails:      133.4 i/s - 5.08x  slower
         blueprinter:      109.8 i/s - 6.17x  slower
       representable:       71.9 i/s - 9.43x  slower
          simple_ams:       70.2 i/s - 9.66x  slower
                 ams:       21.5 i/s - 31.49x  slower
         alba_inline:       12.4 i/s - 54.78x  slower
```

`benchmark-ips` with YJIT and without `Oj.optimize_rails`:

```
Comparison:
               panko:      666.6 i/s
       turbostreamer:      310.9 i/s - 2.14x  slower
         jserializer:      275.3 i/s - 2.42x  slower
                alba:      266.7 i/s - 2.50x  slower
alba_with_transformation:      266.6 i/s - 2.50x  slower
     fast_serializer:      183.4 i/s - 3.63x  slower
               rails:      117.2 i/s - 5.69x  slower
         blueprinter:      109.0 i/s - 6.12x  slower
       representable:       68.6 i/s - 9.72x  slower
          simple_ams:       64.9 i/s - 10.27x  slower
                 ams:       20.6 i/s - 32.38x  slower
         alba_inline:       12.1 i/s - 54.97x  slower
```

`benchmark-memory`:

```
Comparison:
               panko:     259178 allocated
       turbostreamer:     641720 allocated - 2.48x more
alba_with_transformation:     650141 allocated - 2.51x more
         jserializer:     822161 allocated - 3.17x more
                alba:     826201 allocated - 3.19x more
     fast_serializer:    1470001 allocated - 5.67x more
         blueprinter:    2297641 allocated - 8.87x more
         alba_inline:    2712001 allocated - 10.46x more
               rails:    3151017 allocated - 12.16x more
                 ams:    5116961 allocated - 19.74x more
       representable:    5151321 allocated - 19.88x more
          simple_ams:    9421433 allocated - 36.35x more
```

Conclusion: panko is extremely fast but it's a C extension gem. As pure Ruby gems, Alba, `turbostreamer` and `jserializer` are notably faster than others, but Alba is slightly slower than other two. With `Oj.optimize_rails`, `jbuilder` and Rails standard serialization are also fast.
