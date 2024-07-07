# frozen_string_literal: true

require_relative "lib/ruby_script_exporter/version"

Gem::Specification.new do |spec|
  spec.name = "ruby_script_exporter"
  spec.version = RubyScriptExporter::VERSION
  spec.authors = ["Martin Schaflitzl"]
  spec.email = ["gems@martin-sc.de"]
  spec.license = 'MIT'

  spec.summary = "Export metrics to prometheus from ruby snippets."
  spec.homepage = "https://rubygems.org/gems/ruby_script_exporter"
  spec.required_ruby_version = ">= 2.6.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/mschaf/ruby_script_exporter"
  spec.metadata["changelog_uri"] = "https://github.com/mschaf/ruby_script_exporter/blob/main/CHANGELOG.md"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(__dir__) do
    `git ls-files -z`.split("\x0").reject do |f|
      (File.expand_path(f) == __FILE__) || f.start_with?(*%w[bin/ test/ spec/ features/ .git .circleci appveyor])
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "sinatra", "~> 4.0.0"
  spec.add_dependency "rackup", "~> 2.1.0"
  spec.add_dependency "http", "~> 5.2.0"

  spec.add_development_dependency 'rspec', '~> 3.6'
  spec.add_development_dependency 'timecop', '~> 0.9.8'
  spec.add_development_dependency 'rake', '~> 13.0'
  spec.add_development_dependency 'byebug', '~> 11.1.3'
  spec.add_development_dependency 'webmock', '~> 3.23.1'
end
