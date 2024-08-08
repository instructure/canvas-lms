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

require_relative "../../common"
require_relative "../pages/speedgrader_page"

describe "SpeedGrader - discussion submissions" do
  include_context "in-process server selenium tests"

  before do
    course_with_teacher_logged_in
    outcome_with_rubric
    @assignment = @course.assignments.create(
      name: "some topic",
      points_possible: 10,
      submission_types: "discussion_topic",
      description: "a little bit of content"
    )
    @student = user_with_pseudonym(
      name: "first student",
      active_user: true,
      username: "student@example.com",
      password: "qwertyuiop"
    )
    @course.enroll_user(@student, "StudentEnrollment", enrollment_state: "active")
    # create and enroll second student
    student_2 = user_with_pseudonym(
      name: "second student",
      active_user: true,
      username: "student2@example.com",
      password: "qwertyuiop"
    )
    @course.enroll_user(student_2, "StudentEnrollment", enrollment_state: "active")

    # create discussion entries
    @first_message = "first student message"
    @second_message = "second student message"
    @discussion_topic = DiscussionTopic.find_by(assignment_id: @assignment.id)
    entry = @discussion_topic.discussion_entries
                             .create!(user: @student, message: @first_message)
    entry.update_topic
    entry.context_module_action
    @attachment_thing = attachment_model(context: student_2, filename: "horse.doc", content_type: "application/msword")
    entry_2 = @discussion_topic.discussion_entries
                               .create!(user: student_2, message: @second_message, attachment: @attachment_thing)
    entry_2.update_topic
    entry_2.context_module_action
  end

  it "displays discussion entries for only one student", priority: "1" do
    Speedgrader.visit(@course.id, @assignment.id)

    # check for correct submissions in SpeedGrader iframe
    in_frame "speedgrader_iframe", "#discussion_view_link" do
      expect(f("#main")).to include_text(@first_message)
      expect(f("#main")).not_to include_text(@second_message)
    end
    f("#next-student-button").click
    wait_for_ajax_requests
    in_frame "speedgrader_iframe", "#discussion_view_link" do
      expect(f("#main")).not_to include_text(@first_message)
      expect(f("#main")).to include_text(@second_message)
      url = f("#main div.attachment_data a")["href"]
      expect(url).to include "/files/#{@attachment_thing.id}/download?verifier=#{@attachment_thing.uuid}"
      expect(url).not_to include "/courses/#{@course}"
    end
  end

  it "displays all entries for group discussion submission" do
    entry_text = "first student message in group1"
    root_topic = group_discussion_assignment
    @group1.add_user(@student, "accepted")

    root_topic.child_topic_for(@student).discussion_entries.create!(user: @student, message: entry_text)
    Speedgrader.visit(@course.id, root_topic.assignment.id)

    in_frame "speedgrader_iframe", "#discussion_view_link" do
      expect(f("#main")).to include_text("The submissions for this assignment are posts in the assignment's discussion for this group. Below are the discussion posts for")
      expect(f("#main")).to include_text(entry_text)
    end
  end

  context "discussion_checkpoints" do
    before do
      Account.site_admin.enable_feature!(:react_discussions_post)
      @course.root_account.enable_feature!(:discussion_checkpoints)
    end

    it "displays whole discussion" do
      Speedgrader.visit(@course.id, @assignment.id)
      in_frame("speedgrader_iframe") do
        in_frame("discussion_preview_iframe") do
          wait_for_ajaximations
          expect(f("div[data-testid='isHighlighted']").text).to include(@student.name)
          expect(f(".discussions-search-filter")).to be_displayed
        end
      end
    end

    it "displays whole discussion for group discussion submission" do
      entry_text = "first student message in group1"
      root_topic = group_discussion_assignment
      @group1.add_user(@student, "accepted")

      root_topic.child_topic_for(@student).discussion_entries.create!(user: @student, message: entry_text)
      Speedgrader.visit(@course.id, root_topic.assignment.id)

      in_frame("speedgrader_iframe") do
        in_frame("discussion_preview_iframe") do
          wait_for_ajaximations
          expect(f("div[data-testid='isHighlighted']").text).to include(@student.name)
          expect(f(".discussions-search-filter")).to be_displayed
        end
      end
    end
  end

  context "when student names hidden" do
    it "hides the name of student on discussion iframe", priority: "2" do
      Speedgrader.visit(@course.id, @assignment.id)

      Speedgrader.click_settings_link
      Speedgrader.click_options_link
      Speedgrader.select_hide_student_names
      expect_new_page_load { fj(".ui-dialog-buttonset .ui-button:visible:last").click }

      # check for correct submissions in SpeedGrader iframe
      in_frame "speedgrader_iframe", "#discussion_view_link" do
        expect(f("#main")).to include_text("This Student")
      end
    end

    it "hides student names and shows name of grading teacher" \
       "entries on both discussion links",
       priority: "2" do
      teacher = @course.teachers.first
      teacher_message = "why did the taco cross the road?"

      teacher_entry = @discussion_topic.discussion_entries
                                       .create!(user: teacher, message: teacher_message)
      teacher_entry.update_topic
      teacher_entry.context_module_action

      Speedgrader.visit(@course.id, @assignment.id)

      Speedgrader.click_settings_link
      Speedgrader.click_options_link
      Speedgrader.select_hide_student_names
      expect_new_page_load { fj(".ui-dialog-buttonset .ui-button:visible:last").click }

      # check for correct submissions in SpeedGrader iframe
      in_frame "speedgrader_iframe", "#discussion_view_link" do
        f("#discussion_view_link").click
        wait_for_ajaximations
        authors = ff("h2.discussion-title span")
        expect(authors).to have_size(3)
        author_text = authors.map(&:text).join("\n")
        expect(author_text).to include("This Student")
        expect(author_text).to include("Discussion Participant")
        expect(author_text).to include(teacher.name)
      end
    end

    it "hides avatars on entries on both discussion links", priority: "2" do
      Speedgrader.visit(@course.id, @assignment.id)

      Speedgrader.click_settings_link
      Speedgrader.click_options_link
      Speedgrader.select_hide_student_names
      expect_new_page_load { fj(".ui-dialog-buttonset .ui-button:visible:last").click }

      # check for correct submissions in SpeedGrader iframe
      in_frame "speedgrader_iframe", "#discussion_view_link" do
        f("#discussion_view_link").click
        expect(f("body")).not_to contain_css(".avatar")
      end

      Speedgrader.visit(@course.id, @assignment.id)

      in_frame "speedgrader_iframe", "#discussion_view_link" do
        f(".header_title a").click
        expect(f("body")).not_to contain_css(".avatar")
      end
    end

    context "discussion_checkpoints" do
      before do
        Account.site_admin.enable_feature!(:react_discussions_post)
        @course.root_account.enable_feature!(:discussion_checkpoints)

        @checkpointed_discussion = DiscussionTopic.create_graded_topic!(course: @course, title: "checkpointed discussion")

        Checkpoints::DiscussionCheckpointCreatorService.call(
          discussion_topic: @checkpointed_discussion,
          checkpoint_label: CheckpointLabels::REPLY_TO_TOPIC,
          dates: [{ type: "everyone", due_at: 2.days.from_now }],
          points_possible: 3
        )
        Checkpoints::DiscussionCheckpointCreatorService.call(
          discussion_topic: @checkpointed_discussion,
          checkpoint_label: CheckpointLabels::REPLY_TO_ENTRY,
          dates: [{ type: "everyone", due_at: 3.days.from_now }],
          points_possible: 9,
          replies_required: 3
        )

        @custom_status = CustomGradeStatus.create!(name: "Custom Status", color: "#000000", root_account_id: @course.root_account_id, created_by: @teacher)
      end

      it "displays the SpeedGraderNavigator" do
        Speedgrader.visit(@course.id, @assignment.id)

        in_frame("speedgrader_iframe") do
          in_frame("discussion_preview_iframe") do
            wait_for_ajaximations

            # These should be uncommented out when the implementation is done in the closing
            # Patchset for VICE-3920
            # expect(f("[data-testid='previous-in-speedgrader']")).not_to be_displayed
            # expect(f("[data-testid='next-in-speedgrader']")).not_to be_displayed
            expect(f("[data-testid='jump-to-speedgrader-navigation']")).not_to be_displayed

            driver.execute_script("document.querySelector('[data-testid=\"jump-to-speedgrader-navigation\"]').focus()")
            wait_for_ajaximations

            # These should be uncommented out when the implementation is done in the closing
            # Patchset for VICE-3920
            # expect(f("[data-testid='previous-in-speedgrader']")).to be_displayed
            # expect(f("[data-testid='next-in-speedgrader']")).to be_displayed
            expect(f("[data-testid='jump-to-speedgrader-navigation']")).to be_displayed
          end
        end
      end

      it "can focus on speedgrader previous student button" do
        Speedgrader.visit(@course.id, @assignment.id)

        in_frame("speedgrader_iframe") do
          in_frame("discussion_preview_iframe") do
            wait_for_ajaximations

            driver.execute_script("document.querySelector('[data-testid=\"jump-to-speedgrader-navigation\"]').focus()")
            wait_for_ajaximations

            expect(f("[data-testid='jump-to-speedgrader-navigation']")).to be_displayed

            f("[data-testid='jump-to-speedgrader-navigation']").click
          end
        end

        check_element_has_focus f("#prev-student-button")
      end

      it "displays whole discussion with hidden student names" do
        Speedgrader.visit(@course.id, @assignment.id)

        Speedgrader.click_settings_link
        Speedgrader.click_options_link
        Speedgrader.select_hide_student_names
        expect_new_page_load { fj(".ui-dialog-buttonset .ui-button:visible:last").click }

        in_frame("speedgrader_iframe") do
          in_frame("discussion_preview_iframe") do
            wait_for_ajaximations
            # this verifies full discussion is displayed, and highlight is set to the first
            # student's entry
            expect(f("div[data-testid='isHighlighted']").text).to include("This Student")
            expect(fj("span:contains('Discussion Participant')")).to be_displayed
            expect(f("body")).not_to contain_css(".discussions-search-filter")
          end
        end
      end

      it "changes grade and status and persist it correctly" do
        # Loads Speedgrader for a student
        get "/courses/#{@course.id}/gradebook/speed_grader?assignment_id=#{@checkpointed_discussion.assignment.id}&student_id=#{@student.id}"
        wait_for_ajaximations

        # Sets the grade for the reply_to_topic checkpoint

        reply_to_topic_grade_input = ff("[data-testid='grade-input']")[0]
        reply_to_topic_grade_input.send_keys("2")
        reply_to_topic_grade_input.send_keys(:tab)
        wait_for_ajaximations

        reply_to_topic_assignment = @checkpointed_discussion.assignment.sub_assignments.find_by(sub_assignment_tag: "reply_to_topic")
        reply_to_topic_submission = reply_to_topic_assignment.submissions.find_by(user: @student)

        expect(reply_to_topic_submission.score).to eq 2

        # Sets the grade for the reply_to_entry checkpoint

        reply_to_entry_grade_input = ff("[data-testid='grade-input']")[1]
        reply_to_entry_grade_input.send_keys("5")
        reply_to_entry_grade_input.send_keys(:tab)
        wait_for_ajaximations

        reply_to_entry_assignment = @checkpointed_discussion.assignment.sub_assignments.find_by(sub_assignment_tag: "reply_to_entry")
        reply_to_entry_submission = reply_to_entry_assignment.submissions.find_by(user: @student)

        expect(reply_to_entry_submission.score).to eq 5

        # Change the status of the reply_to_topic checkpoint to late and set the time late to 2 days

        reply_to_topic_select = f("[data-testid='reply_to_topic-checkpoint-status-select']")

        reply_to_topic_select.click
        fj("span[role='option']:contains('Late')").click
        wait_for_ajaximations

        time_late_input = f("[data-testid='reply_to_topic-checkpoint-time-late-input']")
        time_late_input.send_keys("2")
        time_late_input.send_keys(:tab)
        wait_for_ajaximations

        reply_to_topic_submission.reload
        expect(reply_to_topic_submission.late).to be true
        expect(reply_to_topic_submission.late_policy_status).to eq "late"
        expect(reply_to_topic_submission.seconds_late_override).to eq 2 * 24 * 3600

        # Change the status of the reply_to_entry checkpoint to "Custom Status"

        reply_to_entry_select = f("[data-testid='reply_to_entry-checkpoint-status-select']")

        reply_to_entry_select.click
        fj("span[role='option']:contains('Custom Status')").click
        wait_for_ajaximations

        reply_to_entry_submission.reload

        expect(reply_to_entry_submission.custom_grade_status_id).to eq @custom_status.id

        # Reload the page to make sure the grades, statuses and time late are persisted

        get "/courses/#{@course.id}/gradebook/speed_grader?assignment_id=#{@checkpointed_discussion.assignment.id}&student_id=#{@student.id}"
        wait_for_ajaximations

        reply_to_topic_grade_input = ff("[data-testid='grade-input']")[0]
        expect(reply_to_topic_grade_input).to have_value "2"

        reply_to_entry_grade_input = ff("[data-testid='grade-input']")[1]
        expect(reply_to_entry_grade_input).to have_value "5"

        reply_to_topic_select = f("[data-testid='reply_to_topic-checkpoint-status-select']")
        expect(reply_to_topic_select).to have_value "Late"

        time_late_input = f("[data-testid='reply_to_topic-checkpoint-time-late-input']")
        expect(time_late_input).to have_value "2"

        reply_to_entry_select = f("[data-testid='reply_to_entry-checkpoint-status-select']")
        expect(reply_to_entry_select).to have_value "Custom Status"
      end

      it "does not displays the no submission message if student has a partial submission" do
        DiscussionEntry.create!(
          message: "1st level reply",
          discussion_topic_id: @checkpointed_discussion.discussion_topic_id,
          user_id: @student.id
        )

        get "/courses/#{@course.id}/gradebook/speed_grader?assignment_id=#{@checkpointed_discussion.assignment.id}&student_id=#{@student.id}"
        wait_for_ajaximations

        expect(f("#this_student_does_not_have_a_submission")).to_not be_displayed
      end

      it "displays the no submission message if student has no submission" do
        get "/courses/#{@course.id}/gradebook/speed_grader?assignment_id=#{@checkpointed_discussion.assignment.id}&student_id=#{@student.id}"
        wait_for_ajaximations

        expect(f("#this_student_does_not_have_a_submission")).to be_displayed
      end
    end
  end
end
