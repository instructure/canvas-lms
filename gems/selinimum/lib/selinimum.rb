module Selinimum
  class SelinimumError < StandardError; end
  class UnknownDependenciesError < SelinimumError; end
  class TooManyDependenciesError < SelinimumError; end

  def self.minimize!(spec_files, options = {})
    sha = options.delete(:sha)
    json_path = options.delete(:json_path)

    unless sha && json_path
      stats = Selinimum::StatStore.fetch_stats(sha) || raise(SelinimumError, "no stats available")
      sha = stats[:sha]
      json_path = stats[:json_path]
    end
    log("selinimizing against #{sha}") if options[:verbose]

    commit_files = Selinimum::Git.change_list(sha) ||
                   raise(SelinimumError, "invalid sha `#{sha}'")
    log("commit files: \n  #{commit_files.join("\n  ")}") if options[:verbose]
    dependency_map = Selinimum::StatStore.load_stats(json_path) ||
                     raise(SelinimumError, "can't load stats from `#{json_path}'")

    minimizer = Selinimum::Minimizer.new(dependency_map, detectors, options)
    minimizer.filter(commit_files, spec_files)
  end

  def self.log(message)
    $stderr.puts message
  end

  def self.detectors
    [
      Selinimum::Detectors::RubyDetector.new,
      Selinimum::Detectors::WhitelistDetector.new
      # TODO: JSDetector et al once they work
    ]
  end

  def self.minimize(spec_files, options = {})
    minimize! spec_files, options
  rescue SelinimumError => e
    $stderr.puts "SELINIMUM: #{e}, testing all the things :("

    spec_files
  rescue => e
    $stderr.puts "SELINIMUM: unexpected error, testing all the things :("
    $stderr.puts e.to_s
    $stderr.puts e.backtrace.join("\n")

    spec_files
  end
end

require_relative "selinimum/capture"
require_relative "selinimum/git"
require_relative "selinimum/minimizer"
require_relative "selinimum/stat_store"
require_relative "selinimum/detectors"
