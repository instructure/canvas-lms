#
# Copyright (C) 2011 - present Instructure, Inc.
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

describe Plannable do
  context 'planner_override_for' do
    before :once do
      course_with_student(active_all: true)
    end

    it 'should not return deleted overrides' do
      assignment = assignment_model
      override = assignment.planner_overrides.create!(user: @student)
      override.destroy!
      expect(override.workflow_state).to eq 'deleted'
      expect(assignment.planner_override_for(@student)).to be_nil
    end
  end
end
