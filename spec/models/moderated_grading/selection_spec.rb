# frozen_string_literal: true

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

describe ModeratedGrading::Selection do
  it { is_expected.to belong_to(:assignment) }

  it do
    expect(subject).to belong_to(:provisional_grade)
      .with_foreign_key(:selected_provisional_grade_id)
      .class_name("ModeratedGrading::ProvisionalGrade")
  end

  it do
    expect(subject).to belong_to(:student)
      .class_name("User")
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

    expect(subject).to validate_uniqueness_of(:student_id).scoped_to(:assignment_id)
  end

  describe "#create_moderation_event" do
    before(:once) do
      course = Course.create!
      @teacher = User.create!
      course.enroll_teacher(@teacher, enrollment_state: :active)
      student = User.create!
      course.enroll_student(student, enrollment_state: :active)
      assignment = course.assignments.create!(moderated_grading: true, grader_count: 2)
      assignment.grade_student(student, grader: @teacher, provisional: true, score: 10)
      @provisional_grade = assignment.provisional_grades.find_by(scorer: @teacher)
      @selection = assignment.moderated_grading_selections.find_by(student:)
    end

    it "raises an error if there is no selected provisional grade" do
      expect { @selection.create_moderation_event(@teacher) }.to raise_error(ActiveRecord::RecordInvalid)
    end

    it "creates an event if there is a selected provisional grade" do
      @selection.update!(provisional_grade: @provisional_grade)
      expect { @selection.create_moderation_event(@teacher) }.to change {
        AnonymousOrModerationEvent.where(user: @teacher, event_type: :provisional_grade_selected).count
      }.from(0).to(1)
    end

    context "given a selection that is updated by a teacher" do
      subject(:event) { @selection.create_moderation_event(@teacher) }

      before(:once) { @selection.update!(provisional_grade: @provisional_grade) }

      it { is_expected.to have_attributes(assignment_id: @selection.assignment_id) }
      it { is_expected.to have_attributes(user_id: @teacher.id) }
      it { is_expected.to have_attributes(submission_id: @provisional_grade.submission_id) }
      it { is_expected.to have_attributes(event_type: "provisional_grade_selected") }
      it { expect(event.payload).to include("id" => @selection.selected_provisional_grade_id) }
      it { expect(event.payload).to include("student_id" => @selection.student_id) }
    end
  end
end
