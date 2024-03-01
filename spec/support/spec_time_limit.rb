# frozen_string_literal: true

#
# Copyright (C) 2017 - present Instructure, Inc.
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

module SpecTimeLimit
  class Error < ::Timeout::Error
    # #initialize and #to_s are overwritten here to prevent Timeout.timeout
    # overwriting the error message to "execution expired"
    def initialize(message) # rubocop:disable Lint/MissingSuper
      @message = message
    end

    def to_s
      @message
    end

    def self.message_for(type, timeout)
      case type
      when :target
        "Exceeded the #{timeout} sec target threshold for new/modified specs"
      when :absolute
        "Exceeded the #{timeout} sec absolute threshold for existing specs"
      else
        "Exceeded the #{timeout} sec historical threshold for this particular spec"
      end
    end
  end

  class << self
    def enforce(example)
      type, timeout = timeout_for(example)
      Timeout.timeout(timeout, Error, Error.message_for(type, timeout), &example)
      # no error handling needed, since rspec will catch the error and
      # perform set_exception(spec_time_limit_error) on the example
    end

    # find an appropriate timeout for this spec
    def timeout_for(example)
      if example.metadata[:custom_timeout]
        raise "Custom timeouts cannot exceed #{ABSOLUTE_TIMEOUT} seconds!" if example.metadata[:custom_timeout].to_i > ABSOLUTE_TIMEOUT

        [:target, example.metadata[:custom_timeout].to_i]
      elsif ENV.fetch("SELENIUM_REMOTE_URL", "undefined remote url").include? "saucelabs"
        [:status_quo, SAUCELABS_ABSOLUTE_TIMEOUT]
      elsif example.file_path.match?(%r{\./spec/selenium/.*rcs}) # files in ./spec/selenium/**/rcs
        [:target, SIDEBAR_LOADING_TIMEOUT]
      elsif example.file_path.include? "./spec/selenium/performance/"
        [:status_quo, PERFORMANCE_TIMEOUT]
      elsif commit_modifies_spec?(example)
        [:target, TARGET_TIMEOUT]
      else
        # in jenkins land, everything should fall into one of the two
        # above, but for local testing or if for some reason we don't have
        # stats, let's still enforce a reasonable timeout
        [:absolute, ABSOLUTE_TIMEOUT]
      end
    end

    SAUCELABS_ABSOLUTE_TIMEOUT = ENV.fetch("SAUCELABS_SPEC_TIME_LIMIT_ABSOLUTE", 240).to_i
    PERFORMANCE_TIMEOUT = ENV.fetch("SPEC_TIME_LIMIT_PERFORMANCE", 120).to_i
    ABSOLUTE_TIMEOUT = ENV.fetch("SPEC_TIME_LIMIT_ABSOLUTE", 60).to_i
    TARGET_TIMEOUT = ENV.fetch("SPEC_TIME_LIMIT_TARGET", 15).to_i
    SIDEBAR_LOADING_TIMEOUT = ENV.fetch("SIDEBAR_LOADING_TIMEOUT", 35).to_i

    # NOTE: we only see if the file itself was modified, this won't catch
    # changes to things it depends on. but that's where the status_quo stuff
    # helps us out
    def commit_modifies_spec?(example)
      commit_files.include?(example.metadata[:file_path].delete_prefix("./"))
    end

    def commit_files
      @commit_files ||=
        `git diff-tree --no-commit-id --name-only -r HEAD | grep -E '_spec\.rb$'`
        .split("\n")
    end
  end
end
