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

require "rspec/core/formatters/base_formatter"

class AbortOnConsistentBadnessFormatter < ::RSpec::Core::Formatters::BaseFormatter
  ::RSpec::Core::Formatters.register self, :example_finished

  # Number of identical failures in a row before we abort this worker
  RECENT_SPEC_FAILURE_LIMIT = 10

  def example_finished(notification)
    example = notification.example
    return unless example.exception

    recent_spec_errors << example.exception.to_s
    recent_errors = recent_spec_errors.last(RECENT_SPEC_FAILURE_LIMIT)
    if recent_errors.size >= RECENT_SPEC_FAILURE_LIMIT && recent_errors.uniq.size == 1
      $stderr.puts "ERROR: got the same failure #{RECENT_SPEC_FAILURE_LIMIT} times in a row, aborting"
      ::RSpec.world.wants_to_quit = true
    end
  end

  def recent_spec_errors
    @recent_spec_errors ||= []
  end
end
