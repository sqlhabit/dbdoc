require_relative 'lib/dbdoc/version'

Gem::Specification.new do |spec|
  spec.name          = "dbdoc"
  spec.version       = Dbdoc::VERSION
  spec.authors       = ["Anatoli Makarevich"]
  spec.email         = ["makaroni4@gmail.com"]

  spec.summary       = %q{Dbdoc is a tool to keep your database documentation up-to-date and version controlled.}
  spec.description   = %q{Dbdoc is a tool to keep your database documentation up-to-date and version controlled.}
  spec.homepage      = "https://github.com/sqlhabit/dbdoc"
  spec.license       = "MIT"
  spec.required_ruby_version = Gem::Requirement.new(">= 2.3.0")

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/sqlhabit/dbdoc"
  spec.metadata["changelog_uri"] = "https://github.com/sqlhabit/dbdoc/blob/master/CHANGELOG.md"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files         = Dir.chdir(File.expand_path('..', __FILE__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end

  spec.executables   = ["dbdoc"]
  spec.require_paths = ["lib"]
end
