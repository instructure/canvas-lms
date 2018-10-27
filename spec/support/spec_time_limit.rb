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
    def initialize(message)
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
      Timeout.timeout(timeout, Error.new(Error.message_for(type, timeout))) do
        example.run
      end
      # no error handling needed, since rspec will catch the error and
      # perform set_exception(spec_time_limit_error) on the example
    end

    # find an appropriate timeout for this spec
    def timeout_for(example)
      if ENV.fetch("SELENIUM_REMOTE_URL", "undefined remote url").include? "saucelabs"
        [:status_quo, SAUCELABS_ABSOLUTE_TIMEOUT]
      elsif example.file_path.include? "./spec/selenium/performance/"
        [:status_quo, PERFORMANCE_TIMEOUT]
      elsif (timeout = typical_time_for(example))
        [:status_quo, [timeout, ABSOLUTE_TIMEOUT].min]
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

    def typical_time_for(example)
      return unless defined?(TestQueue::Runner::RSpec::GroupQueue)
      stat_key = TestQueue::Runner::RSpec::GroupQueue.stat_key_for(example.example)
      return unless stats[stat_key]

      # specs inside Timecop.freeze filters can report taking 0 time. In those
      # cases, we just shoot for the target time.
      return if stats[stat_key] == 0

      # since actual time can depend on external factors (hardware, load,
      # photons, etc.), apply a generous fudge factor ... you should only
      # ever hit the threshold when you introduce something :bananas:, e.g.
      # `sleep 10`, or `100.times { course_with_student }`
      #
      # furthermore, these are exempt from rerun thresholds so your build
      # will likely still pass if it was a total fluke.
      ((stats[stat_key] * 2) + 5).ceil
    end

    def stats
      @stats ||= if File.exist?(".test_queue_stats")
                   Marshal.load(IO.binread(".test_queue_stats")) || {}
                 else
                   {}
                 end
    end

    # note: we only see if the file itself was modified, this won't catch
    # changes to things it depends on. but that's where the status_quo stuff
    # helps us out
    def commit_modifies_spec?(example)
      commit_files.include?(example.metadata[:file_path].sub(/\A\.\//, ''))
    end

    def commit_files
      # env var since in test-queue land workers won't have a .git dir
      @commit_files ||= ENV.fetch(
        "RELEVANT_SPECS",
        `git diff-tree --no-commit-id --name-only -r HEAD | grep -E '_spec\.rb$'`
      ).split("\n")
    end
  end
end
