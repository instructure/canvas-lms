# frozen_string_literal: true

#
# Copyright (C) 2024 - present Instructure, Inc.
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

describe DataFixup::SetConcludedGradingSchemeIds do
  before do
    concluded_course_without_scheme = Course.create!(grading_standard_id: nil, workflow_state: "completed")
    concluded_course_with_scheme = Course.create!(grading_standard_id: 1, workflow_state: "completed")
    active_course_without_scheme = Course.create!(grading_standard_id: nil, workflow_state: "active")
    active_course_with_scheme = Course.create!(grading_standard_id: 1, workflow_state: "active")

    @inheriting_canvas_default_assignment_letter_grade = Assignment.create!(grading_standard_id: nil, grading_type: "letter_grade", course: concluded_course_without_scheme)
    @inheriting_canvas_default_assignment_gpa_scale = Assignment.create!(grading_standard_id: nil, grading_type: "gpa_scale", course: concluded_course_without_scheme)
    @inheriting_from_course_with_scheme = Assignment.create!(grading_standard_id: nil, grading_type: "letter_grade", course: concluded_course_with_scheme)
    @inheriting_from_active_course_without_scheme = Assignment.create!(grading_standard_id: nil, grading_type: "letter_grade", course: active_course_without_scheme)
    @inheriting_from_active_course_with_scheme = Assignment.create!(grading_standard_id: nil, grading_type: "letter_grade", course: active_course_with_scheme)
  end

  it "sets grading_standard_id to 0 for letter grade assignments inheriting from a concluded course without a grading scheme" do
    expect { DataFixup::SetConcludedGradingSchemeIds.run }.to change {
      @inheriting_canvas_default_assignment_letter_grade.reload.grading_standard_id
    }.from(nil).to(0)
  end

  it "sets grading_standard_id to 0 for gpa scale assignments inheriting from a concluded course without a grading scheme" do
    expect { DataFixup::SetConcludedGradingSchemeIds.run }.to change {
      @inheriting_canvas_default_assignment_gpa_scale.reload.grading_standard_id
    }.from(nil).to(0)
  end

  it "does not set grading_standard_id to 0 for assignments inheriting from a concluded course with a grading scheme" do
    expect { DataFixup::SetConcludedGradingSchemeIds.run }.not_to change {
      @inheriting_from_course_with_scheme.reload.grading_standard_id
    }
  end

  it "does not set grading_standard_id to 0 for assignments inheriting from an active course without a grading scheme" do
    expect { DataFixup::SetConcludedGradingSchemeIds.run }.not_to change {
      @inheriting_from_active_course_without_scheme.reload.grading_standard_id
    }
  end

  it "does not set grading_standard_id to 0 for assignments inheriting from an active course with a grading scheme" do
    expect { DataFixup::SetConcludedGradingSchemeIds.run }.not_to change {
      @inheriting_from_active_course_with_scheme.reload.grading_standard_id
    }
  end
end
