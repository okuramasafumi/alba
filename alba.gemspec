require_relative 'lib/alba/version'

Gem::Specification.new do |spec|
  spec.name          = 'alba'
  spec.version       = Alba::VERSION
  spec.authors       = ['OKURA Masafumi']
  spec.email         = ['masafumi.o1988@gmail.com']

  spec.summary       = 'Alba is a JSON serializer for Ruby, JRuby and TruffleRuby.'
  spec.description   = "Alba is a JSON serializer for Ruby, JRuby and TruffleRuby. It focuses on performance, flexibility and usability."
  spec.homepage      = 'https://github.com/okuramasafumi/alba'
  spec.license       = 'MIT'
  spec.required_ruby_version = Gem::Requirement.new('>= 3.0.0')

  spec.metadata = {
    'bug_tracker_uri' => 'https://github.com/okuramasafumi/alba/issues',
    'changelog_uri' => 'https://github.com/okuramasafumi/alba/blob/main/CHANGELOG.md',
    'documentation_uri' => 'https://okuramasafumi.github.io/alba/',
    'source_code_uri' => 'https://github.com/okuramasafumi/alba',
    'rubygems_mfa_required' => 'true'
  }

  spec.files         = `git ls-files -- lib/*`.split("\n")
  # Ship the signatures so RBS tools load them. `sig/external.rbs` stubs Rails and ActiveSupport APIs for
  # Alba's own type check and would clash with an application's real signatures for them, and
  # `sig/alba/railtie.rbs` needs `Rails::Railtie`, so neither is packaged.
  spec.files         += `git ls-files -- sig/*`.split("\n") - %w[sig/external.rbs sig/alba/railtie.rbs]
  spec.files         += %w[README.md LICENSE.txt CHANGELOG.md]
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']
end
