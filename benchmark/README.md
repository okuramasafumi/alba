## Benchmark for json serializers

This directory contains a few different benchmark scripts. They all use inline Bundler definitions so you can run them by `ruby benchmark/collection.rb` for instance.

## Result

As a reference, here's the benchmark result run in my (@okuramasafumi) machine.

Machine spec:

|Key|Value|
|---|---|
|OS|macOS 12.2.1|
|CPU|Intel Corei7 Quad Core 2.3Ghz|
|RAM|32GB|
|Ruby|ruby 3.0.2p107 (2021-07-07 revision 0db68f0233) [x86_64-darwin19]|

`benchmark-ips` with `Oj.optimize_rails`:

```
Comparison:
               panko:      267.6 i/s
               rails:      111.2 i/s - 2.41x  (± 0.00) slower
         jserializer:      106.2 i/s - 2.52x  (± 0.00) slower
                alba:      102.8 i/s - 2.60x  (± 0.00) slower
       turbostreamer:       99.9 i/s - 2.68x  (± 0.00) slower
            jbuilder:       90.7 i/s - 2.95x  (± 0.00) slower
         alba_inline:       90.0 i/s - 2.97x  (± 0.00) slower
           primalize:       82.1 i/s - 3.26x  (± 0.00) slower
     fast_serializer:       62.7 i/s - 4.27x  (± 0.00) slower
 jsonapi_same_format:       59.5 i/s - 4.50x  (± 0.00) slower
             jsonapi:       55.3 i/s - 4.84x  (± 0.00) slower
         blueprinter:       54.1 i/s - 4.95x  (± 0.00) slower
       representable:       35.9 i/s - 7.46x  (± 0.00) slower
          simple_ams:       25.4 i/s - 10.53x  (± 0.00) slower
                 ams:        9.1 i/s - 29.39x  (± 0.00) slower
```

`benchmark-ips` without `Oj.optimize_rails`:

```
Comparison:
               panko:      283.8 i/s
       turbostreamer:      102.9 i/s - 2.76x  (± 0.00) slower
                alba:      102.4 i/s - 2.77x  (± 0.00) slower
         alba_inline:       98.7 i/s - 2.87x  (± 0.00) slower
         jserializer:       93.3 i/s - 3.04x  (± 0.00) slower
     fast_serializer:       60.1 i/s - 4.73x  (± 0.00) slower
         blueprinter:       53.8 i/s - 5.28x  (± 0.00) slower
               rails:       37.1 i/s - 7.65x  (± 0.00) slower
            jbuilder:       37.1 i/s - 7.66x  (± 0.00) slower
           primalize:       31.2 i/s - 9.08x  (± 0.00) slower
 jsonapi_same_format:       28.3 i/s - 10.03x  (± 0.00) slower
       representable:       27.8 i/s - 10.23x  (± 0.00) slower
             jsonapi:       27.5 i/s - 10.34x  (± 0.00) slower
          simple_ams:       16.9 i/s - 16.75x  (± 0.00) slower
                 ams:        8.3 i/s - 34.36x  (± 0.00) slower
```

`benchmark-memory`:

```
Comparison:
               panko:     230418 allocated
                alba:     733217 allocated - 3.18x more
         alba_inline:     748297 allocated - 3.25x more
       turbostreamer:     781008 allocated - 3.39x more
         jserializer:     819705 allocated - 3.56x more
           primalize:    1195163 allocated - 5.19x more
     fast_serializer:    1232385 allocated - 5.35x more
               rails:    1236761 allocated - 5.37x more
         blueprinter:    1588937 allocated - 6.90x more
            jbuilder:    1774157 allocated - 7.70x more
 jsonapi_same_format:    2132489 allocated - 9.25x more
             jsonapi:    2279958 allocated - 9.89x more
       representable:    2869166 allocated - 12.45x more
                 ams:    4473161 allocated - 19.41x more
          simple_ams:    7868345 allocated - 34.15x more
```

Conclusion: panko is extremely fast but it's a C extension gem. As pure Ruby gems, Alba, turbostreamer and jserializer are notably faster than others. With `Oj.optimize_rails` jbuilder and Rails standard serialization are also fast.
