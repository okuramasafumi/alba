## Benchmark for json serializers

This directory contains a few different benchmark scripts. They all use inline Bundler definitions so you can run them by `ruby benchmark/collection.rb` for instance.

## Result

As a reference, here's the benchmark result run in my (@okuramasafumi) machine.

Machine spec:

|Key|Value|
|---|---|
|OS|macOS 14.7|
|CPU|Apple M1 Pro|
|RAM|16GB|
|Ruby|ruby 3.3.5 (2024-09-03 revision ef084cc8f4) [arm64-darwin23]|

Library versions:

|Library|Version|
|---|---|
|alba|3.2.0|
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
               panko:      447.0 i/s
         jserializer:      168.9 i/s - 2.65x  slower
         alba_inline:      149.4 i/s - 2.99x  slower
                alba:      146.5 i/s - 3.05x  slower
       turbostreamer:      138.7 i/s - 3.22x  slower
               rails:      105.6 i/s - 4.23x  slower
     fast_serializer:       97.6 i/s - 4.58x  slower
         blueprinter:       66.7 i/s - 6.70x  slower
       representable:       50.6 i/s - 8.83x  slower
          simple_ams:       35.5 i/s - 12.57x  slower
                 ams:       14.8 i/s - 30.25x  slower
```

`benchmark-ips` without `Oj.optimize_rails`:

```
Comparison:
               panko:      457.9 i/s
         jserializer:      165.9 i/s - 2.76x  slower
                alba:      160.1 i/s - 2.86x  slower
         alba_inline:      158.5 i/s - 2.89x  slower
       turbostreamer:      141.7 i/s - 3.23x  slower
     fast_serializer:       96.2 i/s - 4.76x  slower
               rails:       87.2 i/s - 5.25x  slower
         blueprinter:       67.4 i/s - 6.80x  slower
       representable:       43.4 i/s - 10.55x  slower
          simple_ams:       34.7 i/s - 13.20x  slower
                 ams:       14.2 i/s - 32.28x  slower
```

`benchmark-ips` with `Oj.optimize_rail` and YJIT:

```
Comparison:
               panko:      676.6 i/s
         jserializer:      285.3 i/s - 2.37x  slower
       turbostreamer:      264.2 i/s - 2.56x  slower
                alba:      258.9 i/s - 2.61x  slower
     fast_serializer:      179.0 i/s - 3.78x  slower
               rails:      150.7 i/s - 4.49x  slower
         alba_inline:      131.5 i/s - 5.15x  slower
         blueprinter:      110.0 i/s - 6.15x  slower
       representable:       73.5 i/s - 9.21x  slower
          simple_ams:       62.8 i/s - 10.77x  slower
                 ams:       20.4 i/s - 33.10x  slower
```

`benchmark-ips` with YJIT and without `Oj.optimize_rail`:

```
Comparison:
               panko:      701.9 i/s
                alba:      311.1 i/s - 2.26x  slower
         jserializer:      281.6 i/s - 2.49x  slower
       turbostreamer:      240.4 i/s - 2.92x  slower
     fast_serializer:      180.5 i/s - 3.89x  slower
         alba_inline:      135.6 i/s - 5.18x  slower
               rails:      131.4 i/s - 5.34x  slower
         blueprinter:      110.7 i/s - 6.34x  slower
       representable:       70.5 i/s - 9.96x  slower
          simple_ams:       57.3 i/s - 12.24x  slower
                 ams:       20.3 i/s - 34.51x  slower
```

`benchmark-memory`:

```
Comparison:
               panko:     259178 allocated
       turbostreamer:     817800 allocated - 3.16x more
         jserializer:     826425 allocated - 3.19x more
                alba:     846465 allocated - 3.27x more
         alba_inline:     867361 allocated - 3.35x more
     fast_serializer:    1474345 allocated - 5.69x more
               rails:    2265905 allocated - 8.74x more
         blueprinter:    2469905 allocated - 9.53x more
       representable:    4994281 allocated - 19.27x more
                 ams:    5233265 allocated - 20.19x more
          simple_ams:    9506817 allocated - 36.68x more
```

Conclusion: panko is extremely fast but it's a C extension gem. As pure Ruby gems, Alba, `turbostreamer` and `jserializer` are notably faster than others, but Alba is slightly slower than other two. With `Oj.optimize_rails`, `jbuilder` and Rails standard serialization are also fast.
