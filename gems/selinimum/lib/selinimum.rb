#
# Copyright (C) 2015 - present Instructure, Inc.
#
# This file is part of Canvas.
#
# Canvas is free software: you can redistribute it and/or modify it under
# the terms of the GNU Affero General Public License as published by the Free
# Software Foundation, version 3 of the License.
#
# Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
# A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
# details.
#
# You should have received a copy of the GNU Affero General Public License along
# with this program. If not, see <http://www.gnu.org/licenses/>.

module Selinimum
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
      Selinimum::Detectors::WhitelistDetector.new,
      Selinimum::Detectors::JSDetector.new,
      Selinimum::Detectors::JSXDetector.new,
      Selinimum::Detectors::CSSDetector.new,
      Selinimum::Detectors::CoffeeDetector.new,
      Selinimum::Detectors::HandlebarsDetector.new
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

  def self.whitelist
    @whitelist ||= begin
      path = `git rev-parse --show-toplevel`.strip + "/.selinimumignore"
      File.read(path).split(/\r?\n|\r/)
    end
  end
end

require_relative "selinimum/errors"
require_relative "selinimum/git"
require_relative "selinimum/minimizer"
require_relative "selinimum/stat_store"
require_relative "selinimum/detectors"
