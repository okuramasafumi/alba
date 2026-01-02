# frozen_string_literal: true

require_relative "lib/rubocop/gem_dev/version"

Gem::Specification.new do |spec|
  spec.name = "rubocop-gem_dev"
  spec.version = Rubocop::GemDev::VERSION
  spec.authors = ["OKURA Masafumi"]
  spec.email = ["masafumi.o1988@gmail.com"]

  spec.summary = "RuboCop configuration for gem development"
  spec.description = "RuboCop configuration for gem development"
  spec.homepage = "https://github.com/okuramasafumi/rubocop-sensible"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 2.6.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/okuramasafumi/rubocop-sensible/rubocop-gem_dev"
  spec.metadata["changelog_uri"] = "https://github.com/okuramasafumi/rubocop-sensible/rubocop-gem_dev/blob/master/CHANGELOG.md"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject do |f|
      (f == __FILE__) || f.match(%r{\A(?:(?:bin|test|spec|features)/|\.(?:git|travis|circleci)|appveyor)})
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  # Uncomment to register a new dependency of your gem
  # spec.add_dependency "example-gem", "~> 1.0"

  # For more information and examples about making a new gem, check out our
  # guide at: https://bundler.io/guides/creating_gem.html
end
