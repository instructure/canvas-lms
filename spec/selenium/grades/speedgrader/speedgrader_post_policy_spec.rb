# frozen_string_literal: true

#
# Copyright (C) 2019 - present Instructure, Inc.
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

require_relative "../../common"
require_relative "../pages/speedgrader_page"
require_relative "../pages/student_grades_page"

RSpec.shared_examples "hidden student grade" do
  it "does not post for student in the other section", priority: "1" do
    Speedgrader.select_student(student)
    expect(Speedgrader.hidden_pill).to be_displayed

    user_session(student)
    StudentGradesPage.visit_as_student(@course)
    assignment_row = StudentGradesPage.assignment_row(@assignment)
    aggregate_failures("eye icon is present, no grade is present and no comments are present") do
      expect(StudentGradesPage.hidden_eye_icon(scope: assignment_row)).to be_present
      expect(StudentGradesPage.fetch_assignment_score(@assignment)).to be_blank
      expect(StudentGradesPage.comment_buttons).to be_blank
      expect(assignment_row).not_to contain_css "#comments_thread_#{@assignment.id}"
    end
  end
end

RSpec.shared_examples "ungraded student grade" do
  it "does not post for student in the other section", priority: "1" do
    Speedgrader.select_student(student)
    expect(Speedgrader.hidden_pill_container.text).not_to include "HIDDEN"

    user_session(student)
    StudentGradesPage.visit_as_student(@course)
    assignment_row = StudentGradesPage.assignment_row(@assignment)
    aggregate_failures("eye icon is not present, no grade is present and no comments are present") do
      expect(StudentGradesPage.hidden_eye_icon(scope: assignment_row)).to be_present
      expect(StudentGradesPage.fetch_assignment_score(@assignment)).to be_blank
      expect(StudentGradesPage.comment_buttons).to be_blank
      expect(assignment_row).not_to contain_css "#comments_thread_#{@assignment.id}"
    end
  end
end

RSpec.shared_examples "displayable student grade" do
  it "publishes grade and comments to student", priority: "1" do
    user_session(student)
    StudentGradesPage.visit_as_student(@course)
    StudentGradesPage.comment_buttons.first.click
    aggregate_failures("has grade and comment present") do
      expect(StudentGradesPage.fetch_assignment_score(@assignment)).to eq submission.grade
      expect(StudentGradesPage.submission_comments.first).to include_text submission_comment.comment
    end
  end
end

