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

`benchmark-ips` with `Oj.optimize_rails` and with YJIT:

```
Comparison:
               panko:      872.4 i/s
       turbostreamer:      634.5 i/s - 1.38x  slower
                alba:      603.1 i/s - 1.45x  slower
         jserializer:      484.0 i/s - 1.80x  slower
alba_with_transformation:      423.3 i/s - 2.06x  slower
            jbuilder:      333.5 i/s - 2.62x  slower
     fast_serializer:      265.9 i/s - 3.28x  slower
               rails:      240.0 i/s - 3.63x  slower
         blueprinter:      238.7 i/s - 3.65x  slower
                rabl:      206.7 i/s - 4.22x  slower
       representable:      118.1 i/s - 7.39x  slower
          simple_ams:       65.5 i/s - 13.32x  slower
                 ams:       29.3 i/s - 29.75x  slower
         alba_inline:       13.1 i/s - 66.76x  slower
```

`benchmark-ips` without `Oj.optimize_rails` and with YJIT:

```
Comparison:
               panko:      890.9 i/s
                alba:      670.6 i/s - 1.33x  slower
       turbostreamer:      622.1 i/s - 1.43x  slower
         jserializer:      490.6 i/s - 1.82x  slower
alba_with_transformation:      432.9 i/s - 2.06x  slower
            jbuilder:      271.8 i/s - 3.28x  slower
     fast_serializer:      259.6 i/s - 3.43x  slower
         blueprinter:      237.2 i/s - 3.76x  slower
               rails:      213.3 i/s - 4.18x  slower
                rabl:      199.5 i/s - 4.46x  slower
       representable:      115.1 i/s - 7.74x  slower
          simple_ams:       68.8 i/s - 12.94x  slower
                 ams:       27.7 i/s - 32.15x  slower
         alba_inline:       13.5 i/s - 65.92x  slower
```

`benchmark-ips` with `Oj.optimize_rails` and without YJIT:

```
Comparison:
               panko:      564.5 i/s
         jserializer:      244.0 i/s - 2.31x  slower
       turbostreamer:      241.3 i/s - 2.34x  slower
                alba:      229.7 i/s - 2.46x  slower
alba_with_transformation:      211.9 i/s - 2.66x  slower
            jbuilder:      167.3 i/s - 3.38x  slower
               rails:      131.9 i/s - 4.28x  slower
         blueprinter:      122.4 i/s - 4.61x  slower
     fast_serializer:      117.2 i/s - 4.82x  slower
                rabl:       74.9 i/s - 7.53x  slower
       representable:       68.2 i/s - 8.28x  slower
         alba_inline:       68.2 i/s - 8.28x  slower
          simple_ams:       55.0 i/s - 10.27x  slower
                 ams:       18.4 i/s - 30.73x  slower
```

`benchmark-ips` without YJIT and without `Oj.optimize_rails`:

```
Comparison:
               panko:      560.0 i/s
                alba:      252.8 i/s - 2.22x  slower
         jserializer:      245.6 i/s - 2.28x  slower
       turbostreamer:      234.5 i/s - 2.39x  slower
alba_with_transformation:      226.7 i/s - 2.47x  slower
            jbuilder:      138.2 i/s - 4.05x  slower
         blueprinter:      118.4 i/s - 4.73x  slower
     fast_serializer:      116.1 i/s - 4.82x  slower
               rails:      110.2 i/s - 5.08x  slower
                rabl:       77.3 i/s - 7.25x  slower
       representable:       69.0 i/s - 8.11x  slower
         alba_inline:       68.9 i/s - 8.13x  slower
          simple_ams:       52.3 i/s - 10.71x  slower
                 ams:       17.8 i/s - 31.41x  slower
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
