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
require_relative "../../helpers/k5_common"
require_relative "../dashboard/pages/k5_important_dates_section_page"
require_relative "../dashboard/pages/k5_dashboard_common_page"
require_relative "../common"
require_relative "pages/discussion_page"
require_relative "../assignments/page_objects/assignment_create_edit_page"

describe "discussions" do
  include_context "in-process server selenium tests"
  include DiscussionsCommon
  include ItemsAssignToTray
  include ContextModulesCommon
  include K5DashboardCommonPageObject
  include K5Common
  include K5ImportantDatesSectionPageObject

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

  context "on the edit page" do
    let(:url) { "/courses/#{course.id}/discussion_topics/#{topic.id}/edit" }

    context "when :discussion_create feature flag is OFF" do
      before do
        Account.site_admin.disable_feature! :discussion_create
      end

      context "as a teacher" do
        let(:topic) { teacher_topic }

        before do
          user_session(teacher)
          stub_rcs_config
        end

        context "graded" do
          let(:topic) { assignment_topic }

          it "allows editing the assignment group", priority: "1" do
            assign_group_2 = course.assignment_groups.create!(name: "Group 2")

            get url
            click_option("#assignment_group_id", assign_group_2.name)

            expect_new_page_load { f(".form-actions button[type=submit]").click }
            expect(topic.reload.assignment.assignment_group_id).to eq assign_group_2.id
          end

          it "allows editing the grading type", priority: "1" do
            get url
            click_option("#assignment_grading_type", "Letter Grade")

            expect_new_page_load { f(".form-actions button[type=submit]").click }
            expect(topic.reload.assignment.grading_type).to eq "letter_grade"
          end

          it "allows editing the group category", priority: "1" do
            group_cat = course.group_categories.create!(name: "Groupies")
            get url

            f("#has_group_category").click
            click_option("#assignment_group_category_id", group_cat.name)

            expect_new_page_load { f(".form-actions button[type=submit]").click }
            expect(topic.reload.group_category_id).to eq group_cat.id
          end

          it "allows editing the peer review", priority: "1" do
            get url

            f("#assignment_peer_reviews").click

            expect_new_page_load { f(".form-actions button[type=submit]").click }
            expect(topic.reload.assignment.peer_reviews).to be true
          end

          it "allows editing the due dates", priority: "1" do
            get url
            wait_for_tiny(f("textarea[name=message]"))

            due_at = 3.days.from_now
            unlock_at = 2.days.from_now
            lock_at = 4.days.from_now

            # set due_at, lock_at, unlock_at
            replace_content(f(".date_field[data-date-type='due_at']"), format_date_for_view(due_at), tab_out: true)
            replace_content(f(".date_field[data-date-type='unlock_at']"), format_date_for_view(unlock_at), tab_out: true)
            replace_content(f(".date_field[data-date-type='lock_at']"), format_date_for_view(lock_at), tab_out: true)
            wait_for_ajaximations

            expect_new_page_load { f(".form-actions button[type=submit]").click }

            a = DiscussionTopic.last.assignment
            expect(a.due_at.to_date).to eq due_at.to_date
            expect(a.unlock_at.to_date).to eq unlock_at.to_date
            expect(a.lock_at.to_date).to eq lock_at.to_date
          end

          it "adds an attachment to a graded topic", priority: "1" do
            get url
            wait_for_tiny(f("textarea[name=message]"))

            add_attachment_and_validate do
              # should correctly save changes to the assignment
              set_value f("#discussion_topic_assignment_points_possible"), "123"
            end
            assignment.reload
            expect(assignment.points_possible).to eq 123
          end

          it "returns focus to add attachment when removed" do
            get url
            add_attachment_and_validate
            get url
            f(".removeAttachment").click
            wait_for_ajaximations
            check_element_has_focus(f("input[name=attachment]"))
          end

          it "warns user when leaving page unsaved", priority: "1" do
            skip_if_safari(:alert)
            title = "new title"
            get url
            wait_for_tiny(f("textarea[name=message]"))

            replace_content(f("input[name=title]"), title)
            fln("Home").click

            expect(alert_present?).to be_truthy

            driver.switch_to.alert.dismiss
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

              discussion_assignment_peer_review_options = {
                peer_reviews: true,
                automatic_peer_reviews: true,
                peer_reviews_due_at: 1.day.ago,
                peer_review_count: 2,
              }

              discussion_assignment_options = discussion_assignment_options.merge(discussion_assignment_peer_review_options)

              @graded_discussion = create_graded_discussion(course, discussion_assignment_options)

              course_override_due_date = 5.days.from_now
              course_section = course.course_sections.create!(name: "section alpha")
              @graded_discussion.assignment.assignment_overrides.create!(set_type: "CourseSection", set_id: course_section.id, due_at: course_override_due_date)
              @assignment = @graded_discussion.assignment
            end

            it "shows archived grading scheme if it is the course default twice, once to follow course default scheme and once to choose that scheme to use" do
              @course.update!(grading_standard_id: @archived_grading_standard.id)
              @course.reload
              get "/courses/#{@course.id}/discussion_topics/#{@graded_discussion.id}/edit"
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
              get "/courses/#{@course.id}/assignments/#{@assignment.id}/edit"
              wait_for_ajaximations
              f("[data-testid='grading-schemes-selector-dropdown']").click
              f("[data-testid='grading-schemes-selector-option-#{grading_standard.id}']").click

              f(".form-actions button[type=submit]").click
              fj(".ui-button-text:contains('Continue')").click
              a = DiscussionTopic.last.assignment
              expect(a.grading_standard_id).to eq grading_standard.id
            end
          end
        end

        context "with a group attached" do
          let(:graded_topic) { assignment_topic }

          before do
            @gc = GroupCategory.create(name: "Sharks", context: @course)
            @student = student_in_course(course: @course, active_all: true).user
            group = @course.groups.create!(group_category: @gc)
            group.users << @student
          end

          it "group discussions with entries should lock and display the group name", priority: "1" do
            topic.group_category = @gc
            topic.save!
            topic.child_topics[0].reply_from({ user: @student, text: "I feel pretty" })
            @gc.destroy
            get url

            expect(f("#assignment_group_category_id")).to be_disabled
            expect(get_value("#assignment_group_category_id")).to eq topic.group_category.id.to_s
          end

          it "prompts for creating a new group category if original group is deleted with no submissions", priority: "1" do
            topic.group_category = @gc
            topic.save!
            @gc.destroy
            get url
            wait_for_ajaximations
            expect(f("#assignment_group_category_id")).not_to be_displayed
          end

          context "graded" do
            let(:topic) { assignment_topic }

            it "locks and display the group name", priority: "1" do
              topic.group_category = @gc
              topic.save!
              topic.reply_from({ user: @student, text: "I feel pretty" })
              @gc.destroy
              get url

              expect(f("#assignment_group_category_id")).to be_disabled
              expect(get_value("#assignment_group_category_id")).to eq topic.group_category.id.to_s
            end
          end
        end

        it "saves and display all changes", priority: "2" do
          course.require_assignment_group

          confirm(:off)
          toggle(:on)
          confirm(:on)
        end

        it "preserves query parameters in the URL when you CANCEL", :ignore_js_errors do
          get "/courses/#{course.id}/discussion_topics/#{topic.id}/edit?embed=true"
          force_click("button:contains('Cancel')")
          wait_for_ajaximations
          expect(driver.current_url).not_to include("edit")
          expect(driver.current_url).to include("?embed=true")
        end

        it "shows correct date when saving" do
          Timecop.freeze do
            topic.lock_at = 5.days.ago
            topic.save!
            teacher.time_zone = "Hawaii"
            teacher.save!
            get url
            f(".form-actions button[type=submit]").click
            get url
            expect(topic.reload.lock_at).to eq 5.days.ago.beginning_of_minute
          end
        end

        it "toggles checkboxes when clicking their labels", priority: "1" do
          get url

          expect(is_checked("input[type=checkbox][name=threaded]")).not_to be_truthy
          force_click_native("input#threaded")
          expect(is_checked("input[type=checkbox][name=threaded]")).to be_truthy
        end

        context "locking" do
          it "sets as active when removing existing delayed_post_at and lock_at dates", priority: "1" do
            topic.delayed_post_at = 10.days.ago
            topic.lock_at         = 5.days.ago
            topic.locked          = true
            topic.save!

            get url
            wait_for_tiny(f("textarea[name=message]"))

            expect(f('input[type=text][name="delayed_post_at"]')).to be_displayed

            f('input[type=text][name="delayed_post_at"]').clear
            f('input[type=text][name="lock_at"]').clear

            expect_new_page_load { f(".form-actions button[type=submit]").click }

            topic.reload
            expect(topic.delayed_post_at).to be_nil
            expect(topic.lock_at).to be_nil
            expect(topic.active?).to be_truthy
            expect(topic.locked?).to be_falsey
          end

          it "is locked when delayed_post_at and lock_at are in past", priority: "2" do
            topic.delayed_post_at = nil
            topic.lock_at         = nil
            topic.workflow_state  = "active"
            topic.save!

            get url
            wait_for_tiny(f("textarea[name=message]"))

            delayed_post_at = 10.days.ago
            lock_at = 5.days.ago

            replace_content(f('input[type=text][name="delayed_post_at"]'), format_date_for_view(delayed_post_at), tab_out: true)
            replace_content(f('input[type=text][name="lock_at"]'), format_date_for_view(lock_at), tab_out: true)

            expect_new_page_load { f(".form-actions button[type=submit]").click }
            wait_for_ajaximations

            topic.reload
            expect(topic.delayed_post_at.to_date).to eq delayed_post_at.to_date
            expect(topic.lock_at.to_date).to eq lock_at.to_date
            expect(topic.locked?).to be_truthy
          end

          it "sets workflow to active when delayed_post_at in past and lock_at in future", priority: "2" do
            topic.delayed_post_at = 5.days.from_now
            topic.lock_at         = 10.days.from_now
            topic.workflow_state  = "active"
            topic.locked          = false
            topic.save!

            get url
            wait_for_tiny(f("textarea[name=message]"))

            delayed_post_at = 5.days.ago

            replace_content(f('input[type=text][name="delayed_post_at"]'), format_date_for_view(delayed_post_at), tab_out: true)

            expect_new_page_load { f(".form-actions button[type=submit]").click }
            wait_for_ajaximations

            topic.reload
            expect(topic.delayed_post_at.to_date).to eq delayed_post_at.to_date
            expect(topic.active?).to be_truthy
            expect(topic.locked?).to be_falsey
          end
        end

        context "usage rights" do
          before do
            course.root_account.enable_feature!(:usage_rights_discussion_topics)
            course.update!(usage_rights_required: true)
          end

          it "validates that usage rights are set" do
            get url
            _filename, fullpath, _data = get_file("testfile5.zip")
            f("input[name=attachment]").send_keys(fullpath)
            type_in_tiny("textarea[name=message]", "file attachment discussion")
            f("#edit_discussion_form_buttons .btn-primary[type=submit]").click
            wait_for_ajaximations
            error_box = f("div[role='alert'] .error_text")
            expect(error_box.text).to eq "You must set usage rights"
          end

          it "sets usage rights on file attachment" do
            get url
            _filename, fullpath, _data = get_file("testfile1.txt")
            f("input[name=attachment]").send_keys(fullpath)
            f("#usage_rights_control button").click
            click_option(".UsageRightsSelectBox__container select", "own_copyright", :value)
            f(".UsageRightsDialog__Footer-Actions button[type='submit']").click
            expect_new_page_load { f(".form-actions button[type=submit]").click }
            expect(topic.reload.attachment.usage_rights).not_to be_nil
          end

          it "displays usage rights on file attachment" do
            usage_rights = @course.usage_rights.create!(
              legal_copyright: "(C) 2012 Initrode",
              use_justification: "own_copyright"
            )
            file = @course.attachments.create!(
              display_name: "hey.txt",
              uploaded_data: default_uploaded_data,
              usage_rights:
            )
            file.usage_rights
            topic.attachment = file
            topic.save!

            get url
            expect(element_exists?("#usage_rights_control i.icon-files-copyright")).to be(true)
          end
        end

        context "in paced course" do
          let(:topic) { assignment_topic }

          before do
            course.enable_course_paces = true
            course.save!
            context_module = course.context_modules.create! name: "M"
            assignment_topic.context_module_tags.create! context_module:, context: @course, tag_type: "context_module"
          end

          it "shows the course pacing notice on a graded discussion" do
            get url
            expect(Discussion.course_pacing_notice).to be_displayed
          end

          it "does not show the course pacing notice on a graded discussion when feature off in account" do
            course.account.disable_feature!(:course_paces)

            get url
            expect(element_exists?(Discussion.course_pacing_notice_selector)).to be_falsey
          end
        end

        context "anonymous topic" do
          let(:topic) { course.discussion_topics.create!(user: teacher, title: "anonymous topic title", message: "anonymous topic message", anonymous_state: "full_anonymity") }

          before do
            Account.site_admin.enable_feature! :react_discussions_post
          end

          it "able to save" do
            get url

            expect_new_page_load { f(".form-actions button[type=submit]").click }
            expect(fj("span:contains('anonymous topic title')")).to be_present
          end
        end
      end
    end

    context "when :discussion_create feature flag is ON" do
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
          expect(f("input[value='full_anonymity']").attribute("disabled")).to eq "true"

          expect(f("input[value='must-respond-before-viewing-replies']").selected?).to be_truthy
          expect(f("input[value='enable-podcast-feed']").selected?).to be_truthy
          expect(f("input[value='include-student-replies-in-podcast-feed']").selected?).to be_truthy
          expect(f("input[value='allow-liking']").selected?).to be_truthy
          expect(f("input[value='only-graders-can-like']").selected?).to be_truthy
          expect(f("input[value='add-to-student-to-do']").selected?).to be_truthy

          # Just checking for a value. Formatting and TZ differences between front-end and back-end
          # makes an exact comparison too fragile.
          expect(ff("input[placeholder='Select Date']")[0].attribute("value")).to be_truthy
          expect(ff("input[placeholder='Select Date']")[1].attribute("value")).to be_truthy
        end

        it "does not display the grading and groups not supported in anonymous discussions message in the edit page" do
          get "/courses/#{course.id}/discussion_topics/#{@topic_all_options.id}/edit"

          expect(f("input[value='full_anonymity']").selected?).to be_truthy
          expect(f("input[value='full_anonymity']").attribute("disabled")).to eq "true"
          expect(f("body")).not_to contain_jqcss("[data-testid=groups_grading_not_allowed]")
        end

        it "displays all unselected options correctly" do
          get "/courses/#{course.id}/discussion_topics/#{@topic_no_options.id}/edit"

          expect(f("input[value='full_anonymity']").selected?).to be_falsey
          expect(f("input[value='full_anonymity']").attribute("disabled")).to eq "true"

          # There are less checks here because certain options are only visible if their parent input is selected
          expect(f("input[value='must-respond-before-viewing-replies']").selected?).to be_falsey
          expect(f("input[value='enable-podcast-feed']").selected?).to be_falsey
          expect(f("input[value='allow-liking']").selected?).to be_falsey
          expect(f("input[value='add-to-student-to-do']").selected?).to be_falsey

          # Just checking for a value. Formatting and TZ differences between front-end and back-end
          # makes an exact comparison too fragile.
          expect(ff("input[placeholder='Select Date']")[0].attribute("value")).to eq("")
          expect(ff("input[placeholder='Select Date']")[1].attribute("value")).to eq("")
        end

        context "usage rights" do
          before do
            course.root_account.enable_feature!(:usage_rights_discussion_topics)
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

          f("button[title='Remove All Sections']").click
          f("input[data-testid='section-select']").click
          fj("li:contains('value for name')").click

          # we cannot change anonymity on edit, so we just verify its disabled
          expect(ffj("fieldset:contains('Anonymous Discussion') input[disabled]").count).to eq 3

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
          expect(@topic_all_options.is_section_specific).to be_truthy
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

          expect(f("input[value='enable-delay-posting']").selected?).to be_truthy
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

          expect(f("input[value='enable-delay-posting']").selected?).to be_falsey
          expect(f("input[value='enable-participants-commenting']").selected?).to be_falsey
          expect(f("input[value='must-respond-before-viewing-replies']").selected?).to be_falsey
          expect(f("input[value='allow-liking']").selected?).to be_falsey
          expect(f("input[value='enable-podcast-feed']").selected?).to be_falsey
        end
      end

      context "graded" do
        def create_graded_discussion(discussion_course, assignment_options = {})
          default_assignment_options = {
            name: "Default Assignment",
            points_possible: 10,
            assignment_group: discussion_course.assignment_groups.create!(name: "Default Assignment Group"),
            only_visible_to_overrides: false
          }
          options = default_assignment_options.merge(assignment_options)

          discussion_assignment = discussion_course.assignments.create!(options)
          all_graded_discussion_options = {
            user: teacher,
            title: "assignment topic title",
            message: "assignment topic message",
            discussion_type: "threaded",
            assignment: discussion_assignment,
          }
          discussion_course.discussion_topics.create!(all_graded_discussion_options)
        end

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

          expect(f("span[data-testid='assign-to-select-span']").present?).to be_truthy
          expect(fj("span:contains('#{course_section.name}')").present?).to be_truthy

          # Verify that the only_visible_to_overrides field is being respected
          expect(f("body")).not_to contain_jqcss("span:contains('Everyone')")

          # Just checking for a value. Formatting and TZ differences between front-end and back-end
          # makes an exact comparison too fragile.
          expect(f("input[placeholder='Select Assignment Due Date']").attribute("value")).not_to be_empty
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

        context "differentiated modules Feature Flag", :ignore_js_errors do
          before do
            differentiated_modules_on
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
            Discussion.assign_to_button.click

            # Expect check card and override count/content
            expect(module_item_assign_to_card.count).to eq 1
            expect(selected_assignee_options.count).to eq 1
            expect(selected_assignee_options.first.find("span").text).to eq "Everyone"

            # Find the date inputs, extract their values, combine date and time values, and parse into DateTime objects
            displayed_override_dates = all_displayed_assign_to_date_and_time

            # Check that the due dates are correctly displayed
            expect(displayed_override_dates.include?(DateTime.parse(due_date))).to be_truthy
            expect(displayed_override_dates.include?(DateTime.parse(unlock_at))).to be_truthy
            expect(displayed_override_dates.include?(DateTime.parse(lock_at))).to be_truthy
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
            Discussion.assign_to_button.click

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
            Discussion.assign_to_button.click

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
            Discussion.assign_to_button.click
            wait_for_assign_to_tray_spinner

            keep_trying_until { expect(item_tray_exists?).to be_truthy }

            click_add_assign_to_card
            select_module_item_assignee(1, @student1.name)

            click_save_button("Apply")

            keep_trying_until { expect(element_exists?(module_item_edit_tray_selector)).to be_falsey }
            expect(AssignmentCreateEditPage.pending_changes_pill_exists?).to be_truthy

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
            Discussion.assign_to_button.click
            wait_for_assign_to_tray_spinner

            keep_trying_until { expect(item_tray_exists?).to be_truthy }

            # Remove the section override
            click_delete_assign_to_card(1)
            click_save_button("Apply")

            keep_trying_until { expect(element_exists?(module_item_edit_tray_selector)).to be_falsey }
            expect(AssignmentCreateEditPage.pending_changes_pill_exists?).to be_truthy

            Discussion.save_button.click
            wait_for_ajaximations

            assignment = Assignment.last
            expect(assignment.assignment_overrides.active.count).to eq 0
          end

          it "displays module overrides correctly" do
            graded_discussion = create_graded_discussion(course)
            module1 = course.context_modules.create!(name: "Module 1")
            graded_discussion.context_module_tags.create! context_module: module1, context: course, tag_type: "context_module"

            override = module1.assignment_overrides.create!
            override.assignment_override_students.create!(user: @student1)

            # Open page and assignTo tray
            get "/courses/#{course.id}/discussion_topics/#{graded_discussion.id}/edit"
            Discussion.assign_to_button.click
            wait_for_assign_to_tray_spinner

            # Verify that Everyone tag does not appear
            expect(module_item_assign_to_card.count).to eq 1
            expect(module_item_assign_to_card[0].find_all(assignee_selected_option_selector).map(&:text)).to eq ["User"]
            expect(inherited_from.last.text).to eq("Inherited from #{module1.name}")

            # Update the inherited card due date, should remove inherited
            update_due_date(0, "12/31/2022")
            update_due_time(0, "5:00 PM")
            click_save_button("Apply")

            Discussion.assign_to_button.click
            expect(f("body")).not_to contain_jqcss(inherited_from_selector)
            click_save_button("Apply")

            Discussion.save_button.click
            Discussion.section_warning_continue_button.click
            wait_for_ajaximations

            # Expect the module override to be overridden and not appear
            get "/courses/#{course.id}/discussion_topics/#{graded_discussion.id}/edit"
            Discussion.assign_to_button.click

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
            Discussion.assign_to_button.click
            wait_for_assign_to_tray_spinner

            # Verify that Everyone tag does not appear
            expect(module_item_assign_to_card.count).to eq 2
            expect(module_item_assign_to_card[0].find_all(assignee_selected_option_selector).map(&:text)).to eq ["Everyone else"]
            expect(module_item_assign_to_card[1].find_all(assignee_selected_option_selector).map(&:text)).to eq ["User"]
            expect(inherited_from.last.text).to eq("Inherited from #{module1.name}")
          end

          it "creates a course override if everyone is added with a module override" do
            graded_discussion = create_graded_discussion(course)
            module1 = course.context_modules.create!(name: "Module 1")
            graded_discussion.context_module_tags.create! context_module: module1, context: course, tag_type: "context_module"

            override = module1.assignment_overrides.create!
            override.assignment_override_students.create!(user: @student1)

            # Open page and assignTo tray
            get "/courses/#{course.id}/discussion_topics/#{graded_discussion.id}/edit"
            Discussion.assign_to_button.click
            wait_for_assign_to_tray_spinner

            # Verify the module override is shown
            expect(module_item_assign_to_card.count).to eq 1
            expect(module_item_assign_to_card[0].find_all(assignee_selected_option_selector).map(&:text)).to eq ["User"]
            expect(inherited_from.last.text).to eq("Inherited from #{module1.name}")

            click_add_assign_to_card
            select_module_item_assignee(1, "Everyone else")

            click_save_button("Apply")

            # Save the discussion without changing the inherited module override
            Discussion.save_button.click
            Discussion.section_warning_continue_button.click
            wait_for_ajaximations

            assignment = graded_discussion.assignment

            # Expect the existing override to be the module override
            expect(assignment.assignment_overrides.active.count).to eq 1
            expect(assignment.all_assignment_overrides.active.count).to eq 2
            expect(assignment.assignment_overrides.first.set_type).to eq "Course"
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
            Discussion.assign_to_button.click
            wait_for_assign_to_tray_spinner

            # Verify the module override is not shown
            expect(module_item_assign_to_card.count).to eq 1
            expect(module_item_assign_to_card[0].find_all(assignee_selected_option_selector).map(&:text)).to eq ["User"]
            expect(module_item_assign_to_card[0]).not_to contain_css(inherited_from_selector)
          end

          it "does not create an override if the modules override is not updated" do
            graded_discussion = create_graded_discussion(course)
            module1 = course.context_modules.create!(name: "Module 1")
            graded_discussion.context_module_tags.create! context_module: module1, context: course, tag_type: "context_module"

            override = module1.assignment_overrides.create!
            override.assignment_override_students.create!(user: @student1)

            # Open page and assignTo tray
            get "/courses/#{course.id}/discussion_topics/#{graded_discussion.id}/edit"
            Discussion.assign_to_button.click
            wait_for_assign_to_tray_spinner

            # Verify the module override is shown
            expect(module_item_assign_to_card.count).to eq 1
            expect(module_item_assign_to_card[0].find_all(assignee_selected_option_selector).map(&:text)).to eq ["User"]
            expect(inherited_from.last.text).to eq("Inherited from #{module1.name}")
            click_save_button("Apply")

            # Save the discussion without changing the inherited module override
            Discussion.save_button.click
            Discussion.section_warning_continue_button.click
            wait_for_ajaximations

            assignment = graded_discussion.assignment

            # Expect the existing override to be the module override
            expect(assignment.assignment_overrides.active.count).to eq 0
            expect(assignment.all_assignment_overrides.active.count).to eq 1
            expect(assignment.all_assignment_overrides.first.context_module_id).to eq module1.id
          end

          it "displays highighted cards correctly" do
            graded_discussion = create_graded_discussion(course)
            get "/courses/#{course.id}/discussion_topics/#{graded_discussion.id}/edit"
            Discussion.assign_to_button.click
            wait_for_assign_to_tray_spinner

            # Expect there to be no highlighted cards
            expect(module_item_assign_to_card.count).to eq 1
            expect(f("body")).not_to contain_jqcss(highlighted_card_selector)
            click_save_button("Apply")

            # Expect that if no changes were made, that the apply button doens't highlight old cards
            Discussion.assign_to_button.click
            wait_for_assign_to_tray_spinner
            expect(module_item_assign_to_card.count).to eq 1
            expect(f("body")).not_to contain_jqcss(highlighted_card_selector)

            # Expect highlighted card after making a change
            update_due_date(0, "12/31/2022")
            click_save_button("Apply")
            Discussion.assign_to_button.click
            wait_for_assign_to_tray_spinner
            expect(highlighted_item_assign_to_card.count).to eq 1
          end

          it "cancels correctly" do
            graded_discussion = create_graded_discussion(course)

            # Open page and assignTo tray
            get "/courses/#{course.id}/discussion_topics/#{graded_discussion.id}/edit"
            Discussion.assign_to_button.click
            wait_for_assign_to_tray_spinner

            # Create a new card, don't apply it
            click_add_assign_to_card
            select_module_item_assignee(1, @student1.name)
            expect(module_item_assign_to_card.count).to eq 2
            cancel_button.click

            # Reopen, expect new card to not be there
            Discussion.assign_to_button.click
            expect(module_item_assign_to_card.count).to eq 1

            # Add a new card, apply it
            click_add_assign_to_card
            select_module_item_assignee(1, @student1.name)
            click_save_button("Apply")
            expect(AssignmentCreateEditPage.pending_changes_pill_exists?).to be_truthy

            # Expect both cards to be there
            Discussion.assign_to_button.click
            expect(module_item_assign_to_card.count).to eq 2
          end

          it "sets the mark important dates checkbox for discussion edit" do
            feature_setup

            graded_discussion = create_graded_discussion(course)

            get "/courses/#{course.id}/discussion_topics/#{graded_discussion.id}/edit"

            Discussion.assign_to_button.click
            wait_for_assign_to_tray_spinner

            keep_trying_until { expect(item_tray_exists?).to be_truthy }

            formatted_date = format_date_for_view(2.days.from_now(Time.zone.now), "%m/%d/%Y")
            update_due_date(0, formatted_date)
            update_due_time(0, "5:00 PM")

            click_save_button("Apply")

            expect(mark_important_dates).to be_displayed
            scroll_to_element(mark_important_dates)
            click_mark_important_dates

            Discussion.save_button.click
            wait_for_ajaximations

            assignment = Assignment.last

            expect(assignment.important_dates).to be(true)
          end
        end

        context "checkpoints" do
          before do
            course.root_account.enable_feature!(:discussion_checkpoints)
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
        end
      end
    end
  end
end
