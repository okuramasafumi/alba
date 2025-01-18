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
  spec.required_ruby_version = Gem::Requirement.new('>= 3.0.0')

  spec.metadata = {
    'bug_tracker_uri' => 'https://github.com/okuramasafumi/alba/issues',
    'changelog_uri' => 'https://github.com/okuramasafumi/alba/blob/main/CHANGELOG.md',
    'documentation_uri' => 'https://rubydoc.info/github/okuramasafumi/alba',
    'source_code_uri' => 'https://github.com/okuramasafumi/alba',
    'rubygems_mfa_required' => 'true'
  }

  spec.files         = `git ls-files -- lib/*`.split("\n")
  spec.files         += %w[README.md LICENSE.txt CHANGELOG.md]
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']
end
