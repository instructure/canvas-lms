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

describe "SpeedGrader - discussion submissions", :ignore_js_errors do
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
    @student_2 = user_with_pseudonym(
      name: "second student",
      active_user: true,
      username: "student2@example.com",
      password: "qwertyuiop"
    )
    @course.enroll_user(@student_2, "StudentEnrollment", enrollment_state: "active")

    # create discussion entries
    @first_message = "first student message"
    @second_message = "second student message"
    @discussion_topic = DiscussionTopic.find_by(assignment_id: @assignment.id)
    entry = @discussion_topic.discussion_entries
                             .create!(user: @student, message: @first_message)
    entry.update_topic
    entry.context_module_action
    @attachment_thing = attachment_model(context: @student_2, filename: "horse.doc", content_type: "application/msword")
    entry_2 = @discussion_topic.discussion_entries
                               .create!(user: @student_2, message: @second_message, attachment: @attachment_thing)
    entry_2.update_topic
    entry_2.context_module_action
  end

  context "when discussion_checkpoints is off" do
    before do
      @course.account.disable_feature!(:discussion_checkpoints)
    end

    it "displays discussion entries for only one student", priority: "1" do
      Speedgrader.visit(@course.id, @assignment.id)
      # check for correct submissions in SpeedGrader iframe
      in_frame "speedgrader_iframe", "#discussion_view_link" do
        expect(f("#main")).to include_text("The submissions for this assignment are posts in the assignment's discussion. Below are the discussion posts for")
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
  end

  context "discussion_checkpoints" do
    before do
      Account.site_admin.enable_feature!(:react_discussions_post)
      @course.root_account.enable_feature!(:discussion_checkpoints)
    end

    it "displays whole discussion" do
      Speedgrader.visit(@course.id, @assignment.id)
      Speedgrader.permanently_set_to_show_replies_in_context
      Speedgrader.wait_for_speedgrader_iframe
      in_frame("speedgrader_iframe") do
        Speedgrader.wait_for_discussions_iframe
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
      Speedgrader.permanently_set_to_show_replies_in_context
      Speedgrader.wait_for_speedgrader_iframe
      in_frame("speedgrader_iframe") do
        Speedgrader.wait_for_discussions_iframe
        in_frame("discussion_preview_iframe") do
          wait_for_ajaximations
          expect(f("div[data-testid='isHighlighted']").text).to include(@student.name)
          expect(f(".discussions-search-filter")).to be_displayed
        end
      end
    end

    it "displays the SpeedGraderNavigator" do
      Speedgrader.visit(@course.id, @assignment.id)
      Speedgrader.permanently_set_to_show_replies_in_context
      Speedgrader.wait_for_speedgrader_iframe
      in_frame("speedgrader_iframe") do
        Speedgrader.wait_for_discussions_iframe
        in_frame("discussion_preview_iframe") do
          wait_for_ajaximations

          expect(f("[data-testid='previous-in-speedgrader']")).not_to be_displayed
          expect(f("[data-testid='next-in-speedgrader']")).not_to be_displayed
          expect(f("[data-testid='jump-to-speedgrader-navigation']")).not_to be_displayed
          expect(f("body")).to contain_jqcss("[data-testid='jump-to-speedgrader-navigation']")

          # rubocop:disable Specs/NoExecuteScript
          driver.execute_script("document.querySelector('[data-testid=\"jump-to-speedgrader-navigation\"]').focus()")
          # rubocop:enable Specs/NoExecuteScript
          wait_for_ajaximations

          expect(f("[data-testid='previous-in-speedgrader']")).to be_displayed
          expect(f("[data-testid='next-in-speedgrader']")).to be_displayed
          expect(f("[data-testid='jump-to-speedgrader-navigation']")).to be_displayed
        end
      end
    end

    it "can focus on speedgrader previous student button" do
      Speedgrader.visit(@course.id, @assignment.id)
      Speedgrader.permanently_set_to_show_replies_in_context
      Speedgrader.wait_for_speedgrader_iframe
      in_frame("speedgrader_iframe") do
        Speedgrader.wait_for_discussions_iframe
        in_frame("discussion_preview_iframe") do
          wait_for_ajaximations
          # rubocop:disable Specs/NoExecuteScript
          driver.execute_script("document.querySelector('[data-testid=\"jump-to-speedgrader-navigation\"]').focus()")
          # rubocop:enable Specs/NoExecuteScript
          wait_for_ajaximations

          expect(f("[data-testid='jump-to-speedgrader-navigation']")).to be_displayed

          f("[data-testid='jump-to-speedgrader-navigation']").click
        end
      end

      check_element_has_focus f("#prev-student-button")
    end

    it "opens the student context card when clicking on the student name" do
      Speedgrader.visit(@course.id, @assignment.id)
      Speedgrader.permanently_set_to_show_replies_in_context
      Speedgrader.wait_for_all_speedgrader_iframes_to_load do
        f("[data-testid='author_name']").click
        expect(f(".StudentContextTray-Header")).to be_present
      end
    end

    it "focuses on the entry_id defined in the speegrader url in inline even if user has splitscreen preference" do
      entry_3 = @discussion_topic.discussion_entries.create!(user: @student, message: "third student message", parent_id: @discussion_topic.discussion_entries.first.id)
      @teacher.preferences[:discussions_splitscreen_view] = true
      @teacher.save!
      Speedgrader.visit(@course.id, @assignment.id, entry_id: entry_3.id)
      Speedgrader.permanently_set_to_show_replies_in_context

      Speedgrader.wait_for_all_speedgrader_iframes_to_load do
        wait_for_ajaximations
        expect(f("div[data-testid='discussion-root-entry-container'] div.highlight-discussion").text).to include entry_3.message
      end
    end

    it "focuses on the entry_id defined in the speegrader url (inline)" do
      entry_3 = @discussion_topic.discussion_entries.create!(user: @student, message: "third student message", parent_id: @discussion_topic.discussion_entries.first.id)
      @teacher.preferences[:discussions_splitscreen_view] = false
      @teacher.save!
      Speedgrader.visit(@course.id, @assignment.id, entry_id: entry_3.id)
      Speedgrader.permanently_set_to_show_replies_in_context
      Speedgrader.wait_for_all_speedgrader_iframes_to_load do
        wait_for_ajaximations
        expect(f("div[data-testid='discussion-root-entry-container'] div.highlight-discussion").text).to include entry_3.message
      end
    end

    context "sticky header" do
      it "displays the sticky header when scrolling", :ignore_js_errors do
        Speedgrader.visit(@course.id, @assignment.id)
        Speedgrader.permanently_set_to_show_replies_in_context
        Speedgrader.wait_for_speedgrader_iframe
        in_frame("speedgrader_iframe") do
          Speedgrader.wait_for_discussions_iframe
          in_frame("discussion_preview_iframe") do
            wait_for_ajaximations
            scroll_page_to_bottom
            expect(f("div[data-testid='sticky-toolbar']")).to be_present
          end
        end
      end
    end

    context "Default Discussion View Options" do
      it "is set to No Context by default and retains on save" do
        Speedgrader.visit(@course.id, @assignment.id)
        f("button[title='Settings']").click
        fj("[class*=menuItem__label]:contains('Options')").click
        expect(f("input[value='discussion_view_no_context']").attribute("checked")).to eq("true")
        expect(f("body")).not_to contain_jqcss("button[data-testid='discussions-previous-reply-button']")

        Speedgrader.submit_settings_form
        expect(f("body")).not_to contain_jqcss("button[data-testid='discussions-previous-reply-button']")
      end

      it "applies and persists new Discussion View Options selection" do
        Speedgrader.visit(@course.id, @assignment.id)
        Speedgrader.permanently_set_to_show_replies_in_context

        expect(f("button[data-testid='discussions-previous-reply-button']")).to be_present

        Speedgrader.wait_for_speedgrader_iframe
        in_frame("speedgrader_iframe") do
          Speedgrader.wait_for_discussions_iframe
          in_frame("discussion_preview_iframe") do
            wait_for_ajaximations
            expect(f("body")).to contain_jqcss(".discussions-search-filter")
          end
        end

        Speedgrader.visit(@course.id, @assignment.id)

        f("button[title='Settings']").click
        fj("[class*=menuItem__label]:contains('Options')").click
        expect(f("input[value='discussion_view_with_context']").attribute("checked")).to eq("true")
        fj(".ui-dialog-buttonset .ui-button:visible:first").click

        expect(f("button[data-testid='discussions-previous-reply-button']")).to be_present

        Speedgrader.wait_for_speedgrader_iframe
        in_frame("speedgrader_iframe") do
          Speedgrader.wait_for_discussions_iframe
          in_frame("discussion_preview_iframe") do
            wait_for_ajaximations
            expect(f("body")).to contain_jqcss(".discussions-search-filter")
          end
        end
      end
    end

    context "discussion context temporary toggling", skip: "EGG-1031" do
      it "toggles back and forth group discussions just fine", :ignore_js_errors do
        entry_text = "first student message in group1"
        root_topic = group_discussion_assignment
        @group1.add_user(@student, "accepted")

        entry = root_topic.child_topic_for(@student).discussion_entries.create!(user: @student, message: entry_text)
        Speedgrader.visit(@course.id, root_topic.assignment.id)
        wait_for_ajaximations

        # every time a temporary toggle is clicked, iframes get removed and recreated
        Speedgrader.wait_for_parent_speedgrader_iframe_to_load do
          wait_for_ajaximations
          expect(f("#main")).to include_text("The submissions for the assignment are posts in the assignment's discussion for this group. You can view the discussion posts for")
          expect(f("#main")).to include_text(entry_text)
          wait_for(method: nil, timeout: 3) { f("#discussion_temporary_toggle") }
          f("#discussion_temporary_toggle").click
        end

        Speedgrader.wait_for_all_speedgrader_iframes_to_load do
          wait_for(method: nil, timeout: 5) { f("div.highlight-discussion") }
          # test higlighting
          expect(f("div.highlight-discussion").text).to include(entry.message)
          # test header elements
          expect(fj("button:contains('Expand Threads')")).to be_present
          expect("f[data-testid='groups-menu-btn']").to be_present
          expect(f("span[data-testid='toggle-filter-menu']")).to be_present
          expect(f("input[data-testid='search-filter']")).to be_present
          expect(f("button[data-testid='sortButton']")).to be_present
          # click on temporary toggle
          f("button#switch-to-individual-posts-link").click
        end
        wait_for_ajaximations

        # again in the legacy view
        Speedgrader.wait_for_parent_speedgrader_iframe_to_load do
          wait_for(method: nil, timeout: 3) { f("#discussion_temporary_toggle") }
          expect(f("#discussion_temporary_toggle")).to be_present
        end
        wait_for_ajaximations
      end

      it "it toggles non-group discussions just fine" do
        Speedgrader.visit(@course.id, @assignment.id)
        Speedgrader.wait_for_parent_speedgrader_iframe_to_load do
          expect(f("#main")).to include_text("The submissions for the assignment are posts in the assignment's discussion. You can view the discussion posts for")
          wait_for(method: nil, timeout: 3) { f("#discussion_temporary_toggle") }
          f("#discussion_temporary_toggle").click
        end

        Speedgrader.wait_for_all_speedgrader_iframes_to_load do
          f("button#switch-to-individual-posts-link").click
        end

        Speedgrader.wait_for_parent_speedgrader_iframe_to_load do
          wait_for(method: nil, timeout: 3) { f("#discussion_temporary_toggle") }
          expect(f("#discussion_temporary_toggle")).to be_present
        end
      end

      it "toggles back and forth via specific discussion entries just fine", :ignore_js_errors do
        2.times do |i|
          @discussion_topic.discussion_entries.create!(user: @student, message: "extra message #{i}")
        end

        Speedgrader.visit(@course.id, @assignment.id)
        # we start in individual posts view
        Speedgrader.wait_for_parent_speedgrader_iframe_to_load do
          f("[id='discussion_link_entryId=#{@discussion_topic.discussion_entries.last.id}']").click
          wait_for_ajaximations
        end

        # we are now in full context view
        Speedgrader.wait_for_all_speedgrader_iframes_to_load do
          expect(f("div[data-testid='isHighlighted']").text).to include(@discussion_topic.discussion_entries.last.message)
          f("button#switch-to-individual-posts-link").click
          wait_for_ajaximations
        end

        # we are back in individual posts view
        Speedgrader.wait_for_parent_speedgrader_iframe_to_load do
          wait_for(method: nil, timeout: 3) { f("#discussion_temporary_toggle") }
          expect(f("#discussion_temporary_toggle")).to be_present

          f("[id='discussion_link_entryId=#{@discussion_topic.discussion_entries.first.id}']").click
        end

        # lastly we are back in full context view
        Speedgrader.wait_for_all_speedgrader_iframes_to_load do
          expect(f("div[data-testid='isHighlighted']").text).to include(@discussion_topic.discussion_entries.first.message)
        end
      end
    end

    context "with checkpoint submissions" do
      before do
        Account.site_admin.enable_feature!(:react_discussions_post)
        @course.root_account.enable_feature!(:discussion_checkpoints)

        @checkpointed_discussion = DiscussionTopic.create_graded_topic!(course: @course, title: "checkpointed discussion")
        @replies_required = 3

        @reply_to_topic_checkpoint = Checkpoints::DiscussionCheckpointCreatorService.call(
          discussion_topic: @checkpointed_discussion,
          checkpoint_label: CheckpointLabels::REPLY_TO_TOPIC,
          dates: [{ type: "everyone", due_at: 2.days.from_now }],
          points_possible: 3
        )
        @reply_to_entry_checkpint = Checkpoints::DiscussionCheckpointCreatorService.call(
          discussion_topic: @checkpointed_discussion,
          checkpoint_label: CheckpointLabels::REPLY_TO_ENTRY,
          dates: [{ type: "everyone", due_at: 3.days.from_now }],
          points_possible: 9,
          replies_required: @replies_required
        )

        @custom_status = CustomGradeStatus.create!(name: "Custom Status", color: "#000000", root_account_id: @course.root_account_id, created_by: @teacher)
      end

      describe "grading resubmissions" do
        before do
          root_entry = @checkpointed_discussion.discussion_entries.create!(user: @student, message: "reply to topic")
          child_entries = Array.new(@replies_required) do |i|
            @checkpointed_discussion.discussion_entries.create!(user: @student, message: "reply to entry #{i}", parent_entry: root_entry)
          end
          @reply_to_topic_checkpoint.grade_student(@student, grade: 5, grader: @teacher)
          @reply_to_entry_checkpint.grade_student(@student, grade: 7, grader: @teacher)
          root_entry.destroy
          child_entries.each(&:destroy)
          resubmitted_rtt = @checkpointed_discussion.discussion_entries.create!(user: @student, message: "reply to topic resubmitted")
          @replies_required.times { |i| @checkpointed_discussion.discussion_entries.create!(user: @student, message: "reply to entry #{i}", parent_entry: resubmitted_rtt) }
        end

        it "display the regular assignment grading interface after disabling checkpoints", :ignore_js_errors do
          @course.root_account.disable_feature!(:discussion_checkpoints)

          get "/courses/#{@course.id}/gradebook/speed_grader?assignment_id=#{@checkpointed_discussion.assignment.id}&student_id=#{@student.id}"
          wait_for_ajaximations

          expect(f("body")).to contain_jqcss("input[id='grading-box-extended']")
        end

        it "displays the use same grade link for the previous submission" do
          # Loads Speedgrader for a student
          get "/courses/#{@course.id}/gradebook/speed_grader?assignment_id=#{@checkpointed_discussion.assignment.id}&student_id=#{@student.id}"
          wait_for_ajaximations

          use_same_grade_links = ff("[data-testid='use-same-grade-link']")
          expect(use_same_grade_links.count).to eq(2)
        end

        it "links are removed when the grade is set" do
          # Loads Speedgrader for a student
          get "/courses/#{@course.id}/gradebook/speed_grader?assignment_id=#{@checkpointed_discussion.assignment.id}&student_id=#{@student.id}"
          wait_for_ajaximations

          use_same_grade_links = ff("[data-testid='use-same-grade-link']")
          expect(use_same_grade_links.count).to eq(2)

          # Sets the grade as the previous submission grade from the reply_to_topic checkpoint
          reply_to_topic_use_same_grade_link = use_same_grade_links[0]
          reply_to_entry_use_same_grade_link = use_same_grade_links[1]

          reply_to_topic_use_same_grade_link.click
          wait_for_ajaximations

          # The use same grade link disappears after the grade is set
          expect(ff("[data-testid='use-same-grade-link']").count).to eq(1)

          # Sets the grade as the previous submission grade from the reply_to_entry checkpoint
          reply_to_entry_use_same_grade_link.click
          wait_for_ajaximations

          # The use same grade link disappears after the grade is set
          expect(f("body")).to_not contain_jqcss("[data-testid='use-same-grade-link']")
        end

        it "changes grade and status and persist it correctly" do
          # Loads Speedgrader for a student
          get "/courses/#{@course.id}/gradebook/speed_grader?assignment_id=#{@checkpointed_discussion.assignment.id}&student_id=#{@student.id}"
          wait_for_ajaximations

          use_same_grade_links = ff("[data-testid='use-same-grade-link']")
          expect(use_same_grade_links.count).to eq(2)

          # Sets the grade as the previous submission grade from the reply_to_topic checkpoint
          reply_to_topic_use_same_grade_link = use_same_grade_links[0]
          reply_to_entry_use_same_grade_link = use_same_grade_links[1]

          reply_to_topic_use_same_grade_link.click
          wait_for_ajaximations

          reply_to_topic_assignment = @checkpointed_discussion.assignment.sub_assignments.find_by(sub_assignment_tag: CheckpointLabels::REPLY_TO_TOPIC)
          reply_to_topic_submission = reply_to_topic_assignment.submissions.find_by(user: @student)

          expect(reply_to_topic_submission.grade).to eq("5")
          expect(reply_to_topic_submission.grade_matches_current_submission).to be true

          # Sets the grade as the previous submission grade from the reply_to_entry checkpoint
          reply_to_entry_use_same_grade_link.click
          wait_for_ajaximations

          reply_to_entry_assignment = @checkpointed_discussion.assignment.sub_assignments.find_by(sub_assignment_tag: CheckpointLabels::REPLY_TO_ENTRY)
          reply_to_entry_submission = reply_to_entry_assignment.submissions.find_by(user: @student)

          expect(reply_to_entry_submission.grade).to eq("7")
          expect(reply_to_entry_submission.grade_matches_current_submission).to be true

          # reload speedgrader to check that grades persist and are correct
          get "/courses/#{@course.id}/gradebook/speed_grader?assignment_id=#{@checkpointed_discussion.assignment.id}&student_id=#{@student.id}"
          wait_for_ajaximations

          # should not contain use same grade links
          expect(f("body")).to_not contain_jqcss("[data-testid='use-same-grade-link']")

          reply_to_topic_grade_input = ff("[data-testid='grade-input']")[0]
          expect(reply_to_topic_grade_input).to have_value "5"

          reply_to_entry_grade_input = ff("[data-testid='grade-input']")[1]
          expect(reply_to_entry_grade_input).to have_value "7"
        end

        it "changes grade using grade input and persists correctly" do
          # Loads Speedgrader for a student
          get "/courses/#{@course.id}/gradebook/speed_grader?assignment_id=#{@checkpointed_discussion.assignment.id}&student_id=#{@student.id}"
          wait_for_ajaximations

          use_same_grade_links = ff("[data-testid='use-same-grade-link']")
          expect(use_same_grade_links.count).to eq(2)

          # Sets the grade using the grade input instead of use same grade link
          reply_to_topic_grade_input = ff("[data-testid='grade-input']")[0]
          reply_to_topic_grade_input.send_keys(:backspace)
          reply_to_topic_grade_input.send_keys("2")
          reply_to_topic_grade_input.send_keys(:tab)
          wait_for_ajaximations

          reply_to_topic_assignment = @checkpointed_discussion.assignment.sub_assignments.find_by(sub_assignment_tag: CheckpointLabels::REPLY_TO_TOPIC)
          reply_to_topic_submission = reply_to_topic_assignment.submissions.find_by(user: @student)

          # Sets resubmission grade to 2 and replay to topic use same grade link is no longer present
          expect(reply_to_topic_submission.grade).to eq("2")
          expect(reply_to_topic_submission.grade_matches_current_submission).to be true
          expect(ff("[data-testid='use-same-grade-link']").count).to eq(1)

          # Sets the grade as the previous submission grade from the reply_to_entry checkpoint
          reply_to_entry_grade_input = ff("[data-testid='grade-input']")[1]
          reply_to_entry_grade_input.send_keys(:backspace)
          reply_to_entry_grade_input.send_keys("5")
          reply_to_entry_grade_input.send_keys(:tab)
          wait_for_ajaximations

          reply_to_entry_assignment = @checkpointed_discussion.assignment.sub_assignments.find_by(sub_assignment_tag: CheckpointLabels::REPLY_TO_ENTRY)
          reply_to_entry_submission = reply_to_entry_assignment.submissions.find_by(user: @student)

          # Sets resubmission grade to 5 and replay to topic use same grade link is no longer present
          expect(reply_to_entry_submission.grade).to eq("5")
          expect(reply_to_entry_submission.grade_matches_current_submission).to be true
          expect(f("body")).to_not contain_jqcss("[data-testid='use-same-grade-link']")

          # reload speedgrader to check that grades persist and are correct
          get "/courses/#{@course.id}/gradebook/speed_grader?assignment_id=#{@checkpointed_discussion.assignment.id}&student_id=#{@student.id}"
          wait_for_ajaximations

          # should not contain use same grade links
          expect(f("body")).to_not contain_jqcss("[data-testid='use-same-grade-link']")

          reply_to_topic_grade_input = ff("[data-testid='grade-input']")[0]
          expect(reply_to_topic_grade_input).to have_value "2"

          reply_to_entry_grade_input = ff("[data-testid='grade-input']")[1]
          expect(reply_to_entry_grade_input).to have_value "5"
        end
      end

      it "changes grade and status and persist it correctly" do
        @course.create_late_policy(
          missing_submission_deduction_enabled: true,
          missing_submission_deduction: 25.0,
          late_submission_deduction_enabled: true,
          late_submission_deduction: 10.0,
          late_submission_interval: "day",
          late_submission_minimum_percent_enabled: true,
          late_submission_minimum_percent: 50.0
        )

        # Loads Speedgrader for a student
        get "/courses/#{@course.id}/gradebook/speed_grader?assignment_id=#{@checkpointed_discussion.assignment.id}&student_id=#{@student.id}"
        wait_for_ajaximations

        # Sets the grade for the reply_to_topic checkpoint

        reply_to_topic_grade_input = ff("[data-testid='grade-input']")[0]
        reply_to_topic_grade_input.send_keys("2")
        reply_to_topic_grade_input.send_keys(:tab)
        wait_for_ajaximations
        # this is the screenreader alert that gets announced when the grade is saved
        # using be_truthy since the alert is not visible
        expect(fj("div:contains('Current Total Updated: 2')")).to be_truthy

        reply_to_topic_assignment = @checkpointed_discussion.assignment.sub_assignments.find_by(sub_assignment_tag: "reply_to_topic")
        reply_to_topic_submission = reply_to_topic_assignment.submissions.find_by(user: @student)

        expect(reply_to_topic_submission.score).to eq(2.0)

        # Sets the grade for the reply_to_entry checkpoint

        reply_to_entry_grade_input = ff("[data-testid='grade-input']")[1]
        reply_to_entry_grade_input.send_keys("5")
        reply_to_entry_grade_input.send_keys(:tab)
        wait_for_ajaximations
        expect(fj("div:contains('Current Total Updated: 7')")).to be_truthy

        reply_to_entry_assignment = @checkpointed_discussion.assignment.sub_assignments.find_by(sub_assignment_tag: "reply_to_entry")
        reply_to_entry_submission = reply_to_entry_assignment.submissions.find_by(user: @student)

        expect(reply_to_entry_submission.score).to eq(5)

        # Change the status of the reply_to_topic checkpoint to late and set the time late to 2 days

        reply_to_topic_select = f("[data-testid='reply_to_topic-checkpoint-status-select']")

        reply_to_topic_select.click
        fj("span[role='option']:contains('Late')").click
        wait_for_ajaximations

        time_late_input = f("[data-testid='reply_to_topic-checkpoint-time-late-input']")
        time_late_input.send_keys("2")
        time_late_input.send_keys(:tab)
        wait_for_ajaximations
        expect(fj("div:contains('Current Total Updated: 6.5')")).to be_truthy

        reply_to_topic_submission.reload
        expect(reply_to_topic_submission.late).to be true
        expect(reply_to_topic_submission.late_policy_status).to eq("late")
        expect(reply_to_topic_submission.seconds_late_override).to eq(2 * 24 * 3600)

        # Change the status of the reply_to_entry checkpoint to "Custom Status"

        reply_to_entry_select = f("[data-testid='reply_to_entry-checkpoint-status-select']")

        reply_to_entry_select.click
        fj("span[role='option']:contains('Custom Status')").click
        wait_for_ajaximations

        reply_to_entry_submission.reload

        expect(reply_to_entry_submission.custom_grade_status_id).to be @custom_status.id

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

      context "out of range values" do
        it "displays This student was just awarded negative points with negative values" do
          get "/courses/#{@course.id}/gradebook/speed_grader?assignment_id=#{@checkpointed_discussion.assignment.id}&student_id=#{@student.id}"
          wait_for_ajaximations

          # Sets the grade for the reply_to_topic checkpoint
          reply_to_topic_grade_input = ff("[data-testid='grade-input']")[0]
          reply_to_topic_grade_input.send_keys("-2")
          reply_to_topic_grade_input.send_keys(:tab)
          wait_for_ajaximations
          expect(fj("span:contains('This student was just awarded negative points.')")).to be_present

          # Sets the grade for the reply_to_entry checkpoint
          reply_to_entry_grade_input = ff("[data-testid='grade-input']")[1]
          reply_to_entry_grade_input.send_keys("-5")
          reply_to_entry_grade_input.send_keys(:tab)
          wait_for_ajaximations
          expect(fj("span:contains('This student was just awarded negative points.')")).to be_present
        end

        it "displays This student was just awarded an unusually high grade with high values" do
          get "/courses/#{@course.id}/gradebook/speed_grader?assignment_id=#{@checkpointed_discussion.assignment.id}&student_id=#{@student.id}"
          wait_for_ajaximations

          # 1.5 is used as a threshold to define when a score is unusually high
          # See OutlierScoreHelper.ts

          # Sets the grade for the reply_to_topic checkpoint
          reply_to_topic_grade_input = ff("[data-testid='grade-input']")[0]
          reply_to_topic_grade = @checkpointed_discussion.reply_to_topic_checkpoint.points_possible * 1.5
          reply_to_topic_grade_input.send_keys(reply_to_topic_grade)
          reply_to_topic_grade_input.send_keys(:tab)
          wait_for_ajaximations
          expect(fj("span:contains('This student was just awarded an unusually high grade.')")).to be_present

          # Sets the grade for the reply_to_entry checkpoint
          reply_to_entry_grade_input = ff("[data-testid='grade-input']")[1]
          reply_to_entry_grade = @checkpointed_discussion.reply_to_entry_checkpoint.points_possible * 1.5
          reply_to_entry_grade_input.send_keys(reply_to_entry_grade)
          reply_to_entry_grade_input.send_keys(:tab)
          wait_for_ajaximations
          expect(fj("span:contains('This student was just awarded an unusually high grade.')")).to be_present
        end
      end

      it "displays the no submission message only if student has a partial submission (reply_to_topic)" do
        de = DiscussionEntry.create!(
          message: "1st level reply",
          discussion_topic_id: @checkpointed_discussion.discussion_topic_id,
          user_id: @student.id
        )

        get "/courses/#{@course.id}/gradebook/speed_grader?assignment_id=#{@checkpointed_discussion.assignment.id}&student_id=#{@student.id}"
        Speedgrader.permanently_set_to_show_replies_in_context
        Speedgrader.wait_for_all_speedgrader_iframes_to_load do
          wait_for_ajaximations
          expect(f("div[data-testid='discussion-root-entry-container']").text).to include(de.message)
        end
        expect(f("#this_student_does_not_have_a_submission")).to_not be_displayed

        de.destroy

        get "/courses/#{@course.id}/gradebook/speed_grader?assignment_id=#{@checkpointed_discussion.assignment.id}&student_id=#{@student.id}"
        wait_for_ajaximations
        expect(f("#this_student_does_not_have_a_submission")).to be_displayed
      end

      it "displays the no submission message only if student has a partial submission (reply_to_entry)" do
        teacher_de = DiscussionEntry.create!(
          message: "1st level reply",
          discussion_topic_id: @checkpointed_discussion.discussion_topic_id,
          user_id: @teacher.id
        )

        student_des = Array.new(3) do |i|
          DiscussionEntry.create!(
            message: "#{i + 1} reply",
            discussion_topic_id: @checkpointed_discussion.discussion_topic_id,
            user_id: @student.id,
            parent_id: teacher_de.id
          )
        end

        get "/courses/#{@course.id}/gradebook/speed_grader?assignment_id=#{@checkpointed_discussion.assignment.id}&student_id=#{@student.id}"
        Speedgrader.permanently_set_to_show_replies_in_context
        Speedgrader.wait_for_all_speedgrader_iframes_to_load do
          wait_for_ajaximations
          expect(f("div[data-testid='discussion-root-entry-container']").text).to include(teacher_de.message)
        end
        expect(f("#this_student_does_not_have_a_submission")).to_not be_displayed

        student_des.each(&:destroy)

        get "/courses/#{@course.id}/gradebook/speed_grader?assignment_id=#{@checkpointed_discussion.assignment.id}&student_id=#{@student.id}"
        wait_for_ajaximations
        expect(f("#this_student_does_not_have_a_submission")).to be_displayed
      end

      it "does not display the no submission message if student has a partial submission and the checkpoints flag is off", :ignore_js_errors do
        @checkpointed_discussion.reply_to_topic_checkpoint.submit_homework(@student, submission_type: "discussion_topic", submitted_at: Time.now.utc)
        @course.root_account.disable_feature!(:discussion_checkpoints)

        get "/courses/#{@course.id}/gradebook/speed_grader?assignment_id=#{@checkpointed_discussion.assignment.id}&student_id=#{@student.id}"
        wait_for_ajaximations
        expect(f("#this_student_does_not_have_a_submission")).to_not be_displayed
      end

      it "displays the no submission message if student has no submission" do
        get "/courses/#{@course.id}/gradebook/speed_grader?assignment_id=#{@checkpointed_discussion.assignment.id}&student_id=#{@student.id}"
        wait_for_ajaximations

        expect(f("#this_student_does_not_have_a_submission")).to be_displayed
      end

      context "discussions navigation" do
        it "does not display if student has no submission" do
          get "/courses/#{@course.id}/gradebook/speed_grader?assignment_id=#{@checkpointed_discussion.assignment.id}&student_id=#{@student.id}"
          wait_for_ajaximations

          expect(f("body")).to_not contain_jqcss("button[data-testid='discussions-previous-reply-button']")
          expect(f("body")).to_not contain_jqcss("button[data-testid='discussions-next-reply-button']")
        end

        it "does not display if not discussion assignment" do
          non_discussion_assignment = @course.assignments.create!(points_possible: 10, submission_types: "online_text_entry")
          non_discussion_assignment.submit_homework(@student, body: "hi")

          expect(non_discussion_assignment.submission_types).to_not eq("discussion_topic")
          get "/courses/#{@course.id}/gradebook/speed_grader?assignment_id=#{non_discussion_assignment.id}&student_id=#{@student.id}"
          wait_for_ajaximations

          expect(f("body")).to_not contain_jqcss("button[data-testid='discussions-previous-reply-button']")
          expect(f("body")).to_not contain_jqcss("button[data-testid='discussions-next-reply-button']")
        end

        it "does display if student has submission" do
          DiscussionEntry.create!(
            message: "1st level reply",
            discussion_topic_id: @checkpointed_discussion.discussion_topic_id,
            user_id: @student.id
          )

          get "/courses/#{@course.id}/gradebook/speed_grader?assignment_id=#{@checkpointed_discussion.assignment.id}&student_id=#{@student.id}"
          Speedgrader.permanently_set_to_show_replies_in_context
          wait_for_ajaximations

          expect(f("button[data-testid='discussions-previous-reply-button']")).to be_displayed
          expect(f("button[data-testid='discussions-next-reply-button']")).to be_displayed
        end
      end

      it "displays the root topic for group discussion if groups have no users", :ignore_js_errors do
        entry_text = "first student message"
        root_topic = group_discussion_assignment
        root_topic.discussion_entries.create!(user: @student, message: entry_text)
        Speedgrader.visit(@course.id, root_topic.assignment.id)

        Speedgrader.click_settings_link
        Speedgrader.click_options_link
        Speedgrader.select_hide_student_names
        fj("label:contains('Show replies in context')").click
        expect_new_page_load { fj(".ui-dialog-buttonset .ui-button:visible:last").click }
        Speedgrader.wait_for_all_speedgrader_iframes_to_load do
          expect(f("div[data-testid='discussion-root-entry-container']").text).to include(@student.name)
          expect(f("div[data-testid='discussion-root-entry-container']").text).to include(entry_text)
          expect(f("body")).not_to contain_jqcss(".discussions-search-filter")
        end
      end
    end
  end

  context "when student names hidden" do
    context "when discussion_checkpoints is off" do
      before do
        Account.site_admin.enable_feature!(:react_discussions_post)
        @course.root_account.disable_feature!(:discussion_checkpoints)
      end

      it "hides the name of student on discussion iframe", priority: "2" do
        Speedgrader.visit(@course.id, @assignment.id)

        Speedgrader.click_settings_link
        Speedgrader.click_options_link
        Speedgrader.select_hide_student_names
        expect_new_page_load { fj(".ui-dialog-buttonset .ui-button:visible:last").click }

        # check for correct submissions in SpeedGrader iframe
        Speedgrader.wait_for_parent_speedgrader_iframe_to_load do
          expect(f("#main")).to include_text("This Student")
        end
      end

      it "hides student names and shows name of grading teacher entries on both discussion links" do
        skip "Will be fixed in VICE-5209"
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
          authors = ff("span[data-testid='author_name']")
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
        Speedgrader.wait_for_parent_speedgrader_iframe_to_load do
          expect(f("body")).not_to contain_css(".avatar")
          f("#discussion_view_link").click
          wait_for_ajaximations
          expect(ff("span[data-testid='anonymous_avatar']").length).to eq 2
        end
      end

      it "displays all entries for group discussion submission" do
        entry_text = "first student message in group1"
        root_topic = group_discussion_assignment
        @group1.add_user(@student, "accepted")

        root_topic.child_topic_for(@student).discussion_entries.create!(user: @student, message: entry_text)
        Speedgrader.visit(@course.id, root_topic.assignment.id)

        Speedgrader.wait_for_parent_speedgrader_iframe_to_load do
          expect(f("#main")).to include_text("The submissions for this assignment are posts in the assignment's discussion for this group. Below are the discussion posts for")
          expect(f("#main")).to include_text(entry_text)
        end
      end
    end

    context "discussion_checkpoints with hide student names" do
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
      end

      it "displays whole discussion with hidden student names", :ignore_js_errors do
        Speedgrader.visit(@course.id, @assignment.id)

        Speedgrader.click_settings_link
        Speedgrader.click_options_link
        Speedgrader.select_hide_student_names
        fj("label:contains('Show replies in context')").click
        expect_new_page_load { fj(".ui-dialog-buttonset .ui-button:visible:last").click }

        Speedgrader.wait_for_all_speedgrader_iframes_to_load do
          # this verifies full discussion is displayed, and highlight is set to the first
          # student's entry
          expect(f("div[data-testid='isHighlighted']").text).to include("This Student")
          expect(fj("span:contains('Discussion Participant')")).to be_displayed
          expect(f("body")).not_to contain_css(".discussions-search-filter")
        end
      end

      it "displays the root topic for group discussion if groups have no users", :ignore_js_errors do
        entry_text = "first student message"
        root_topic = group_discussion_assignment
        root_topic.discussion_entries.create!(user: @student, message: entry_text)
        Speedgrader.visit(@course.id, root_topic.assignment.id)

        Speedgrader.click_settings_link
        Speedgrader.click_options_link
        Speedgrader.select_hide_student_names
        fj("label:contains('Show replies in context')").click
        expect_new_page_load { fj(".ui-dialog-buttonset .ui-button:visible:last").click }

        Speedgrader.wait_for_all_speedgrader_iframes_to_load do
          wait_for_ajaximations
          expect(f("div[data-testid='discussion-root-entry-container']").text).to include("This Student")
          expect(f("div[data-testid='discussion-root-entry-container']").text).to include(entry_text)
          expect(f("body")).not_to contain_jqcss(".discussions-search-filter")
        end
      end
    end
  end
end
