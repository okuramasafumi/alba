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

Machine spec:

|Key|Value|
|---|---|
|OS|macOS 26.4|
|CPU|Apple M4 Pro|
|RAM|48GB|
|Ruby|ruby 3.4.8 (2025-12-17 revision 995b59f666) +PRISM [arm64-darwin25]|

Library versions:

|Library|Version|
|---|---|
|alba|3.10.0|
|barley|0.9.0|
|blueprinter|1.2.1|
|fast_serializer_ruby|0.6.9|
|jserializer|0.2.1|
|oj|3.16.13|
|simple_ams|0.2.6|
|representable|3.2.0|
|turbostreamer|1.11.0|
|jbuilder|2.14.1|
|panko_serializer|0.8.4|
|active_model_serializers|0.10.16|
|rabl|0.17.0|
|props_template|1.0.1|

`benchmark-ips` with `Oj.optimize_rails` and with YJIT:

```
Comparison:
               panko:     1267.6 i/s
      props_template:      966.2 i/s - 1.31x  slower
                alba:      905.1 i/s - 1.40x  slower
       turbostreamer:      881.3 i/s - 1.44x  slower
         jserializer:      694.1 i/s - 1.83x  slower
alba_with_transformation:      632.2 i/s - 2.01x  slower
        barley_cache:      450.4 i/s - 2.81x  slower
              barley:      437.6 i/s - 2.90x  slower
            jbuilder:      416.0 i/s - 3.05x  slower
     fast_serializer:      384.0 i/s - 3.30x  slower
               rails:      357.1 i/s - 3.55x  slower
                rabl:      299.9 i/s - 4.23x  slower
         blueprinter:      275.1 i/s - 4.61x  slower
       representable:      177.1 i/s - 7.16x  slower
          simple_ams:      114.2 i/s - 11.10x  slower
                 ams:       41.7 i/s - 30.37x  slower
         alba_inline:       12.7 i/s - 99.68x  slower
```

`benchmark-ips` without `Oj.optimize_rails` and with YJIT:

```
Comparison:
               panko:     1281.1 i/s
                alba:     1058.7 i/s - 1.21x  slower
      props_template:      969.6 i/s - 1.32x  slower
       turbostreamer:      877.2 i/s - 1.46x  slower
alba_with_transformation:      705.5 i/s - 1.82x  slower
         jserializer:      702.1 i/s - 1.82x  slower
        barley_cache:      637.6 i/s - 2.01x  slower
              barley:      629.1 i/s - 2.04x  slower
            jbuilder:      532.6 i/s - 2.41x  slower
     fast_serializer:      380.3 i/s - 3.37x  slower
               rails:      324.9 i/s - 3.94x  slower
                rabl:      306.4 i/s - 4.18x  slower
         blueprinter:      274.8 i/s - 4.66x  slower
       representable:      184.3 i/s - 6.95x  slower
          simple_ams:      128.7 i/s - 9.96x  slower
                 ams:       42.0 i/s - 30.49x  slower
         alba_inline:       13.2 i/s - 96.87x  slower
```

`benchmark-ips` with `Oj.optimize_rails` and without YJIT:

```
Comparison:
               panko:      845.8 i/s
      props_template:      386.7 i/s - 2.19x  slower
         jserializer:      384.9 i/s - 2.20x  slower
       turbostreamer:      369.0 i/s - 2.29x  slower
                alba:      367.1 i/s - 2.30x  slower
        barley_cache:      347.4 i/s - 2.43x  slower
alba_with_transformation:      334.1 i/s - 2.53x  slower
              barley:      278.3 i/s - 3.04x  slower
            jbuilder:      224.0 i/s - 3.78x  slower
               rails:      206.1 i/s - 4.10x  slower
     fast_serializer:      189.6 i/s - 4.46x  slower
         blueprinter:      150.3 i/s - 5.63x  slower
                rabl:      114.0 i/s - 7.42x  slower
         alba_inline:      102.1 i/s - 8.28x  slower
       representable:      101.9 i/s - 8.30x  slower
          simple_ams:       73.6 i/s - 11.49x  slower
                 ams:       28.7 i/s - 29.45x  slower
```

`benchmark-ips` without YJIT and without `Oj.optimize_rails`:

```
Comparison:
               panko:      835.7 i/s
        barley_cache:      406.2 i/s - 2.06x  slower
      props_template:      389.1 i/s - 2.15x  slower
                alba:      381.7 i/s - 2.19x  slower
       turbostreamer:      366.6 i/s - 2.28x  slower
         jserializer:      363.3 i/s - 2.30x  slower
alba_with_transformation:      350.5 i/s - 2.38x  slower
              barley:      316.5 i/s - 2.64x  slower
            jbuilder:      232.6 i/s - 3.59x  slower
     fast_serializer:      185.0 i/s - 4.52x  slower
               rails:      163.2 i/s - 5.12x  slower
         blueprinter:      144.2 i/s - 5.80x  slower
                rabl:      113.3 i/s - 7.38x  slower
       representable:      101.7 i/s - 8.22x  slower
         alba_inline:      101.4 i/s - 8.24x  slower
          simple_ams:       75.4 i/s - 11.08x  slower
                 ams:       27.7 i/s - 30.21x  slower
```

`benchmark-memory` (with `Oj.optimize_rails` and YJIT):

```
Comparison:
               panko:     259178 allocated
      props_template:     457698 allocated - 1.77x more
       turbostreamer:     641720 allocated - 2.48x more
         jserializer:     822289 allocated - 3.17x more
alba_with_transformation:     833869 allocated - 3.22x more
                alba:     833929 allocated - 3.22x more
     fast_serializer:    1470129 allocated - 5.67x more
                rabl:    1676235 allocated - 6.47x more
              barley:    2753439 allocated - 10.62x more
               rails:    2757857 allocated - 10.64x more
         alba_inline:    2848849 allocated - 10.99x more
            jbuilder:    2916385 allocated - 11.25x more
        barley_cache:    2973079 allocated - 11.47x more
         blueprinter:    3705929 allocated - 14.30x more
                 ams:    4715961 allocated - 18.20x more
       representable:    5151441 allocated - 19.88x more
          simple_ams:   11133273 allocated - 42.96x more
```

Conclusion: panko is extremely fast but it's a C extension gem. As pure Ruby gems, Alba, `props_template`, `turbostreamer` and `jserializer` are notably faster than others. With `Oj.optimize_rails`, `jbuilder` and Rails standard serialization are also fast. 
