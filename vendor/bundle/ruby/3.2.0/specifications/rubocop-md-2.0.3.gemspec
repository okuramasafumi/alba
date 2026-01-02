# -*- encoding: utf-8 -*-
# stub: rubocop-md 2.0.3 ruby lib

Gem::Specification.new do |s|
  s.name = "rubocop-md".freeze
  s.version = "2.0.3"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.metadata = { "bug_tracker_uri" => "http://github.com/rubocop/rubocop-md/issues", "changelog_uri" => "https://github.com/rubocop/rubocop-md/blob/master/CHANGELOG.md", "default_lint_roller_plugin" => "RuboCop::Markdown::Plugin", "documentation_uri" => "https://github.com/rubocop/rubocop-md/blob/master/README.md", "homepage_uri" => "https://github.com/rubocop/rubocop-md", "source_code_uri" => "http://github.com/rubocop/rubocop-md" } if s.respond_to? :metadata=
  s.require_paths = ["lib".freeze]
  s.authors = ["Vladimir Dementyev".freeze]
  s.date = "2025-09-30"
  s.description = "Run RuboCop against your Markdown files to make sure that code examples follow style guidelines.".freeze
  s.email = ["dementiev.vm@gmail.com".freeze]
  s.homepage = "https://github.com/rubocop/rubocop-md".freeze
  s.licenses = ["MIT".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 2.7.0".freeze)
  s.rubygems_version = "3.4.20".freeze
  s.summary = "Run RuboCop against your Markdown files to make sure that code examples follow style guidelines.".freeze

  s.installed_by_version = "3.4.20" if s.respond_to? :installed_by_version

  s.specification_version = 4

  s.add_runtime_dependency(%q<lint_roller>.freeze, ["~> 1.1"])
  s.add_runtime_dependency(%q<rubocop>.freeze, [">= 1.72.1"])
  s.add_development_dependency(%q<bundler>.freeze, [">= 1.15"])
  s.add_development_dependency(%q<rake>.freeze, [">= 13.0"])
  s.add_development_dependency(%q<minitest>.freeze, ["~> 5.0"])
end
