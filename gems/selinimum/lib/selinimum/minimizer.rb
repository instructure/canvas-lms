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

require "set"
require_relative "errors"

module Selinimum
  class Minimizer
    attr_reader :spec_dependency_map, :detectors, :options

    def initialize(spec_dependency_map, detectors, options = {})
      @spec_dependency_map = spec_dependency_map
      @detectors = detectors
      @options = options
    end

    def filter(commit_files, spec_files)
      commit_files = Set.new(commit_files)
      detectors.each { |detector| detector.commit_files = commit_files }

      if commit_files.any? { |file| !can_maybe_find_dependents?(file) }
        warn "SELINIMUM: some changed files are too global-y, testing all the things :("
        return spec_files
      end

      begin
        commit_dependents = dependents_for(commit_files)
      rescue SelinimumError
        return spec_files
      end

      spec_files.select do |spec|
        spec_dependencies = spec_dependency_map[spec] || []
        spec_dependencies << "file:#{spec}"
        spec_dependencies.any? { |dependency| commit_dependents.include?(dependency) }
      end
    end

    # indicates whether or not this file can potentially be scoped to only
    # the specs that actually need it. it may not actually be, but it's a
    # quick/cheap filter. dependents_for will do a more robust check
    def can_maybe_find_dependents?(file)
      !detector_for(file).nil?
    end

    # get the list of things whose behavior depends on these files, so we
    # can cross reference them with the specs' recorded dependencies.
    # this includes:
    #
    # * bundles in the case of css/js/hbs
    # * the files themselves in the case of recognized ruby stuff (views,
    #   controllers)
    # * nothing in the case of whitelisted/safe stuff
    def dependents_for(files)
      files.inject(Set.new) do |result, file|
        result.merge detector_for(file).dependents_for(file)
      end
    rescue UnknownDependentsError => e
      warn "SELINIMUM: unable to find dependents of #{e}; testing all the things :(\n" \
           "though maybe this file is actually unused? if so, please to delete"
      raise
    end

    def detector_for(file)
      detectors.detect { |detector| detector.can_process?(file, spec_dependency_map) }
    end

    def warn(message)
      $stderr.puts(message) if options[:verbose]
    end
  end
end
