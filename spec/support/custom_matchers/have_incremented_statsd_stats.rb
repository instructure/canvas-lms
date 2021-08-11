# frozen_string_literal: true

#
# Copyright (C) 2021 - present Instructure, Inc.
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
RSpec::Matchers.define :have_incremented_statsd_stats do |stats|
  match do |action|
    allow(InstStatsd::Statsd).to receive(:increment).and_call_original
    stats.each do |obj|
      stat = obj[:stat]
      options = obj[:options]
      count = obj[:count] || 1
      # expect increment to be called with stat and options if provided
      expect(InstStatsd::Statsd).to(
        receive(:increment).with(*[stat, options].compact).exactly(count).times,
        "expected stat: #{stat} with options: #{options} to be incremented exactly #{count} times but wasn't"
      )
    end
    action.call
    RSpec::Mocks.verify  # run mock verifications
  end

  supports_block_expectations
end
