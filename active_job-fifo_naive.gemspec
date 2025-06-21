# frozen_string_literal: true

require_relative "lib/active_job/fifo_naive/version"

Gem::Specification.new do |spec|
  spec.name = "active_job-fifo_naive"
  spec.version = ActiveJob::FifoNaive::VERSION
  spec.authors = ["Uchio Kondo"]
  spec.email = ["udzura@udzura.jp"]

  spec.summary = "fifo adapter sample for active job"
  spec.description = "fifo adapter sample for active job"
  spec.homepage = "https://github.com/udzura/active_job-fifo_naive"
  spec.required_ruby_version = ">= 3.1.0"

  # since it's a sample unsafe implementation of adapters, it won't be released onto RubyGems.org
  spec.metadata["allowed_push_host"] = "nil"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/udzura/active_job-fifo_naive"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  gemspec = File.basename(__FILE__)
  spec.files = IO.popen(%w[git ls-files -z], chdir: __dir__, err: IO::NULL) do |ls|
    ls.readlines("\x0", chomp: true).reject do |f|
      (f == gemspec) ||
        f.start_with?(*%w[bin/ test/ spec/ features/ .git .github appveyor Gemfile])
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "activejob", ">= 7.0"
end
