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
require_relative "../helpers/context_modules_common"
require_relative "../assignments/page_objects/assignment_create_edit_page"
require_relative "pages/discussion_page"
require_relative "../../helpers/k5_common"
require_relative "../dashboard/pages/k5_important_dates_section_page"
require_relative "../dashboard/pages/k5_dashboard_common_page"
require_relative "../../helpers/selective_release_common"
require_relative "../conditional_release/page_objects/conditional_release_objects"

describe "discussions" do
  include_context "in-process server selenium tests"
  include DiscussionsCommon
  include ItemsAssignToTray
  include ContextModulesCommon
  include K5DashboardCommonPageObject
  include K5Common
  include K5ImportantDatesSectionPageObject
  include SelectiveReleaseCommon

  let(:course) { course_model.tap(&:offer!) }
  let(:default_section) { course.default_section }
  let(:new_section) { course.course_sections.create!(name: "section 2") }
  let(:group) do
    course.groups.create!(name: "group",
                          group_category:).tap do |g|
      g.add_user(student, "accepted", nil)
    end
  end
  let(:student) { student_in_course(course:, name: "student", display_name: "mister student", active_all: true).user }
  let(:teacher) { teacher_in_course(course:, name: "teacher", active_all: true).user }
  let(:assignment_group) { course.assignment_groups.create!(name: "assignment group") }
  let(:group_category) { course.group_categories.create!(name: "group category") }
  let(:assignment) do
    course.assignments.create!(
      name: "assignment",
      # submission_types: 'discussion_topic',
      assignment_group:
    )
  end

  before do
    stub_rcs_config
  end

  def set_react_topic_title_and_message(title, message)
    f("input[placeholder='Topic Title']").send_keys title
    type_in_tiny("textarea", message)
  end

  context "when discussion_create feature flag is OFF" do
    let(:url) { "/courses/#{course.id}/discussion_topics/new" }

    context "as a teacher" do
      before do
        user_session(teacher)
      end

      it "adds an attachment to a new topic", priority: "1" do
        skip_if_firefox("known issue with firefox https://bugzilla.mozilla.org/show_bug.cgi?id=1335085")
        topic_title = "new topic with file"
        get url
        wait_for_tiny(f("textarea[name=message]"))
        replace_content(f("input[name=title]"), topic_title)
        add_attachment_and_validate
        expect(DiscussionTopic.where(title: topic_title).first.attachment_id).to be_present
      end

      it "creates a podcast enabled topic", priority: "1" do
        get url
        wait_for_tiny(f("textarea[name=message]"))
        replace_content(f("input[name=title]"), "This is my test title")
        type_in_tiny("textarea[name=message]", "This is the discussion description.")

        f("input[type=checkbox][name=podcast_enabled]").click
        expect_new_page_load { submit_form(".form-actions") }
        # get "/courses/#{course.id}/discussion_topics"
        # TODO: talk to UI, figure out what to display here
        # f('.discussion-topic .icon-rss').should be_displayed
        expect(DiscussionTopic.last.podcast_enabled).to be_truthy
      end

      it "does not display the section specific announcer if the FF is disabled" do
        get url
        graded_checkbox = f('input[type=checkbox][name="assignment[set_assignment]"]')
        graded_checkbox.click
        expect(f("body")).not_to contain_css('input[id^="Autocomplete"]')
      end

      context "graded" do
        it "allows creating multiple due dates", priority: "1" do
          differentiated_modules_off
          assignment_group
          group_category
          new_section
          get url
          wait_for_tiny(f("textarea[name=message]"))

          f('input[type=checkbox][name="assignment[set_assignment]"]').click

          due_at1 = 3.days.from_now
          due_at2 = 4.days.from_now

          fj(".ic-tokeninput-input:first").send_keys(default_section.name)
          wait_for_ajaximations
          fj(".ic-tokeninput-option:visible:first").click
          wait_for_ajaximations
          fj(".datePickerDateField[data-date-type='due_at']:first").send_keys(format_date_for_view(due_at1), :tab)
          wait_for_ajaximations
          f("#add_due_date").click
          wait_for_ajaximations

          fj(".ic-tokeninput-input:last").send_keys(new_section.name)
          wait_for_ajaximations
          fj(".ic-tokeninput-option:visible:first").click
          wait_for_ajaximations
          fj(".datePickerDateField[data-date-type='due_at']:last").send_keys(format_date_for_view(due_at2))

          expect_new_page_load { f(".form-actions button[type=submit]").click }
          topic = DiscussionTopic.last

          overrides = topic.assignment.assignment_overrides
          expect(overrides.count).to eq 2
          default_override = overrides.detect { |o| o.set_id == default_section.id }
          expect(default_override.due_at.to_date).to eq due_at1.to_date
          other_override = overrides.detect { |o| o.set_id == new_section.id }
          expect(other_override.due_at.to_date).to eq due_at2.to_date
        end

        it "validates that a group category is selected", priority: "1" do
          assignment_group
          get url

          f('input[type=checkbox][name="assignment[set_assignment]"]').click
          f("#has_group_category").click
          f(%(span[data-testid="group-set-close"])).click
          submit_button = f("#edit_discussion_form_buttons .btn-primary[type=submit]")
          scroll_into_view(submit_button)
          submit_button.click
          wait_for_ajaximations
          error_box = f("div[role='alert'] .error_text")
          expect(error_box.text).to eq "Please create a group set"
        end

        context "archived grading schemes enabled" do
          before do
            Account.site_admin.enable_feature!(:grading_scheme_updates)
            Account.site_admin.enable_feature!(:archived_grading_schemes)
            @course = course
            @account = @course.account
            @active_grading_standard = @course.grading_standards.create!(title: "Active Grading Scheme", data: { "A" => 0.9, "F" => 0 }, scaling_factor: 1.0, points_based: false, workflow_state: "active")
            @archived_grading_standard = @course.grading_standards.create!(title: "Archived Grading Scheme", data: { "A" => 0.9, "F" => 0 }, scaling_factor: 1.0, points_based: false, workflow_state: "archived")
            @account_grading_standard = @account.grading_standards.create!(title: "Account Grading Scheme", data: { "A" => 0.9, "F" => 0 }, scaling_factor: 1.0, points_based: false, workflow_state: "active")
          end

          it "shows archived grading scheme if it is the course default twice, once to follow course default scheme and once to choose that scheme to use" do
            @course.update!(grading_standard_id: @archived_grading_standard.id)
            @course.reload
            get "/courses/#{@course.id}/discussion_topics/new"
            wait_for_ajaximations
            f('input[type=checkbox][name="assignment[set_assignment]"]').click
            wait_for_ajaximations
            f("#assignment_grading_type").click
            ffj("option:contains('Letter Grade')").last.click
            wait_for_ajaximations
            expect(f("[data-testid='grading-schemes-selector-dropdown']").attribute("title")).to eq(@archived_grading_standard.title + " (course default)")
            f("[data-testid='grading-schemes-selector-dropdown']").click
            expect(f("[data-testid='grading-schemes-selector-option-#{@course.grading_standard.id}']")).to include_text(@course.grading_standard.title)
          end

          it "removes grading schemes from dropdown after archiving them but still shows them upon reopening the modal" do
            get "/courses/#{@course.id}/discussion_topics/new"
            wait_for_ajaximations
            f('input[type=checkbox][name="assignment[set_assignment]"]').click
            wait_for_ajaximations
            f("#assignment_grading_type").click
            ffj("option:contains('Letter Grade')").last.click
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
            get "/courses/#{@course.id}/discussion_topics/new"
            wait_for_ajaximations
            f('input[type=checkbox][name="assignment[set_assignment]"]').click
            wait_for_ajaximations
            f("#assignment_grading_type").click
            ffj("option:contains('Letter Grade')").last.click
            wait_for_ajaximations
            f("[data-testid='manage-all-grading-schemes-button']").click
            wait_for_ajaximations
            expect(f("[data-testid='grading-scheme-#{archived_gs1.id}-name']")).to include_text(archived_gs1.title)
            expect(f("[data-testid='grading-scheme-#{archived_gs2.id}-name']")).to include_text(archived_gs2.title)
            expect(f("[data-testid='grading-scheme-#{archived_gs3.id}-name']")).to include_text(archived_gs3.title)
          end

          it "creates a discussion topic with selected grading scheme/standard" do
            grading_standard = course.grading_standards.create!(title: "Win/Lose", data: [["Winner", 0.94], ["Loser", 0]])

            get "/courses/#{@course.id}/discussion_topics/new"

            title = "Graded Discussion Topic with letter grade type"
            message = "replying to topic"

            f("input[placeholder='Topic Title']").send_keys title
            type_in_tiny("textarea", message)

            f('input[type=checkbox][name="assignment[set_assignment]"]').click
            wait_for_ajaximations
            f("#assignment_grading_type").click
            ffj("option:contains('Letter Grade')").last.click
            wait_for_ajaximations
            expect(fj("span:contains('Manage All Grading Schemes')").present?).to be_truthy
            f("[data-testid='grading-schemes-selector-dropdown']").click
            f("[data-testid='grading-schemes-selector-option-#{grading_standard.id}']").click
            f(".btn.btn-default.save_and_publish").click
            wait_for_ajaximations

            dt = DiscussionTopic.last

            expect(dt.title).to eq title
            expect(dt.assignment.name).to eq title
            expect(dt.assignment.grading_standard_id).to eq grading_standard.id
          end
        end
      end

      context "post to sis default setting" do
        before do
          @account = @course.root_account
          @account.set_feature_flag! "post_grades", "on"
        end

        it "defaults to post grades if account setting is enabled" do
          @account.settings[:sis_default_grade_export] = { locked: false, value: true }
          @account.save!

          get url
          f('input[type=checkbox][name="assignment[set_assignment]"]').click

          expect(is_checked("#assignment_post_to_sis")).to be_truthy
        end

        it "does not default to post grades if account setting is not enabled" do
          get url
          f('input[type=checkbox][name="assignment[set_assignment]"]').click

          expect(is_checked("#assignment_post_to_sis")).to be_falsey
        end
      end

      context "when react_discussions_post feature_flag is on", :ignore_js_errors do
        before do
          course.enable_feature! :react_discussions_post
        end

        it "allows creating anonymous discussions" do
          get url
          replace_content(f("input[name=title]"), "my anonymous title")
          f("input[value='full_anonymity']").click
          expect_new_page_load { submit_form(".form-actions") }
          expect(DiscussionTopic.last.anonymous_state).to eq "full_anonymity"
          expect(f("span[data-testid='anon-conversation']").text).to(
            eq("This is an anonymous Discussion. Though student names and profile pictures will be hidden, your name and profile picture will be visible to all course members. Mentions have also been disabled.")
          )
          expect(f("span[data-testid='author_name']").text).to eq teacher.short_name
        end

        it "disallows full_anonymity along with graded" do
          skip("revert enable ungraded discussion")
          get url
          replace_content(f("input[name=title]"), "my anonymous title")
          expect(f("input[id='use_for_grading']").attribute("checked")).to be_nil
          expect(f("span[data-testid=groups_grading_not_allowed]")).to_not be_displayed
          f("input[id='use_for_grading']").click
          expect(f("input[id='use_for_grading']").attribute("checked")).to eq "true"
          f("input[value='full_anonymity']").click
          expect(f("input[id='use_for_grading']").attribute("checked")).to be_nil # disabled
          expect(f("span[data-testid=groups_grading_not_allowed]")).to be_displayed
          expect_new_page_load { submit_form(".form-actions") }
        end
      end

      context "when react_discussions_post feature_flag is off" do
        before do
          course.disable_feature! :react_discussions_post
        end

        it "does not show anonymous discussion options" do
          get url
          expect(f("body")).not_to contain_jqcss "input[value='full_anonymity']"
        end
      end
    end

    context "as a student" do
      let(:account) { course.account }

      before do
        user_session(student)
      end

      context "when all discussion anonymity feature flags are ON", :ignore_js_errors do
        before do
          course.enable_feature! :react_discussions_post
        end

        it "lets students create anonymous discussions when allowed" do
          course.allow_student_anonymous_discussion_topics = true
          course.save!
          get url
          replace_content(f("input[name=title]"), "my anonymous title")
          f("input[value='full_anonymity']").click
          expect_new_page_load { submit_form(".form-actions") }
          expect(DiscussionTopic.last.anonymous_state).to eq "full_anonymity"
          expect(f("span[data-testid='anon-conversation']").text).to(
            eq("This is an anonymous Discussion. Your name and profile picture will be hidden from other course members. Mentions have also been disabled.")
          )
        end

        it "does not allow creation of anonymous group discussions" do
          course.allow_student_anonymous_discussion_topics = true
          course.save!
          get url
          expect(f("span[data-testid=groups_grading_not_allowed]")).to_not be_displayed
          f("input[value='full_anonymity']").click
          expect(f("span[data-testid=groups_grading_not_allowed]")).to be_displayed
        end

        it "does not let students create anonymous discussions when disallowed" do
          get url
          expect(course.allow_student_anonymous_discussion_topics).to be false
          expect(f("body")).not_to contain_jqcss "input[value='full_anonymity']"
        end

        it "lets students choose to make topics as themselves" do
          course.allow_student_anonymous_discussion_topics = true
          course.save!
          get url
          replace_content(f("input[name=title]"), "Student Partial Discussion")
          f("input[value='partial_anonymity']").click

          # verify default anonymous post selector
          expect(f("span[data-testid='current_user_avatar']")).to be_present
          expect(fj("div#sections_anonymous_post_selector span:contains('#{@student.name}')")).to be_truthy
          expect(f("input[data-component='anonymous_post_selector']").attribute("value")).to eq "Show to everyone"

          expect_new_page_load { submit_form(".form-actions") }
          expect(f("span[data-testid='non-graded-discussion-info']")).to include_text "Partially Anonymous Discussion"
          expect(f("span[data-testid='author_name']")).to include_text @student.name
        end

        it "lets students choose to make topics anonymously" do
          course.allow_student_anonymous_discussion_topics = true
          course.save!
          get url
          replace_content(f("input[name=title]"), "Student Partial Discussion (student anonymous)")
          f("input[value='partial_anonymity']").click
          f("input[data-component='anonymous_post_selector']").click
          fj("li:contains('Hide from everyone')").click
          expect(f("span[data-testid='anonymous_avatar']")).to be_present
          expect(fj("div#sections_anonymous_post_selector span:contains('Anonymous')")).to be_truthy
          expect(f("input[data-component='anonymous_post_selector']").attribute("value")).to eq "Hide from everyone"

          expect_new_page_load { submit_form(".form-actions") }
          expect(f("span[data-testid='non-graded-discussion-info']")).to include_text "Partially Anonymous Discussion"
          expect(f("span[data-testid='author_name']")).to include_text "Anonymous"
        end
      end

      it "creates a delayed discussion", priority: "1" do
        get url
        wait_for_tiny(f("textarea[name=message]"))
        replace_content(f("input[name=title]"), "Student Delayed")
        type_in_tiny("textarea[name=message]", "This is the discussion description.")
        target_time = 1.day.from_now
        unlock_text = format_time_for_view(target_time)
        unlock_text_index_page = format_date_for_view(target_time, :short)
        replace_content(f("#delayed_post_at"), unlock_text, tab_out: true)
        expect_new_page_load { submit_form(".form-actions") }
        expect(f(".entry-content").text).to include("This topic is locked until #{unlock_text}")
        expect_new_page_load { f("#section-tabs .discussions").click }
        expect(f(".discussion-availability").text).to include("Not available until #{unlock_text_index_page}")
      end

      it "gives error if Until date isn't after Available From date", priority: "1" do
        get url
        wait_for_tiny(f("textarea[name=message]"))
        replace_content(f("input[name=title]"), "Invalid Until date")
        type_in_tiny("textarea[name=message]", "This is the discussion description.")

        replace_content(f("#delayed_post_at"), format_time_for_view(1.day.from_now), tab_out: true)
        replace_content(f("#lock_at"), format_time_for_view(-2.days.from_now), tab_out: true)

        submit_form(".form-actions")
        expect(
          fj("div.error_text:contains('Date must be after date available')")
        ).to be_present
      end

      it "allows a student to create a discussion", priority: "1" do
        skip_if_firefox("known issue with firefox https://bugzilla.mozilla.org/show_bug.cgi?id=1335085")
        get url
        wait_for_tiny(f("textarea[name=message]"))
        replace_content(f("input[name=title]"), "Student Discussion")
        type_in_tiny("textarea[name=message]", "This is the discussion description.")
        expect(f("#discussion-edit-view")).to_not contain_css("#has_group_category")
        expect_new_page_load { submit_form(".form-actions") }
        expect(f(".discussion-title").text).to eq "Student Discussion"
        expect(f("#content")).not_to contain_css("#topic_publish_button")
      end

      it "does not show file attachment if allow_student_forum_attachments is not true", priority: "2" do
        skip_if_safari(:alert)
        # given
        course.allow_student_forum_attachments = false
        course.save!
        # expect
        get url
        expect(f("#content")).not_to contain_css("#disussion_attachment_uploaded_data")
      end

      it "shows file attachment if allow_student_forum_attachments is true", priority: "2" do
        skip_if_safari(:alert)
        # given
        course.allow_student_forum_attachments = true
        course.save!
        # expect
        get url
        expect(f("#discussion_attachment_uploaded_data")).not_to be_nil
      end

      context "in a course group" do
        let(:url) { "/groups/#{group.id}/discussion_topics/new" }

        it "does not show file attachment if allow_student_forum_attachments is not true", priority: "2" do
          skip_if_safari(:alert)
          # given
          course.allow_student_forum_attachments = false
          course.save!
          # expect
          get url
          expect(f("#content")).not_to contain_css("label[for=discussion_attachment_uploaded_data]")
        end

        it "shows file attachment if allow_student_forum_attachments is true", priority: "2" do
          skip_if_safari(:alert)
          # given
          course.allow_student_forum_attachments = true
          course.save!
          # expect
          get url
          expect(f("label[for=discussion_attachment_uploaded_data]")).to be_displayed
        end

        context "with usage rights required" do
          before { course.update!(usage_rights_required: true) }

          context "without the ability to attach files" do
            before { course.update!(allow_student_forum_attachments: false) }

            it "loads page without usage rights" do
              get url

              expect(f("body")).not_to contain_jqcss("#usage_rights_control button")
              # verify that the page did load correctly
              expect(ff("button[type='submit']").length).to eq 1
            end
          end
        end
      end

      context "in an account group" do
        let(:group) { account.groups.create! }

        before do
          tie_user_to_account(student, account:, role: student_role)
          group.add_user(student)
        end

        context "usage rights" do
          before do
            account.root_account.enable_feature!(:usage_rights_discussion_topics)
            account.settings = { "usage_rights_required" => {
              "value" => true
            } }
            account.save!
          end

          it "loads page" do
            get "/groups/#{group.id}/discussion_topics/new"

            expect(f("body")).not_to contain_jqcss("#usage_rights_control button")
            expect(ff("button[type='submit']").length).to eq 1
          end
        end
      end
    end
  end

  context "when discussion_create feature flag is ON", :ignore_js_errors do
    def set_datetime_input(input, date)
      input.click
      wait_for_ajaximations
      input.send_keys date
      input.send_keys :return
      wait_for_ajaximations
    end

    before do
      Account.site_admin.enable_feature! :discussion_create
      # we must turn react_discussions_post ON as well since some new
      # features, like, anonymous discussions, are dependent on it
      Account.site_admin.enable_feature! :react_discussions_post
    end

    context "as a student" do
      before do
        user_session(student)
      end

      it "does not show anonymity options when not allowed" do
        course.allow_student_anonymous_discussion_topics = false
        course.save!
        get "/courses/#{course.id}/discussion_topics/new"
        expect(f("body")).not_to contain_jqcss "input[value='full_anonymity']"
      end

      it "lets students create fully anonymous discussions when allowed" do
        course.allow_student_anonymous_discussion_topics = true
        course.save!
        get "/courses/#{course.id}/discussion_topics/new"
        f("input[placeholder='Topic Title']").send_keys "This is fully anonymous"
        force_click_native("input[value='full_anonymity']")
        f("button[data-testid='save-button']").click
        wait_for_ajaximations
        expect(f("span[data-testid='anon-conversation']").text).to eq "This is an anonymous Discussion. Your name and profile picture will be hidden from other course members. Mentions have also been disabled."
        expect(f("span[data-testid='author_name']").text).to include "Anonymous"
      end

      it "lets students create partially anonymous discussions when allowed (anonymous author by default)" do
        course.allow_student_anonymous_discussion_topics = true
        course.save!
        get "/courses/#{course.id}/discussion_topics/new"
        f("input[placeholder='Topic Title']").send_keys "This is partially anonymous"
        force_click_native("input[value='partial_anonymity']")
        f("button[data-testid='save-button']").click
        wait_for_ajaximations
        expect(f("span[data-testid='anon-conversation']").text).to eq "When creating a reply, you will have the option to show your name and profile picture to other course members or remain anonymous. Mentions have also been disabled."
        expect(f("span[data-testid='author_name']").text).to include "Anonymous"
      end

      it "lets students create partially anonymous discussions using their real name" do
        course.allow_student_anonymous_discussion_topics = true
        course.save!
        get "/courses/#{course.id}/discussion_topics/new"
        f("input[placeholder='Topic Title']").send_keys "This is partially anonymous"
        force_click_native("input[value='partial_anonymity']")

        # open anonymous selector
        # select real name to begin with
        force_click_native("input[value='Anonymous']")
        fj("li:contains('student')").click

        f("button[data-testid='save-button']").click
        wait_for_ajaximations
        expect(f("span[data-testid='anon-conversation']").text).to eq "When creating a reply, you will have the option to show your name and profile picture to other course members or remain anonymous. Mentions have also been disabled."
        expect(f("span[data-testid='author_name']").text).to include "student"
      end

      it "lets students create partially anonymous discussions when allowed (anonymous author by choice)" do
        course.allow_student_anonymous_discussion_topics = true
        course.save!
        get "/courses/#{course.id}/discussion_topics/new"
        f("input[placeholder='Topic Title']").send_keys "This is partially anonymous"
        force_click_native("input[value='partial_anonymity']")

        # open anonymous selector
        # select real name to begin with
        force_click_native("input[value='Anonymous']")
        fj("li:contains('student')").click
        # now go back to anonymous
        force_click_native("input[value='student']")
        fj("li:contains('Anonymous')").click

        f("button[data-testid='save-button']").click
        wait_for_ajaximations
        expect(f("span[data-testid='anon-conversation']").text).to eq "When creating a reply, you will have the option to show your name and profile picture to other course members or remain anonymous. Mentions have also been disabled."
        expect(f("span[data-testid='author_name']").text).to include "Anonymous"
      end

      it "hides the correct options" do
        get "/courses/#{course.id}/discussion_topics/new"
        expect(f("body")).not_to contain_jqcss "input[value='full_anonymity']"
        expect(f("body")).not_to contain_jqcss "input[value='enable-podcast-feed']"
        expect(f("body")).not_to contain_jqcss "input[value='graded']"
        expect(f("body")).not_to contain_jqcss "input[data-testid='group-discussion-checkbox']"
      end

      it "only shows the assign to UI when selective_release_backend and selective_release_ui_api is enabled if the student has an unrestricted enrollment" do
        Account.site_admin.enable_feature!(:selective_release_backend)
        Account.site_admin.enable_feature!(:selective_release_ui_api)
        get "/courses/#{course.id}/discussion_topics/new"
        expect(element_exists?(Discussion.assign_to_button_selector)).to be_truthy

        enrollment = course.enrollments.find_by(user: student)
        enrollment.update!(limit_privileges_to_course_section: true)
        get "/courses/#{course.id}/discussion_topics/new"
        expect(element_exists?(Discussion.assign_to_button_selector)).to be_falsey
      end
    end

    context "as a teacher" do
      before do
        user_session(teacher)
      end

      it "creates a new discussion topic with default selections successfully" do
        get "/courses/#{course.id}/discussion_topics/new"

        title = "My Test Topic"
        message = "replying to topic"

        # Set title
        f("input[placeholder='Topic Title']").send_keys title
        # Set Message
        type_in_tiny("textarea", message)

        # Save and publish
        f("button[data-testid='save-and-publish-button']").click
        wait_for_ajaximations

        dt = DiscussionTopic.last

        expect(dt.title).to eq title
        expect(dt.message).to include message
        expect(dt.require_initial_post).to be false
        expect(dt.delayed_post_at).to be_nil
        expect(dt.lock_at).to be_nil
        expect(dt.anonymous_state).to be_nil
        expect(dt.is_anonymous_author).to be false
        expect(dt).to be_published

        # Verify that the discussion topic redirected the page to the new discussion topic
        expect(driver.current_url).to end_with("/courses/#{course.id}/discussion_topics/#{dt.id}")
      end

      it "creates a require initial post discussion topic successfully" do
        get "/courses/#{course.id}/discussion_topics/new"
        title = "My Test Topic"
        message = "replying to topic"

        f("input[placeholder='Topic Title']").send_keys title
        type_in_tiny("textarea", message)
        force_click_native("input[data-testid='require-initial-post-checkbox']")
        f("button[data-testid='save-and-publish-button']").click
        wait_for_ajaximations
        dt = DiscussionTopic.last
        expect(dt.require_initial_post).to be true
      end

      it "creates a topic with available from and until dates successfully" do
        differentiated_modules_off
        get "/courses/#{course.id}/discussion_topics/new"

        title = "My Test Topic"
        message = "replying to topic"
        available_from = 5.days.ago
        available_until = 5.days.from_now

        f("input[placeholder='Topic Title']").send_keys title
        type_in_tiny("textarea", message)

        available_from_input = ff("input[placeholder='Select Date']")[0]
        available_until_input = ff("input[placeholder='Select Date']")[1]

        set_datetime_input(available_from_input, format_date_for_view(available_from))
        set_datetime_input(available_until_input, format_date_for_view(available_until))

        f("button[data-testid='save-and-publish-button']").click
        wait_for_ajaximations

        dt = DiscussionTopic.last
        expect(dt.delayed_post_at).to be_between(6.days.ago, 4.days.ago)
        expect(dt.lock_at).to be_between(4.days.from_now, 6.days.from_now)
      end

      it "create a topic with a TODO date successfully" do
        get "/courses/#{course.id}/discussion_topics/new"

        title = "My Test Topic"
        message = "replying to topic"
        todo_date = 3.days.from_now

        f("input[placeholder='Topic Title']").send_keys title
        type_in_tiny("textarea", message)

        force_click_native("input[value='add-to-student-to-do']")
        todo_input = ff("[data-testid='todo-date-section'] input")[0]
        set_datetime_input(todo_input, format_date_for_view(todo_date))
        f("button[data-testid='save-and-publish-button']").click
        wait_for_ajaximations

        dt = DiscussionTopic.last
        expect(dt.todo_date).to be_between(2.days.from_now, 4.days.from_now)
      end

      it "creates a fully anonymous discussion topic successfully" do
        get "/courses/#{course.id}/discussion_topics/new"
        f("input[placeholder='Topic Title']").send_keys "This is fully anonymous"
        force_click_native("input[value='full_anonymity']")
        f("button[data-testid='save-and-publish-button']").click
        wait_for_ajaximations
        expect(f("span[data-testid='anon-conversation']").text).to eq "This is an anonymous Discussion. Though student names and profile pictures will be hidden, your name and profile picture will be visible to all course members. Mentions have also been disabled."
        expect(f("span[data-testid='author_name']").text).to eq "teacher"
      end

      it "creates a partially anonymous discussion topic successfully" do
        get "/courses/#{course.id}/discussion_topics/new"
        f("input[placeholder='Topic Title']").send_keys "This is partially anonymous"
        force_click_native("input[value='partial_anonymity']")
        f("button[data-testid='save-and-publish-button']").click
        wait_for_ajaximations
        expect(f("span[data-testid='anon-conversation']").text).to eq "When creating a reply, students will have the option to show their name and profile picture or remain anonymous. Your name and profile picture will be visible to all course members. Mentions have also been disabled."
        expect(f("span[data-testid='author_name']").text).to eq "teacher"
      end

      it "displays the grading and groups not supported in anonymous discussions message when either of the anonymous options are selected" do
        get "/courses/#{course.id}/discussion_topics/new"
        force_click_native("input[value='full_anonymity']")
        expect(f("[data-testid=groups_grading_not_allowed]")).to be_displayed
        force_click_native("input[value='partial_anonymity']")
        expect(f("[data-testid=groups_grading_not_allowed]")).to be_displayed
      end

      it "creates an allow_rating discussion topic successfully" do
        get "/courses/#{course.id}/discussion_topics/new"
        f("input[placeholder='Topic Title']").send_keys "This is allow_rating"
        force_click_native("input[value='allow-liking']")
        f("button[data-testid='save-and-publish-button']").click
        wait_for_ajaximations
        dt = DiscussionTopic.last
        expect(dt.allow_rating).to be true
        expect(dt.only_graders_can_rate).to be false
      end

      it "creates an only_graders_can_rate discussion topic successfully" do
        get "/courses/#{course.id}/discussion_topics/new"
        f("input[placeholder='Topic Title']").send_keys "This is only_graders_can_rate"
        force_click_native("input[value='allow-liking']")
        force_click_native("input[value='only-graders-can-like']")
        f("button[data-testid='save-and-publish-button']").click
        wait_for_ajaximations
        dt = DiscussionTopic.last
        expect(dt.allow_rating).to be true
        expect(dt.only_graders_can_rate).to be true
      end

      it "creates a discussion topic successfully with podcast_enabled and podcast_has_student_posts" do
        get "/courses/#{course.id}/discussion_topics/new"
        f("input[placeholder='Topic Title']").send_keys "This is a topic with podcast_enabled and podcast_has_student_posts"
        force_click_native("input[value='enable-podcast-feed']")
        wait_for_ajaximations
        force_click_native("input[value='include-student-replies-in-podcast-feed']")
        f("button[data-testid='save-and-publish-button']").click
        wait_for_ajaximations
        dt = DiscussionTopic.last
        expect(dt.podcast_enabled).to be true
        expect(dt.podcast_has_student_posts).to be true
      end

      it "does not show allow liking options when course is a k5 homeroom course" do
        Account.default.enable_as_k5_account!
        course.homeroom_course = true
        course.save!

        get "/courses/#{course.id}/discussion_topics/new"
        f("input[placeholder='Topic Title']").send_keys "Liking not settable in k5 homeroom courses"
        expect(f("body")).not_to contain_jqcss "input[value='allow-liking']"
        expect(f("body")).not_to contain_jqcss "input[value='only-graders-can-like']"
        f("button[data-testid='save-and-publish-button']").click
        wait_for_ajaximations
        dt = DiscussionTopic.last
        expect(dt.allow_rating).to be false
        expect(dt.only_graders_can_rate).to be false
      end

      it "shows course sections or course group categories" do
        differentiated_modules_off
        new_section
        group_category
        group

        get "/courses/#{course.id}/discussion_topics/new"
        f("[data-testid='section-select']").click
        # verify all sections exist in the dropdown
        expect(f("[data-testid='section-opt-#{default_section.id}']")).to be_present
        expect(f("[data-testid='section-opt-#{new_section.id}']")).to be_present
        force_click_native("input[data-testid='group-discussion-checkbox']")
        f("input[placeholder='Select a group category']").click
        # very group category exists in the dropdown
        expect(f("[data-testid='group-category-opt-#{group_category.id}']")).to be_present
      end

      it "create a require initial post discussion topic successfully for course discussions with a group category" do
        group_category
        group

        get "/courses/#{course.id}/discussion_topics/new"
        f("input[placeholder='Topic Title']").send_keys "my group discussion from course"
        force_click_native("input[data-testid='require-initial-post-checkbox']")
        force_click_native("input[data-testid='group-discussion-checkbox']")
        f("input[placeholder='Select a group category']").click
        force_click_native("[data-testid='group-category-opt-#{group_category.id}']")
        f("button[data-testid='save-and-publish-button']").click
        wait_for_ajaximations
        dts = DiscussionTopic.where(user_id: teacher.id)
        expect(dts.collect(&:require_initial_post?)).to match_array([true, true])
      end

      it "creates group via shared group modal" do
        new_section
        group_category
        group

        get "/courses/#{course.id}/discussion_topics/new"
        force_click_native("input[data-testid='group-discussion-checkbox']")
        f("input[placeholder='Select a group category']").click
        wait_for_ajaximations
        force_click_native("[data-testid='group-category-opt-new-group-category']")
        wait_for_ajaximations
        expect(f("[data-testid='modal-create-groupset']")).to be_present
        f("#new-group-set-name").send_keys("Onyx 1")
        force_click_native("[data-testid='group-set-save']")
        wait_for_ajaximations
        new_group_category = GroupCategory.last
        expect(new_group_category.name).to eq("Onyx 1")
        expect(f("input[placeholder='Select a group category']")["value"]).to eq(new_group_category.name)
      end

      context "usage rights" do
        before do
          course.root_account.enable_feature!(:usage_rights_discussion_topics)
          course.update!(usage_rights_required: true)
        end

        it "sets an error if no usage rights is selected" do
          get "/courses/#{course.id}/discussion_topics/new"

          set_react_topic_title_and_message("My Test Topic", "replying to topic")

          # Verify that the usage-rights-icon appears
          expect(f("button[data-testid='usage-rights-icon']")).to be_truthy
          icon_color_before = f("button[data-testid='usage-rights-icon']").find_element(css: "span").style("color")

          # Attach a file
          _filename, fullpath, _data = get_file("graded.png")
          f("[data-testid='attachment-input']").send_keys(fullpath)

          # Save and publish
          f("button[data-testid='save-and-publish-button']").click
          wait_for_ajaximations

          icon_color_after = f("button[data-testid='usage-rights-icon']").find_element(css: "span").style("color")

          # Expect the color of the icon to change to indicate an error
          expect(icon_color_before == icon_color_after).to be false
          # Verify that the page did not redirect when the error occured
          expect(driver.current_url).to end_with("/courses/#{course.id}/discussion_topics/new")
        end

        it "does not set an error if there is no attachment" do
          get "/courses/#{course.id}/discussion_topics/new"

          set_react_topic_title_and_message("My Test Topic", "replying to topic")

          # Verify that the usage-rights-icon appears
          expect(f("button[data-testid='usage-rights-icon']")).to be_truthy

          # Save and publish
          f("button[data-testid='save-and-publish-button']").click
          wait_for_ajaximations

          dt = DiscussionTopic.last
          expect(dt.title).to eq "My Test Topic"

          # Verify that the discussion topic redirected the page to the new discussion topic
          expect(driver.current_url).to end_with("/courses/#{course.id}/discussion_topics/#{dt.id}")
        end

        it "correctly sets usage rights" do
          get "/courses/#{course.id}/discussion_topics/new"

          set_react_topic_title_and_message("My Test Topic", "replying to topic")

          # Attach a file
          _filename, fullpath, _data = get_file("graded.png")
          f("[data-testid='attachment-input']").send_keys(fullpath)

          # Verify that the usage-rights-icon appears
          expect(f("button[data-testid='usage-rights-icon']")).to be_truthy

          f("button[data-testid='usage-rights-icon']").click
          wait_for_ajaximations
          f("input[data-testid='usage-select']").click
          ff("span[data-testid='usage-rights-option']")[1].click
          f("button[data-testid='save-usage-rights']").click

          # Save and publish
          f("button[data-testid='save-and-publish-button']").click
          wait_for_ajaximations

          dt = DiscussionTopic.last
          usage_rights = DiscussionTopic.last.attachment.usage_rights

          # Verify that the usage_rights were correctly set
          expect(dt.title).to eq "My Test Topic"
          expect(usage_rights.use_justification).to eq "own_copyright"
          expect(usage_rights.legal_copyright).to eq ""

          # Verify that the discussion topic redirected the page to the new discussion topic
          expect(driver.current_url).to end_with("/courses/#{course.id}/discussion_topics/#{dt.id}")
        end
      end

      context "mastery paths" do
        before do
          course.conditional_release = true
          course.save!

          @assignment_for_mp = assignment_model(course: @course, points_possible: 0, title: "Assignment for MP")
        end

        it "allows creating a discussion with mastery paths" do
          get "/courses/#{course.id}/discussion_topics/new"

          title = "Graded Discussion w/Mastery Paths"

          f("input[placeholder='Topic Title']").send_keys title

          force_click_native('input[type=checkbox][value="graded"]')
          wait_for_ajaximations

          f("input[data-testid='points-possible-input']").send_keys "10"
          fj("div[role='tab']:contains('Mastery Paths')").click

          ConditionalReleaseObjects.last_add_assignment_button.click
          ConditionalReleaseObjects.mp_assignment_checkbox(@assignment_for_mp.title).click
          ConditionalReleaseObjects.add_items_button.click

          expect(ConditionalReleaseObjects.assignment_card_exists?(@assignment_for_mp.title)).to be(true)

          f("button[data-testid='save-and-publish-button']").click
          wait_for_ajaximations

          dt = DiscussionTopic.last
          rule = ConditionalRelease::Rule.last
          rule_assignment = rule.trigger_assignment
          rule_first_assignment = rule.assignment_set_associations.first.assignment

          expect(rule_assignment.id).to eq(dt.assignment.id)
          expect(rule_first_assignment.id).to eq(@assignment_for_mp.id)
        end
      end
    end

    context "announcements" do
      it "displays correct fields for a new announcement" do
        user_session(teacher)
        get "/courses/#{course.id}/discussion_topics/new?is_announcement=true"
        # Expect certain field to be present
        expect(f("body")).to contain_jqcss "input[value='enable-participants-commenting']"
        expect(f("body")).to contain_jqcss "input[value='must-respond-before-viewing-replies']"
        expect(f("body")).to contain_jqcss "input[value='enable-podcast-feed']"
        expect(f("body")).to contain_jqcss "input[value='allow-liking']"
        expect(f("body")).to contain_jqcss "div[data-testid='non-graded-date-options']"

        # Expect certain field to not be present
        expect(f("body")).not_to contain_jqcss "input[value='full_anonymity']"
        expect(f("body")).not_to contain_jqcss "input[value='graded']"
        expect(f("body")).not_to contain_jqcss "input[value='group-discussion']"
        expect(f("body")).not_to contain_jqcss "input[value='add-to-student-to-do']"
      end
    end

    context "group context" do
      before do
        user_session(teacher)
      end

      it "shows only and creates only group context discussions options" do
        get "/groups/#{group.id}/discussion_topics/new"
        expect(f("body")).not_to contain_jqcss "input[value='enable-delay-posting']"
        expect(f("body")).not_to contain_jqcss "input[value='enable-participants-commenting']"
        expect(f("body")).not_to contain_jqcss "input[value='must-respond-before-viewing-replies']"
        expect(f("body")).not_to contain_jqcss "input[value='full_anonymity']"
        expect(f("body")).not_to contain_jqcss "input[value='graded']"
        expect(f("body")).not_to contain_jqcss "input[value='group-discussion']"

        title = "Group Context Discussion"
        message = "this is a group context discussion"
        todo_date = 3.days.from_now

        f("input[placeholder='Topic Title']").send_keys title
        type_in_tiny("textarea#discussion-topic-message-body", message)
        force_click_native("input[value='enable-podcast-feed']")
        force_click_native("input[value='allow-liking']")
        force_click_native("input[value='only-graders-can-like']")
        force_click_native("input[value='add-to-student-to-do']")
        todo_input = ff("[data-testid='todo-date-section'] input")[0]
        set_datetime_input(todo_input, format_date_for_view(todo_date))
        f("button[data-testid='save-and-publish-button']").click
        wait_for_ajaximations

        dt = DiscussionTopic.last
        expect(dt.title).to eq title
        expect(dt.message).to include message
        expect(dt.podcast_enabled).to be true
        expect(dt.only_graders_can_rate).to be true
        expect(dt.allow_rating).to be true
        expect(dt.context_type).to eq "Group"
        expect(driver.current_url).to end_with("/groups/#{group.id}/discussion_topics/#{dt.id}")
      end
    end

    context "assignment creation" do
      before do
        user_session(teacher)
      end

      it "does not display multiple assignTo options for students in multiple sections" do
        differentiated_modules_off
        # create and enroll student into a second section
        section2 = course.course_sections.create! name: "section2"
        course.enroll_student(student, enrollment_state: "active", section: section2, allow_multiple_enrollments: true)

        get "/courses/#{course.id}/discussion_topics/new"

        force_click_native('input[type=checkbox][value="graded"]')
        wait_for_ajaximations

        f("input[data-testid='assign-to-select']").click

        assign_to_option_count = course.all_accepted_students.count + course.course_sections.active.count + 1
        expect(ff("span[data-testid='assign-to-select-option']").count).to eq assign_to_option_count
      end

      it "creates a discussion topic with an assignment with automatic peer reviews" do
        get "/courses/#{course.id}/discussion_topics/new"

        title = "Graded Discussion Topic with Peer Reviews"
        message = "replying to topic"

        f("input[placeholder='Topic Title']").send_keys title
        type_in_tiny("textarea", message)

        force_click_native('input[type=checkbox][value="graded"]')
        wait_for_ajaximations

        f("input[data-testid='points-possible-input']").send_keys "12"
        force_click_native("input[data-testid='peer_review_auto']")

        f("button[data-testid='save-and-publish-button']").click
        wait_for_ajaximations

        dt = DiscussionTopic.last
        expect(dt.title).to eq title
        expect(dt.assignment.name).to eq title
        expect(dt.assignment.peer_review_count).to be 1
        expect(dt.assignment.peer_reviews).to be true
        expect(dt.assignment.automatic_peer_reviews).to be true
      end

      describe "when updating Assign To" do
        before do
          differentiated_modules_off
          course.course_sections.create!(name: "Section 3")
          course.course_sections.create!(name: "Section 4")

          get "/courses/#{course.id}/discussion_topics/new"
          f("input[placeholder='Topic Title']").send_keys "Assign To warning in topic creation"

          force_click_native('input[type=checkbox][value="graded"]')
          wait_for_ajaximations

          f("button[title='Remove Everyone']").click
        end

        it "shows warning when not all sections are assigned" do
          f("button[data-testid='save-and-publish-button']").click

          expect(fj("span:contains('Not all sections will be assigned this item.')")).to be_present
          course.course_sections.each do |section|
            expect(fj("span:contains('#{section.name}')")).to be_present
          end
        end

        it "shows warning when not all sections are assigned but then, continues to create the discussion topic" do
          # Assigns to one of the sections
          f("input[data-testid='assign-to-select']").click
          ff("span[data-testid='assign-to-select-option']")[1].click

          f("button[data-testid='save-and-publish-button']").click

          expect(fj("span:contains('Not all sections will be assigned this item.')")).to be_present

          f("button[data-testid='continue-button']").click
          wait_for_ajaximations

          dt = DiscussionTopic.last
          expect(dt.title).to eq "Assign To warning in topic creation"
        end
      end

      it "creates a discussion topic with an assignment with manual peer reviews" do
        get "/courses/#{course.id}/discussion_topics/new"

        title = "Graded Discussion Topic with Peer Reviews"
        message = "replying to topic"

        f("input[placeholder='Topic Title']").send_keys title
        type_in_tiny("textarea", message)

        force_click_native('input[type=checkbox][value="graded"]')
        wait_for_ajaximations

        f("input[data-testid='points-possible-input']").send_keys "12"
        force_click_native("input[data-testid='peer_review_manual']")

        f("button[data-testid='save-and-publish-button']").click
        wait_for_ajaximations

        dt = DiscussionTopic.last
        expect(dt.assignment.peer_review_count).to be 0
        expect(dt.assignment.peer_reviews).to be true
        expect(dt.assignment.automatic_peer_reviews).to be false
      end

      it "creates a discussion topic with an assignment with Sync to SIS" do
        @account = @course.root_account
        @account.set_feature_flag! "post_grades", "on"
        get "/courses/#{course.id}/discussion_topics/new"

        title = "Graded Discussion Topic with Sync to SIS"
        message = "replying to topic"

        f("input[placeholder='Topic Title']").send_keys title
        type_in_tiny("textarea", message)

        force_click_native('input[type=checkbox][value="graded"]')
        wait_for_ajaximations

        f("input[data-testid='points-possible-input']").send_keys "12"
        force_click_native('input[type=checkbox][value="post_to_sis"]')

        f("button[data-testid='save-and-publish-button']").click
        wait_for_ajaximations

        dt = DiscussionTopic.last
        expect(dt.assignment.post_to_sis).to be true
        expect(dt.assignment.name).to eq title
      end

      it "creates a discussion topic with selected grading scheme/standard and archived grading schemes is disabled" do
        Account.site_admin.disable_feature!(:archived_grading_schemes)
        grading_standard = course.grading_standards.create!(title: "Win/Lose", data: [["Winner", 0.94], ["Loser", 0]])

        get "/courses/#{course.id}/discussion_topics/new"

        title = "Graded Discussion Topic with letter grade type"
        message = "replying to topic"

        f("input[placeholder='Topic Title']").send_keys title
        type_in_tiny("textarea", message)

        force_click_native('input[type=checkbox][value="graded"]')
        wait_for_ajaximations

        f("input[data-testid='display-grade-input']").click
        ffj("span:contains('Letter Grade')").last.click
        expect(fj("span:contains('Manage All Grading Schemes')").present?).to be_truthy
        ffj("span:contains('Default Canvas Grading Scheme')").last.click
        fj("option:contains('#{grading_standard.title}')").click

        f("button[data-testid='save-and-publish-button']").click
        wait_for_ajaximations

        dt = DiscussionTopic.last

        expect(dt.title).to eq title
        expect(dt.assignment.name).to eq title
        expect(dt.assignment.grading_standard_id).to eq grading_standard.id
      end

      context "archived grading schemes enabled" do
        before do
          Account.site_admin.enable_feature!(:grading_scheme_updates)
          Account.site_admin.enable_feature!(:archived_grading_schemes)
          @course = course
          @account = @course.account
          @active_grading_standard = @course.grading_standards.create!(title: "Active Grading Scheme", data: { "A" => 0.9, "F" => 0 }, scaling_factor: 1.0, points_based: false, workflow_state: "active")
          @archived_grading_standard = @course.grading_standards.create!(title: "Archived Grading Scheme", data: { "A" => 0.9, "F" => 0 }, scaling_factor: 1.0, points_based: false, workflow_state: "archived")
          @account_grading_standard = @account.grading_standards.create!(title: "Account Grading Scheme", data: { "A" => 0.9, "F" => 0 }, scaling_factor: 1.0, points_based: false, workflow_state: "active")
        end

        it "shows archived grading scheme if it is the course default twice, once to follow course default scheme and once to choose that scheme to use" do
          @course.update!(grading_standard_id: @archived_grading_standard.id)
          @course.reload
          get "/courses/#{@course.id}/discussion_topics/new"
          wait_for_ajaximations
          force_click_native('input[type=checkbox][value="graded"]')
          wait_for_ajaximations
          f("input[data-testid='display-grade-input']").click
          ffj("span:contains('Letter Grade')").last.click
          wait_for_ajaximations
          expect(f("[data-testid='grading-schemes-selector-dropdown']").attribute("title")).to eq(@archived_grading_standard.title + " (course default)")
          f("[data-testid='grading-schemes-selector-dropdown']").click
          expect(f("[data-testid='grading-schemes-selector-option-#{@course.grading_standard.id}']")).to include_text(@course.grading_standard.title)
        end

        it "removes grading schemes from dropdown after archiving them but still shows them upon reopening the modal" do
          get "/courses/#{@course.id}/discussion_topics/new"
          wait_for_ajaximations
          force_click_native('input[type=checkbox][value="graded"]')
          wait_for_ajaximations
          f("input[data-testid='display-grade-input']").click
          ffj("span:contains('Letter Grade')").last.click
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
          get "/courses/#{@course.id}/discussion_topics/new"
          wait_for_ajaximations
          force_click_native('input[type=checkbox][value="graded"]')
          wait_for_ajaximations
          f("input[data-testid='display-grade-input']").click
          ffj("span:contains('Letter Grade')").last.click
          wait_for_ajaximations
          f("[data-testid='manage-all-grading-schemes-button']").click
          wait_for_ajaximations
          expect(f("[data-testid='grading-scheme-#{archived_gs1.id}-name']")).to include_text(archived_gs1.title)
          expect(f("[data-testid='grading-scheme-#{archived_gs2.id}-name']")).to include_text(archived_gs2.title)
          expect(f("[data-testid='grading-scheme-#{archived_gs3.id}-name']")).to include_text(archived_gs3.title)
        end

        it "creates a discussion topic with selected grading scheme/standard" do
          grading_standard = course.grading_standards.create!(title: "Win/Lose", data: [["Winner", 0.94], ["Loser", 0]])

          get "/courses/#{course.id}/discussion_topics/new"

          title = "Graded Discussion Topic with letter grade type"
          message = "replying to topic"

          f("input[placeholder='Topic Title']").send_keys title
          type_in_tiny("textarea", message)

          force_click_native('input[type=checkbox][value="graded"]')
          wait_for_ajaximations

          f("input[data-testid='display-grade-input']").click
          ffj("span:contains('Letter Grade')").last.click
          expect(fj("span:contains('Manage All Grading Schemes')").present?).to be_truthy
          f("[data-testid='grading-schemes-selector-dropdown']").click
          f("[data-testid='grading-schemes-selector-option-#{grading_standard.id}']").click

          f("button[data-testid='save-and-publish-button']").click
          wait_for_ajaximations

          dt = DiscussionTopic.last

          expect(dt.title).to eq title
          expect(dt.assignment.name).to eq title
          expect(dt.assignment.grading_standard_id).to eq grading_standard.id
        end
      end

      it "edits a topic with an assignment with sync to sis" do
        @account = @course.root_account
        @account.set_feature_flag! "post_grades", "on"

        # topic with assignment
        dt = @course.discussion_topics.create!(title: "no options enabled - topic", message: "test")

        assignment = dt.context.assignments.build(points_possible: 50, post_to_sis: true)
        dt.assignment = assignment
        dt.save!
        dt.reload

        expect(dt.assignment.post_to_sis).to be true

        get "/courses/#{course.id}/discussion_topics/#{dt.id}/edit"
        force_click_native('input[type=checkbox][value="post_to_sis"]')
        f("button[data-testid='save-button']").click
        wait_for_ajaximations

        expect(dt.reload.assignment.post_to_sis).to be false
      end

      it "does not allow submitting, when groups outside of the selected group category are selected" do
        differentiated_modules_off
        group_category.groups.create!(name: "group 1", context_type: "Course", context_id: course.id)
        get "/courses/#{course.id}/discussion_topics/new"

        title = "Group Context Discussion"
        message = "this is a group context discussion"

        f("input[placeholder='Topic Title']").send_keys title
        type_in_tiny("textarea#discussion-topic-message-body", message)
        force_click_native('input[type=checkbox][value="graded"]')
        force_click_native("input[data-testid='group-discussion-checkbox']")
        group_selector = f("input[placeholder='Select a group category']")
        group_selector.click
        wait_for_ajaximations
        group_selector.send_keys :arrow_down
        group_selector.send_keys :enter
        wait_for_ajaximations

        assign_to_selector = f("input[data-testid='assign-to-select']")
        assign_to_selector.click
        assign_to_selector.send_keys "group 1"
        assign_to_selector.send_keys :enter
        wait_for_ajaximations
        force_click_native("input[data-testid='group-discussion-checkbox']")
        wait_for_ajaximations

        f("button[data-testid='save-and-publish-button']").click
        wait_for_ajaximations

        expect(fj("body:contains('Groups can only be part of the actively selected group set.')")).to be_present
      end

      context "discussion form validations" do
        it "Post to section validation works correctly" do
          differentiated_modules_off
          get "/courses/#{course.id}/discussion_topics/new"

          # Add a title, so that we know that the empty post to field is causing it to not submit
          title = "Graded Discussion Topic with Peer Reviews"
          f("input[placeholder='Topic Title']").send_keys title

          fj("button:contains('All Sections')").click
          # Verify that the error message "A section is required" appears
          expect(fj("body:contains('A section is required')")).to be_present

          # Verify that you can not submit the form
          f("button[data-testid='save-and-publish-button']").click
          wait_for_ajaximations
          # Verify that no redirect happened
          expect(driver.current_url).to end_with("/courses/#{course.id}/discussion_topics/new")
        end

        it "Assign To validation works correctly" do
          differentiated_modules_off
          get "/courses/#{course.id}/discussion_topics/new"

          # Add a title, so that we know that the empty post to field is causing it to not submit
          title = "Graded Discussion Topic with Peer Reviews"
          f("input[placeholder='Topic Title']").send_keys title

          force_click_native('input[type=checkbox][value="graded"]')

          fj("button:contains('Everyone')").click
          # Verify that the error message "Please select at least one option." appears
          expect(fj("body:contains('Please select at least one option.')")).to be_present

          # Verify that you can not submit the form
          f("button[data-testid='save-and-publish-button']").click
          wait_for_ajaximations
          # Verify that no redirect happened
          expect(driver.current_url).to end_with("/courses/#{course.id}/discussion_topics/new")
        end

        it "Due Date validations work" do
          differentiated_modules_off
          get "/courses/#{course.id}/discussion_topics/new"

          # Add a title, so that we know that the empty post to field is causing it to not submit
          title = "Graded Discussion Topic with due date"
          f("input[placeholder='Topic Title']").send_keys title

          force_click_native('input[type=checkbox][value="graded"]')

          due_at_input = f("input[placeholder='Select Assignment Due Date']")
          available_from_input = f("input[placeholder='Select Assignment Available From Date']")
          available_until_input = f("input[placeholder='Select Assignment Available Until Date']")

          set_datetime_input(due_at_input, format_date_for_view(10.days.from_now))
          set_datetime_input(available_from_input, format_date_for_view(5.days.from_now))
          set_datetime_input(available_until_input, format_date_for_view(5.days.ago))

          expect(fj("span:contains('Due date must not be after the Available Until date.')")).to be_present
          expect(ffj("span:contains('Unlock date cannot be after lock date')").count).not_to be 0

          # Verify that you can not submit the form
          f("button[data-testid='save-and-publish-button']").click
          wait_for_ajaximations
          # Verify that no redirect happened
          expect(driver.current_url).to end_with("/courses/#{course.id}/discussion_topics/new")
        end
      end

      context "assignment overrides" do
        before do
          @section_1 = course.course_sections.create!(name: "section 1")
          @section_2 = course.course_sections.create!(name: "section 2")
          @section_3 = course.course_sections.create!(name: "section 3")

          @group_category = course.group_categories.create!(name: "group category 1")
          @group_1 = @group_category.groups.create!(name: "group 1", context_type: "Course", context_id: course.id)
          @group_2 = @group_category.groups.create!(name: "group 2", context_type: "Course", context_id: course.id)
          @group_3 = @group_category.groups.create!(name: "group 3", context_type: "Course", context_id: course.id)

          @student_1 = User.create!(name: "student 1")
          @student_2 = User.create!(name: "student 2")
          @student_3 = User.create!(name: "student 3")

          course.enroll_student(@student_1, enrollment_state: "active", section: @section_1)
          course.enroll_student(@student_2, enrollment_state: "active", section: @section_2)
          course.enroll_student(@student_3, enrollment_state: "active", section: @section_3)
        end

        context "with differentiated modules FF OFF" do
          before(:once) do
            differentiated_modules_off
          end

          it "creates a discussion topic with an assignment with a mastery path override" do
            course.conditional_release = true
            course.save!
            get "/courses/#{course.id}/discussion_topics/new"

            title = "Graded Discussion Topic with mastery path override"
            message = "replying to topic"

            f("input[placeholder='Topic Title']").send_keys title
            type_in_tiny("textarea", message)

            force_click_native('input[type=checkbox][value="graded"]')
            wait_for_ajaximations

            f("input[data-testid='points-possible-input']").send_keys "12"

            assign_to_element = f("input[data-testid='assign-to-select']")
            assign_to_element.click
            assign_to_element.send_keys :backspace
            assign_to_element.send_keys "mastery path"
            assign_to_element.send_keys :enter

            f("button[data-testid='save-and-publish-button']").click
            wait_for_ajaximations

            f("button[data-testid='continue-button']").click
            wait_for_ajaximations

            dt = DiscussionTopic.last
            expect(dt.title).to eq title
            expect(dt.assignment.name).to eq title

            overrides = dt.assignment.assignment_overrides
            expect(overrides.length).to be 1
            expect(overrides[0].title).to eq "Mastery Paths"
            expect(overrides[0].set_id).to eq 1
            expect(overrides[0].set_type).to eq "Noop"
          end

          it "creates a discussion topic with an assignment with section overrides" do
            get "/courses/#{course.id}/discussion_topics/new"

            title = "Graded Discussion Topic with section overrides"
            message = "replying to topic"

            f("input[placeholder='Topic Title']").send_keys title
            type_in_tiny("textarea", message)

            force_click_native('input[type=checkbox][value="graded"]')
            wait_for_ajaximations

            f("input[data-testid='points-possible-input']").send_keys "12"

            assign_to_element = f("input[data-testid='assign-to-select']")
            assign_to_element.click
            assign_to_element.send_keys :backspace
            assign_to_element.send_keys "section 1"
            assign_to_element.send_keys :enter
            assign_to_element.send_keys "section 2"
            assign_to_element.send_keys :enter
            assign_to_element.send_keys "section 3"
            assign_to_element.send_keys :enter

            f("button[data-testid='save-and-publish-button']").click
            wait_for_ajaximations

            f("button[data-testid='continue-button']").click
            wait_for_ajaximations

            dt = DiscussionTopic.last
            expect(dt.title).to eq title
            expect(dt.assignment.name).to eq title

            overrides = dt.assignment.assignment_overrides
            expect(overrides.length).to be 3
            override_titles = overrides.map(&:title)
            expect(override_titles).to include @section_1.name
            expect(override_titles).to include @section_2.name
            expect(override_titles).to include @section_3.name
          end

          it "creates a discussion topic with an assignment with group overrides" do
            get "/courses/#{course.id}/discussion_topics/new"

            title = "Graded Discussion Topic with group overrides"
            message = "replying to topic"

            f("input[placeholder='Topic Title']").send_keys title
            type_in_tiny("textarea", message)

            force_click_native('input[type=checkbox][value="graded"]')
            wait_for_ajaximations

            f("input[data-testid='points-possible-input']").send_keys "12"

            force_click_native("input[data-testid='group-discussion-checkbox']")
            group_category_input = f("input[placeholder='Select a group category']")
            group_category_input.click
            group_category_input.send_keys :arrow_down
            group_category_input.send_keys :enter

            assign_to_element = f("input[data-testid='assign-to-select']")
            assign_to_element.click
            assign_to_element.send_keys :backspace
            assign_to_element.send_keys "group 1"
            assign_to_element.send_keys :enter
            assign_to_element.send_keys "group 2"
            assign_to_element.send_keys :enter
            assign_to_element.send_keys "group 3"
            assign_to_element.send_keys :enter

            f("button[data-testid='save-and-publish-button']").click
            wait_for_ajaximations

            f("button[data-testid='continue-button']").click
            wait_for_ajaximations

            dt = Assignment.last.discussion_topic
            expect(dt.title).to eq title
            expect(dt.assignment.name).to eq title

            overrides = dt.assignment.assignment_overrides
            expect(overrides.length).to be 3
            override_titles = overrides.map(&:title)
            expect(override_titles).to include @group_1.name
            expect(override_titles).to include @group_2.name
            expect(override_titles).to include @group_3.name
            overrides.each do |override|
              expect(override.workflow_state).to eq "active"
            end
          end

          it "creates a discussion topic with an assignment with student override" do
            get "/courses/#{course.id}/discussion_topics/new"

            title = "Graded Discussion Topic with student overrides"
            message = "replying to topic"

            f("input[placeholder='Topic Title']").send_keys title
            type_in_tiny("textarea", message)

            force_click_native('input[type=checkbox][value="graded"]')
            wait_for_ajaximations

            f("input[data-testid='points-possible-input']").send_keys "12"

            assign_to_element = f("input[data-testid='assign-to-select']")
            assign_to_element.click
            assign_to_element.send_keys :backspace
            assign_to_element.send_keys "student 1"
            assign_to_element.send_keys :enter
            assign_to_element.send_keys "student 2"
            assign_to_element.send_keys :enter
            assign_to_element.send_keys "student 3"
            assign_to_element.send_keys :enter

            f("button[data-testid='save-and-publish-button']").click
            wait_for_ajaximations

            f("button[data-testid='continue-button']").click
            wait_for_ajaximations

            dt = DiscussionTopic.last
            expect(dt.title).to eq title
            expect(dt.assignment.name).to eq title

            overrides = dt.assignment.assignment_overrides
            expect(overrides.length).to be 1
            expect(overrides[0].title).to eq "3 students"
          end

          it "creates a discussion topic with an assignment with section, group, and student overries as part of one" do
            get "/courses/#{course.id}/discussion_topics/new"

            title = "Graded Discussion Topic with section, group, and student overries as part of one"
            message = "replying to topic"

            f("input[placeholder='Topic Title']").send_keys title
            type_in_tiny("textarea", message)

            force_click_native('input[type=checkbox][value="graded"]')
            wait_for_ajaximations

            force_click_native("input[data-testid='group-discussion-checkbox']")
            group_category_input = f("input[placeholder='Select a group category']")
            group_category_input.click
            group_category_input.send_keys :arrow_down
            group_category_input.send_keys :enter

            f("input[data-testid='points-possible-input']").send_keys "12"

            assign_to_element = f("input[data-testid='assign-to-select']")
            assign_to_element.click
            assign_to_element.send_keys :backspace
            assign_to_element.send_keys "section 1"
            assign_to_element.send_keys :enter
            assign_to_element.send_keys "section 2"
            assign_to_element.send_keys :enter
            assign_to_element.send_keys "section 3"
            assign_to_element.send_keys :enter
            assign_to_element.send_keys "group 1"
            assign_to_element.send_keys :enter
            assign_to_element.send_keys "group 2"
            assign_to_element.send_keys :enter
            assign_to_element.send_keys "group 3"
            assign_to_element.send_keys :enter
            assign_to_element.send_keys "student 1"
            assign_to_element.send_keys :enter
            assign_to_element.send_keys "student 2"
            assign_to_element.send_keys :enter
            assign_to_element.send_keys "student 3"
            assign_to_element.send_keys :enter

            f("button[data-testid='save-and-publish-button']").click
            wait_for_ajaximations

            f("button[data-testid='continue-button']").click
            wait_for_ajaximations

            dt = Assignment.last.discussion_topic
            expect(dt.title).to eq title
            expect(dt.assignment.name).to eq title

            overrides = dt.assignment.assignment_overrides
            override_titles = overrides.map(&:title)
            expect(overrides.length).to be 7
            expect(override_titles).to include "3 students"
            expect(override_titles).to include @section_1.name
            expect(override_titles).to include @section_2.name
            expect(override_titles).to include @section_3.name
            expect(override_titles).to include @group_1.name
            expect(override_titles).to include @group_2.name
            expect(override_titles).to include @group_3.name
          end

          it "creates a discussion topic with an assignment with section, group, and student overries separately" do
            get "/courses/#{course.id}/discussion_topics/new"

            title = "Graded Discussion Topic with section, group, and student overries separately"
            message = "replying to topic"

            f("input[placeholder='Topic Title']").send_keys title
            type_in_tiny("textarea", message)

            force_click_native('input[type=checkbox][value="graded"]')
            wait_for_ajaximations

            force_click_native("input[data-testid='group-discussion-checkbox']")
            group_category_input = f("input[placeholder='Select a group category']")
            group_category_input.click
            group_category_input.send_keys :arrow_down
            group_category_input.send_keys :enter

            f("input[data-testid='points-possible-input']").send_keys "12"

            f("button[data-testid='add-assignment-override-seciont-btn']").click
            f("button[data-testid='add-assignment-override-seciont-btn']").click

            assign_to_elements = ff("input[data-testid='assign-to-select']")
            assign_to_elements[0].click
            assign_to_elements[0].send_keys :backspace
            assign_to_elements[0].send_keys "section 1"
            assign_to_elements[0].send_keys :enter
            assign_to_elements[0].send_keys "section 2"
            assign_to_elements[0].send_keys :enter
            assign_to_elements[0].send_keys "section 3"
            assign_to_elements[0].send_keys :enter

            assign_to_elements[1].click
            assign_to_elements[1].send_keys "group 1"
            assign_to_elements[1].send_keys :enter
            assign_to_elements[1].send_keys "group 2"
            assign_to_elements[1].send_keys :enter
            assign_to_elements[1].send_keys "group 3"
            assign_to_elements[1].send_keys :enter

            assign_to_elements[2].click
            assign_to_elements[2].send_keys "student 1"
            assign_to_elements[2].send_keys :enter
            assign_to_elements[2].send_keys "student 2"
            assign_to_elements[2].send_keys :enter
            assign_to_elements[2].send_keys "student 3"
            assign_to_elements[2].send_keys :enter

            f("button[data-testid='save-and-publish-button']").click
            wait_for_ajaximations

            f("button[data-testid='continue-button']").click
            wait_for_ajaximations

            dt = Assignment.last.discussion_topic
            expect(dt.title).to eq title
            expect(dt.assignment.name).to eq title

            overrides = dt.assignment.assignment_overrides
            override_titles = overrides.map(&:title)
            expect(overrides.length).to be 7
            expect(override_titles).to include "3 students"
            expect(override_titles).to include @section_1.name
            expect(override_titles).to include @section_2.name
            expect(override_titles).to include @section_3.name
            expect(override_titles).to include @group_1.name
            expect(override_titles).to include @group_2.name
            expect(override_titles).to include @group_3.name
          end

          it "creates a published graded group discussion with group overrides with the expected assignment properties" do
            get "/courses/#{course.id}/discussion_topics/new"

            title = "Graded Discussion Topic with section, group, and student overries separately"
            message = "replying to topic"

            f("input[placeholder='Topic Title']").send_keys title
            type_in_tiny("textarea", message)

            force_click_native('input[type=checkbox][value="graded"]')
            wait_for_ajaximations

            force_click_native("input[data-testid='group-discussion-checkbox']")
            group_category_input = f("input[placeholder='Select a group category']")
            group_category_input.click
            group_category_input.send_keys :arrow_down
            group_category_input.send_keys :enter

            f("input[data-testid='points-possible-input']").send_keys "12"

            assign_to_element = f("input[data-testid='assign-to-select']")
            assign_to_element.click
            assign_to_element.send_keys :backspace
            assign_to_element.send_keys "group 1"
            assign_to_element.send_keys :enter
            assign_to_element.send_keys "group 2"
            assign_to_element.send_keys :enter
            assign_to_element.send_keys "group 3"
            assign_to_element.send_keys :enter

            f("button[data-testid='save-and-publish-button']").click
            wait_for_ajaximations

            f("button[data-testid='continue-button']").click
            wait_for_ajaximations

            dt = Assignment.last.discussion_topic
            expect(dt.assignment.workflow_state).to eq "published"
            expect(dt.assignment.group_category_id).to be_nil
            expect(dt.assignment.submission_types).to eq "discussion_topic"
            expect(dt.assignment.only_visible_to_overrides).to be true
            expect(dt.assignment.group_category).to be_nil
            expect(dt.assignment.description).to eq "<p>replying to topic</p>"
          end

          it "creates an unpublished graded group discussion with no overrides with the expected assignment properties" do
            get "/courses/#{course.id}/discussion_topics/new"

            title = "Graded Discussion Topic with section, group, and student overries separately"
            message = "replying to topic"

            f("input[placeholder='Topic Title']").send_keys title
            type_in_tiny("textarea", message)

            force_click_native('input[type=checkbox][value="graded"]')
            wait_for_ajaximations

            force_click_native("input[data-testid='group-discussion-checkbox']")
            group_category_input = f("input[placeholder='Select a group category']")
            group_category_input.click
            group_category_input.send_keys :arrow_down
            group_category_input.send_keys :enter

            f("input[data-testid='points-possible-input']").send_keys "12"

            f("button[data-testid='save-button']").click
            wait_for_ajaximations

            dt = Assignment.last.discussion_topic
            expect(dt.assignment.workflow_state).to eq "unpublished"
            expect(dt.assignment.group_category_id).to be_nil
            expect(dt.assignment.submission_types).to eq "discussion_topic"
            expect(dt.assignment.only_visible_to_overrides).to be false
            expect(dt.assignment.group_category).to be_nil
            expect(dt.assignment.description).to eq "<p>replying to topic</p>"
          end

          it "sets the mark important dates checkbox for discussion create with differentiated modules FF off" do
            feature_setup

            get "/courses/#{course.id}/discussion_topics/new"

            Discussion.update_discussion_topic_title

            force_click_native('input[type=checkbox][value="graded"]')
            wait_for_ajaximations

            assign_to_element = f("input[placeholder='Select Assignment Due Date']")
            formatted_date = format_date_for_view(2.days.from_now(Time.zone.now), "%m/%d/%Y")
            assign_to_element.send_keys formatted_date
            assign_to_element.send_keys :enter

            scroll_to_element(mark_important_dates)
            click_mark_important_dates

            Discussion.save_and_publish_button.click
            wait_for_ajaximations

            assignment = Assignment.last
            expect(assignment.important_dates).to be(true)
          end
        end

        context "with Differentiated Modules FF on" do
          before do
            differentiated_modules_on
          end

          context "set with ItemAssigntoTray" do
            before do
              course.conditional_release = true
              course.save!

              Discussion.start_new_discussion(course.id)
              Discussion.update_discussion_topic_title
              Discussion.update_discussion_message

              force_click_native(Discussion.grade_checkbox_selector)
              wait_for_ajaximations

              Discussion.points_possible_input.send_keys "12"
            end

            it "creates a discussion topic with an assignment set to a student" do
              Discussion.assign_to_button.click
              wait_for_assign_to_tray_spinner

              click_add_assign_to_card
              select_module_item_assignee(1, @student_1.name)
              update_due_date(1, "12/31/2022")
              update_due_time(1, "5:00 PM")
              update_available_date(1, "12/27/2022")
              update_available_time(1, "8:00 AM")
              update_until_date(1, "1/7/2023")
              update_until_time(1, "9:00 PM")

              click_save_button("Apply")

              keep_trying_until { expect(element_exists?(module_item_edit_tray_selector)).to be_falsey }
              expect(AssignmentCreateEditPage.pending_changes_pill_exists?).to be_truthy

              Discussion.save_and_publish_button.click
              wait_for_ajaximations

              assignment = Assignment.last
              expect(assignment.assignment_overrides.active.last.assignment_override_students.count).to eq(1)
              expect(assignment.only_visible_to_overrides).to be false
            end

            it "assigns a section and saves assignment" do
              Discussion.assign_to_button.click
              wait_for_assign_to_tray_spinner

              keep_trying_until { expect(item_tray_exists?).to be_truthy }

              click_add_assign_to_card
              select_module_item_assignee(1, @section_1.name)
              update_due_date(1, "12/31/2022")
              update_due_time(1, "5:00 PM")
              update_available_date(1, "12/27/2022")
              update_available_time(1, "8:00 AM")
              update_until_date(1, "1/7/2023")
              update_until_time(1, "9:00 PM")

              click_save_button("Apply")

              keep_trying_until { expect(element_exists?(module_item_edit_tray_selector)).to be_falsey }
              expect(AssignmentCreateEditPage.pending_changes_pill_exists?).to be_truthy

              Discussion.save_and_publish_button.click
              wait_for_ajaximations
              assignment = Assignment.last

              expect(assignment.assignment_overrides.active.count).to eq(1)
              expect(assignment.assignment_overrides.active.last.set_type).to eq("CourseSection")
              expect(assignment.only_visible_to_overrides).to be false
            end

            it "assigns overrides only correctly" do
              Discussion.assign_to_button.click
              wait_for_assign_to_tray_spinner

              keep_trying_until { expect(item_tray_exists?).to be_truthy }

              click_add_assign_to_card
              select_module_item_assignee(1, @section_1.name)
              select_module_item_assignee(1, @section_2.name)
              select_module_item_assignee(1, @section_3.name)
              select_module_item_assignee(1, @student_1.name)
              select_module_item_assignee(1, @student_2.name)
              select_module_item_assignee(1, @student_3.name)
              select_module_item_assignee(1, "Mastery Paths")

              # Set dates for these overrides
              update_due_date(1, "12/31/2022")
              update_due_time(1, "5:00 PM")
              update_available_date(1, "12/27/2022")
              update_available_time(1, "8:00 AM")
              update_until_date(1, "1/7/2023")
              update_until_time(1, "9:00 PM")

              # Remove the Everyone Else option
              click_delete_assign_to_card(0)

              click_save_button("Apply")
              keep_trying_until { expect(element_exists?(module_item_edit_tray_selector)).to be_falsey }

              expect(AssignmentCreateEditPage.pending_changes_pill_exists?).to be_truthy

              # Since not all sections were selected, a warning is displayed
              Discussion.save_and_publish_button.click
              Discussion.section_warning_continue_button.click
              wait_for_ajaximations

              assignment = Assignment.last

              expect(assignment.assignment_overrides.active.count).to eq(5)
              expected_overrides = [
                { set_type: "CourseSection", title: "section 1" },
                { set_type: "CourseSection", title: "section 2" },
                { set_type: "CourseSection", title: "section 3" },
                { set_type: "ADHOC", title: "3 students" },
                { set_type: "Noop", title: "Mastery Paths" }
              ]

              expected_overrides.each_with_index do |expected_override, index|
                actual_override = assignment.assignment_overrides[index]

                expect(actual_override.set_type).to eq(expected_override[:set_type])
                expect(actual_override.title).to eq(expected_override[:title])
              end

              expect(assignment.only_visible_to_overrides).to be true
            end
          end

          it "sets the mark important dates checkbox for discussion create" do
            feature_setup

            get "/courses/#{course.id}/discussion_topics/new"

            Discussion.update_discussion_topic_title

            force_click_native(Discussion.grade_checkbox_selector)
            wait_for_ajaximations

            Discussion.assign_to_button.click
            wait_for_assign_to_tray_spinner

            keep_trying_until { expect(item_tray_exists?).to be_truthy }

            formatted_date = format_date_for_view(2.days.from_now(Time.zone.now), "%m/%d/%Y")
            update_due_date(0, formatted_date)
            update_due_time(0, "5:00 PM")

            click_save_button("Apply")
            keep_trying_until { expect(element_exists?(module_item_edit_tray_selector)).to be_falsey }

            expect(mark_important_dates).to be_displayed
            scroll_to_element(mark_important_dates)
            click_mark_important_dates

            Discussion.save_and_publish_button.click
            wait_for_ajaximations

            assignment = Assignment.last

            expect(assignment.important_dates).to be(true)
          end

          context "post to sis" do
            before do
              course.account.set_feature_flag! "post_grades", "on"
              course.account.set_feature_flag! :new_sis_integrations, "on"
              course.account.settings[:sis_syncing] = { value: true, locked: false }
              course.account.settings[:sis_require_assignment_due_date] = { value: true }
              course.account.save!
            end

            it "default value is false" do
              get "/courses/#{course.id}/discussion_topics/new"
              Discussion.click_graded_checkbox
              expect(is_checked(Discussion.sync_to_sis_checkbox_selector)).to be_falsey
            end

            it "blocks when enabled", :ignore_js_errors do
              get "/courses/#{course.id}/discussion_topics/new"

              Discussion.update_discussion_topic_title
              Discussion.click_graded_checkbox
              Discussion.click_sync_to_sis_checkbox
              Discussion.save_button.click
              wait_for_ajaximations

              expect(driver.current_url).to include("new")
              expect_instui_flash_message("Please set a due date or change your selection for the “Sync to SIS” option.")

              Discussion.click_assign_to_button

              wait_for_assign_to_tray_spinner
              keep_trying_until { expect(item_tray_exists?).to be_truthy }

              expect(assign_to_date_and_time[0].text).to include("Please add a due date")

              update_due_date(0, format_date_for_view(Time.zone.now, "%-m/%-d/%Y"))
              update_due_time(0, "11:59 PM")
              click_save_button("Apply")
              keep_trying_until { expect(element_exists?(module_item_edit_tray_selector)).to be_falsey }

              expect_new_page_load { Discussion.save_button.click }
              expect(driver.current_url).not_to include("new")
              expect(DiscussionTopic.last.assignment.post_to_sis).to be_truthy
            end

            it "does not block when disabled" do
              get "/courses/#{course.id}/discussion_topics/new"

              Discussion.update_discussion_topic_title
              Discussion.click_graded_checkbox
              expect_new_page_load { Discussion.save_button.click }
              expect(driver.current_url).not_to include("new")
              expect(DiscussionTopic.last.assignment.post_to_sis).to be_falsey
            end

            it "validates due date when user checks/unchecks the box", :ignore_js_errors do
              get "/courses/#{course.id}/discussion_topics/new"
              Discussion.update_discussion_topic_title
              Discussion.click_graded_checkbox
              Discussion.click_sync_to_sis_checkbox
              Discussion.click_assign_to_button
              wait_for_assign_to_tray_spinner
              keep_trying_until { expect(item_tray_exists?).to be_truthy }

              expect(assign_to_date_and_time[0].text).to include("Please add a due date")

              click_cancel_button
              keep_trying_until { expect(element_exists?(module_item_edit_tray_selector)).to be_falsey }

              Discussion.click_sync_to_sis_checkbox
              Discussion.click_assign_to_button
              wait_for_assign_to_tray_spinner
              keep_trying_until { expect(item_tray_exists?).to be_truthy }

              expect(assign_to_date_and_time[0].text).not_to include("Please add a due date")

              click_cancel_button
              keep_trying_until { expect(element_exists?(module_item_edit_tray_selector)).to be_falsey }

              expect_new_page_load { Discussion.save_button.click }
              expect(driver.current_url).not_to include("new")
              expect(DiscussionTopic.last.assignment.post_to_sis).to be_falsey
            end
          end
        end

        context "checkpoints" do
          before do
            course.root_account.enable_feature!(:discussion_checkpoints)
          end

          it "successfully creates a discussion topic with checkpoints" do
            get "/courses/#{course.id}/discussion_topics/new"

            title = "Graded Discussion Topic with checkpoints"

            f("input[placeholder='Topic Title']").send_keys title

            force_click_native('input[type=checkbox][value="graded"]')
            wait_for_ajaximations

            force_click_native('input[type=checkbox][value="checkpoints"]')

            f("input[data-testid='points-possible-input-reply-to-topic']").send_keys "5"
            f("input[data-testid='reply-to-entry-required-count']").send_keys :backspace
            f("input[data-testid='reply-to-entry-required-count']").send_keys 3
            f("input[data-testid='points-possible-input-reply-to-entry']").send_keys "7"

            f("button[data-testid='save-and-publish-button']").click
            wait_for_ajaximations

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
          end
        end
      end
    end

    context "with selective_release_backend and selective_release_ui_api enabled" do
      before do
        Account.site_admin.enable_feature!(:selective_release_backend)
        Account.site_admin.enable_feature!(:selective_release_ui_api)
        user_session(teacher)
      end

      it "does not display 'Post To' section and Available From/Until inputs" do
        get "/courses/#{course.id}/discussion_topics/new"
        expect(Discussion.select_date_input_exists?).to be_falsey
        expect(Discussion.section_selection_input_exists?).to be_falsey
      end

      it "creates overrides using 'Assign To' tray", :ignore_js_errors do
        student1 = @course.enroll_student(User.create!, enrollment_state: "active").user
        title = "My Test Topic"
        available_from = 5.days.ago
        available_until = 5.days.from_now

        get "/courses/#{course.id}/discussion_topics/new"

        Discussion.update_discussion_topic_title(title)

        Discussion.click_assign_to_button
        wait_for_assign_to_tray_spinner
        keep_trying_until { expect(item_tray_exists?).to be_truthy }

        click_add_assign_to_card
        expect(element_exists?(due_date_input_selector)).to be_falsey
        select_module_item_assignee(1, student1.name)
        update_available_date(1, format_date_for_view(available_from, "%-m/%-d/%Y"), true)
        update_available_time(1, "8:00 AM", true)
        update_until_date(1, format_date_for_view(available_until, "%-m/%-d/%Y"), true)
        update_until_time(1, "9:00 PM", true)

        click_save_button("Apply")
        keep_trying_until { expect(element_exists?(module_item_edit_tray_selector)).to be_falsey }

        Discussion.save_button.click
        wait_for_ajaximations

        course.reload
        discussion_topic = DiscussionTopic.last
        new_override = discussion_topic.active_assignment_overrides.last
        expect(new_override.set_type).to eq("ADHOC")
        expect(new_override.set_id).to be_nil
        expect(new_override.set.map(&:id)).to match_array([student1.id])
      end
    end
  end
end
