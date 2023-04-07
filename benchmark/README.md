## Benchmark for json serializers

This directory contains a few different benchmark scripts. They all use inline Bundler definitions so you can run them by `ruby benchmark/collection.rb` for instance.

## Result

As a reference, here's the benchmark result run in my (@okuramasafumi) machine.

Machine spec:

|Key|Value|
|---|---|
|OS|macOS 13.2.1|
|CPU|Intel Corei7 Quad Core 2.3Ghz|
|RAM|32GB|
|Ruby|ruby 3.2.1 (2023-02-08 revision 31819e82c8) [x86_64-darwin21]|

Library versions:

|Library|Version|
|---|---|
|alba|2.2.0|
|blueprinter|0.25.3|
|fast_serializer_ruby|0.6.9|
|jserializer|0.2.1|
|oj|3.14.2|
|simple_ams|0.2.6|
|representable|3.2.0|
|turbostreamer|1.10.0|
|jbuilder|2.11.5|
|panko_serializer|0.7.9|
|active_model_serializers|0.10.13|

`benchmark-ips` with `Oj.optimize_rails`:

```
Comparison:
               panko:      310.4 i/s
         jserializer:      120.6 i/s - 2.57x  slower
       turbostreamer:      117.3 i/s - 2.65x  slower
               rails:      114.0 i/s - 2.72x  slower
         alba_inline:       99.3 i/s - 3.13x  slower
                alba:       94.1 i/s - 3.30x  slower
     fast_serializer:       67.8 i/s - 4.58x  slower
         blueprinter:       57.6 i/s - 5.39x  slower
       representable:       36.3 i/s - 8.56x  slower
          simple_ams:       23.3 i/s - 13.32x  slower
                 ams:       10.9 i/s - 28.53x  slower
```

`benchmark-ips` without `Oj.optimize_rails`:

```
Comparison:
               panko:      326.1 i/s
       turbostreamer:      120.6 i/s - 2.70x  slower
         jserializer:      119.2 i/s - 2.74x  slower
         alba_inline:      104.3 i/s - 3.13x  slower
                alba:      102.2 i/s - 3.19x  slower
     fast_serializer:       66.9 i/s - 4.88x  slower
         blueprinter:       56.7 i/s - 5.75x  slower
               rails:       33.9 i/s - 9.63x  slower
       representable:       30.3 i/s - 10.77x  slower
          simple_ams:       16.4 i/s - 19.84x  slower
                 ams:        9.4 i/s - 34.56x  slower
```

`benchmark-memory`:

```
Comparison:
               panko:     242426 allocated
       turbostreamer:     817568 allocated - 3.37x more
         jserializer:     831705 allocated - 3.43x more
                alba:    1072217 allocated - 4.42x more
         alba_inline:    1084889 allocated - 4.48x more
     fast_serializer:    1244385 allocated - 5.13x more
               rails:    1272761 allocated - 5.25x more
         blueprinter:    1680137 allocated - 6.93x more
       representable:    2892425 allocated - 11.93x more
                 ams:    4479569 allocated - 18.48x more
          simple_ams:    6957913 allocated - 28.70x more
```

Conclusion: panko is extremely fast but it's a C extension gem. As pure Ruby gems, Alba, `turbostreamer` and `jserializer` are notably faster than others, but Alba is slightly slower than other two. With `Oj.optimize_rails`, `jbuilder` and Rails standard serialization are also fast.
