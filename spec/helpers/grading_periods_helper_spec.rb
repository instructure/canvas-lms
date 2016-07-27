#
# Copyright (C) 2016 Instructure, Inc.
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

require 'spec_helper'

describe GradingPeriodsHelper do
  describe '#grading_period_set_title' do
    it 'uses the grading period set title when present' do
      group = GradingPeriodGroup.new(title: "Example Set")
      expect(helper.grading_period_set_title(group, "Account Name")).to eql("Example Set")
    end

    it 'uses the given account name when the set has no title' do
      group = GradingPeriodGroup.new
      expect(helper.grading_period_set_title(group, "Account Name")).to match(/Account Name/)
    end
  end
end
