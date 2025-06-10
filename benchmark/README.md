## Benchmark for json serializers

This directory contains a few different benchmark scripts.

## How to run

```
bundle install

# with `Oj.optimize_rails` and without YJIT
NO_YJIT=1 bundle exec ruby collection.rb

# without `Oj.optimize_rails` and without YJIT
NO_YJIT=1 NO_OJ_OPTIMIZE_RAILS=1 bundle exec ruby collection.rb

# with `Oj.optimize_rails` and YJIT
bundle exec ruby collection.rb

# without `Oj.optimize_rails` and with YJIT
NO_OJ_OPTIMIZE_RAILS=1 bundle exec ruby collection.rb
```

## Result

As a reference, here's the benchmark result run in my (@okuramasafumi) machine.

Machine spec:

|Key|Value|
|---|---|
|OS|macOS 15.5|
|CPU|Apple M1 Pro|
|RAM|16GB|
|Ruby|ruby 3.4.4 (2025-05-14 revision a38531fd3f) +PRISM [arm64-darwin24]|

Library versions:

|Library|Version|
|---|---|
|alba|3.7.2|
|blueprinter|1.1.2|
|fast_serializer_ruby|0.6.9|
|jserializer|0.2.1|
|oj|3.16.11|
|simple_ams|0.2.6|
|representable|3.2.0|
|turbostreamer|1.11.0|
|jbuilder|2.13.0|
|panko_serializer|0.8.3|
|active_model_serializers|0.10.15|
|rabl|0.17.0|

`benchmark-ips` with `Oj.optimize_rails`:

```
Comparison:
               panko:      501.4 i/s
         jserializer:      217.4 i/s - 2.31x  slower
       turbostreamer:      207.8 i/s - 2.41x  slower
                alba:      201.0 i/s - 2.50x  slower
alba_with_transformation:      189.4 i/s - 2.65x  slower
               rails:      115.7 i/s - 4.33x  slower
         blueprinter:      109.1 i/s - 4.60x  slower
     fast_serializer:      106.4 i/s - 4.71x  slower
                rabl:       68.3 i/s - 7.34x  slower
       representable:       60.7 i/s - 8.26x  slower
         alba_inline:       59.0 i/s - 8.50x  slower
          simple_ams:       47.7 i/s - 10.51x  slower
                 ams:       16.8 i/s - 29.92x  slower
```

`benchmark-ips` without `Oj.optimize_rails`:

```
Comparison:
               panko:      495.6 i/s
                alba:      228.8 i/s - 2.17x  slower
         jserializer:      215.5 i/s - 2.30x  slower
       turbostreamer:      207.2 i/s - 2.39x  slower
alba_with_transformation:      203.9 i/s - 2.43x  slower
         blueprinter:      106.4 i/s - 4.66x  slower
     fast_serializer:      106.0 i/s - 4.67x  slower
               rails:       97.2 i/s - 5.10x  slower
                rabl:       68.3 i/s - 7.26x  slower
       representable:       62.1 i/s - 7.99x  slower
         alba_inline:       58.2 i/s - 8.52x  slower
          simple_ams:       44.1 i/s - 11.24x  slower
                 ams:       16.2 i/s - 30.63x  slower
```

`benchmark-ips` with `Oj.optimize_rails` and YJIT:

```
Comparison:
               panko:      786.7 i/s
       turbostreamer:      546.0 i/s - 1.44x  slower
                alba:      532.6 i/s - 1.48x  slower
         jserializer:      413.6 i/s - 1.90x  slower
alba_with_transformation:      358.9 i/s - 2.19x  slower
     fast_serializer:      226.3 i/s - 3.48x  slower
         blueprinter:      207.8 i/s - 3.79x  slower
               rails:      203.2 i/s - 3.87x  slower
                rabl:      180.1 i/s - 4.37x  slower
       representable:       99.4 i/s - 7.91x  slower
          simple_ams:       79.2 i/s - 9.94x  slower
                 ams:       26.4 i/s - 29.76x  slower
         alba_inline:       13.5 i/s - 58.26x  slower
```

`benchmark-ips` with YJIT and without `Oj.optimize_rails`:

```
Comparison:
               panko:     259178 allocated
       turbostreamer:     641720 allocated - 2.48x more
         jserializer:     822281 allocated - 3.17x more
alba_with_transformation:     834341 allocated - 3.22x more
                alba:     834401 allocated - 3.22x more
     fast_serializer:    1470121 allocated - 5.67x more
                rabl:    1748204 allocated - 6.75x more
         blueprinter:    2297921 allocated - 8.87x more
               rails:    2757857 allocated - 10.64x more
         alba_inline:    2809641 allocated - 10.84x more
                 ams:    4715801 allocated - 18.20x more
       representable:    5151321 allocated - 19.88x more
          simple_ams:    9020273 allocated - 34.80x more
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
