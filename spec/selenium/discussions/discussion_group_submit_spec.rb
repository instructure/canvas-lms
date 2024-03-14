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

require_relative "../helpers/assignments_common"
require_relative "../helpers/discussions_common"

describe "discussion assignments" do
  include_context "in-process server selenium tests"
  include DiscussionsCommon
  include AssignmentsCommon

  before :once do
    course_with_teacher(active_all: true)
    @course.assignment_groups.create!(name: "Assignment Group")
    @category1 = @course.group_categories.create!(name: "category 1")
    @category1.configure_self_signup(true, false)
    @category1.save!
    @g1 = @course.groups.create!(name: "some group", group_category: @category1)
    @g1.save!
  end

  before do
    user_session(@teacher)
  end

  context "when discussion anonymity is allowed" do
    before :once do
      @course.enable_feature! :react_discussions_post
    end

    context "for discussions getting created within a group's context" do
      it "does not show anonymity options" do
        get "/groups/#{@g1.id}/discussion_topics/new"
        expect(f("body")).not_to contain_jqcss "input[value='full_anonymity']"
      end
    end
  end

  context "create group discussion" do
    context "when discussion_create feature flag is OFF" do
      before do
        get "/courses/#{@course.id}/discussion_topics/new"
        f("#discussion-title").send_keys("New Discussion Title")
        type_in_tiny("textarea[name=message]", "Discussion topic message body")
        f("#has_group_category").click
        click_option("#assignment_group_category_id", "category 1")
      end

      it "creates a group discussion ungraded", priority: "1" do
        expect_new_page_load { submit_form(".form-actions") }
        expect(f("#discussion_container").text).to include("Since this is a group discussion, " \
                                                           "each group has its own conversation for this topic. " \
                                                           "Here are the ones you have access to:\nsome group")
      end

      it "creates a group discussion graded", priority: "1" do
        f("#use_for_grading").click
        f("#discussion_topic_assignment_points_possible").send_keys("10")
        click_option("#assignment_group_id", "Assignment Group")
        expect_new_page_load { submit_form(".form-actions") }
        expect(f("#discussion_container").text).to include("This is a graded discussion: 10 points possible")
        expect(f("#discussion_container").text).to include("Since this is a group discussion, " \
                                                           "each group has its own conversation for this topic. " \
                                                           "Here are the ones you have access to:\nsome group")
      end
    end

    context "when discussion_create feature flag is ON" do
      before do
        Account.site_admin.enable_feature!(:discussion_create)
        Account.site_admin.enable_feature!(:react_discussions_post)
      end

      it "creates an ungraded group discussion in a course context" do
        get "/courses/#{@course.id}/discussion_topics/new"
        f("input[placeholder='Topic Title']").send_keys "Ungraded Group Discussion"
        force_click_native("input[data-testid='group-discussion-checkbox']")
        force_click_native("input[placeholder='Select a group category']")
        fj("li:contains('category 1')").click
        f("button[data-testid='save-button']").click
        dt = DiscussionTopic.last
        expect(dt.title).to eq "Ungraded Group Discussion - some group"
        expect(dt.group_category).to eq @category1
        expect(dt.assignment).to be_nil
      end

      it "creates a graded group discussion in a course context" do
        get "/courses/#{@course.id}/discussion_topics/new"
        f("input[placeholder='Topic Title']").send_keys "Graded Group Discussion"
        force_click_native("input[data-testid='group-discussion-checkbox']")
        force_click_native("input[placeholder='Select a group category']")
        fj("li:contains('category 1')").click
        force_click("label:contains('Graded')")
        f("input[data-testid='points-possible-input']").send_keys 10
        force_click_native("input[title='Points']")
        fj("li:contains('Percentage')").click
        f("button[data-testid='save-button']").click
        expect(Assignment.count).to eq 1
        dt = DiscussionTopic.last
        expect(dt.assignment).to eq Assignment.last
        expect(dt.assignment.points_possible).to eq 10
        expect(dt.assignment.grading_type).to eq "percent"
      end
    end
  end

  context "student reply and total count" do
    before do
      @discussion_topic = @course.discussion_topics.create!(user: @teacher,
                                                            title: "assignment topic title",
                                                            message: "assignment topic message",
                                                            group_category: @category1)
      @student1 = user_with_pseudonym(username: "student1@example.com", active_all: 1)
      @course.enroll_student(@student1).accept!
      @g1.add_user @student1
    end

    it "allows the student to reply and teacher to see the unread count", priority: "1" do
      get "/courses/#{@course.id}/discussion_topics/#{@discussion_topic.id}"
      expect(f(".new-and-total-badge .new-items").text).to include ""
      user_session(@student1)
      get "/courses/#{@course.id}/discussion_topics"
      expect_new_page_load { f("[data-testid='discussion-link-#{@discussion_topic.id}']").click }
      expect(f("#breadcrumbs").text).to include("some group")
      f(".discussion-reply-action").click
      type_in_tiny "textarea", "something to submit"
      f('button[type="submit"]').click
      wait_for_ajaximations
      user_session(@teacher)
      get "/courses/#{@course.id}/discussion_topics/#{@discussion_topic.id}"
      expect(f(".new-and-total-badge .new-items").text).to include "1"
    end
  end
end
