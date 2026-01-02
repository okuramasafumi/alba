[![Gem Version](https://badge.fury.io/rb/rubocop-md.svg)](http://badge.fury.io/rb/rubocop-md)
![Test](https://github.com/rubocop/rubocop-md/workflows/Test/badge.svg)

# Rubocop Markdown

Run Rubocop against your Markdown files to make sure that code examples follow style guidelines and have valid syntax.

## Features

- Analyzes code blocks within Markdown files
- Shows correct line numbers in output
- Preserves specified language (i.e., do not try to analyze "\`\`\`sh")
- **Supports autocorrect 📝**

This project was developed to keep [test-prof](https://github.com/test-prof/test-prof) guides consistent with Ruby style guide back in 2017. Since then, many popular Ruby projects adopted it, including:

- [Ruby on Rails](https://github.com/rails/rails)
- [AnyCable](https://github.com/anycable/anycable)
- [ViewComponent](https://github.com/ViewComponent/view_component)
- [Action Policy](https://github.com/palkan/action_policy)

## Installation

Add this line to your application's Gemfile:

```ruby
gem "rubocop-md"
```

And then execute:

    $ bundle install

Or install it yourself as:

    $ gem install rubocop-md

## Usage

### Command line

Just require `rubocop-md` plugin in your command:

```sh
rubocop --plugin "rubocop-md" ./lib
```

Autocorrect works too:

```sh
rubocop --plugin "rubocop-md" -a ./lib
```

### Configuration

Code in the documentation does not make sense to be checked for some style guidelines (eg `Style/FrozenStringLiteralComment`).

We described such rules in the [default config](config/default.yml), but if you use the same settings in your project’s `.rubocop.yml` file, `RuboCop` will override them.

Fortunately, `RuboCop` supports directory-level configuration and we can do the next trick.

At first, add `rubocop-md` to your main `.rubocop.yml`:

```yml
# .rubocop.yml

plugins:
  - "rubocop-md"
```

*Notice: additional options*

```yml
# .rubocop.yml

Markdown:
  # Whether to run RuboCop against non-valid snippets
  WarnInvalid: true
  # Whether to lint codeblocks without code attributes
  Autodetect: true
```

Secondly, create empty `.rubocop.yml` in your docs directory.

```bash
├── docs
│   ├── .rubocop.yml
│   ├── doc1.md
│   ├── doc2.md
│   └── doc3.md
├── lib
├── .rubocop.yml # main
└── ...
```

Third, just run

```bash
$ rubocop
```

Also you can add special rules in the second `.rubocop.yml`

```yml
# rubocop.yml in docs folder

Metrics/LineLength:
  Max: 100

Lint/Void:
  Exclude:
    - '*.md'
```

### But if I want to use inline disabling some directive like in classic RuboCop?

You can use this tricks

````md
# my_post.md

... some markdown ...

<span style="display:none;"># rubocop:disable all</span>

```ruby
def my_poor_method(foo)
  [:a, :b, :c] + ["#{foo}".to_sym]
end
```

end of snippet

<span style="display:none;"># rubocop:enable all</span>

... continuation of article ...
````

## How it works?

- Preprocess Markdown source into Ruby source preserving line numbers
- Let RuboCop do its job
- Restore Markdown from preprocessed Ruby if it has been autocorrected

## Limitations

- RuboCop cache is disabled for Markdown files (because cache knows nothing about preprocessing)
- Uses naive Regexp-based approach to extract code blocks from Markdown, support only backticks-style code blocks\*
- No language detection included; if you do not specify language for your code blocks, you'd better turn `WarnInvalid` off (see above)

\* It should be easy to integrate a _real_ parser (e.g. [Kramdown](https://kramdown.gettalong.org)) and handle all possible syntax. Feel free to open an issue or pull request!

## Development

After checking out the repo, run `bundle install` to install dependencies. Then, run `rake test` to run the tests.

To install this gem onto your local machine, run `bundle exec rake install`.

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/rubocop/rubocop-md.

## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).
