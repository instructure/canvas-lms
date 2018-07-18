#
# Copyright (C) 2018 - present Instructure, Inc.
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
require_relative "../../helpers/speed_grader_common"
require_relative "../pages/speedgrader_page"

describe "SpeedGrader" do
  include_context "in-process server selenium tests"
  include SpeedGraderCommon

  before(:once) do
    # a course with 1 teacher
    @teacher1 = course_with_teacher(name: 'Teacher1', active_all: true).user
    @teacher2 = course_with_teacher(course: @course, name: 'Teacher2', active_all: true).user
    @teacher3 = course_with_teacher(course: @course, name: 'Teacher3', active_all: true).user

    # enroll two students
    @student1 = User.create!(name: 'First Student')
    @student1.register!
    @course.enroll_student(@student1, enrollment_state: 'active')

    @student2 = User.create!(name: 'Second Student')
    @student2.register!
    @course.enroll_student(@student2, enrollment_state: 'active')
  end

  context "with an anonymous assignment" do
    before(:each) do
      # an anonymous assignment
      @assignment = @course.assignments.create!(
        name: 'anonymous assignment',
        points_possible: 10,
        submission_types: 'online_text_entry,online_upload',
        anonymous_grading: true
      )

      # Student1 & Student2 submit homework and a comment
      file_attachment = attachment_model(content_type: 'application/pdf', context: @student1)
      @submission1 = @assignment.submit_homework(@student1,
                                  submission_type: 'online_upload',
                                  attachments: [file_attachment],
                                  comment: "This is Student One's comment")

      file_attachment = attachment_model(content_type: 'application/pdf', context: @student2)
      @submission1 = @assignment.submit_homework(@student2,
                                                 submission_type: 'online_upload',
                                                 attachments: [file_attachment],
                                                 comment: "This is Student Two's comment")
      user_session(@teacher)
      Speedgrader.visit(@course.id, @assignment.id)
    end

    it "student names are anonymous", priority: "1", test_id: 3481048 do
      Speedgrader.students_dropdown_button.click
      student_names = Speedgrader.students_select_menu_list.map(&:text)
      expect(student_names).to eql ["Student 1", "Student 2"]
    end

    context "given a specific student" do
      before do
        Speedgrader.click_next_or_prev_student(:next)
        Speedgrader.students_dropdown_button.click
        @current_student = Speedgrader.selected_student
      end

      it "when their submission is selected and page reloaded", priority: "1", test_id: 3481049 do
        expect { refresh_page }.not_to change { Speedgrader.selected_student.text }.from('Student 2')
      end
    end

    context "given student comment and file submission" do
      it 'author of comment is anonymous', priority: 2, test_id: 3496274 do
        expect(Speedgrader.comment_citation.first.text).not_to match(/(First|Second) Student/)
        expect(Speedgrader.comment_citation.first.text).to match(/Student (1|2)/)
      end
    end
  end

  context 'with a moderated assignment' do
    before(:each) do
      @moderated_assignment = @course.assignments.create!(
        title: 'Moderated Assignment1',
        grader_count: 2,
        final_grader_id: @teacher1.id,
        grading_type: 'points',
        points_possible: 15,
        submission_types: 'online_text_entry',
        moderated_grading: true
      )
    end

    it 'prevents unmuting the assignment before grades are posted', priority: '2', test_id: 3493531 do
      user_session(@teacher2)
      Speedgrader.visit(@course.id, @moderated_assignment.id)

      expect(Speedgrader.mute_button.attribute('data-muted')).to eq 'true'
      expect(Speedgrader.mute_button.attribute('class')).to include 'disabled'
    end

    it 'allows unmuting the assignment after grades are posted', priority: '2', test_id: 3493531 do
      user_session(@teacher2)
      @moderated_assignment.update!(grades_published_at: Time.zone.now)
      Speedgrader.visit(@course.id, @moderated_assignment.id)

      expect(Speedgrader.mute_button.attribute('class')).not_to include 'disabled'
    end

    it 'allows adding provisional grades', priority: '2', test_id: 3505172 do
      user_session(@teacher2)
      Speedgrader.visit(@course.id, @moderated_assignment.id)
      Speedgrader.enter_grade(10)
      wait_for_ajaximations
      expect(@moderated_assignment.provisional_grades.first.scorer_id).to eq @teacher2.id
    end

    it 'shows multiple provisional grades', priority: '2', test_id: 3505172 do
      @moderated_assignment.grade_student(@student1, grade: '2', grader: @teacher2, provisional: true)
      @moderated_assignment.grade_student(@student1, grade: '3', grader: @teacher3, provisional: true)

      user_session(@teacher1)
      Speedgrader.visit(@course.id, @moderated_assignment.id)
      Speedgrader.show_details_button.click
      expect(Speedgrader.provisional_grade_radio_buttons.length).to eq 3
      expect(Speedgrader.grading_details_container.text).to include 'Custom'
      expect(Speedgrader.grading_details_container.text).to include 'Teacher2'
      expect(Speedgrader.grading_details_container.text).to include 'Teacher3'
    end

    it 'allows selecting a custom grade', priority: '1', test_id: 3505172 do
      @moderated_assignment.grade_student(@student1, grade: '2', grader: @teacher2, provisional: true)
      @moderated_assignment.grade_student(@student1, grade: '3', grader: @teacher3, provisional: true)

      user_session(@teacher1)
      Speedgrader.visit(@course.id, @moderated_assignment.id)
      Speedgrader.show_details_button.click
      Speedgrader.select_provisional_grade_by_label('Custom')
      Speedgrader.enter_grade(12)
      wait_for_ajaximations

      pg = @moderated_assignment.provisional_grades.last
      selections = @moderated_assignment.moderated_grading_selections

      expect(pg.score).to eq 12
      expect(selections.exists?(selected_provisional_grade_id: pg.id)).to be true
    end
  end

  context 'with an anonymous moderated assignment and provisional comments' do
    before(:once) do
      @moderated_assignment = @course.assignments.create!(
        title: 'Moderated Assignment1',
        grader_count: 2,
        final_grader_id: @teacher1.id,
        grading_type: 'points',
        points_possible: 15,
        submission_types: 'online_text_entry',
        moderated_grading: true
      )
      @moderated_assignment.update_submission(
        @student1,
        author: @teacher2,
        comment: 'Some comment text by non-final grader',
        provisional: true
      )
      @moderated_assignment.update_submission(
        @student1,
        author: @teacher3,
        comment: 'Some comment text by another non-final grader',
        provisional: true
      )
      @moderated_assignment.update_submission(
        @student2,
        author: @teacher2,
        comment: 'Some comment text by non-final grader',
        provisional: true
      )
      @moderated_assignment.update_submission(
        @student2,
        author: @teacher3,
        comment: 'Some comment text by another non-final grader',
        provisional: true
      )
      ModerationGrader.find_by(user: @teacher2, assignment: @moderated_assignment).update!(anonymous_id: 'AAAAA')
      ModerationGrader.find_by(user: @teacher3, assignment: @moderated_assignment).update!(anonymous_id: 'BBBBB')
    end

    it "graders cannot view other grader's comments when `grader_comments_visible_to_graders = false`",
       priority: 1, test_id: 3512445 do

      @moderated_assignment.update!(grader_comments_visible_to_graders: false)
      user_session(@teacher3)
      Speedgrader.visit(@course.id, @moderated_assignment.id)

      # dont see Teacher2's comment
      expect(Speedgrader.comments.first.text).not_to include 'Some comment text by non-final grader'
      expect(Speedgrader.comment_citation.first.text).not_to eq 'Teacher2'

      # see comment made by self
      expect(Speedgrader.comments.first.text).to include 'Some comment text by another non-final grader'
      expect(Speedgrader.comment_citation.first.text).to eq 'Teacher3'
    end

    it "graders can view other grader's comments when `grader_comments_visible_to_graders = true`" do # test_id: 3512445

      @moderated_assignment.update!(grader_comments_visible_to_graders: true)
      user_session(@teacher3)
      Speedgrader.visit(@course.id, @moderated_assignment.id)

      expect(Speedgrader.comments.first.text).to include 'Some comment text by non-final grader'
      expect(Speedgrader.comment_citation.first.text).to eq 'Teacher2'
    end

    it "final-grader can view other grader's comments by default", priority: 1, test_id: 3512445 do
      user_session(@teacher1)
      Speedgrader.visit(@course.id, @moderated_assignment.id)

      expect(Speedgrader.comments.first.text).to include 'Some comment text by non-final grader'
      expect(Speedgrader.comment_citation.first.text).to eq 'Teacher2'
    end

    it "final-grader cannot view other grader's name with `grader_names_visible_to_final_grader = false`" do
      @moderated_assignment.update!(
        anonymous_grading: true,
        graders_anonymous_to_graders: true,
        grader_names_visible_to_final_grader: false
      )
      user_session(@teacher1)
      Speedgrader.visit(@course.id, @moderated_assignment.id)

      expect(Speedgrader.comments.first.text).to include 'Some comment text by non-final grader'
      expect(Speedgrader.comment_citation.first.text).to eq 'Grader 1'
    end

    it "anonymizes grader comments for other non-final graders when `graders_anonymous_to_graders = true`",
       priority: 1, test_id: 3505165 do
      @moderated_assignment.update!(
        grader_comments_visible_to_graders: true,
        anonymous_grading: true,
        graders_anonymous_to_graders: true,
        grader_names_visible_to_final_grader: false
      )
      user_session(@teacher3)
      Speedgrader.visit(@course.id, @moderated_assignment.id)
      Speedgrader.click_next_student_btn

      expect(Speedgrader.comments.length).to eq 2
      expect(Speedgrader.comments.first.text).to include 'Some comment text by non-final grader'
      expect(Speedgrader.comment_citation.first.text).to eq 'Grader 1'
    end
  end

  context 'with a moderated anonymous assignment' do
    before(:once) do
      @moderated_anonymous_assignment = @course.assignments.create!(
        title: 'Moderated Anonymous Assignment1',
        grader_count: 2,
        final_grader_id: @teacher1.id,
        moderated_grading: true,
        grader_comments_visible_to_graders: true,
        anonymous_grading: true,
        graders_anonymous_to_graders: true,
        grader_names_visible_to_final_grader: false
      )
    end

    it 'anonymizes grader names in provisional grade details', priority: '2', test_id: 3505172 do
      @moderated_anonymous_assignment.grade_student(@student1, grade: '2', grader: @teacher2, provisional: true)
      @moderated_anonymous_assignment.grade_student(@student1, grade: '3', grader: @teacher3, provisional: true)

      @moderated_anonymous_assignment.grade_student(@student2, grade: '2', grader: @teacher2, provisional: true)
      @moderated_anonymous_assignment.grade_student(@student2, grade: '3', grader: @teacher3, provisional: true)

      user_session(@teacher1)
      Speedgrader.visit(@course.id, @moderated_anonymous_assignment.id)
      Speedgrader.show_details_button.click

      expect(Speedgrader.grading_details_container.text).to include 'Grader 1'
      expect(Speedgrader.grading_details_container.text).to include 'Grader 2'
    end
  end
end
