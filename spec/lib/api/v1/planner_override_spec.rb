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

require 'spec_helper'

describe Api::V1::PlannerOverride do
  class PlannerOverrideHarness
    include Api::V1::PlannerOverride
  end

  before :once do
    course_factory active_all: true
    @course.root_account.enable_feature!(:student_planner)

    student_in_course active_all: true
  end

  describe '.planner_override_json' do
    let(:api) { PlannerOverrideHarness.new }
    let(:session) { double }

    it 'should show plannable_type as a string' do
      assignment_model
      po = PlannerOverride.create!(plannable_id: @assignment.id, plannable_type: Assignment, user_id: @student.id)
      json = api.planner_override_json(po, @student, session)
      expect(json['plannable_type']).to eq 'assignment'
    end
  end
end
