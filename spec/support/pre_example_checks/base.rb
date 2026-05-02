# frozen_string_literal: true

#
# Copyright (C) 2026 - present Instructure, Inc.
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
#
module PreExampleChecks
  class Base
    def self.run_types
      @run_types || []
    end

    def self.run_during(stages)
      @run_types = Array(stages)
    end

    def self.log(message)
      PreExampleChecks.log(message)
    end

    # Override this method in a class that inherits from PreExampleChecks::Base.
    # The self.run method should be the method that runs whatever checks you
    # want, and returns false if those checks failed (meaning the test name should
    # be logged).
    def self.run
      true
    end

    def self.check_and_log
      result = run
      return if result || result.nil?

      example = RSpec.current_example
      location = example ? "#{example.location} - #{example.full_description}" : "(no example context)"
      log("#{name} check failed for #{location}")
    end
  end
end
