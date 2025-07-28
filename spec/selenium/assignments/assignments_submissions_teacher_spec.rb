# frozen_string_literal: true

#
# Copyright (C) 2012 - present Instructure, Inc.
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

require_relative "../common"
require_relative "../helpers/files_common"
require_relative "../helpers/submissions_common"

describe "submissions" do
  include_context "in-process server selenium tests"
  include FilesCommon
  include SubmissionsCommon

  context "as a teacher" do
    before do
      course_with_teacher_logged_in
    end

    describe "submission comments" do
      it "allows media comments", priority: "1" do
        stub_kaltura

        student_in_course
        assignment = create_assignment
        get "/courses/#{@course.id}/assignments/#{assignment.id}/submissions/#{@student.id}"

        # make sure the JS didn't burn any bridges, and submit two
        submit_media_comment_1
        submit_media_comment_2

        # check that the thumbnails show up on the right sidebar
        comment_list = driver.find_element(css: ".comment_list")
        number_of_comments = comment_list.find_elements(css: ":scope > *").size
        expect(number_of_comments).to eq 2
      end

      it "allows file comments" do
        student_in_course
        assignment = create_assignment
        get "/courses/#{@course.id}/assignments/#{assignment.id}/submissions/#{@student.id}"

        upload_submission_comment_file
      end

      it "displays error if user tries to submit empty comment" do
        student_in_course
        assignment = create_assignment
        get "/courses/#{@course.id}/assignments/#{assignment.id}/submissions/#{@student.id}"

        comment_save_button.click
        expect(f("[data-testid='error-message-container']")).to be_displayed
      end
    end

    it "displays the grade in grade field", priority: "1" do
      student_in_course
      assignment = create_assignment
      assignment.grade_student @student, grade: 2, grader: @teacher
      get "/courses/#{@course.id}/assignments/#{assignment.id}/submissions/#{@student.id}"
      expect(f(".grading_value")[:value]).to eq "2"
    end

    describe "checkpoints" do
      before do
        @student = student_in_course(active_all: true).user
        @course.account.enable_feature!(:discussion_checkpoints)
        @topic = DiscussionTopic.create_graded_topic!(course: @course, title: "Discussion Topic", user: @teacher)
        @topic.create_checkpoints(reply_to_topic_points: 10, reply_to_entry_points: 5, reply_to_entry_required_count: 2)

        # Create submission for the student
        entry_by_teacher = @topic.discussion_entries.create!(user: @teacher, message: "reply to topic by teacher")
        @topic.discussion_entries.create!(user: @student, message: "reply to topic by student")
        2.times do
          @topic.discussion_entries.create!(user: @student, message: "reply to entry by student", root_entry_id: entry_by_teacher.id, parent_id: entry_by_teacher.id)
        end
      end

      it "Displays grade in grade field, priority: 1" do
        # Grade the student
        @topic.reply_to_topic_checkpoint.grade_student(@student, grade: 8, grader: @teacher)
        @topic.reply_to_entry_checkpoint.grade_student(@student, grade: 4, grader: @teacher)

        assignment = @topic.assignment

        get "/courses/#{@course.id}/assignments/#{assignment.id}/submissions/#{@student.id}"
        wait_for_ajaximations

        expect(ff("[data-testid='default-grade-input']")[0][:value]).to eq "8"
        expect(ff("[data-testid='default-grade-input']")[1][:value]).to eq "4"
      end

      it "Total score is updated when checkpoints are changed, priority: 1" do
        assignment = @topic.assignment

        # Grade the student
        @topic.reply_to_topic_checkpoint.grade_student(@student, grade: 8, grader: @teacher)
        @topic.reply_to_entry_checkpoint.grade_student(@student, grade: 4, grader: @teacher)

        get "/courses/#{@course.id}/assignments/#{assignment.id}/submissions/#{@student.id}"
        wait_for_ajaximations

        expect(f("[data-testid='total-score-display']")[:value]).to eq "12"

        # Change the grade of the checkpoints
        inputs = ff("[data-testid='default-grade-input']")

        # Reply to Topic
        inputs[0].send_keys [:backspace, "9", :tab] # Tab causes "blur" event so submission updates

        # Reply to Entry
        inputs[1].send_keys [:backspace, "5", :tab]

        wait_for_ajaximations
        expect(f("[data-testid='total-score-display']")[:value]).to eq "14"
      end

      context "pass_fail_grading_type" do
        before do
          @student = student_in_course(active_all: true).user
          @topic = DiscussionTopic.create_graded_topic!(course: @course, title: "Discussion Topic", user: @teacher)
          @topic.create_checkpoints(reply_to_topic_points: 10, reply_to_entry_points: 5, reply_to_entry_required_count: 2)

          @topic.assignment.update!(grading_type: "pass_fail", points_possible: 15)
          @topic.assignment.sub_assignments.find_by(sub_assignment_tag: CheckpointLabels::REPLY_TO_TOPIC).update!(grading_type: "pass_fail")
          @topic.assignment.sub_assignments.find_by(sub_assignment_tag: CheckpointLabels::REPLY_TO_ENTRY).update!(grading_type: "pass_fail")

          # Create submission for the student
          entry_by_teacher = @topic.discussion_entries.create!(user: @teacher, message: "reply to topic by teacher")
          @topic.discussion_entries.create!(user: @student, message: "reply to topic by student")
          2.times do
            @topic.discussion_entries.create!(user: @student, message: "reply to entry by student", root_entry_id: entry_by_teacher.id, parent_id: entry_by_teacher.id)
          end
        end

        it "Total score is updated when checkpoints are changed, priority: 1" do
          assignment = @topic.assignment

          # Grade the student
          @topic.reply_to_topic_checkpoint.grade_student(@student, grade: "complete", grader: @teacher)
          @topic.reply_to_entry_checkpoint.grade_student(@student, grade: "incomplete", grader: @teacher)

          get "/courses/#{@course.id}/assignments/#{assignment.id}/submissions/#{@student.id}"
          wait_for_ajaximations

          expect(f("[data-testid='total-score-display']")[:value]).to eq "Incomplete"

          # Select the "reply to entry" dropdown and select "Complete"
          ff("[data-testid='select-dropdown']")[1].click
          f("[data-testid='complete-dropdown-option']").click
          wait_for_ajaximations

          expect(f("[data-testid='total-score-display']")[:value]).to eq "Complete"
        end
      end
    end
  end

  context "student view" do
    before do
      course_with_teacher_logged_in
    end

    it "allows a student view student to view/submit assignments", priority: "1" do
      @assignment = @course.assignments.create(
        title: "Cool Assignment",
        points_possible: 10,
        submission_types: "online_text_entry",
        due_at: Time.now.utc + 2.days
      )

      enter_student_view
      get "/courses/#{@course.id}/assignments/#{@assignment.id}"

      expect(f(".assignment .title")).to include_text @assignment.title
      f(".submit_assignment_link").click
      assignment_form = f("#submit_online_text_entry_form")
      wait_for_tiny(assignment_form)

      type_in_tiny("#submission_body", "my assignment submission")
      expect_new_page_load { scroll_to_submit_button_and_click(assignment_form) }

      expect(@course.student_view_student.submissions.count).to eq 1
      expect(f("#sidebar_content .details")).to include_text "Submitted!"
    end

    it "allows a student view student to submit file upload assignments", priority: "1" do
      skip("investigate in EVAL-2966")
      @assignment = @course.assignments.create(
        title: "Cool Assignment",
        points_possible: 10,
        submission_types: "online_upload",
        due_at: Time.now.utc + 2.days
      )

      enter_student_view
      get "/courses/#{@course.id}/assignments/#{@assignment.id}"

      f(".submit_assignment_link").click

      _filename, fullpath, _data = get_file("testfile1.txt")
      f(".submission_attachment input").send_keys(fullpath)
      scroll_to(f("#submit_file_button"))
      expect_new_page_load { f("#submit_file_button").click }

      expect(f(".details .header")).to include_text "Submitted!"
      expect(f(".details")).to include_text "testfile1"
    end
  end
end
