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
#

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe PlannerHelper do
  include PlannerHelper

  describe "#formatted_planner_date" do
    it 'should create errors for bad dates' do
      expect {formatted_planner_date('start_date', '123-456-789')}.to raise_error(PlannerHelper::InvalidDates)
      expect {formatted_planner_date('end_date', '9876-5-4321')}.to raise_error(PlannerHelper::InvalidDates)
    end
  end
end
