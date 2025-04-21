# frozen_string_literal: true

#
# Copyright (C) 2014 - present Instructure, Inc.
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

require_relative "../helpers/discussions_common"
require_relative "../helpers/items_assign_to_tray"
require_relative "../helpers/assignments_common"
require_relative "../helpers/context_modules_common"
require_relative "../../helpers/k5_common"
require_relative "../dashboard/pages/k5_important_dates_section_page"
require_relative "../dashboard/pages/k5_dashboard_common_page"
require_relative "../common"
require_relative "pages/discussion_page"
require_relative "../assignments/page_objects/assignment_create_edit_page"
require_relative "../discussions/discussion_helpers"

describe "discussions" do
  include_context "in-process server selenium tests"
  include DiscussionsCommon
  include AssignmentsCommon
  include DiscussionHelpers
  include ItemsAssignToTray
  include ContextModulesCommon
  include K5DashboardCommonPageObject
  include K5Common
  include K5ImportantDatesSectionPageObject

  def create_graded_discussion(discussion_course, assignment_options = {})
    default_assignment_options = {
      name: "Default Assignment",
      points_possible: 10,
      assignment_group: discussion_course.assignment_groups.create!(name: "Default Assignment Group"),
      only_visible_to_overrides: false
    }
    options = default_assignment_options.merge(assignment_options)

    @discussion_assignment = discussion_course.assignments.create!(options)
    all_graded_discussion_options = {
      user: teacher,
      title: "assignment topic title",
      message: "assignment topic message",
      discussion_type: "threaded",
      assignment: @discussion_assignment,
    }
    discussion_course.discussion_topics.create!(all_graded_discussion_options)
  end

  let(:course) { course_model.tap(&:offer!) }
  let(:teacher) { teacher_in_course(course:, name: "teacher", active_all: true).user }
  let(:teacher_topic) { course.discussion_topics.create!(user: teacher, title: "teacher topic title", message: "teacher topic message") }
  let(:assignment_group) { course.assignment_groups.create!(name: "assignment group") }
  let(:group_category) { course.group_categories.create!(name: "group category") }
  let(:assignment) do
    course.assignments.create!(
      name: "assignment",
      points_possible: 10,
      # submission_types: 'discussion_topic',
      assignment_group:
    )
  end
  let(:assignment_topic) do
    course.discussion_topics.create!(user: teacher,
                                     title: "assignment topic title",
                                     message: "assignment topic message",
                                     assignment:)
  end

  context "on the edit page", :ignore_js_errors do
    let(:url) { "/courses/#{course.id}/discussion_topics/#{topic.id}/edit" }

    before do
      Account.site_admin.enable_feature!(:discussion_create)
      Account.site_admin.enable_feature!(:react_discussions_post)
      user_session(teacher)
    end

    context "ungraded" do
      before do
        attachment_model
        # TODO: Update to cover: graded, group discussions, file attachment, any other options later implemented
        all_discussion_options_enabled = {
          title: "value for title",
          message: "value for message",
          is_anonymous_author: false,
          anonymous_state: "full_anonymity",
          todo_date: "Thu, 12 Oct 2023 15:59:59.000000000 UTC +00:00",
          allow_rating: true,
          only_graders_can_rate: true,
          podcast_enabled: true,
          podcast_has_student_posts: true,
          require_initial_post: true,
          discussion_type: "side_comment",
          delayed_post_at: "Tue, 10 Oct 2023 16:00:00.000000000 UTC +00:00",
          lock_at: "Wed, 11 Nov 2023 15:59:59.999999000 UTC +00:00",
          is_section_specific: false,
          attachment: @attachment
        }

        @topic_all_options = course.discussion_topics.create!(all_discussion_options_enabled)
        @topic_no_options = course.discussion_topics.create!(title: "no options enabled - topic", message: "test")
      end

      it "displays all selected options correctly" do
        get "/courses/#{course.id}/discussion_topics/#{@topic_all_options.id}/edit"

        expect(f("input[value='full_anonymity']").selected?).to be_truthy
        expect(f("input[value='full_anonymity']").attribute("disabled")).to be_nil

        expect(f("input[value='must-respond-before-viewing-replies']").selected?).to be_truthy
        expect(f("input[value='enable-podcast-feed']").selected?).to be_truthy
        expect(f("input[value='include-student-replies-in-podcast-feed']").selected?).to be_truthy
        expect(f("input[value='allow-liking']").selected?).to be_truthy
        expect(f("input[value='only-graders-can-like']").selected?).to be_truthy
        expect(f("input[value='add-to-student-to-do']").selected?).to be_truthy
      end

      it "can convert ungraded to graded and checkpointed" do
        get "/courses/#{course.id}/discussion_topics/#{@topic_no_options.id}/edit"
        force_click_native("input[data-testid='graded-checkbox']")
        force_click_native("input[data-testid='checkpoints-checkbox']")
        fj("button:contains('Save')").click
        expect(@topic_no_options.reload.checkpoints?).to be_truthy
      end

      it "cannot convert ungraded to checkpointed if there are replies" do
        @topic_no_options.reply_from({ user: teacher, text: "I feel pretty" })
        get "/courses/#{course.id}/discussion_topics/#{@topic_no_options.id}/edit"
        force_click_native("input[data-testid='graded-checkbox']")
        expect(f("input[data-testid='checkpoints-checkbox']").attribute("disabled")).to be_truthy
        expect(fj("span[class*='screenReaderContent']:contains('Checkpoints cannot be toggled after replies have been made.')")).to be_present
      end

      it "displays the grading and groups not supported in anonymous discussions message in the edit page" do
        get "/courses/#{course.id}/discussion_topics/#{@topic_all_options.id}/edit"

        expect(f("input[value='full_anonymity']").selected?).to be_truthy
        expect(f("input[value='full_anonymity']").attribute("disabled")).to be_nil
        expect(f("body")).to contain_jqcss("[data-testid=groups_grading_not_allowed]")
      end

      it "displays all unselected options correctly" do
        get "/courses/#{course.id}/discussion_topics/#{@topic_no_options.id}/edit"

        expect(f("input[value='full_anonymity']").selected?).to be_falsey
        expect(f("input[value='full_anonymity']").attribute("disabled")).to be_nil

        # There are less checks here because certain options are only visible if their parent input is selected
        expect(f("input[value='must-respond-before-viewing-replies']").selected?).to be_falsey
        expect(f("input[value='enable-podcast-feed']").selected?).to be_falsey
        expect(f("input[value='allow-liking']").selected?).to be_falsey
        expect(f("input[value='add-to-student-to-do']").selected?).to be_falsey
      end

      context "usage rights" do
        before do
          course.update!(usage_rights_required: true)

          usage_rights = @course.usage_rights.create! use_justification: "creative_commons", legal_copyright: "(C) 2014 XYZ Corp", license: "cc_by_nd"
          @attachment.usage_rights = usage_rights
          @attachment.save!
        end

        it "displays correct usage rights" do
          get "/courses/#{course.id}/discussion_topics/#{@topic_all_options.id}/edit"

          expect(f("button[data-testid='usage-rights-icon']")).to be_truthy
          f("button[data-testid='usage-rights-icon']").find_element(css: "svg")
          # Verify that the correct icon appears
          expect(f("button[data-testid='usage-rights-icon']").find_element(css: "svg").attribute("name")).to eq "IconFilesCreativeCommons"

          f("button[data-testid='usage-rights-icon']").click

          expect(f("input[data-testid='usage-select']").attribute("value")).to eq "The material is licensed under Creative Commons"
          expect(f("input[data-testid='cc-license-select']").attribute("value")).to eq "CC Attribution No Derivatives"
          expect(f("input[data-testid='legal-copyright']").attribute("value")).to eq "(C) 2014 XYZ Corp"
        end
      end

      it "saves all changes correctly" do
        get "/courses/#{course.id}/discussion_topics/#{@topic_all_options.id}/edit"

        replace_content(f("input[placeholder='Topic Title']"), "new title", { tab_out: true })

        clear_tiny(f("#discussion-topic-message-body"), "discussion-topic-message-body_ifr")
        type_in_tiny("#discussion-topic-message-body", "new message")

        driver.action.move_to(f("span[data-testid='removable-item']")).perform
        f("[data-testid='remove-button']").click
        _, fullpath, _data = get_file("testfile5.zip")
        f("[data-testid='attachment-input']").send_keys(fullpath)

        # we can change anonymity on edit, if there is no reply
        expect(ffj("fieldset:contains('Anonymous Discussion') input[type=radio]").count).to eq 3

        force_click_native("input[value='must-respond-before-viewing-replies']")

        force_click_native("input[value='enable-podcast-feed']")
        expect(f("body")).not_to contain_jqcss("input[value='include-student-replies-in-podcast-feed']")

        force_click_native("input[value='allow-liking']")
        expect(f("body")).not_to contain_jqcss("input[value='only-graders-can-like']")

        force_click_native("input[value='add-to-student-to-do']")

        fj("button:contains('Save')").click

        @topic_all_options.reload
        expect(@topic_all_options.title).to eq "new title"
        expect(@topic_all_options.message).to include "new message"
        expect(@topic_all_options.attachment_id).to eq Attachment.last.id
        expect(@topic_all_options.require_initial_post).to be_falsey
        expect(@topic_all_options.podcast_enabled).to be_falsey
        expect(@topic_all_options.allow_rating).to be_falsey
        expect(@topic_all_options.only_graders_can_rate).to be_falsey
        expect(@topic_all_options.todo_date).to be_nil
      end

      # ignore js errors in unrelated discussion show page
      it "preserves URL query parameters on CANCEL", :ignore_js_errors do
        get "/courses/#{course.id}/discussion_topics/#{@topic_all_options.id}/edit?embed=true"
        fj("button:contains('Cancel')").click
        wait_for_ajaximations
        expect(driver.current_url).not_to include("edit")
        expect(driver.current_url).to include("?embed=true")
      end

      context "selective release assignment embedded in discussions edit page" do
        it "allows edit with group category", :ignore_js_errors do
          group_cat = course.group_categories.create!(name: "Groupies")
          get "/courses/#{course.id}/discussion_topics/#{teacher_topic.id}/edit"

          Discussion.click_group_discussion_checkbox
          Discussion.click_group_category_select
          Discussion.click_group_category_option(group_cat.name)
          Discussion.save_button.click

          wait_for_new_page_load
          expect(driver.current_url).not_to end_with("/courses/#{course.id}/discussion_topics/#{teacher_topic.id}/edit")
        end

        it "allows edit with group category and graded", :ignore_js_errors do
          group_cat = course.group_categories.create!(name: "Groupies")
          get "/courses/#{course.id}/discussion_topics/#{teacher_topic.id}/edit"

          Discussion.click_graded_checkbox
          Discussion.click_group_discussion_checkbox
          Discussion.click_group_category_select
          Discussion.click_group_category_option(group_cat.name)
          Discussion.save_button.click

          wait_for_new_page_load
          expect(driver.current_url).not_to end_with("/courses/#{course.id}/discussion_topics/#{teacher_topic.id}/edit")
        end

        it "shows the assign to UI regardless of limit privilege settings with moderate forum set" do
          # i.e., they have moderate_forum permission but not admin or unrestricted student enrollment
          RoleOverride.create!(context: @course.account, permission: "moderate_forum", role: student_role, enabled: true)
          student_in_course(active_all: true)
          user_session(@student)
          get "/courses/#{course.id}/discussion_topics/#{@topic_no_options.id}/edit"

          expect(element_exists?(Discussion.assign_to_section_selector)).to be_truthy

          enrollment = @course.enrollments.find_by(user: @student)
          enrollment.update!(limit_privileges_to_course_section: true)
          get "/courses/#{course.id}/discussion_topics/#{@topic_no_options.id}/edit"

          expect(element_exists?(Discussion.assign_to_section_selector)).to be_truthy
        end

        it "allows student to save edit of created discussion" do
          student_in_course(active_all: true)
          user_session(@student)

          get "/courses/#{course.id}/discussion_topics/new"

          title = "My Test Topic"
          message = "replying to topic"
          available_date = "12/27/2023"

          # Set title
          Discussion.update_discussion_topic_title(title)
          # Set Message
          Discussion.update_discussion_message(message)

          update_available_date(0, available_date, true)
          update_available_time(0, "8:00 AM", true)

          # Save and publish
          Discussion.save_button.click
          wait_for_ajaximations

          dt = DiscussionTopic.last

          get "/courses/#{course.id}/discussion_topics/#{dt.id}/edit"

          new_title = "My New Test Topic"
          Discussion.update_discussion_topic_title(new_title)

          Discussion.save_button.click
          wait_for_ajaximations

          dt.reload
          expect(dt.title).to eq(new_title)
          expect(dt.message).to include message
          expect(format_date_for_view(dt.unlock_at, "%m/%d/%Y")).to eq(available_date)
        end

        it "does not display 'Assign To' section for an ungraded group discussion" do
          group = course.groups.create!(name: "group")
          group_ungraded = course.discussion_topics.create!(title: "no options enabled - topic", group_category: group.group_category)
          get "/courses/#{course.id}/discussion_topics/#{group_ungraded.id}/edit"
          expect(Discussion.select_date_input_exists?).to be_truthy
          expect(element_exists?(Discussion.assign_to_section_selector)).to be_falsey
        end

        it "does not display 'Post To' section and Available From/Until inputs" do
          get "/courses/#{course.id}/discussion_topics/#{@topic_no_options.id}/edit"
          expect(Discussion.select_date_input_exists?).to be_falsey
          expect(Discussion.section_selection_input_exists?).to be_falsey
        end

        it "updates overrides using 'Assign To' tray", :ignore_js_errors do
          student1 = course.enroll_student(User.create!, enrollment_state: "active").user
          available_from = 5.days.ago
          available_until = 5.days.from_now

          get "/courses/#{course.id}/discussion_topics/#{@topic_no_options.id}/edit"

          click_add_assign_to_card
          expect(element_exists?(due_date_input_selector)).to be_falsey
          select_module_item_assignee(1, student1.name)
          update_available_date(1, format_date_for_view(available_from, "%-m/%-d/%Y"), true)
          update_available_time(1, "8:00 AM", true)
          update_until_date(1, format_date_for_view(available_until, "%-m/%-d/%Y"), true)
          update_until_time(1, "9:00 PM", true)

          Discussion.save_button.click
          wait_for_ajaximations

          @topic_no_options.reload
          new_override = @topic_no_options.active_assignment_overrides.last
          expect(new_override.set_type).to eq("ADHOC")
          expect(new_override.set_id).to be_nil
          expect(new_override.set.map(&:id)).to match_array([student1.id])
        end

        it "transitions from ungraded to graded and overrides are ok", :ignore_js_errors do
          discussion_topic = DiscussionHelpers.create_discussion_topic(
            course,
            teacher,
            "Teacher Discussion 1 Title",
            "Teacher Discussion 1 message",
            nil
          )
          student1 = course.enroll_student(User.create!, enrollment_state: "active").user
          available_from = 5.days.ago
          available_until = 5.days.from_now

          discussion_topic.assignment_overrides.create!(set_type: "ADHOC",
                                                        unlock_at: available_from,
                                                        lock_at: available_until)

          discussion_topic.assignment_overrides.last.assignment_override_students.create!(user: student1)

          get "/courses/#{course.id}/discussion_topics/#{discussion_topic.id}/edit"

          expect(is_checked(Discussion.graded_checkbox)).to be_falsey

          Discussion.click_graded_checkbox
          Discussion.save_button.click
          wait_for_ajaximations

          get "/courses/#{course.id}/discussion_topics/#{discussion_topic.id}/edit"

          expect(assign_to_due_date(1).attribute("value")).to eq("")
          expect(assign_to_due_time(1).attribute("value")).to eq("")
          expect(assign_to_available_from_date(1).attribute("value")).to eq(format_date_for_view(available_from, "%b %-e, %Y"))
          expect(assign_to_available_from_time(1).attribute("value")).to eq(available_from.strftime("%-l:%M %p"))
          expect(assign_to_until_date(1).attribute("value")).to eq(format_date_for_view(available_until, "%b %-e, %Y"))
          expect(assign_to_until_time(1).attribute("value")).to eq(available_until.strftime("%-l:%M %p"))
        end

        it "transitions from graded to ungraded and overrides are ok", :ignore_js_errors do
          discussion_assignment_options = {
            name: "assignment",
            points_possible: 10,
          }
          discussion_topic = create_graded_discussion(course, discussion_assignment_options)

          student1 = course.enroll_student(User.create!, enrollment_state: "active").user

          due_at = 3.days.from_now
          available_from = 5.days.ago
          available_until = 5.days.from_now

          @discussion_assignment.assignment_overrides.create!(set_type: "ADHOC",
                                                              due_at:,
                                                              unlock_at: available_from,
                                                              lock_at: available_until)

          @discussion_assignment.assignment_overrides.last.assignment_override_students.create!(user: student1)

          get "/courses/#{course.id}/discussion_topics/#{discussion_topic.id}/edit"

          expect(is_checked(Discussion.graded_checkbox)).to be_truthy

          Discussion.click_graded_checkbox
          Discussion.save_button.click
          wait_for_ajaximations

          get "/courses/#{course.id}/discussion_topics/#{discussion_topic.id}/edit"

          expect(assign_to_date_and_time[1].text).not_to include("Due Date")
          expect(assign_to_available_from_date(1, true).attribute("value")).to eq(format_date_for_view(available_from, "%b %-e, %Y"))
          expect(assign_to_available_from_time(1, true).attribute("value")).to eq(available_from.strftime("%-l:%M %p"))
          expect(assign_to_until_date(1, true).attribute("value")).to eq(format_date_for_view(available_until, "%b %-e, %Y"))
          expect(assign_to_until_time(1, true).attribute("value")).to eq(available_until.strftime("%-l:%M %p"))
        end

        it "does not recover a deleted card when adding an assignee", :ignore_js_errors do
          # Bug fix of LX-1619
          student1 = course.enroll_student(User.create!, enrollment_state: "active").user

          get "/courses/#{course.id}/discussion_topics/#{@topic_all_options.id}/edit"

          click_add_assign_to_card
          click_delete_assign_to_card(0)
          select_module_item_assignee(0, student1.name)

          expect(selected_assignee_options.count).to be(1)
        end

        it "does not navigate to existsing discussion edit page" do
          course.account.enable_feature!(:horizon_course_setting)
          course.horizon_course = true
          course.save!
          get "/courses/#{course.id}/discussion_topics/#{@topic_all_options.id}/edit"
          expect(element_exists?(Discussion.save_selector)).to be_falsey
        end
      end
    end

    context "ungraded group" do
      it "displays the selected group category correctly" do
        group_category = course.group_categories.create!(name: "group category 1")

        discussion_with_group_category = {
          title: "value for title",
          message: "value for message",
          group_category_id: group_category.id,
        }

        group_topic = course.discussion_topics.create!(discussion_with_group_category)
        group_topic.update!(group_category_id: group_category.id)

        get "/courses/#{course.id}/discussion_topics/#{group_topic.id}/edit"

        expect(f("input[value='group-discussion']").selected?).to be_truthy
        expect(f("input[placeholder='Select a group category']").attribute("title")).to eq group_category.name
      end
    end

    context "announcement" do
      before do
        # TODO: Update to cover: file attachments and any other options later implemented
        all_announcement_options = {
          title: "value for title",
          message: "value for message",
          delayed_post_at: "Thu, 16 Nov 2023 17:00:00.000000000 UTC +00:00",
          podcast_enabled: true,
          podcast_has_student_posts: true,
          require_initial_post: true,
          discussion_type: "side_comment",
          allow_rating: true,
          only_graders_can_rate: true,
          locked: false,
        }

        @announcement_all_options = course.announcements.create!(all_announcement_options)
        # In this case, locked: true displays itself as an unchecked "allow participants to comment" option
        @announcement_no_options = course.announcements.create!({ title: "no options", message: "nothing else", locked: true })
      end

      it "displays all selected options correctly" do
        get "/courses/#{course.id}/discussion_topics/#{@announcement_all_options.id}/edit"

        expect(f("input[value='enable-participants-commenting']").selected?).to be_truthy
        expect(f("input[value='must-respond-before-viewing-replies']").selected?).to be_truthy
        expect(f("input[value='allow-liking']").selected?).to be_truthy
        expect(f("input[value='only-graders-can-like']").selected?).to be_truthy
        expect(f("input[value='enable-podcast-feed']").selected?).to be_truthy
        expect(f("input[value='include-student-replies-in-podcast-feed']").selected?).to be_truthy

        # Just checking for a value. Formatting and TZ differences between front-end and back-end
        # makes an exact comparison too fragile.
        expect(ff("input[placeholder='Select Date']")[0].attribute("value")).to be_truthy
      end

      it "displays all unselected options correctly" do
        get "/courses/#{course.id}/discussion_topics/#{@announcement_no_options.id}/edit"

        expect(f("input[value='enable-participants-commenting']").selected?).to be_falsey
        expect(f("input[value='allow-liking']").selected?).to be_falsey
        expect(f("input[value='enable-podcast-feed']").selected?).to be_falsey
      end

      it "displays comment related fields when participants commenting is enabled" do
        user_session(teacher)
        get "/courses/#{course.id}/discussion_topics/#{@announcement_no_options.id}/edit"

        force_click_native("input[value='enable-participants-commenting']")
        expect(f("body")).to contain_jqcss "input[value='must-respond-before-viewing-replies']"
        expect(f("body")).to contain_jqcss "input[value='disallow-threaded-replies']"
      end
    end

    context "graded" do
      it "displays graded assignment options correctly when initially opening edit page with archived grading schemes disabled" do
        Account.site_admin.disable_feature!(:archived_grading_schemes)
        grading_standard = course.grading_standards.create!(title: "Win/Lose", data: [["Winner", 0.94], ["Loser", 0]])

        # Create a grading standard and make sure it is selected
        discussion_assignment_options = {
          name: "assignment",
          points_possible: 10,
          grading_type: "letter_grade",
          assignment_group: course.assignment_groups.create!(name: "assignment group"),
          grading_standard_id: grading_standard.id,
          only_visible_to_overrides: true,
        }

        discussion_assignment_peer_review_options = {
          peer_reviews: true,
          automatic_peer_reviews: true,
          peer_reviews_due_at: 1.day.ago,
          peer_review_count: 2,
        }

        discussion_assignment_options = discussion_assignment_options.merge(discussion_assignment_peer_review_options)

        graded_discussion = create_graded_discussion(course, discussion_assignment_options)

        course_override_due_date = 5.days.from_now
        course_section = course.course_sections.create!(name: "section alpha")
        graded_discussion.assignment.assignment_overrides.create!(set_type: "CourseSection", set_id: course_section.id, due_at: course_override_due_date)

        get "/courses/#{course.id}/discussion_topics/#{graded_discussion.id}/edit"
        # Grading scheme sub menu is selected
        expect(fj("span:contains('#{grading_standard.title}')").present?).to be_truthy
        expect(fj("span:contains('Manage All Grading Schemes')").present?).to be_truthy
        # Graded checkbox
        expect(is_checked(f("input[data-testid='graded-checkbox']"))).to be_truthy
        # Points possible
        expect(f("input[data-testid='points-possible-input']").attribute("value")).to eq "10"
        # Grading type
        expect(f("input[data-testid='display-grade-input']").attribute("value")).to eq "Letter Grade"
        # Assignment Group
        expect(f("input[data-testid='assignment-group-input']").attribute("value")).to eq "assignment group"
        # Peer review checkboxes
        expect(is_checked(f("input[data-testid='peer_review_manual']"))).to be_falsey
        expect(is_checked(f("input[data-testid='peer_review_off']"))).to be_falsey
        expect(is_checked(f("input[data-testid='peer_review_auto']"))).to be_truthy
        # peer review count
        expect(f("input[data-testid='peer-review-count-input']").attribute("value")).to eq "2"

        # Peer review date
        # Just checking for a value. Formatting and TZ differences between front-end and back-end
        # makes an exact comparison too fragile.
        expect(ff("input[placeholder='Select Date']")[0].attribute("value")).not_to be_empty

        expect(assign_to_in_tray("Remove #{course_section.name}")[0]).to be_displayed
      end

      it "allows settings a graded discussion to an ungraded discussion" do
        graded_discussion = create_graded_discussion(course)
        get "/courses/#{course.id}/discussion_topics/#{graded_discussion.id}/edit"

        # Uncheck the "graded" checkbox
        force_click_native('input[type=checkbox][value="graded"]')
        fj("button:contains('Save')").click

        expect(DiscussionTopic.last.assignment).to be_nil
      end

      it "sets the mark important dates checkbox for discussion edit when differentiated modules ff is off" do
        feature_setup

        graded_discussion = create_graded_discussion(course)

        course_override_due_date = 5.days.from_now
        course_section = course.course_sections.create!(name: "section alpha")
        graded_discussion.assignment.assignment_overrides.create!(set_type: "CourseSection", set_id: course_section.id, due_at: course_override_due_date)

        get "/courses/#{course.id}/discussion_topics/#{graded_discussion.id}/edit"

        expect(mark_important_dates).to be_displayed
        scroll_to_element(mark_important_dates)
        click_mark_important_dates

        Discussion.save_button.click
        wait_for_ajaximations

        assignment = Assignment.last

        expect(assignment.important_dates).to be(true)
      end

      context "with archived grading schemes enabled" do
        before do
          Account.site_admin.enable_feature!(:grading_scheme_updates)
          Account.site_admin.enable_feature!(:archived_grading_schemes)
          @course = course
          @account = @course.account
          @active_grading_standard = @course.grading_standards.create!(title: "Active Grading Scheme", data: { "A" => 0.9, "F" => 0 }, scaling_factor: 1.0, points_based: false, workflow_state: "active")
          @archived_grading_standard = @course.grading_standards.create!(title: "Archived Grading Scheme", data: { "A" => 0.9, "F" => 0 }, scaling_factor: 1.0, points_based: false, workflow_state: "archived")
          @account_grading_standard = @account.grading_standards.create!(title: "Account Grading Scheme", data: { "A" => 0.9, "F" => 0 }, scaling_factor: 1.0, points_based: false, workflow_state: "active")
          discussion_assignment_options = {
            name: "assignment",
            points_possible: 10,
            grading_type: "letter_grade",
            assignment_group: course.assignment_groups.create!(name: "assignment group"),
            only_visible_to_overrides: true,
          }

          @graded_discussion = create_graded_discussion(course, discussion_assignment_options)
          @assignment = @graded_discussion.assignment
        end

        it "shows archived grading scheme if it is the course default twice, once to follow course default scheme and once to choose that scheme to use" do
          @course.update!(grading_standard_id: @archived_grading_standard.id)
          @course.reload
          get "/courses/#{@course.id}/discussion_topics/#{@graded_discussion.id}/edit"
          wait_for_ajaximations
          expect(f("[data-testid='grading-schemes-selector-dropdown']").attribute("title")).to eq(@archived_grading_standard.title + " (course default)")
          f("[data-testid='grading-schemes-selector-dropdown']").click
          expect(f("[data-testid='grading-schemes-selector-option-#{@course.grading_standard.id}']")).to include_text(@course.grading_standard.title)
        end

        it "shows archived grading scheme if it is the current assignment grading standard" do
          @assignment.update!(grading_standard_id: @archived_grading_standard.id)
          @assignment.reload
          get "/courses/#{@course.id}/discussion_topics/#{@graded_discussion.id}/edit"
          wait_for_ajaximations
          expect(f("[data-testid='grading-schemes-selector-dropdown']").attribute("title")).to eq(@archived_grading_standard.title)
        end

        it "removes grading schemes from dropdown after archiving them but still shows them upon reopening the modal" do
          get "/courses/#{@course.id}/discussion_topics/#{@graded_discussion.id}/edit"
          wait_for_ajaximations
          f("[data-testid='grading-schemes-selector-dropdown']").click
          expect(f("[data-testid='grading-schemes-selector-option-#{@active_grading_standard.id}']")).to be_present
          f("[data-testid='manage-all-grading-schemes-button']").click
          wait_for_ajaximations
          f("[data-testid='grading-scheme-#{@active_grading_standard.id}-archive-button']").click
          wait_for_ajaximations
          f("[data-testid='manage-all-grading-schemes-close-button']").click
          wait_for_ajaximations
          f("[data-testid='grading-schemes-selector-dropdown']").click
          expect(f("[data-testid='grading-schemes-selector-dropdown-form']")).not_to contain_css("[data-testid='grading-schemes-selector-option-#{@active_grading_standard.id}']")
          f("[data-testid='manage-all-grading-schemes-button']").click
          wait_for_ajaximations
          expect(f("[data-testid='grading-scheme-row-#{@active_grading_standard.id}']").text).to be_present
        end

        it "shows all archived schemes in the manage grading schemes modal" do
          archived_gs1 = @course.grading_standards.create!(title: "Archived Grading Scheme 1", data: { "A" => 0.9, "F" => 0 }, scaling_factor: 1.0, points_based: false, workflow_state: "archived")
          archived_gs2 = @course.grading_standards.create!(title: "Archived Grading Scheme 2", data: { "A" => 0.9, "F" => 0 }, scaling_factor: 1.0, points_based: false, workflow_state: "archived")
          archived_gs3 = @course.grading_standards.create!(title: "Archived Grading Scheme 3", data: { "A" => 0.9, "F" => 0 }, scaling_factor: 1.0, points_based: false, workflow_state: "archived")
          get "/courses/#{@course.id}/discussion_topics/#{@graded_discussion.id}/edit"
          wait_for_ajaximations
          f("[data-testid='manage-all-grading-schemes-button']").click
          wait_for_ajaximations
          expect(f("[data-testid='grading-scheme-#{archived_gs1.id}-name']")).to include_text(archived_gs1.title)
          expect(f("[data-testid='grading-scheme-#{archived_gs2.id}-name']")).to include_text(archived_gs2.title)
          expect(f("[data-testid='grading-scheme-#{archived_gs3.id}-name']")).to include_text(archived_gs3.title)
        end

        it "will still show the assignment grading scheme if you archive it on the edit page in the management modal and persist on reload" do
          @assignment.update!(grading_standard_id: @active_grading_standard.id)
          @assignment.reload
          get "/courses/#{@course.id}/discussion_topics/#{@graded_discussion.id}/edit"
          wait_for_ajaximations
          expect(f("[data-testid='grading-schemes-selector-dropdown']").attribute("title")).to eq(@active_grading_standard.title)
          f("[data-testid='manage-all-grading-schemes-button']").click
          wait_for_ajaximations
          f("[data-testid='grading-scheme-#{@active_grading_standard.id}-archive-button']").click
          wait_for_ajaximations
          f("[data-testid='manage-all-grading-schemes-close-button']").click
          wait_for_ajaximations
          expect(f("[data-testid='grading-schemes-selector-dropdown']").attribute("title")).to eq(@active_grading_standard.title)
          get "/courses/#{@course.id}/assignments/#{@assignment.id}/edit"
          wait_for_ajaximations
          expect(f("[data-testid='grading-schemes-selector-dropdown']").attribute("title")).to eq(@active_grading_standard.title)
        end

        it "creates a discussion topic with selected grading scheme/standard" do
          grading_standard = @course.grading_standards.create!(title: "Win/Lose", data: [["Winner", 0.94], ["Loser", 0]])
          get "/courses/#{@course.id}/discussion_topics/#{@graded_discussion.id}/edit"
          wait_for_ajaximations
          f("[data-testid='grading-schemes-selector-dropdown']").click
          f("[data-testid='grading-schemes-selector-option-#{grading_standard.id}']").click
          f("[data-testid='save-button']").click
          wait_for_ajaximations
          expect_new_page_load { f("[data-testid='continue-button']").click }
          a = DiscussionTopic.last.assignment
          expect(a.grading_standard_id).to eq grading_standard.id
        end
      end

      it "allows editing the assignment group for the graded discussion" do
        assign_group_2 = course.assignment_groups.create!(name: "Group 2")
        get "/courses/#{course.id}/discussion_topics/#{assignment_topic.id}/edit"
        force_click_native("input[title='assignment group']")
        wait_for(method: nil, timeout: 3) { fj("li:contains('Group 2')").present? }
        fj("li:contains('Group 2')").click
        fj("button:contains('Save')").click
        expect(assignment.reload.assignment_group_id).to eq assign_group_2.id
      end

      it "allows editing the points possible, grading type, group category, and peer review for the graded discussion" do
        pp_string = "80"
        group_cat = course.group_categories.create!(name: "another group set")
        get "/courses/#{course.id}/discussion_topics/#{assignment_topic.id}/edit"

        # change points possible from 10 to 80. selenium's clear method does not completely remove the previous value
        # so we use backspace instead
        pp_string.each_char { f("input[data-testid='points-possible-input']").send_keys(:backspace) }
        f("input[data-testid='points-possible-input']").send_keys(pp_string)

        force_click_native("input[value='Points']")
        fj("li:contains('Letter Grade')").click

        force_click_native("input[data-testid='peer_review_manual']")

        force_click_native("input[data-testid='group-discussion-checkbox']")
        force_click_native("input[placeholder='Select a group category']")
        fj("li:contains('#{group_cat.name}')").click

        fj("button:contains('Save')").click
        updated_assignment = assignment.reload
        expect(updated_assignment.points_possible).to eq 80
        expect(updated_assignment.grading_type).to eq "letter_grade"
        expect(updated_assignment.peer_reviews).to be true
        expect(updated_assignment.automatic_peer_reviews).to be false
        expect(updated_assignment.peer_reviews_assign_at).to be_nil
        expect(assignment.effective_group_category_id).to eq group_cat.id
      end

      it "adds an attachment to a graded discussion" do
        get "/courses/#{course.id}/discussion_topics/#{assignment_topic.id}/edit"
        _filename, fullpath, _data = get_file("testfile5.zip")
        f("input[data-testid='attachment-input']").send_keys(fullpath)
        fj("button:contains('Save')").click
        expect(assignment_topic.reload.attachment_id).to eq Attachment.last.id
      end

      context "selective release with embedded assign to cards", :ignore_js_errors do
        before do
          @student1 = student_in_course(course:, active_all: true).user
          @student2 = student_in_course(course:, active_all: true).user
          @course_section = course.course_sections.create!(name: "section alpha")
          @course_section_2 = course.course_sections.create!(name: "section Beta")
        end

        it "displays Everyone correctly", custom_timeout: 30 do
          graded_discussion = create_graded_discussion(course)

          due_date = "Sat, 06 Apr 2024 00:00:00.000000000 UTC +00:00"
          unlock_at = "Fri, 05 Apr 2024 00:00:00.000000000 UTC +00:00"
          lock_at = "Sun, 07 Apr 2024 00:00:00.000000000 UTC +00:00"
          graded_discussion.assignment.update!(due_at: due_date, unlock_at:, lock_at:)

          # Open page and assignTo tray
          get "/courses/#{course.id}/discussion_topics/#{graded_discussion.id}/edit"

          # Expect check card and override count/content
          expect(module_item_assign_to_card.count).to eq 1
          expect(selected_assignee_options.count).to eq 1
          expect(selected_assignee_options.first.find("span").text).to eq "Everyone"

          # Find the date inputs, extract their values, combine date and time values, and parse into DateTime objects
          displayed_override_dates = all_displayed_assign_to_date_and_time

          # Check that the due dates are correctly displayed
          expect(displayed_override_dates.include?(Time.zone.parse(due_date))).to be_truthy
          expect(displayed_override_dates.include?(Time.zone.parse(unlock_at))).to be_truthy
          expect(displayed_override_dates.include?(Time.zone.parse(lock_at))).to be_truthy
        end

        it "displays everyone and section and student overrides correctly", custom_timeout: 30 do
          graded_discussion = create_graded_discussion(course)

          # Create overrides
          # Card 1 = ["Everyone else"], Set by: only_visible_to_overrides: false

          # Card 2
          graded_discussion.assignment.assignment_overrides.create!(set_type: "CourseSection", set_id: @course_section.id)

          # Card 3
          graded_discussion.assignment.assignment_overrides.create!(set_type: "CourseSection", set_id: @course_section_2.id)

          # Card 4
          graded_discussion.assignment.assignment_overrides.create!(set_type: "ADHOC")
          graded_discussion.assignment.assignment_overrides.last.assignment_override_students.create!(user: @student1)
          graded_discussion.assignment.assignment_overrides.last.assignment_override_students.create!(user: @student2)

          # Open edit page and AssignTo Tray
          get "/courses/#{course.id}/discussion_topics/#{graded_discussion.id}/edit"

          # Check that displayed cards and overrides are correct
          expect(module_item_assign_to_card.count).to eq 4

          displayed_overrides = module_item_assign_to_card.map do |card|
            card.find_all(assignee_selected_option_selector).map(&:text)
          end

          expected_overrides = generate_expected_overrides(graded_discussion.assignment)
          expect(displayed_overrides).to match_array(expected_overrides)
        end

        it "displays visible to overrides only correctly", custom_timeout: 30 do
          # The main difference in this test is that only_visible_to_overrides is true
          discussion_assignment_options = {
            only_visible_to_overrides: true,
          }
          graded_discussion = create_graded_discussion(course, discussion_assignment_options)

          # Create overrides
          # Card 1
          graded_discussion.assignment.assignment_overrides.create!(set_type: "CourseSection", set_id: @course_section.id)
          # Card 2
          graded_discussion.assignment.assignment_overrides.create!(set_type: "CourseSection", set_id: @course_section_2.id)
          # Card 3
          graded_discussion.assignment.assignment_overrides.create!(set_type: "ADHOC")
          graded_discussion.assignment.assignment_overrides.last.assignment_override_students.create!(user: @student1)
          graded_discussion.assignment.assignment_overrides.last.assignment_override_students.create!(user: @student2)

          # Open edit page and AssignTo Tray
          get "/courses/#{course.id}/discussion_topics/#{graded_discussion.id}/edit"

          # Check that displayed cards and overrides are correct
          expect(module_item_assign_to_card.count).to eq 3

          displayed_overrides = module_item_assign_to_card.map do |card|
            card.find_all(assignee_selected_option_selector).map(&:text)
          end

          expected_overrides = generate_expected_overrides(graded_discussion.assignment)
          expect(displayed_overrides).to match_array(expected_overrides)
        end

        it "allows adding overrides" do
          graded_discussion = create_graded_discussion(course)

          due_date = "Sat, 06 Apr 2024 00:00:00.000000000 UTC +00:00"
          unlock_at = "Fri, 05 Apr 2024 00:00:00.000000000 UTC +00:00"
          lock_at = "Sun, 07 Apr 2024 00:00:00.000000000 UTC +00:00"
          graded_discussion.assignment.update!(due_at: due_date, unlock_at:, lock_at:)
          course.reload
          # Open page and assignTo tray
          get "/courses/#{course.id}/discussion_topics/#{graded_discussion.id}/edit"

          click_add_assign_to_card
          select_module_item_assignee(1, @student1.name)

          Discussion.save_button.click
          wait_for_ajaximations

          assignment = Assignment.last

          expect(assignment.assignment_overrides.active.count).to eq 1
        end

        it "allows removing overrides" do
          graded_discussion = create_graded_discussion(course)

          due_date = "Sat, 06 Apr 2024 00:00:00.000000000 UTC +00:00"
          unlock_at = "Fri, 05 Apr 2024 00:00:00.000000000 UTC +00:00"
          lock_at = "Sun, 07 Apr 2024 00:00:00.000000000 UTC +00:00"
          graded_discussion.assignment.update!(due_at: due_date, unlock_at:, lock_at:)

          # Create section override
          course_section = course.course_sections.create!(name: "section alpha")
          graded_discussion.assignment.assignment_overrides.create!(set_type: "CourseSection", set_id: course_section.id)

          course.reload
          # Open page and assignTo tray
          get "/courses/#{course.id}/discussion_topics/#{graded_discussion.id}/edit"

          # Remove the section override
          click_delete_assign_to_card(1)

          Discussion.save_button.click
          wait_for_ajaximations

          assignment = Assignment.last
          assignment.reload
          expect(assignment.assignment_overrides.active.count).to eq 0
          expect(assignment.only_visible_to_overrides).to be_falsey
        end

        it "displays module overrides correctly" do
          graded_discussion = create_graded_discussion(course)
          module1 = course.context_modules.create!(name: "Module 1")
          graded_discussion.context_module_tags.create! context_module: module1, context: course, tag_type: "context_module"

          override = module1.assignment_overrides.create!
          override.assignment_override_students.create!(user: @student1)

          # Open page and assignTo tray
          get "/courses/#{course.id}/discussion_topics/#{graded_discussion.id}/edit"

          # Verify that Everyone tag does not appear
          expect(module_item_assign_to_card.count).to eq 1
          expect(module_item_assign_to_card[0].find_all(assignee_selected_option_selector).map(&:text)).to eq ["User"]
          expect(inherited_from.last.text).to eq("Inherited from #{module1.name}")

          # Update the inherited card due date, should remove inherited
          update_due_date(0, "12/31/2022")
          update_due_time(0, "5:00 PM")

          expect(f("body")).not_to contain_jqcss(inherited_from_selector)

          Discussion.save_button.click
          Discussion.section_warning_continue_button.click
          wait_for_ajaximations

          # Expect the module override to be overridden and not appear
          get "/courses/#{course.id}/discussion_topics/#{graded_discussion.id}/edit"

          expect(module_item_assign_to_card.count).to eq 1
          expect(f("body")).not_to contain_jqcss(inherited_from_selector)
        end

        it "displays module and course overrides correctly" do
          graded_discussion = create_graded_discussion(course)
          module1 = course.context_modules.create!(name: "Module 1")
          graded_discussion.context_module_tags.create! context_module: module1, context: course, tag_type: "context_module"

          override = module1.assignment_overrides.create!
          override.assignment_override_students.create!(user: @student1)
          graded_discussion.assignment.assignment_overrides.create!(set: course, due_at: 1.day.from_now)

          # Open page and assignTo tray
          get "/courses/#{course.id}/discussion_topics/#{graded_discussion.id}/edit"

          # Verify that Everyone tag does not appear
          expect(module_item_assign_to_card.count).to eq 2
          expect(module_item_assign_to_card[0].find_all(assignee_selected_option_selector).map(&:text)).to eq ["Everyone else"]
          expect(module_item_assign_to_card[1].find_all(assignee_selected_option_selector).map(&:text)).to eq ["User"]
          expect(inherited_from.last.text).to eq("Inherited from #{module1.name}")
        end

        it "saves group overrides correctly" do
          graded_discussion = create_graded_discussion(course)
          group_category.create_groups(1)
          get "/courses/#{course.id}/discussion_topics/#{graded_discussion.id}/edit"

          # select group category
          force_click_native("input[data-testid='group-discussion-checkbox']")
          force_click_native("input[placeholder='Select a group category']")
          fj("li:contains('#{group_category.name}')").click

          # set group category override
          force_click_native('input[data-testid="assignee_selector"]')
          fj("li:contains('#{group_category.groups.first.name}')").click
          Discussion.save_button.click

          wait_for_new_page_load
          expect(driver.current_url).not_to include("edit")
        end

        it "creates a course override if everyone is added with a module override" do
          graded_discussion = create_graded_discussion(course)
          module1 = course.context_modules.create!(name: "Module 1")
          graded_discussion.context_module_tags.create! context_module: module1, context: course, tag_type: "context_module"

          override = module1.assignment_overrides.create!
          override.assignment_override_students.create!(user: @student1)

          # Open page and assignTo tray
          get "/courses/#{course.id}/discussion_topics/#{graded_discussion.id}/edit"

          # Verify the module override is shown
          expect(module_item_assign_to_card.count).to eq 1
          expect(module_item_assign_to_card[0].find_all(assignee_selected_option_selector).map(&:text)).to eq ["User"]
          expect(inherited_from.last.text).to eq("Inherited from #{module1.name}")

          click_add_assign_to_card
          select_module_item_assignee(1, "Everyone else")

          # Save the discussion without changing the inherited module override
          Discussion.save_button.click
          Discussion.section_warning_continue_button.click
          wait_for_ajaximations

          assignment = graded_discussion.assignment
          assignment.reload
          # Expect the existing override to be the module override
          expect(assignment.assignment_overrides.active.count).to eq 1
          expect(assignment.all_assignment_overrides.active.count).to eq 2
          expect(assignment.assignment_overrides.first.set_type).to eq "Course"
          expect(assignment.only_visible_to_overrides).to be_truthy
        end

        it "does not display module override if an unassigned override exists" do
          graded_discussion = create_graded_discussion(course)
          module1 = course.context_modules.create!(name: "Module 1")
          graded_discussion.context_module_tags.create! context_module: module1, context: course, tag_type: "context_module"

          override = module1.assignment_overrides.create!
          override.assignment_override_students.create!(user: @student1)

          unassigned_override = graded_discussion.assignment.assignment_overrides.create!
          unassigned_override.assignment_override_students.create!(user: @student1)
          unassigned_override.update(unassign_item: true)

          assigned_override = graded_discussion.assignment.assignment_overrides.create!
          assigned_override.assignment_override_students.create!(user: @student2)

          # Open page and assignTo tray
          get "/courses/#{course.id}/discussion_topics/#{graded_discussion.id}/edit"

          # Verify the module override is not shown
          expect(module_item_assign_to_card.count).to eq 1
          expect(module_item_assign_to_card[0].find_all(assignee_selected_option_selector).map(&:text)).to eq ["User"]
          expect(module_item_assign_to_card[0]).not_to contain_css(inherited_from_selector)
        end

        it "displays highighted cards correctly" do
          graded_discussion = create_graded_discussion(course)
          get "/courses/#{course.id}/discussion_topics/#{graded_discussion.id}/edit"

          # Expect there to be no highlighted cards
          expect(module_item_assign_to_card.count).to eq 1
          expect(f("body")).not_to contain_jqcss(highlighted_card_selector)

          # Expect highlighted card after making a change
          update_due_date(0, "12/31/2022")

          expect(highlighted_item_assign_to_card.count).to eq 1
        end

        it "sets the mark important dates checkbox for discussion edit" do
          feature_setup

          graded_discussion = create_graded_discussion(course)

          get "/courses/#{course.id}/discussion_topics/#{graded_discussion.id}/edit"

          formatted_date = format_date_for_view(2.days.from_now(Time.zone.now), "%m/%d/%Y")
          update_due_date(0, formatted_date)
          update_due_time(0, "5:00 PM")

          expect(mark_important_dates).to be_displayed
          scroll_to_element(mark_important_dates)
          click_mark_important_dates

          Discussion.save_button.click
          wait_for_ajaximations

          assignment = Assignment.last

          expect(assignment.important_dates).to be(true)
        end

        it "does not show the assign to UI when the user does not have permission even if user can access edit page" do
          # i.e., they have moderate_forum permission but not manage_assignments_edit
          discussion = create_graded_discussion(course)
          get "/courses/#{course.id}/discussion_topics/#{discussion.id}/edit"
          expect(element_exists?(Discussion.assign_to_section_selector)).to be_truthy

          RoleOverride.create!(context: @course.account, permission: "manage_assignments_edit", role: teacher_role, enabled: false)
          get "/courses/#{course.id}/discussion_topics/#{discussion.id}/edit"
          expect(element_exists?(Discussion.assign_to_section_selector)).to be_falsey
        end

        it "does not recover a deleted card when adding an assignee", :ignore_js_errors do
          # Bug fix of LX-1619
          discussion = create_graded_discussion(course)
          get "/courses/#{course.id}/discussion_topics/#{discussion.id}/edit"

          click_add_assign_to_card
          click_delete_assign_to_card(0)
          select_module_item_assignee(0, @course_section_2.name)

          expect(selected_assignee_options.count).to be(1)
        end

        context "differentiaiton tags" do
          before do
            @course.account.enable_feature! :assign_to_differentiation_tags
            @course.account.tap do |a|
              a.settings[:allow_assign_to_differentiation_tags] = { value: true }
              a.save!
            end

            @differentiation_tag_category = @course.group_categories.create!(name: "Differentiation Tag Category", non_collaborative: true)
            @diff_tag1 = @course.groups.create!(name: "Differentiation Tag 1", group_category: @differentiation_tag_category, non_collaborative: true)
            @diff_tag2 = @course.groups.create!(name: "Differentiation Tag 2", group_category: @differentiation_tag_category, non_collaborative: true)
          end

          it "assigns a differentiation tag and saves discussion" do
            graded_discussion = create_graded_discussion(course)

            due_date = "Sat, 06 Apr 2024 00:00:00.000000000 UTC +00:00"
            unlock_at = "Fri, 05 Apr 2024 00:00:00.000000000 UTC +00:00"
            lock_at = "Sun, 07 Apr 2024 00:00:00.000000000 UTC +00:00"
            graded_discussion.assignment.update!(due_at: due_date, unlock_at:, lock_at:)
            course.reload
            # Open page and assignTo tray
            get "/courses/#{course.id}/discussion_topics/#{graded_discussion.id}/edit"

            click_add_assign_to_card
            select_module_item_assignee(1, @diff_tag1.name)

            Discussion.save_button.click
            wait_for_ajaximations

            assignment = Assignment.last

            expect(assignment.assignment_overrides.active.count).to eq 1
          end

          context "existing differentiation tag overrides" do
            before do
              @discussion = create_graded_discussion(@course)
              @discussion.assignment.assignment_overrides.create!(set_type: "Group", set_id: @diff_tag1.id, title: @diff_tag1.name)
              @discussion.assignment.assignment_overrides.create!(set_type: "Group", set_id: @diff_tag2.id, title: @diff_tag2.name)
            end

            it "renders all the override assignees" do
              get "/courses/#{@course.id}/discussion_topics/#{@discussion.id}/edit"

              # 3 differentiation tags
              expect(selected_assignee_options.count).to eq 3
            end
          end
        end

        context "checkpoints" do
          it "shows reply to topic input on graded discussion with sub assignments" do
            Account.site_admin.enable_feature!(:discussion_checkpoints)
            @course.account.enable_feature!(:discussion_checkpoints)
            assignment = @course.assignments.create!(
              name: "Assignment",
              submission_types: ["online_text_entry"],
              points_possible: 20
            )
            assignment.update!(has_sub_assignments: true)
            assignment.sub_assignments.create!(context: assignment.context, sub_assignment_tag: CheckpointLabels::REPLY_TO_TOPIC, points_possible: 10, due_at: 3.days.from_now)
            assignment.sub_assignments.create!(context: assignment.context, sub_assignment_tag: CheckpointLabels::REPLY_TO_ENTRY, points_possible: 10, due_at: 5.days.from_now)
            graded_discussion = @course.discussion_topics.create!(
              title: "Graded Discussion",
              discussion_type: "threaded",
              posted_at: "2017-07-09 16:32:34",
              user: @teacher,
              assignment:,
              reply_to_entry_required_count: 1
            )

            # Open page and assignTo tray
            get "/courses/#{@course.id}/discussion_topics/#{graded_discussion.id}/edit"

            expect(module_item_assign_to_card.last).to contain_css(reply_to_topic_due_date_input_selector)
          end

          it "shows required replies input on graded discussion with sub assignments" do
            Account.site_admin.enable_feature!(:discussion_checkpoints)
            @course.account.enable_feature!(:discussion_checkpoints)
            @student1 = student_in_course(course:, active_all: true).user
            @student2 = student_in_course(course:, active_all: true).user
            @course_section = course.course_sections.create!(name: "section alpha")
            @course_section_2 = course.course_sections.create!(name: "section Beta")

            # Open page and assignTo tray
            get "/courses/#{@course.id}/discussion_topics/new"
            title = "Graded Discussion Topic with letter grade type"
            message = "replying to topic"

            f("input[placeholder='Topic Title']").send_keys title
            type_in_tiny("textarea", message)

            force_click_native('input[type=checkbox][value="graded"]')
            force_click_native('input[type=checkbox][value="checkpoints"]')

            click_add_assign_to_card
            click_delete_assign_to_card(0)
            select_module_item_assignee(0, @course_section_2.name)

            reply_to_topic_date = 3.days.from_now(Time.zone.now).to_date + 17.hours
            reply_to_topic_date_formatted = format_date_for_view(reply_to_topic_date, "%m/%d/%Y")
            update_reply_to_topic_date(0, reply_to_topic_date_formatted)
            update_reply_to_topic_time(0, "5:00 PM")

            # required replies
            required_replies_date = 4.days.from_now(Time.zone.now).to_date + 17.hours
            required_replies_date_formatted = format_date_for_view(required_replies_date, "%m/%d/%Y")
            update_required_replies_date(0, required_replies_date_formatted)
            update_required_replies_time(0, "5:00 PM")

            # available from
            available_from_date = 2.days.from_now(Time.zone.now).to_date + 17.hours
            available_from_date_formatted = format_date_for_view(available_from_date, "%m/%d/%Y")
            update_available_date(0, available_from_date_formatted, true, false)
            update_available_time(0, "5:00 PM", true, false)

            # available until
            until_date = 5.days.from_now(Time.zone.now).to_date + 17.hours
            until_date_formatted = format_date_for_view(until_date, "%m/%d/%Y")
            update_until_date(0, until_date_formatted, true, false)
            update_until_time(0, "5:00 PM", true, false)

            fj("button:contains('Save')").click
            Discussion.section_warning_continue_button.click
            wait_for_ajaximations

            graded_discussion = DiscussionTopic.last
            sub_assignments = graded_discussion.assignment.sub_assignments
            sub_assignment1 = sub_assignments.find_by(sub_assignment_tag: CheckpointLabels::REPLY_TO_TOPIC)
            sub_assignment2 = sub_assignments.find_by(sub_assignment_tag: CheckpointLabels::REPLY_TO_ENTRY)

            expect(graded_discussion.assignment.sub_assignments.count).to eq(2)
            expect(format_date_for_view(sub_assignment1.assignment_overrides.active.first.due_at, "%m/%d/%Y")).to eq(reply_to_topic_date_formatted)
            expect(format_date_for_view(sub_assignment2.assignment_overrides.active.first.due_at, "%m/%d/%Y")).to eq(required_replies_date_formatted)

            # renders update
            get "/courses/#{@course.id}/discussion_topics/#{graded_discussion.id}/edit"

            displayed_override_dates = all_displayed_assign_to_date_and_time
            # Check that the due dates are correctly displayed
            expect(displayed_override_dates.include?(reply_to_topic_date)).to be_truthy
            expect(displayed_override_dates.include?(required_replies_date)).to be_truthy
            expect(displayed_override_dates.include?(available_from_date)).to be_truthy
            expect(displayed_override_dates.include?(until_date)).to be_truthy

            # updates dates and saves
            reply_to_topic_date = 4.days.from_now(Time.zone.now).to_date + 17.hours
            reply_to_topic_date_formatted = format_date_for_view(reply_to_topic_date, "%m/%d/%Y")
            update_reply_to_topic_date(0, reply_to_topic_date_formatted)
            update_reply_to_topic_time(0, "5:00 PM")

            # required replies
            required_replies_date = 5.days.from_now(Time.zone.now).to_date + 17.hours
            required_replies_date_formatted = format_date_for_view(required_replies_date, "%m/%d/%Y")
            update_required_replies_date(0, required_replies_date_formatted)
            update_required_replies_time(0, "5:00 PM")

            # available from
            available_from_date = 3.days.from_now(Time.zone.now).to_date + 17.hours
            available_from_date_formatted = format_date_for_view(available_from_date, "%m/%d/%Y")
            update_available_date(0, available_from_date_formatted, true, false)
            update_available_time(0, "5:00 PM", true, false)

            # available until
            until_date = 6.days.from_now(Time.zone.now).to_date + 17.hours
            until_date_formatted = format_date_for_view(until_date, "%m/%d/%Y")
            update_until_date(0, until_date_formatted, true, false)
            update_until_time(0, "5:00 PM", true, false)

            fj("button:contains('Save')").click
            Discussion.section_warning_continue_button.click
            wait_for_ajaximations

            graded_discussion.reload
            sub_assignments = graded_discussion.assignment.sub_assignments
            sub_assignment1 = sub_assignments.find_by(sub_assignment_tag: CheckpointLabels::REPLY_TO_TOPIC)
            sub_assignment2 = sub_assignments.find_by(sub_assignment_tag: CheckpointLabels::REPLY_TO_ENTRY)

            expect(graded_discussion.assignment.sub_assignments.count).to eq(2)
            expect(format_date_for_view(sub_assignment1.assignment_overrides.active.first.due_at, "%m/%d/%Y")).to eq(reply_to_topic_date_formatted)
            expect(format_date_for_view(sub_assignment2.assignment_overrides.active.first.due_at, "%m/%d/%Y")).to eq(required_replies_date_formatted)
          end

          it "displays an error when the availability date is after the due date" do
            Account.site_admin.enable_feature!(:discussion_checkpoints)
            @course.account.enable_feature!(:discussion_checkpoints)
            assignment = @course.assignments.create!(
              name: "Assignment",
              submission_types: ["online_text_entry"],
              points_possible: 20
            )
            assignment.update!(has_sub_assignments: true)
            assignment.sub_assignments.create!(context: assignment.context, sub_assignment_tag: CheckpointLabels::REPLY_TO_TOPIC, points_possible: 10, due_at: 3.days.from_now)
            assignment.sub_assignments.create!(context: assignment.context, sub_assignment_tag: CheckpointLabels::REPLY_TO_ENTRY, points_possible: 10, due_at: 5.days.from_now)
            graded_discussion = @course.discussion_topics.create!(
              title: "Graded Discussion",
              discussion_type: "threaded",
              posted_at: "2017-07-09 16:32:34",
              user: @teacher,
              assignment:,
              reply_to_entry_required_count: 1
            )

            # Open page and assignTo tray
            get "/courses/#{@course.id}/discussion_topics/#{graded_discussion.id}/edit"

            reply_to_topic_date_formatted = format_date_for_view(1.day.from_now(Time.zone.now).to_date, "%m/%d/%Y")
            update_reply_to_topic_date(0, reply_to_topic_date_formatted)
            update_reply_to_topic_time(0, "5:00 PM")

            # available from
            available_from_date_formatted = format_date_for_view(2.days.from_now(Time.zone.now).to_date, "%m/%d/%Y")
            update_available_date(0, available_from_date_formatted, true, false)
            update_available_time(0, "5:00 PM", true, false)
            expect(assign_to_date_and_time[2].text).to include("Unlock date cannot be after reply to topic due date")

            # correct reply to topic
            reply_to_topic_date_formatted = format_date_for_view(3.days.from_now(Time.zone.now).to_date, "%m/%d/%Y")
            update_reply_to_topic_date(0, reply_to_topic_date_formatted)
            update_reply_to_topic_time(0, "5:00 PM")

            # required replies
            required_replies_date_formatted = format_date_for_view(1.day.from_now(Time.zone.now).to_date, "%m/%d/%Y")
            update_required_replies_date(0, required_replies_date_formatted)
            update_required_replies_time(0, "5:00 PM")
            expect(assign_to_date_and_time[2].text).to include("Unlock date cannot be after required replies due date")

            # available until
            until_date = 5.days.from_now(Time.zone.now).to_date + 17.hours
            until_date_formatted = format_date_for_view(until_date, "%m/%d/%Y")
            update_until_date(0, until_date_formatted, true, false)
            update_until_time(0, "5:00 PM", true, false)

            reply_to_topic_date_formatted = format_date_for_view(6.days.from_now(Time.zone.now).to_date, "%m/%d/%Y")
            update_reply_to_topic_date(0, reply_to_topic_date_formatted)
            update_reply_to_topic_time(0, "5:00 PM")
            expect(assign_to_date_and_time[3].text).to include("Lock date cannot be before reply to topic due date")

            # correct reply to topic
            reply_to_topic_date_formatted = format_date_for_view(3.days.from_now(Time.zone.now).to_date, "%m/%d/%Y")
            update_reply_to_topic_date(0, reply_to_topic_date_formatted)
            update_reply_to_topic_time(0, "5:00 PM")

            # required replies
            required_replies_date_formatted = format_date_for_view(6.days.from_now(Time.zone.now).to_date, "%m/%d/%Y")
            update_required_replies_date(0, required_replies_date_formatted)
            update_required_replies_time(0, "5:00 PM")
            expect(assign_to_date_and_time[3].text).to include("Lock date cannot be before required replies due date")
          end
        end

        context "post to sis" do
          before do
            course.account.set_feature_flag! "post_grades", "on"
            course.account.set_feature_flag! :new_sis_integrations, "on"
            course.account.settings[:sis_syncing] = { value: true, locked: false }
            course.account.settings[:sis_require_assignment_due_date] = { value: true }
            course.account.save!
          end

          it "blocks when enabled", :ignore_js_errors do
            graded_discussion = create_graded_discussion(course)
            get "/courses/#{course.id}/discussion_topics/#{graded_discussion.id}/edit"
            Discussion.click_sync_to_sis_checkbox
            Discussion.save_button.click
            wait_for_ajaximations

            expect(driver.current_url).to include("edit")
            expect_instui_flash_message("Please set a due date or change your selection for the “Sync to SIS” option.")

            expect(assign_to_date_and_time[0].text).to include("Please add a due date")

            update_due_date(0, format_date_for_view(Time.zone.now, "%-m/%-d/%Y"))
            update_due_time(0, "11:59 PM")

            expect_new_page_load { Discussion.save_button.click }
            expect(driver.current_url).not_to include("edit")
            expect(graded_discussion.reload.assignment.post_to_sis).to be_truthy
            get "/courses/#{course.id}/discussion_topics/#{graded_discussion.id}/edit"
            expect(is_checked(Discussion.sync_to_sis_checkbox_selector)).to be_truthy
          end

          it "does not block when disabled" do
            graded_discussion = create_graded_discussion(course)
            get "/courses/#{course.id}/discussion_topics/#{graded_discussion.id}/edit"

            expect_new_page_load { Discussion.save_button.click }
            expect(driver.current_url).not_to include("edit")
            expect(graded_discussion.reload.assignment.post_to_sis).to be_falsey

            get "/courses/#{course.id}/discussion_topics/#{graded_discussion.id}/edit"
            expect(is_checked(Discussion.sync_to_sis_checkbox_selector)).to be_falsey
          end

          it "validates due date when user checks/unchecks the box", :ignore_js_errors do
            graded_discussion = create_graded_discussion(course)
            get "/courses/#{course.id}/discussion_topics/#{graded_discussion.id}/edit"

            Discussion.click_sync_to_sis_checkbox

            Discussion.save_button.click

            expect(assign_to_date_and_time[0].text).to include("Please add a due date")

            update_due_date(0, format_date_for_view(Time.zone.now, "%-m/%-d/%Y"))
            update_due_time(0, "11:59 PM")

            expect_new_page_load { Discussion.save_button.click }
            expect(driver.current_url).not_to include("edit")
            expect(graded_discussion.reload.assignment.post_to_sis).to be_truthy
          end
        end
      end

      context "checkpoints" do
        before do
          course.account.enable_feature!(:discussion_checkpoints)
          @checkpointed_discussion = DiscussionTopic.create_graded_topic!(course:, title: "checkpointed discussion")
          Checkpoints::DiscussionCheckpointCreatorService.call(
            discussion_topic: @checkpointed_discussion,
            checkpoint_label: CheckpointLabels::REPLY_TO_TOPIC,
            dates: [{ type: "everyone", due_at: 2.days.from_now }],
            points_possible: 6
          )
          Checkpoints::DiscussionCheckpointCreatorService.call(
            discussion_topic: @checkpointed_discussion,
            checkpoint_label: CheckpointLabels::REPLY_TO_ENTRY,
            dates: [{ type: "everyone", due_at: 2.days.from_now }],
            points_possible: 7,
            replies_required: 5
          )
        end

        it "displays checkpoint settings values correctly when there are existing checkpoints" do
          get "/courses/#{course.id}/discussion_topics/#{@checkpointed_discussion.id}/edit"
          expect(f("input[data-testid='points-possible-input-reply-to-topic']").attribute("value")).to eq "6"
          expect(f("input[data-testid='points-possible-input-reply-to-entry']").attribute("value")).to eq "7"
          expect(f("input[data-testid='reply-to-entry-required-count']").attribute("value")).to eq "5"
        end

        it "allows for a discussion with checkpoints to be updated" do
          get "/courses/#{course.id}/discussion_topics/#{@checkpointed_discussion.id}/edit"

          f("input[data-testid='points-possible-input-reply-to-topic']").send_keys :backspace
          f("input[data-testid='points-possible-input-reply-to-topic']").send_keys "5"
          f("input[data-testid='reply-to-entry-required-count']").send_keys :backspace
          f("input[data-testid='reply-to-entry-required-count']").send_keys "6"
          f("input[data-testid='points-possible-input-reply-to-entry']").send_keys :backspace
          f("input[data-testid='points-possible-input-reply-to-entry']").send_keys "7"
          fj("button:contains('Save')").click

          expect(DiscussionTopic.last.reply_to_entry_required_count).to eq 6

          assignment = Assignment.last

          sub_assignments = SubAssignment.where(parent_assignment_id: assignment.id)
          sub_assignment1 = sub_assignments.find_by(sub_assignment_tag: CheckpointLabels::REPLY_TO_TOPIC)
          sub_assignment2 = sub_assignments.find_by(sub_assignment_tag: CheckpointLabels::REPLY_TO_ENTRY)

          expect(sub_assignment1.points_possible).to eq 5
          expect(sub_assignment2.points_possible).to eq 7
        end

        it "still saves existing checkpointed discussion successfully even when there are replies" do
          @checkpointed_discussion.discussion_entries.create!(
            user: @teacher,
            message: "Initial post"
          )

          get "/courses/#{course.id}/discussion_topics/#{@checkpointed_discussion.id}/edit"
          fj("button:contains('Save')").click

          expect(f("h2[data-testid='message_title']").text).to include(@checkpointed_discussion.title)
        end

        it "deletes checkpoints if the checkpoint checkbox is unselected on an existing discussion with checkpoints" do
          assignment = Assignment.last
          expect(assignment.sub_assignments.count).to eq 2

          get "/courses/#{course.id}/discussion_topics/#{@checkpointed_discussion.id}/edit"

          force_click_native('input[type=checkbox][value="checkpoints"]')
          fj("button:contains('Save')").click

          expect(DiscussionTopic.last.reply_to_entry_required_count).to eq 0
          expect(assignment.sub_assignments.count).to eq 0
          expect(Assignment.last.has_sub_assignments).to be(false)
        end

        it "can edit a non-checkpointed discussion into a checkpointed discussion" do
          graded_discussion = create_graded_discussion(course)

          get "/courses/#{course.id}/discussion_topics/#{graded_discussion.id}/edit"
          expect(fj("span[class*='screenReaderContent']:contains('Checkpoints can be set to have different due dates and point values for the initial response and the subsequent replies.')")).to be_present
          force_click_native('input[type=checkbox][value="checkpoints"]')

          f("input[data-testid='points-possible-input-reply-to-topic']").send_keys :backspace
          f("input[data-testid='points-possible-input-reply-to-topic']").send_keys "5"
          f("input[data-testid='reply-to-entry-required-count']").send_keys :backspace
          f("input[data-testid='reply-to-entry-required-count']").send_keys "6"
          f("input[data-testid='points-possible-input-reply-to-entry']").send_keys :backspace
          f("input[data-testid='points-possible-input-reply-to-entry']").send_keys "7"

          fj("button:contains('Save')").click

          assignment = Assignment.last

          expect(assignment.has_sub_assignments?).to be true
          expect(DiscussionTopic.last.reply_to_entry_required_count).to eq 6

          sub_assignments = SubAssignment.where(parent_assignment_id: assignment.id)
          sub_assignment1 = sub_assignments.find_by(sub_assignment_tag: CheckpointLabels::REPLY_TO_TOPIC)
          sub_assignment2 = sub_assignments.find_by(sub_assignment_tag: CheckpointLabels::REPLY_TO_ENTRY)

          expect(sub_assignment1.points_possible).to eq 5
          expect(sub_assignment2.points_possible).to eq 7
        end

        it "cannot edit a non-checkpointed discussion with replies into a checkpointed discussion" do
          graded_discussion = create_graded_discussion(course)
          graded_discussion.discussion_entries.create!(
            user: @teacher,
            message: "Initial post"
          )

          get "/courses/#{course.id}/discussion_topics/#{graded_discussion.id}/edit"
          expect(f('input[type=checkbox][value="checkpoints"]')).not_to be_enabled
          expect(fj("span[class*='screenReaderContent']:contains('Checkpoints cannot be toggled after replies have been made.')")).to be_present
        end

        it "deletes checkpoints if the graded checkbox is unselected on an exisitng discussion with checkpoints" do
          assignment = Assignment.last
          expect(assignment.sub_assignments.count).to eq 2

          get "/courses/#{course.id}/discussion_topics/#{@checkpointed_discussion.id}/edit"

          # Uncheck the "graded" checkbox
          force_click_native('input[type=checkbox][value="graded"]')
          fj("button:contains('Save')").click

          # Expect the assignment an the checkpoints to no longer exist
          expect(DiscussionTopic.last.reply_to_entry_required_count).to eq 0
          expect(assignment.sub_assignments.count).to eq 0
          expect(Assignment.last.has_sub_assignments).to be(false)
          expect(DiscussionTopic.last.assignment).to be_nil
        end

        it "clears out group category selection if discussion is turned into a checkpointed discussion" do
          course.account.disable_feature!(:checkpoints_group_discussions)
          topic = group_discussion_assignment
          get "/courses/#{course.id}/discussion_topics/#{topic.id}/edit"
          expect(f("input[data-testid='group-discussion-checkbox']").attribute("checked")).to be_truthy
          expect(f("#discussion_group_category_id").attribute("value")).to eq topic.group_category.name

          force_click_native("input[data-testid='checkpoints-checkbox']")
          expect(f("input[data-testid='group-discussion-checkbox']").attribute("checked")).to be_falsey
        end

        it "preserves group category selection if discussion is turned into a checkpointed discussion when checkpoints_group_discussions is enabled" do
          topic = group_discussion_assignment
          preserved_id = topic.group_category.id
          get "/courses/#{course.id}/discussion_topics/#{topic.id}/edit"
          expect(f("input[data-testid='group-discussion-checkbox']").attribute("checked")).to be_truthy
          expect(f("#discussion_group_category_id").attribute("value")).to eq topic.group_category.name

          force_click_native("input[data-testid='checkpoints-checkbox']")
          expect(f("input[data-testid='group-discussion-checkbox']").attribute("checked")).to be_truthy
          expect(f("#discussion_group_category_id").attribute("value")).to eq topic.group_category.name
          fj("button:contains('Save')").click
          expect(topic.reload.group_category.id).to eq preserved_id
        end

        it "checkpointed discussion assigned to Everyone with no dates appears correctly with embedded assign to cards" do
          get "/courses/#{course.id}/discussion_topics/new"
          title = "checkpointed discussion assigned to Everyone with no dates"

          f("input[placeholder='Topic Title']").send_keys title

          force_click_native('input[type=checkbox][value="graded"]')
          force_click_native('input[type=checkbox][value="checkpoints"]')

          fj("button:contains('Save')").click
          wait_for_ajaximations

          graded_discussion = DiscussionTopic.last
          get "/courses/#{@course.id}/discussion_topics/#{graded_discussion.id}/edit"

          expect(get_all_dates_for_all_cards).to eq [
            {
              reply_to_topic: "",
              required_replies: "",
              available_from: "",
              until: "",
            }
          ]
        end

        it "successfully creates ADHOC overrides if a student is enrolled in multiple sections" do
          student_1 = User.create!(name: "student 1")

          section_1 = course.course_sections.create! name: "section 1"
          course.enroll_student(student_1, enrollment_state: "active", section: section_1, allow_multiple_enrollments: true)

          section_2 = course.course_sections.create! name: "section 2"
          course.enroll_student(student_1, enrollment_state: "active", section: section_2, allow_multiple_enrollments: true)

          section_3 = course.course_sections.create! name: "section 3"
          course.enroll_student(student_1, enrollment_state: "active", section: section_3, allow_multiple_enrollments: true)

          get "/courses/#{course.id}/discussion_topics/#{@checkpointed_discussion.id}/edit"

          title = "Graded Discussion Topic with checkpoints and Student enrolled in multiple sections"
          f("input[placeholder='Topic Title']").clear
          f("input[placeholder='Topic Title']").send_keys title
          f("input[data-testid='points-possible-input-reply-to-topic']").send_keys :backspace
          f("input[data-testid='points-possible-input-reply-to-topic']").send_keys "5"
          f("input[data-testid='reply-to-entry-required-count']").send_keys :backspace
          f("input[data-testid='reply-to-entry-required-count']").send_keys "3"
          f("input[data-testid='points-possible-input-reply-to-entry']").send_keys :backspace
          f("input[data-testid='points-possible-input-reply-to-entry']").send_keys "7"

          assign_to_element = Discussion.assignee_selector.first
          assign_to_element.click
          assign_to_element.send_keys :backspace
          assign_to_element.send_keys "student 1"

          f("button[data-testid='save-button']").click
          wait_for_ajaximations

          Discussion.section_warning_continue_button.click
          dt = DiscussionTopic.last
          expect(dt.reply_to_entry_required_count).to eq 3

          assignment = Assignment.last
          expect(assignment.has_sub_assignments?).to be true

          sub_assignments = SubAssignment.where(parent_assignment_id: assignment.id)
          sub_assignment1 = sub_assignments.find_by(sub_assignment_tag: CheckpointLabels::REPLY_TO_TOPIC)
          sub_assignment2 = sub_assignments.find_by(sub_assignment_tag: CheckpointLabels::REPLY_TO_ENTRY)

          expect(sub_assignment1.sub_assignment_tag).to eq "reply_to_topic"
          expect(sub_assignment1.points_possible).to eq 5
          expect(sub_assignment2.sub_assignment_tag).to eq "reply_to_entry"
          expect(sub_assignment2.points_possible).to eq 7

          assignment_override1 = AssignmentOverride.find_by(assignment: sub_assignment1)
          assignment_override2 = AssignmentOverride.find_by(assignment: sub_assignment2)

          expect(assignment_override1).to be_present
          expect(assignment_override2).to be_present

          expect(assignment_override1.set_type).to eq "ADHOC"

          student_ids = assignment_override1.assignment_override_students.map { |o| o.user.global_id }

          expect(student_ids).to match_array [student_1.global_id]

          # Verify that the discussion topic redirected the page to the new discussion topic
          wait_for_new_page_load
          expect(driver.current_url).to end_with("/courses/#{course.id}/discussion_topics/#{dt.id}")
        end
      end

      context "mastery paths aka cyoe ake conditional release" do
        def create_assignment(course, title, points_possible = 10)
          course.assignments.create!(
            title: "#{title} #{SecureRandom.alphanumeric(10)}",
            description: "General Assignment",
            points_possible:,
            submission_types: "online_text_entry",
            workflow_state: "published"
          )
        end

        def create_discussion(course, creator, workflow_state = "published")
          discussion_assignment = create_assignment(@course, "Discussion Assignment", 10)
          course.discussion_topics.create!(
            user: creator,
            title: "Discussion Topic #{SecureRandom.alphanumeric(10)}",
            message: "Discussion topic message",
            assignment: discussion_assignment,
            workflow_state:
          )
        end

        it "loads connected mastery paths immediately is requested in url" do
          course_with_teacher_logged_in
          @course.conditional_release = true
          @course.save!

          @trigger_assignment = create_assignment(@course, "Mastery Path Main Assignment", 10)
          @set1_assmt1 = create_assignment(@course, "Set 1 Assessment 1", 10)
          @set2_assmt1 = create_assignment(@course, "Set 2 Assessment 1", 10)
          @set2_assmt2 = create_assignment(@course, "Set 2 Assessment 2", 10)
          @set3a_assmt = create_assignment(@course, "Set 3a Assessment", 10)
          @set3b_assmt = create_assignment(@course, "Set 3b Assessment", 10)

          graded_discussion = create_discussion(@course, @teacher)

          course_module = @course.context_modules.create!(name: "Mastery Path Module")
          course_module.add_item(id: @trigger_assignment.id, type: "assignment")
          course_module.add_item(id: @set1_assmt1.id, type: "assignment")
          course_module.add_item(id: graded_discussion.id, type: "discussion_topic")
          course_module.add_item(id: @set2_assmt1.id, type: "assignment")
          course_module.add_item(id: @set2_assmt2.id, type: "assignment")
          course_module.add_item(id: @set3a_assmt.id, type: "assignment")
          course_module.add_item(id: @set3b_assmt.id, type: "assignment")

          ranges = [
            ConditionalRelease::ScoringRange.new(
              lower_bound: 0.7,
              upper_bound: 1.0,
              assignment_sets: [
                ConditionalRelease::AssignmentSet.new(
                  assignment_set_associations: [
                    ConditionalRelease::AssignmentSetAssociation.new(assignment_id: @set1_assmt1.id),
                    ConditionalRelease::AssignmentSetAssociation.new(assignment_id: graded_discussion.assignment_id)
                  ]
                )
              ]
            ),
            ConditionalRelease::ScoringRange.new(
              lower_bound: 0.4,
              upper_bound: 0.7,
              assignment_sets: [
                ConditionalRelease::AssignmentSet.new(
                  assignment_set_associations: [
                    ConditionalRelease::AssignmentSetAssociation.new(assignment_id: @set2_assmt1.id),
                    ConditionalRelease::AssignmentSetAssociation.new(assignment_id: @set2_assmt2.id)
                  ]
                )
              ]
            ),
            ConditionalRelease::ScoringRange.new(
              lower_bound: 0,
              upper_bound: 0.4,
              assignment_sets: [
                ConditionalRelease::AssignmentSet.new(
                  assignment_set_associations: [
                    ConditionalRelease::AssignmentSetAssociation.new(assignment_id: @set3a_assmt.id)
                  ]
                ),
                ConditionalRelease::AssignmentSet.new(
                  assignment_set_associations: [
                    ConditionalRelease::AssignmentSetAssociation.new(assignment_id: @set3b_assmt.id)
                  ]
                )
              ]
            )
          ]
          @rule = @course.conditional_release_rules.create!(trigger_assignment: @trigger_assignment, scoring_ranges: ranges)

          mp_discussion = @course.discussion_topics.create!(assignment: @trigger_assignment, title: "graded discussion")

          get "/courses/#{@course.id}/discussion_topics/#{mp_discussion.id}/edit#mastery-paths-editor"
          fj("div[role='tab']:contains('Mastery Paths')").click

          ui_ranges = ff("div.cr-scoring-range")
          expect(ui_ranges[0].text).to include @set1_assmt1.title
          expect(ui_ranges[0].text).to include graded_discussion.title

          expect(ui_ranges[1].text).to include @set2_assmt1.title
          expect(ui_ranges[1].text).to include @set2_assmt2.title

          expect(ui_ranges[2].text).to include @set3a_assmt.title
          expect(ui_ranges[2].text).to include @set3b_assmt.title
        end

        context "with course paces" do
          before do
            Account.site_admin.enable_feature!(:react_discussions_post)
          end

          it "sets an assignment override for mastery paths when mastery path toggle is turned on" do
            course_with_teacher_logged_in
            @course.root_account.enable_feature!(:course_pace_pacing_with_mastery_paths)
            @course.conditional_release = true
            @course.enable_course_paces = true
            @course.save!

            assignment = create_assignment(@course, "Mastery Path Main Assignment", 10)
            discussion = @course.discussion_topics.create!(assignment:, title: "graded discussion")

            get "/courses/#{@course.id}/discussion_topics/#{discussion.id}/edit"
            Discussion.mastery_path_toggle.click
            expect_new_page_load { Discussion.save_discussion }

            expect(assignment.assignment_overrides.active.find_by(set_id: AssignmentOverride::NOOP_MASTERY_PATHS, set_type: AssignmentOverride::SET_TYPE_NOOP)).to be_present
          end

          it "removes assignment override for mastery paths when mastery path toggle is turned off" do
            course_with_teacher_logged_in
            @course.root_account.enable_feature!(:course_pace_pacing_with_mastery_paths)
            @course.conditional_release = true
            @course.enable_course_paces = true
            @course.save!

            assignment = create_assignment(@course, "Mastery Path Main Assignment", 10)
            discussion = @course.discussion_topics.create!(assignment:, title: "graded discussion")
            assignment.assignment_overrides.create(set_id: AssignmentOverride::NOOP_MASTERY_PATHS, set_type: AssignmentOverride::SET_TYPE_NOOP)

            get "/courses/#{@course.id}/discussion_topics/#{discussion.id}/edit"
            Discussion.mastery_path_toggle.click
            expect_new_page_load { Discussion.save_discussion }

            expect(assignment.assignment_overrides.active.find_by(set_id: AssignmentOverride::NOOP_MASTERY_PATHS, set_type: AssignmentOverride::SET_TYPE_NOOP)).not_to be_present
          end
        end
      end
    end
  end
end