describe "Speed Grader Post Policy" do
  include_context "in-process server selenium tests"

  # all tests skipped due to flakiness; see the referenced ticket
  before { skip } # EVAL-3613

  before :once do
    @teacher = course_with_teacher(course_name: "Post Policy Course", name: "Teacher", active_all: true).user
    @course = Course.find_by!(name: "Post Policy Course")
    @course.default_post_policy.update!(post_manually: true)

    @first_section = @course.course_sections.first
    @second_section = @course.course_sections.create!(name: "Section 2")

    @first_student = create_users_in_course(
      @course, 1, return_type: :record, name_prefix: "Purple", section: @first_section
    ).first
    @second_student = create_users_in_course(
      @course, 1, return_type: :record, name_prefix: "Indigo", section: @second_section
    ).first

    @assignment = @course.assignments.create!(
      title: "post policy assignment",
      submission_types: "online_text_entry",
      grading_type: "points",
      points_possible: 10
    )
  end

  context "given a submission for each student" do
    before :once do
      @assignment.grade_student(@first_student, grade: 1, grader: @teacher)
      @first_submission = @assignment.submissions.find_by!(user: @first_student)
      @first_submission_comment = @first_submission.submission_comments.create!(
        comment: "first teacher comment",
        author: @teacher
      )

      @assignment.grade_student(@second_student, grade: 2, grader: @teacher)
      @second_submission = @assignment.submissions.find_by!(user: @second_student)
      @second_submission_comment = @second_submission.submission_comments.create!(
        comment: "second teacher comment",
        author: @teacher
      )
    end

    before do
      user_session(@teacher)
      Speedgrader.visit(@course.id, @assignment.id)
    end

    context "when posting for everyone" do
      before do
        # this would be faster if we only ran this one time but
        # there's incompatabilities with :once and :all
        Speedgrader.manually_post_grades(type: :everyone)
      end

      it "disables the post grades option" do
        Speedgrader.click_post_or_hide_grades_button
        expect(Speedgrader.all_grades_posted_link).to be_aria_disabled
      end

      it_behaves_like "displayable student grade" do
        let(:student) { @first_student }
        let(:submission) { @first_submission }
        let(:submission_comment) { @first_submission_comment }
      end

      it_behaves_like "displayable student grade" do
        let(:student) { @second_student }
        let(:submission) { @second_submission }
        let(:submission_comment) { @second_submission_comment }
      end
    end

    context "when posting for everyone in a section" do
      before do
        Speedgrader.manually_post_grades(type: :everyone, sections: [@first_section])
      end

      it_behaves_like "displayable student grade" do
        let(:student) { @first_student }
        let(:submission) { @first_submission }
        let(:submission_comment) { @first_submission_comment }
      end

      it_behaves_like "hidden student grade" do
        let(:student) { @second_student }
      end

      it "Post tray shows unposted count", priority: "1" do
        Speedgrader.click_post_or_hide_grades_button
        Speedgrader.click_post_link
        expect(PostGradesTray.unposted_count).to eq "1"
      end
    end

    context "when hide posted grades for everyone" do
      before do
        Speedgrader.manually_post_grades(type: :everyone)
        Speedgrader.manually_hide_grades
      end

      it "header has hidden icon", priority: "1" do
        expect(Speedgrader.grades_hidden_icon).to be_present
      end

      it "hidden pill displayed in side panel", priority: "1" do
        expect(Speedgrader.hidden_pill).to be_displayed
      end

      it_behaves_like "hidden student grade" do
        let(:student) { @first_student }
      end

      it_behaves_like "hidden student grade" do
        let(:student) { @second_student }
      end
    end

    context "when hide posted grades for section" do
      before do
        Speedgrader.manually_post_grades(type: :everyone)
        Speedgrader.manually_hide_grades(sections: [@second_section])
      end

      it_behaves_like "displayable student grade" do
        let(:student) { @first_student }
        let(:submission) { @first_submission }
        let(:submission_comment) { @first_submission_comment }
      end

      it_behaves_like "hidden student grade" do
        let(:student) { @second_student }
      end
    end
  end

  context "when post for graded" do
    before :once do
      @assignment.grade_student(@first_student, grade: 8, grader: @teacher)
      @first_submission = @assignment.submissions.find_by!(user: @first_student)
      @first_submission_comment = @first_submission.submission_comments.create!(comment: "first teacher comment", author: @teacher)
    end

    before do
      user_session(@teacher)
      Speedgrader.visit(@course.id, @assignment.id)
      Speedgrader.manually_post_grades(type: :graded)
    end

    it_behaves_like "displayable student grade" do
      let(:student) { @first_student }
      let(:submission) { @first_submission }
      let(:submission_comment) { @first_submission_comment }
    end

    it_behaves_like "ungraded student grade" do
      let(:student) { @second_student }
    end
  end

  context "when posting by graded and by section" do
    before :once do
      @assignment.grade_student(@first_student, grade: 1, grader: @teacher)
      @assignment.grade_student(@second_student, grade: 2, grader: @teacher)
      @second_submission = @assignment.submissions.find_by!(user: @second_student)
      @second_submission_comment = @second_submission.submission_comments.create!(
        comment: "second teacher comment",
        author: @teacher
      )
    end

    before do
      user_session(@teacher)
      Speedgrader.visit(@course.id, @assignment.id)
      Speedgrader.manually_post_grades(type: :graded, sections: [@second_section])
    end

    it_behaves_like "hidden student grade" do
      let(:student) { @first_student }
    end

    it_behaves_like "displayable student grade" do
      let(:student) { @second_student }
      let(:submission) { @second_submission }
      let(:submission_comment) { @second_submission_comment }
    end
  end
end
