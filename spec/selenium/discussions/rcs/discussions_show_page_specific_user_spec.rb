# frozen_string_literal: true

#
# Copyright (C) 2017 - present Instructure, Inc.
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

require_relative "../../helpers/discussions_common"

describe "discussions" do
  include_context "in-process server selenium tests"
  include DiscussionsCommon

  let(:course) { course_model.tap(&:offer!) }
  let(:student) { student_in_course(course:, name: "student", active_all: true).user }
  let(:teacher) { teacher_in_course(course:, name: "teacher", active_all: true).user }
  let(:student_topic) { course.discussion_topics.create!(user: student, title: "student topic title", message: "student topic message") }
  let(:teacher_topic) { course.discussion_topics.create!(user: teacher, title: "teacher topic title", message: "teacher topic message") }
  let(:assignment_group) { course.assignment_groups.create!(name: "assignment group") }
  let(:assignment) do
    course.assignments.create!(
      name: "assignment",
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
  let(:assignment_with_points) do
    course.assignments.create!(
      name: "assignment",
      points_possible: 10
    )
  end
  let(:graded_discussion) do
    course.discussion_topics.create!(user: teacher,
                                     title: "graded discussion topic",
                                     message: "assignment topic message",
                                     assignment: assignment_with_points)
  end
  let(:entry) { topic.discussion_entries.create!(user: teacher, message: "teacher entry") }

  let(:group) do
    @category1 = course.group_categories.create!(name: "category 1")
    @category1.configure_self_signup(true, false)
    @category1.save!
    @g1 = course.groups.create!(name: "some group", group_category: @category1)
    @g1.save!
  end

  before do
    stub_rcs_config
  end

  context "on the show page" do
    let(:url) { "/courses/#{course.id}/discussion_topics/#{topic.id}/" }

    context "as a student" do
      let(:topic) { student_topic }

      before do
        user_session(student)
      end

      context "teacher topic" do
        let(:topic) { teacher_topic }

        it "allows students to reply to a discussion even if they cannot create a topic", :ignore_js_errors, priority: "2" do
          course.allow_student_discussion_topics = false
          course.save!
          get url
          wait_for_animations
          new_student_entry_text = "Hello there"
          wait_for_animations
          expect(f('[data-testid="discussion-root-entry-container"]')).not_to include_text(new_student_entry_text)
          add_reply new_student_entry_text
          expect(f('[data-testid="discussion-root-entry-container"]')).to include_text(new_student_entry_text)
        end

        it "displays the subscribe button after an initial post", priority: "1" do
          skip "Will be fixed in VICE-5427 2025-07-15"
          topic.unsubscribe(student)
          topic.require_initial_post = true
          topic.save!

          get url

          wait_for_ajaximations
          expect(f(".topic-unsubscribe-button")).not_to be_displayed
          expect(f(".topic-subscribe-button")).not_to be_displayed

          f(".discussion-reply-action").click
          wait_for_ajaximations
          type_in_tiny "textarea", "initial post text"
          scroll_to_submit_button_and_click(".discussion-reply-form")
          wait_for_ajaximations
          expect(f(".topic-unsubscribe-button")).to be_displayed
        end

        it "allows you to subscribe and unsubscribe" do
          get url
          expect(f('[data-testid="discussion-topic-container"]')).to contain_css('[data-action-state="subscribeButton"]')
          expect(f('[data-testid="discussion-topic-container"]')).not_to contain_css('[data-action-state="unsubscribeButton"]')
          f('[data-testid="subscribeToggle"]').click

          get url
          expect(f('[data-testid="discussion-topic-container"]')).not_to contain_css('[data-action-state="subscribeButton"]')
          expect(f('[data-testid="discussion-topic-container"]')).to contain_css('[data-action-state="unsubscribeButton"]')
          f('[data-testid="subscribeToggle"]').click

          get url
          expect(f('[data-testid="discussion-topic-container"]')).to contain_css('[data-action-state="subscribeButton"]')
          expect(f('[data-testid="discussion-topic-container"]')).not_to contain_css('[data-action-state="unsubscribeButton"]')
        end

        it "validates that a student can see it and reply to a discussion", :ignore_js_errors, priority: "1" do
          new_student_entry_text = "new student entry"
          get url
          expect(f('[data-testid="message_title"]')).to include_text("teacher")
          expect(f('[data-testid="discussion-root-entry-container"]')).not_to include_text(new_student_entry_text)
          add_reply new_student_entry_text
          expect(f('[data-testid="discussion-root-entry-container"]')).to include_text(new_student_entry_text)
        end

        it "lets students post to a post-first discussion", :ignore_js_errors, priority: "1" do
          new_student_entry_text = "new student entry"
          topic.require_initial_post = true
          topic.save
          entry
          get url
          # shouldn't see the existing entry until posting
          expect(f('[data-testid="discussion-root-entry-container"]')).not_to include_text("new entry from teacher")
          add_reply new_student_entry_text
          # now they should see the existing entry, and their entry
          entries = get_all_replies
          expect(entries.length).to eq 2
          expect(entries[0]).to include_text(new_student_entry_text)
          expect(entries[1]).to include_text("teacher entry")
        end
      end
    end

    context "as a teacher" do
      let(:topic) { teacher_topic }

      before do
        user_session(teacher)
      end

      it "creates a group discussion", priority: "1" do
        skip "Will be fixed in VICE-5634 2025-11-11"
        group
        get "/courses/#{course.id}/discussion_topics"
        expect_new_page_load { f("#add_discussion").click }
        f("#discussion-title").send_keys("New Discussion")
        type_in_tiny "textarea[name=message]", "Discussion topic message"
        f("#has_group_category").click
        drop_down = get_options("#assignment_group_category_id").map { |e| e.text.strip }
        expect(drop_down).to include("category 1")
        click_option("#assignment_group_category_id", @category1.name)
        expect_new_page_load { submit_form(".form-actions") }
        expect(f('[data-testid="groups-menu-btn"]')).to be_displayed
      end

      it "creates a graded group discussion", priority: "1" do
        skip "Will be fixed in VICE-5634 2025-11-11"
        assignment_group
        group
        get "/courses/#{course.id}/discussion_topics/new"
        f("#discussion-title").send_keys("New Discussion")
        type_in_tiny "textarea[name=message]", "Discussion topic message"
        expect(f("#availability_options")).to be_displayed
        fxpath("//span[text()='Graded']").click
        wait_for_ajaximations
        expect(f("#availability_options")).to_not be_displayed
        f("#discussion_topic_assignment_points_possible").send_keys("10")
        wait_for_ajaximations
        click_option("#assignment_group_id", assignment_group.name)
        f("#has_group_category").click
        drop_down = get_options("#assignment_group_category_id").map { |e| e.text.strip }
        expect(drop_down).to include("category 1")
        click_option("#assignment_group_category_id", @category1.name)
        expect_new_page_load { submit_form(".form-actions") }
        expect(f('[data-testid="groups-menu-btn"]')).to be_displayed
        expect(f('[data-testid="discussion-topic-reply"]')).to be_present
      end

      it "shows attachment", priority: "1" do
        skip "Will be fixed in VICE-5634 2025-11-11"
        get "/courses/#{course.id}/discussion_topics"
        expect_new_page_load { f("#add_discussion").click }
        filename, fullpath, _data = get_file("graded.png")
        f("#discussion-title").send_keys("New Discussion")
        f("input[name=attachment]").send_keys(fullpath)
        type_in_tiny("textarea[name=message]", "file attachment discussion")
        expect_new_page_load { submit_form(".form-actions") }
        expect(f('[data-testid="post-message-container"]').text).to include(filename)
      end

      it "escapes correctly when posting an attachment", :ignore_js_errors, priority: "2" do
        get url
        message = "message that needs escaping ' \" & !@#^&*()$%{}[];: blah"
        add_reply(message, "graded.png")
        expect(@last_entry.find_element(:css, '[data-resource-type="discussion_topic.reply"]').text).to eq message
      end
    end
  end
end
