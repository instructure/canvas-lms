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
require_relative "../conditional_release/page_objects/conditional_release_objects"

describe "discussions" do
  include_context "in-process server selenium tests"
  include DiscussionsCommon
  include ItemsAssignToTray
  include ContextModulesCommon
  include K5DashboardCommonPageObject
  include K5Common
  include K5ImportantDatesSectionPageObject

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

      it "adds an attachment to a new topic", :ignore_js_errors, priority: "1" do
        skip_if_firefox("known issue with firefox https://bugzilla.mozilla.org/show_bug.cgi?id=1335085")
        topic_title = "new topic with file"
        get url
        wait_for_tiny(f("textarea[name=message]"))
        replace_content(f("input[name=title]"), topic_title)
        add_attachment_and_validate
        expect(DiscussionTopic.where(title: topic_title).first.attachment_id).to be_present
      end

      it "creates a podcast enabled topic", :ignore_js_errors, priority: "1" do
        get url
        wait_for_tiny(f("textarea[name=message]"))
        replace_content(f("input[name=title]"), "This is my test title")
        type_in_tiny("textarea[name=message]", "This is the discussion description.")

        f("label[for='checkbox_podcast_enabled']").click
        expect_new_page_load { submit_form(".form-actions") }
        # get "/courses/#{course.id}/discussion_topics"
        # TODO: talk to UI, figure out what to display here
        # f('.discussion-topic .icon-rss').should be_displayed
        expect(DiscussionTopic.last.podcast_enabled).to be_truthy
      end

      it "does not display the section specific announcer if the FF is disabled", :ignore_js_errors do
        get url
        wait_for_ajaximations
        f("label[for='use_for_grading']").click
        expect(f("body")).not_to contain_css('input[id^="Autocomplete"]')
      end

      context "graded" do
        it "validates that a group category is selected", :ignore_js_errors, priority: "1" do
          assignment_group
          get url
          wait_for_ajaximations
          f("label[for='use_for_grading']").click
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

          it "shows archived grading scheme if it is the course default twice, once to follow course default scheme and once to choose that scheme to use", :ignore_js_errors do
            @course.update!(grading_standard_id: @archived_grading_standard.id)
            @course.reload
            get "/courses/#{@course.id}/discussion_topics/new"
            wait_for_ajaximations
            f("label[for='use_for_grading']").click
            wait_for_ajaximations
            f("#assignment_grading_type").click
            ffj("option:contains('Letter Grade')").last.click
            wait_for_ajaximations
            expect(f("[data-testid='grading-schemes-selector-dropdown']").attribute("title")).to eq(@archived_grading_standard.title + " (course default)")
            f("[data-testid='grading-schemes-selector-dropdown']").click
            expect(f("[data-testid='grading-schemes-selector-option-#{@course.grading_standard.id}']")).to include_text(@course.grading_standard.title)
          end

          it "removes grading schemes from dropdown after archiving them but still shows them upon reopening the modal", :ignore_js_errors do
            get "/courses/#{@course.id}/discussion_topics/new"
            wait_for_ajaximations
            f("label[for='use_for_grading']").click
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

          it "shows all archived schemes in the manage grading schemes modal", :ignore_js_errors do
            archived_gs1 = @course.grading_standards.create!(title: "Archived Grading Scheme 1", data: { "A" => 0.9, "F" => 0 }, scaling_factor: 1.0, points_based: false, workflow_state: "archived")
            archived_gs2 = @course.grading_standards.create!(title: "Archived Grading Scheme 2", data: { "A" => 0.9, "F" => 0 }, scaling_factor: 1.0, points_based: false, workflow_state: "archived")
            archived_gs3 = @course.grading_standards.create!(title: "Archived Grading Scheme 3", data: { "A" => 0.9, "F" => 0 }, scaling_factor: 1.0, points_based: false, workflow_state: "archived")
            get "/courses/#{@course.id}/discussion_topics/new"
            wait_for_ajaximations
            f("label[for='use_for_grading']").click
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

          it "creates a discussion topic with selected grading scheme/standard", :ignore_js_errors do
            grading_standard = course.grading_standards.create!(title: "Win/Lose", data: [["Winner", 0.94], ["Loser", 0]])

            get "/courses/#{@course.id}/discussion_topics/new"

            title = "Graded Discussion Topic with letter grade type"
            message = "replying to topic"

            wait_for_ajaximations

            f("input[placeholder='Topic Title']").send_keys title
            type_in_tiny("textarea", message)

            f("label[for='use_for_grading']").click
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

        it "defaults to post grades if account setting is enabled", :ignore_js_errors do
          @account.settings[:sis_default_grade_export] = { locked: false, value: true }
          @account.save!

          get url
          wait_for_ajaximations
          f("label[for='use_for_grading']").click
          expect(is_checked("#assignment_post_to_sis")).to be_truthy
        end

        it "does not default to post grades if account setting is not enabled", :ignore_js_errors do
          get url
          wait_for_ajaximations
          f("label[for='use_for_grading']").click

          expect(is_checked("#assignment_post_to_sis")).to be_falsey
        end
      end

      context "when react_discussions_post feature_flag is on", :ignore_js_errors do
        before do
          course.enable_feature! :react_discussions_post
        end

        it "allows creating anonymous discussions", :ignore_js_errors do
          get url
          wait_for_ajaximations
          replace_content(f("input[name=title]"), "my anonymous title")
          f("label[for='anonymous-selector-full-anonymity']").click

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
          wait_for_ajaximations
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
          skip "Will be fixed in VICE-5209"
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

        it "lets students create anonymous discussions when allowed", :ignore_js_errors do
          course.allow_student_anonymous_discussion_topics = true
          course.save!
          get url
          wait_for_ajaximations
          replace_content(f("input[name=title]"), "my anonymous title")
          f("label[for='anonymous-selector-full-anonymity']").click
          expect_new_page_load { submit_form(".form-actions") }
          expect(DiscussionTopic.last.anonymous_state).to eq "full_anonymity"
          expect(f("span[data-testid='anon-conversation']").text).to(
            eq("This is an anonymous Discussion. Your name and profile picture will be hidden from other course members. Mentions have also been disabled.")
          )
        end

        it "does not allow creation of anonymous group discussions", :ignore_js_errors do
          course.allow_student_anonymous_discussion_topics = true
          course.save!
          get url
          wait_for_ajaximations
          expect(f("span[data-testid=groups_grading_not_allowed]")).to_not be_displayed
          f("label[for='anonymous-selector-full-anonymity']").click
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
          wait_for_ajaximations
          replace_content(f("input[name=title]"), "Student Partial Discussion")
          f("label[for='anonymous-selector-partial-anonymity']").click

          # verify default anonymous post selector
          expect(f("span[data-testid='current_user_avatar']")).to be_present
          expect(fj("span#sections_anonymous_post_selector span:contains('#{@student.name}')")).to be_truthy
          expect(f("input[data-component='anonymous_post_selector']").attribute("value")).to eq "Show to everyone"

          expect_new_page_load { submit_form(".form-actions") }
          expect(f("span[data-testid='non-graded-discussion-info']")).to include_text "Partially Anonymous Discussion"
          expect(f("span[data-testid='author_name']")).to include_text @student.name
        end

        it "lets students choose to make topics anonymously" do
          course.allow_student_anonymous_discussion_topics = true
          course.save!
          get url
          wait_for_ajaximations
          replace_content(f("input[name=title]"), "Student Partial Discussion (student anonymous)")
          f("label[for='anonymous-selector-partial-anonymity']").click
          f("input[data-component='anonymous_post_selector']").click
          fj("li:contains('Hide from everyone')").click
          expect(f("span[data-testid='anonymous_avatar']")).to be_present
          expect(fj("span#sections_anonymous_post_selector span:contains('Anonymous')")).to be_truthy
          expect(f("input[data-component='anonymous_post_selector']").attribute("value")).to eq "Hide from everyone"

          expect_new_page_load { submit_form(".form-actions") }
          expect(f("span[data-testid='non-graded-discussion-info']")).to include_text "Partially Anonymous Discussion"
          expect(f("span[data-testid='author_name']")).to include_text "Anonymous"
        end
      end

      it "creates a delayed discussion", priority: "1" do
        skip "Will be fixed in VICE-5209"
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

      it "gives error if Until date isn't after Available From date", :ignore_js_errors, priority: "1" do
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
        skip "Will be fixed in VICE-5209"
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

      it "does not show file attachment if allow_student_forum_attachments is not true", :ignore_js_errors, priority: "2" do
        skip_if_safari(:alert)
        # given
        course.allow_student_forum_attachments = false
        course.save!
        # expect
        get url
        expect(f("#content")).not_to contain_css("#disussion_attachment_uploaded_data")
      end

      it "shows file attachment if allow_student_forum_attachments is true", :ignore_js_errors, priority: "2" do
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

        it "does not show file attachment if allow_student_forum_attachments is not true", :ignore_js_errors, priority: "2" do
          skip_if_safari(:alert)
          # given
          course.allow_student_forum_attachments = false
          course.save!
          # expect
          get url
          expect(f("#content")).not_to contain_css("label[for=discussion_attachment_uploaded_data]")
        end

        it "shows file attachment if allow_student_forum_attachments is true", :ignore_js_errors, priority: "2" do
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

            it "loads page without usage rights", :ignore_js_errors do
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
            account.settings = { "usage_rights_required" => {
              "value" => true
            } }
            account.save!
          end

          it "loads page", :ignore_js_errors do
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

      it "shows limited assign to UI when selective_release is enabled if the student has an unrestricted enrollment" do
        get "/courses/#{course.id}/discussion_topics/new"
        wait_for_ajaximations

        expect(element_exists?(Discussion.assign_to_card_selector)).to be_truthy
        expect(Discussion.assignee_selector[0]).to be_disabled

        title = "My Test Topic"
        message = "replying to topic"
        available_date = "12/27/2028"

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

        expect(dt.title).to eq title
        expect(dt.message).to include message
        expect(format_date_for_view(dt.unlock_at, "%m/%d/%Y")).to eq(available_date)
      end

      it "shows limited assign to UI when selective_release is enabled if the student has restricted enrollment" do
        enrollment = course.enrollments.find_by(user: student)
        enrollment.update!(limit_privileges_to_course_section: true)

        get "/courses/#{course.id}/discussion_topics/new"

        expect(element_exists?(Discussion.assign_to_card_selector)).to be_truthy
        expect(Discussion.assignee_selector[0]).to be_disabled

        title = "My Test Topic"
        message = "replying to topic"
        available_date = "12/27/2028"

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

        expect(dt.title).to eq title
        expect(dt.message).to include message
        expect(format_date_for_view(dt.unlock_at, "%m/%d/%Y")).to eq(available_date)
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
        expect(f("body")).to contain_jqcss("[data-testid=groups_grading_not_allowed]")
        force_click_native("input[value='full_anonymity']")
        expect(f("body")).to contain_jqcss("[data-testid=groups_grading_not_allowed]")
        force_click_native("input[value='partial_anonymity']")
        expect(f("body")).to contain_jqcss("[data-testid=groups_grading_not_allowed]")
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

      it "creates two different discussions with attachments not overwriting each other" do
        title = "new topic with file"
        title2 = "another topic with file"
        graded_png = File.expand_path(File.dirname(__FILE__) + "/../../../public/images/graded.png")

        get "/courses/#{course.id}/discussion_topics/new"
        wait_for_ajaximations

        set_react_topic_title_and_message(title, "replying to topic")
        _filename, fullpath, file = get_permanent_file(graded_png)
        f("[data-testid='attachment-input']").send_keys(fullpath)

        Discussion.save_button.click
        wait_for_ajaximations

        attachment_id = DiscussionTopic.where(title:).first.attachment_id
        attachment_name = Attachment.find(attachment_id).display_name
        expect(attachment_id).to be_present

        # create the second discussion with the same attachment
        get "/courses/#{course.id}/discussion_topics/new"
        wait_for_ajaximations

        set_react_topic_title_and_message(title2, "replying to topic")
        _filename2, fullpath2, file2 = get_permanent_file(graded_png)
        f("[data-testid='attachment-input']").send_keys(fullpath2)

        Discussion.save_button.click
        wait_for_ajaximations

        attachment_id2 = DiscussionTopic.where(title: title2).first.attachment_id
        attachment_name2 = Attachment.find(attachment_id2).display_name
        expect(attachment_id2).to be_present

        expect(attachment_name).to eq("graded.png")
        expect(attachment_name2).to eq("graded-1.png")
      ensure
        file.close
        file2.close
      end

      context "Horizon course" do
        before do
          @course.account.enable_feature!(:horizon_course_setting)
          @course.horizon_course = true
          @course.save!
        end

        it "does not navigate to discussions create page" do
          Discussion.start_new_discussion @course.id
          expect(element_exists?(Discussion.save_selector)).to be_falsey
        end
      end

      context "usage rights" do
        before do
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

        it "Use tab style filter element in normal view and dropdown in mobile view" do
          get "/courses/#{course.id}/discussion_topics/new"
          expect(f("div[role='tab']").text).to eq "Details"
          resize_screen_to_mobile_width
          expect(f("input[data-testid='view-select']").attribute("title")).to eq "Details"
        end
      end

      context "when instui_nav feature flag on" do
        page_header_title_discussion = "Create Discussion"
        page_header_title_announcement = "Create Announcement"

        before do
          course.root_account.enable_feature!(:instui_nav)
        end

        it "create discussion header title rendered correctly" do
          get "/courses/#{course.id}/discussion_topics/new"
          expect(fj("h1:contains('#{page_header_title_discussion}')").text).to eq page_header_title_discussion
        end

        it "After Save and publish need to see a publish pill in edit page" do
          get "/courses/#{course.id}/discussion_topics/new"

          title = "My Test Topic"

          expect(fj("span[data-testid='publish-status-pill']:contains('Unpublished')").text).to eq "Unpublished"
          f("input[placeholder='Topic Title']").send_keys title
          f("button[data-testid='save-and-publish-button']").click
          wait_for_ajaximations

          dt = DiscussionTopic.last

          expect(dt).to be_published
          expect(driver.current_url).to end_with("/courses/#{course.id}/discussion_topics/#{dt.id}")

          get "/courses/#{course.id}/discussion_topics/#{dt.id}/edit"

          expect(fj("span[data-testid='publish-status-pill']:contains('Published')").text).to eq "Published"
        end

        it "create announcement header title rendered correctly" do
          get "/courses/#{course.id}/discussion_topics/new?is_announcement=true"
          expect(fj("h1:contains('#{page_header_title_announcement}')").text).to eq page_header_title_announcement
        end
      end
    end

    context "announcements" do
      it "displays correct fields for a new announcement" do
        user_session(teacher)
        get "/courses/#{course.id}/discussion_topics/new?is_announcement=true"
        # Expect certain field to be present
        expect(f("body")).to contain_jqcss "input[value='enable-participants-commenting']"
        expect(f("body")).to contain_jqcss "input[value='enable-podcast-feed']"
        expect(f("body")).to contain_jqcss "input[value='allow-liking']"
        expect(f("body")).to contain_jqcss "div[data-testid='non-graded-date-options']"

        # Expect certain field to not be present
        expect(f("body")).not_to contain_jqcss "input[value='full_anonymity']"
        expect(f("body")).not_to contain_jqcss "input[value='graded']"
        expect(f("body")).not_to contain_jqcss "input[value='group-discussion']"
        expect(f("body")).not_to contain_jqcss "input[value='add-to-student-to-do']"
      end

      it "displays comment related fields when participants commenting is enabled" do
        user_session(teacher)
        get "/courses/#{course.id}/discussion_topics/new?is_announcement=true"

        force_click_native("input[value='enable-participants-commenting']")
        expect(f("body")).to contain_jqcss "input[value='must-respond-before-viewing-replies']"
        expect(f("body")).to contain_jqcss "input[value='disallow-threaded-replies']"
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

        context "with assign to embedded in page" do
          it "allows create with group category", :ignore_js_errors do
            group_cat = course.group_categories.create!(name: "Groupies")
            get "/courses/#{course.id}/discussion_topics/new"

            Discussion.update_discussion_topic_title
            Discussion.click_group_discussion_checkbox
            Discussion.click_group_category_select
            Discussion.click_group_category_option(group_cat.name)
            Discussion.save_button.click
            wait_for_ajaximations

            expect(driver.current_url).not_to end_with("/courses/#{course.id}/discussion_topics/new")
          end

          it "allows create with group context", :ignore_js_errors do
            get "/groups/#{group.id}/discussion_topics/new"

            title = "Group Context Discussion"
            message = "this is a group context discussion"

            f("input[placeholder='Topic Title']").send_keys title
            type_in_tiny("textarea#discussion-topic-message-body", message)
            f("button[data-testid='save-and-publish-button']").click
            wait_for_ajaximations

            expect(driver.current_url).not_to end_with("/groups/#{group.id}/discussion_topics/new")
          end

          it "allows create with group category and graded", :ignore_js_errors do
            group_cat = course.group_categories.create!(name: "Groupies")
            get "/courses/#{course.id}/discussion_topics/new"

            Discussion.update_discussion_topic_title
            Discussion.click_graded_checkbox
            Discussion.click_group_discussion_checkbox
            Discussion.click_group_category_select
            Discussion.click_group_category_option(group_cat.name)
            Discussion.save_button.click
            wait_for_ajaximations

            expect(driver.current_url).not_to end_with("/courses/#{course.id}/discussion_topics/new")
          end

          context "set with Assign to Cards" do
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
              click_add_assign_to_card
              select_module_item_assignee(1, @student_1.name)
              update_due_date(1, "12/31/2022")
              update_due_time(1, "5:00 PM")
              update_available_date(1, "12/27/2022")
              update_available_time(1, "8:00 AM")
              update_until_date(1, "1/7/2023")
              update_until_time(1, "9:00 PM")

              Discussion.save_and_publish_button.click
              wait_for_ajaximations

              assignment = Assignment.last
              expect(assignment.assignment_overrides.active.last.assignment_override_students.count).to eq(1)
              expect(assignment.only_visible_to_overrides).to be false
            end

            it "assigns a section and saves assignment" do
              click_add_assign_to_card
              select_module_item_assignee(1, @section_1.name)
              update_due_date(1, "12/31/2022")
              update_due_time(1, "5:00 PM")
              update_available_date(1, "12/27/2022")
              update_available_time(1, "8:00 AM")
              update_until_date(1, "1/7/2023")
              update_until_time(1, "9:00 PM")

              Discussion.save_and_publish_button.click
              wait_for_ajaximations
              assignment = Assignment.last

              expect(assignment.assignment_overrides.active.count).to eq(1)
              expect(assignment.assignment_overrides.active.last.set_type).to eq("CourseSection")
              expect(assignment.only_visible_to_overrides).to be false
            end

            it "assigns overrides only correctly" do
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

              # Since not all sections were selected, a warning is displayed
              Discussion.save_and_publish_button.click
              Discussion.section_warning_continue_button.click
              wait_for_ajaximations

              assignment = Assignment.last

              expect(assignment.assignment_overrides.active.count).to eq(5)
              expected_overrides = [
                ["CourseSection", "section 1"],
                ["CourseSection", "section 2"],
                ["CourseSection", "section 3"],
                ["ADHOC", "3 students"],
                ["Noop", "Mastery Paths"]
              ]
              assignment_overrides = assignment.assignment_overrides.pluck(:set_type, :title)

              expect(expected_overrides.sort == assignment_overrides.sort).to be_truthy
            end
          end

          it "sets the mark important dates checkbox for discussion create" do
            feature_setup

            get "/courses/#{course.id}/discussion_topics/new"

            Discussion.update_discussion_topic_title

            force_click_native(Discussion.grade_checkbox_selector)
            wait_for_ajaximations

            formatted_date = format_date_for_view(2.days.from_now(Time.zone.now), "%m/%d/%Y")
            update_due_date(0, formatted_date)
            update_due_time(0, "5:00 PM")

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

              expect(assign_to_date_and_time[0].text).to include("Please add a due date")

              update_due_date(0, format_date_for_view(Time.zone.now, "%-m/%-d/%Y"))
              update_due_time(0, "11:59 PM")

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

              expect(assign_to_date_and_time[0].text).not_to include("Please add a due date")

              Discussion.save_button.click
              expect(assign_to_date_and_time[0].text).to include("Please add a due date")

              Discussion.click_sync_to_sis_checkbox
              expect_new_page_load { Discussion.save_button.click }

              expect(driver.current_url).not_to include("new")
              expect(DiscussionTopic.last.assignment.post_to_sis).to be_falsey
            end
          end
        end

        context "checkpoints" do
          before do
            course.account.enable_feature!(:discussion_checkpoints)
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

          it "disallows setting the group discussion checkbox when checkpoints_group_discussions ff is disabled" do
            course.account.disable_feature!(:checkpoints_group_discussions)
            get "/courses/#{course.id}/discussion_topics/new"

            expect(element_exists?("input[data-testid='group-discussion-checkbox']")).to be_truthy

            force_click_native('input[type=checkbox][value="graded"]')
            wait_for_ajaximations

            force_click_native('input[type=checkbox][value="checkpoints"]')

            expect(element_exists?("input[data-testid='group-discussion-checkbox']")).to be_falsey
          end

          it "successfully creates a checkpointed graded group discussion" do
            group_category
            group

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
            force_click_native("input[data-testid='group-discussion-checkbox']")
            f("input[placeholder='Select a group category']").click
            force_click_native("[data-testid='group-category-opt-#{group_category.id}']")

            f("button[data-testid='save-and-publish-button']").click
            wait_for_ajaximations

            dt = DiscussionTopic.joins(:child_topics).group("discussion_topics.id").order("discussion_topics.id DESC").first
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

          it "successfully creates ADHOC overrides if a student is enrolled in multiple sections" do
            course.enroll_student(@student_1, enrollment_state: "active", section: @section_2)
            course.enroll_student(@student_1, enrollment_state: "active", section: @section_3)

            get "/courses/#{course.id}/discussion_topics/new"

            title = "Graded Discussion Topic with checkpoints and Student enrolled in multiple sections"
            f("input[placeholder='Topic Title']").send_keys title
            force_click_native('input[type=checkbox][value="graded"]')
            wait_for_ajaximations
            force_click_native('input[type=checkbox][value="checkpoints"]')

            f("input[data-testid='points-possible-input-reply-to-topic']").send_keys 5
            f("input[data-testid='reply-to-entry-required-count']").send_keys :backspace
            f("input[data-testid='reply-to-entry-required-count']").send_keys 3
            f("input[data-testid='points-possible-input-reply-to-entry']").send_keys 7

            assign_to_element = Discussion.assignee_selector.first
            assign_to_element.click
            assign_to_element.send_keys :backspace
            assign_to_element.send_keys "student 1"

            f("button[data-testid='save-and-publish-button']").click
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

            expect(student_ids).to match_array [@student_1.global_id]

            # Verify that the discussion topic redirected the page to the new discussion topic
            expect(driver.current_url).to end_with("/courses/#{course.id}/discussion_topics/#{dt.id}")
          end
        end
      end
    end

    context "with SR on and assign to cards embedded in page" do
      before do
        user_session(teacher)
      end

      it "does not display 'Post To' section and Available From/Until inputs" do
        get "/courses/#{course.id}/discussion_topics/new"
        expect(Discussion.select_date_input_exists?).to be_falsey
        expect(Discussion.section_selection_input_exists?).to be_falsey
      end

      it "creates overrides using 'Assign To' cards embedded in the new page", :ignore_js_errors do
        student1 = @course.enroll_student(User.create!, enrollment_state: "active").user
        title = "My Test Topic"
        available_from = 5.days.ago
        available_until = 5.days.from_now

        get "/courses/#{course.id}/discussion_topics/new"

        Discussion.update_discussion_topic_title(title)

        click_add_assign_to_card
        expect(element_exists?(due_date_input_selector)).to be_falsey
        select_module_item_assignee(1, student1.name)
        update_available_date(1, format_date_for_view(available_from, "%-m/%-d/%Y"), true)
        update_available_time(1, "8:00 AM", true)
        update_until_date(1, format_date_for_view(available_until, "%-m/%-d/%Y"), true)
        update_until_time(1, "9:00 PM", true)

        Discussion.save_button.click
        wait_for_ajaximations

        course.reload
        discussion_topic = DiscussionTopic.last
        new_override = discussion_topic.active_assignment_overrides.last
        expect(new_override.set_type).to eq("ADHOC")
        expect(new_override.set_id).to be_nil
        expect(new_override.set.map(&:id)).to match_array([student1.id])
      end

      context "user has both student and teacher roles in different courses" do
        it "create discussion topic successfully" do
          student_enrollment_course = Course.create!(name: "Student Course", root_account: Account.default)
          teacher_enrollment_course = Course.create!(name: "Teacher Course", root_account: Account.default)
          [student_enrollment_course, teacher_enrollment_course].each do |course|
            course.update!(workflow_state: "available")
          end

          student1 = teacher_enrollment_course.enroll_student(User.create!, enrollment_state: "active").user
          user = User.create!(name: "Multiple Role User")

          student_enrollment_course.enroll_student(user).accept!
          teacher_enrollment_course.enroll_teacher(user).accept!

          user_session(user)
          Discussion.start_new_discussion(teacher_enrollment_course.id)
          Discussion.update_discussion_topic_title
          Discussion.update_discussion_message

          available_from = 5.days.ago
          available_until = 5.days.from_now

          click_add_assign_to_card
          expect(element_exists?(due_date_input_selector)).to be_falsey
          select_module_item_assignee(1, student1.name)
          update_available_date(1, format_date_for_view(available_from, "%-m/%-d/%Y"), true)
          update_available_time(1, "8:00 AM", true)
          update_until_date(1, format_date_for_view(available_until, "%-m/%-d/%Y"), true)
          update_until_time(1, "9:00 PM", true)

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
end
