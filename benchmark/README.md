## Benchmark for json serializers

This directory contains a few different benchmark scripts.

## How to run

From the project root, run `bin/benchmark`. It checks the benchmark bundle and
installs missing dependencies before running the selected script (`collection.rb`
by default). Your shell stays in the project root; the launcher changes directory
only in its own process.

```sh
# with `Oj.optimize_rails` and without YJIT
NO_YJIT=1 bin/benchmark

# without `Oj.optimize_rails` and without YJIT
NO_YJIT=1 NO_OJ_OPTIMIZE_RAILS=1 bin/benchmark

# with `Oj.optimize_rails` and YJIT
bin/benchmark

# without `Oj.optimize_rails` and with YJIT
NO_OJ_OPTIMIZE_RAILS=1 bin/benchmark
```

To select another script, pass its name without the `.rb` extension:

```sh
bin/benchmark collection
bin/benchmark single_resource
```

Adding `benchmark/new_case.rb` makes it available as `bin/benchmark new_case`.
Any arguments after the script name are forwarded to that script. Invalid names
and missing scripts fail before dependency installation.

You can still run individual scripts from this directory with `bundle install`
and `bundle exec ruby collection.rb` (or `single_resource.rb`).

## Result

Machine spec:

|Key|Value|
|---|---|
|OS|macOS 26.7.1|
|CPU|Apple M4 Pro|
|RAM|48GB|
|Ruby|ruby 4.0.9 (2026-10-23 revision 3e93b23afc) +PRISM [arm64-darwin25]|

Library versions:

|Library|Version|
|---|---|
|alba|4.0.1|
|barley|0.9.0|
|blueprinter|1.3.0|
|fast_serializer_ruby|0.6.9|
|jserializer|0.2.1|
|oj|3.17.7|
|simple_ams|0.2.6|
|representable|3.3.1|
|turbostreamer|2.0.1|
|jbuilder|2.15.1|
|panko_serializer|0.8.5|
|active_model_serializers|0.10.16|
|activesupport (`rails`)|8.1.4|
|rabl|0.17.0|
|props_template|1.2.0|

`benchmark-ips` with `Oj.optimize_rails` and with YJIT:

```
Comparison:
          props_template:     1338.1 i/s
                   panko:     1257.2 i/s - 1.06x  slower
                    alba:      939.9 i/s - 1.42x  slower
           turbostreamer:      909.7 i/s - 1.47x  slower
                  barley:      887.7 i/s - 1.51x  slower
                jbuilder:      782.9 i/s - 1.71x  slower
             jserializer:      713.7 i/s - 1.87x  slower
             blueprinter:      662.8 i/s - 2.02x  slower
alba_with_transformation:      653.7 i/s - 2.05x  slower
                    rabl:      418.3 i/s - 3.20x  slower
         fast_serializer:      407.2 i/s - 3.29x  slower
                   rails:      357.7 i/s - 3.74x  slower
              simple_ams:      156.9 i/s - 8.53x  slower
           representable:      155.3 i/s - 8.62x  slower
                     ams:       49.6 i/s - 26.98x  slower
             alba_inline:       13.8 i/s - 96.63x  slower
```

`benchmark-ips` without `Oj.optimize_rails` and with YJIT:

```
Comparison:
          props_template:     1254.1 i/s
                   panko:     1194.4 i/s - 1.05x  slower
                    alba:     1060.5 i/s - 1.18x  slower
           turbostreamer:      893.7 i/s - 1.40x  slower
                  barley:      810.6 i/s - 1.55x  slower
                jbuilder:      783.3 i/s - 1.60x  slower
             jserializer:      713.2 i/s - 1.76x  slower
alba_with_transformation:      702.5 i/s - 1.79x  slower
             blueprinter:      672.7 i/s - 1.86x  slower
                    rabl:      409.7 i/s - 3.06x  slower
         fast_serializer:      402.2 i/s - 3.12x  slower
                   rails:      354.3 i/s - 3.54x  slower
           representable:      157.6 i/s - 7.96x  slower
              simple_ams:      152.9 i/s - 8.20x  slower
                     ams:       48.2 i/s - 26.03x  slower
             alba_inline:       13.4 i/s - 93.78x  slower
```

`benchmark-ips` with `Oj.optimize_rails` and without YJIT:

```
Comparison:
                   panko:      754.4 i/s
                  barley:      417.7 i/s - 1.81x  slower
          props_template:      387.0 i/s - 1.95x  slower
             jserializer:      342.3 i/s - 2.20x  slower
                    alba:      331.0 i/s - 2.28x  slower
           turbostreamer:      321.0 i/s - 2.35x  slower
alba_with_transformation:      310.4 i/s - 2.43x  slower
                jbuilder:      285.2 i/s - 2.64x  slower
             blueprinter:      219.9 i/s - 3.43x  slower
                   rails:      187.1 i/s - 4.03x  slower
         fast_serializer:      172.0 i/s - 4.38x  slower
                    rabl:      155.6 i/s - 4.85x  slower
             alba_inline:       90.0 i/s - 8.39x  slower
           representable:       87.5 i/s - 8.62x  slower
              simple_ams:       84.0 i/s - 8.98x  slower
                     ams:       32.0 i/s - 23.54x  slower
```

`benchmark-ips` without YJIT and without `Oj.optimize_rails`:

```
Comparison:
                   panko:      710.3 i/s
                  barley:      409.3 i/s - 1.74x  slower
          props_template:      376.1 i/s - 1.89x  slower
             jserializer:      345.6 i/s - 2.06x  slower
                    alba:      344.5 i/s - 2.06x  slower
           turbostreamer:      325.2 i/s - 2.18x  slower
alba_with_transformation:      322.3 i/s - 2.20x  slower
                jbuilder:      287.8 i/s - 2.47x  slower
             blueprinter:      219.9 i/s - 3.23x  slower
                   rails:      186.6 i/s - 3.81x  slower
         fast_serializer:      173.8 i/s - 4.09x  slower
                    rabl:      155.9 i/s - 4.56x  slower
             alba_inline:       90.3 i/s - 7.87x  slower
           representable:       88.7 i/s - 8.01x  slower
              simple_ams:       82.5 i/s - 8.61x  slower
                     ams:       32.1 i/s - 22.11x  slower
```

`benchmark-memory` (with `Oj.optimize_rails` and YJIT):

```
Comparison:
               panko:     259018 allocated
      props_template:     281698 allocated - 1.09x more
              barley:     617641 allocated - 2.38x more
         blueprinter:     626281 allocated - 2.42x more
       turbostreamer:     641760 allocated - 2.48x more
alba_with_transformation:     817901 allocated - 3.16x more
                alba:     817961 allocated - 3.16x more
         jserializer:     822161 allocated - 3.17x more
            jbuilder:     946201 allocated - 3.65x more
                rabl:    1236107 allocated - 4.77x more
     fast_serializer:    1470161 allocated - 5.68x more
         alba_inline:    2084081 allocated - 8.05x more
               rails:    2902177 allocated - 11.20x more
                 ams:    4698241 allocated - 18.14x more
       representable:    5552201 allocated - 21.44x more
          simple_ams:    8161193 allocated - 31.51x more
```

Conclusion:  with YJIT, `props_template` and `panko` are the fastest and close
enough that the gap is within run-to-run noise. Both rely on native code for
output: `panko` ships its own C extension, and `props_template` writes directly
through Oj. Among pure ruby libraries (no native extensions and
no Oj dependency), `alba` comes next with YJIT, trailing only `panko` and
`props_template`. Without YJIT, `panko` leads clearly and `alba` falls back to
the middle group.
