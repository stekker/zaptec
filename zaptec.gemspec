require_relative "lib/zaptec/version"
ruby_version = File.read(".ruby-version").strip

Gem::Specification.new do |spec|
  spec.name          = "stekker_zaptec"
  spec.version       = Zaptec::VERSION
  spec.authors       = ["Team Stekker"]
  spec.email         = ["support@stekker.com"]

  spec.summary       = "Connect to your Zaptec charger"
  spec.description   = "Zaptec connector"
  spec.homepage      = "https://stekker.com"
  spec.required_ruby_version = Gem::Requirement.new(">= #{ruby_version}")

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/stekker/zaptec"
  spec.metadata["changelog_uri"] = "https://github.com/stekker/zaptec"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{\A(?:test|spec|features)/}) }
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_runtime_dependency "activemodel"
  spec.add_runtime_dependency "activesupport"
  spec.add_runtime_dependency "faraday"
  spec.add_runtime_dependency "faraday-cookie_jar"
  spec.add_runtime_dependency "faraday-detailed_logger"
  spec.add_runtime_dependency "faraday_middleware"

  spec.metadata["rubygems_mfa_required"] = "true"
end
