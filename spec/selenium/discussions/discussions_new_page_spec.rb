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

describe "discussions" do
  include_context "in-process server selenium tests"
  include DiscussionsCommon

  let(:course) { course_model.tap(&:offer!) }
  let(:default_section) { course.default_section }
  let(:new_section) { course.course_sections.create!(name: "section 2") }
  let(:group) do
    course.groups.create!(name: "group",
                          group_category:).tap do |g|
      g.add_user(student, "accepted", nil)
    end
  end
  let(:student) { student_in_course(course:, name: "student", active_all: true).user }
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
          f("#edit_discussion_form_buttons .btn-primary[type=submit]").click
          wait_for_ajaximations
          error_box = f("div[role='alert'] .error_text")
          expect(error_box.text).to eq "Please create a group set"
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

      context "when react_discussions_post feature_flag is on" do
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
            eq("This is an anonymous Discussion. Though student names and profile pictures will be hidden, your name and profile picture will be visible to all course members.")
          )
          expect(f("span[data-testid='author_name']").text).to eq teacher.short_name
        end

        it "disallows full_anonymity along with graded" do
          get url
          replace_content(f("input[name=title]"), "my anonymous title")
          f("input[value='full_anonymity']").click
          f("input[id='use_for_grading']").click
          submit_form(".form-actions")
          expect(
            fj("div.error_text:contains('You are not allowed to create an anonymous graded discussion')")
          ).to be_present
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

      context "when all discussion anonymity feature flags are ON" do
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
            eq("This is an anonymous Discussion, Your name and profile picture will be hidden from other course members.")
          )
        end

        it "does not allow creation of anonymous group discussions" do
          course.allow_student_anonymous_discussion_topics = true
          course.save!
          get url
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
    before do
      Account.site_admin.enable_feature! :discussion_create
      # we will turn react_discussions_post on here as well (altough it is not required)
      Account.site_admin.enable_feature! :react_discussions_post
    end

    context "as a teacher" do
      before do
        user_session(teacher)
      end

      it "creates a new discussion topic successfully" do
        title = "My Test Topic"
        message = "replying to topic"
        get "/courses/#{course.id}/discussion_topics/new"
        f("input[placeholder='Topic Title']").send_keys title
        type_in_tiny("textarea", message)
        f("button[data-testid='save-and-publish-button']").click
        wait_for_ajaximations
        dt = DiscussionTopic.last
        expect(dt.title).to eq title
        expect(dt.message).to include message
        expect(dt).to be_published
        expect(fj("div[data-testid='discussion-topic-container'] span:contains('#{title}')")).to be_present
      end

      it "shows course sections or course group categories" do
        new_section
        group_category
        group
        get "/courses/#{course.id}/discussion_topics/new"
        f("[data-testid='section-select']").click
        # verify all sections exist in the dropdown
        expect(f("[data-testid='section-opt-#{default_section.id}']")).to be_present
        expect(f("[data-testid='section-opt-#{new_section.id}']")).to be_present
        force_click("input[data-testid='group-discussion-checkbox']")
        f("input[placeholder='Select Group']").click
        # very group category exists in the dropdown
        expect(f("[data-testid='group-category-opt-#{group_category.id}']")).to be_present
      end
    end
  end
end
