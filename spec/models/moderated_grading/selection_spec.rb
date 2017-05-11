#
# Copyright (C) 2015 - present Instructure, Inc.
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

describe ModeratedGrading::Selection do
  it { is_expected.to belong_to(:assignment) }

  it do
    is_expected.to belong_to(:provisional_grade).
      with_foreign_key(:selected_provisional_grade_id).
      class_name('ModeratedGrading::ProvisionalGrade')
  end

  it do
    is_expected.to belong_to(:student).
      class_name('User')
  end

  it "is restricted to one selection per assignment/student pair" do
    # Setup an existing record for shoulda-matcher's uniqueness validation since we have
    # not-null constraints
    course = Course.create!
    assignment = course.assignments.create!
    student = User.create!
    assignment.moderated_grading_selections.create! do |sel|
      sel.student_id = student.id
    end

    is_expected.to validate_uniqueness_of(:student_id).scoped_to(:assignment_id)
  end
end
