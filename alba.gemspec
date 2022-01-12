require_relative 'lib/alba/version'

Gem::Specification.new do |spec|
  spec.name          = 'alba'
  spec.version       = Alba::VERSION
  spec.authors       = ['OKURA Masafumi']
  spec.email         = ['masafumi.o1988@gmail.com']

  spec.summary       = 'Alba is the fastest JSON serializer for Ruby.'
  spec.description   = "Alba is the fastest JSON serializer for Ruby. It focuses on performance, flexibility and usability."
  spec.homepage      = 'https://github.com/okuramasafumi/alba'
  spec.license       = 'MIT'
  spec.required_ruby_version = Gem::Requirement.new('>= 2.5.0')

  spec.metadata = {
    'bug_tracker_uri' => 'https://github.com/okuramasafumi/issues',
    'changelog_uri' => 'https://github.com/okuramasafumi/alba/blob/main/CHANGELOG.md',
    'documentation_uri' => 'https://rubydoc.info/github/okuramasafumi/alba',
    'source_code_uri' => 'https://github.com/okuramasafumi/alba',
    'rubygems_mfa_required' => 'true'
  }

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']
end
