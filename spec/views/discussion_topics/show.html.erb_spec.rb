# frozen_string_literal: true

#
# Copyright (C) 2011 - present Instructure, Inc.
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
#
require_relative "../../spec_helper"
require_relative "../views_helper"

describe "discussion_topics/show" do
  it "renders" do
    course_with_teacher
    view_context(@course, @user)
    assignment_model(course: @course, submission_types: "discussion_topic")
    @topic = @assignment.discussion_topic
    @entry = @topic.discussion_entries.create!(message: "some message")
    @topic.discussion_entries.create!(message: "another message")
    @topic.message = nil
    assign(:assignment, @assignment)
    assign(:topic, @topic)
    assign(:grouped_entries, @topic.discussion_entries.group_by(&:parent_id))
    assign(:entries, @topic.discussion_entries)
    assign(:all_entries, @topic.discussion_entries)
    assign(:assignment_presenter, AssignmentPresenter.new(@assignment))
    assign(:discussion_presenter, DiscussionTopicPresenter.new(@topic, @user))
    render "discussion_topics/show"
    expect(response).to have_tag("div#discussion_subentries")
  end

  it "renders in a group context" do
    assignment_model(submission_types: "discussion_topic")
    rubric_association_model(association_object: @assignment, purpose: "grading")
    group_model
    view_context(@group, @user)
    @topic = @assignment.discussion_topic
    @topic.message = nil # the assigns for @context don't seem to carry over to the controller helper method
    @topic.user = @user
    @topic.save!
    @entry = @topic.discussion_entries.create!(message: "some message")
    @topic.discussion_entries.create!(message: "another message")
    assign(:topic, @topic)
    assign(:grouped_entries, @topic.discussion_entries.group_by(&:parent_id))
    assign(:entries, @topic.discussion_entries)
    assign(:all_entries, @topic.discussion_entries)
    assign(:assignment, AssignmentOverrideApplicator.assignment_overridden_for(@assignment, @user))
    assign(:assignment_presenter, AssignmentPresenter.new(@assignment))
    assign(:discussion_presenter, DiscussionTopicPresenter.new(@topic, @user))
    expect(@topic).to be_for_assignment
    expect(@topic.assignment.rubric_association.rubric).not_to be_nil
    render "discussion_topics/show"
    expect(response).to have_tag("div#discussion_subentries")
  end

  it "renders the student to-do date" do
    assignment_model(submission_types: "discussion_topic")
    rubric_association_model(association_object: @assignment, purpose: "grading")
    group_model
    view_context(@group, @user)
    @topic = @assignment.discussion_topic
    @topic.message = nil # the assigns for @context don't seem to carry over to the controller helper method
    @topic.user = @user
    @topic.todo_date = "2018-06-22 05:59:00"
    @topic.save!
    assign(:topic, @topic)
    assign(:assignment, AssignmentOverrideApplicator.assignment_overridden_for(@assignment, @user))
    assign(:presenter, DiscussionTopicPresenter.new(@topic, @user))
    assign(:assignment_presenter, AssignmentPresenter.new(@assignment))
    render "discussion_topics/show"
    expect(response).to have_tag("div.discussion-tododate")
  end

  context "external tools" do
    def basic_announcement_model(opts = {})
      opts.reverse_merge!({
                            title: "Default title",
                            message: "Default message",
                            is_section_specific: false
                          })
      announcement = Announcement.create!(
        title: opts[:title],
        message: opts[:message],
        user: @teacher,
        context: opts[:course],
        workflow_state: "published"
      )
      announcement.is_section_specific = opts[:is_section_specific]
      announcement
    end

    it "does not render assignment_edit placement lti tools with flag on" do
      Account.site_admin.enable_feature! :assignment_edit_placement_not_on_announcements
      course_with_teacher
      basic_announcement_model(course: @course)
      @topic = Announcement.new({ title: "some title", context: @course, user: @teacher, message: "some message" })
      @topic.save!
      assign(:topic, @topic)
      view_context
      render "discussion_topics/show"
      expect(response).not_to have_tag("div#assignment_external_tools")
    end

    it "renders assignment_edit placement lti tools with flag off" do
      Account.site_admin.disable_feature! :assignment_edit_placement_not_on_announcements
      course_with_teacher
      basic_announcement_model(course: @course)
      @topic = Announcement.new({ title: "some title", context: @course, user: @teacher, message: "some message" })
      @topic.save!
      assign(:topic, @topic)
      view_context
      render "discussion_topics/show"
      expect(response).to have_tag("div#assignment_external_tools")
    end
  end

  context "for TAs" do
    it "renders a speedgrader link if user can manage grades but not view all grades" do
      course_with_teacher
      course_with_ta(course: @course)
      assignment_model(course: @course, submission_types: "discussion_topic")
      @course.account.role_overrides.create!(permission: "view_all_grades", role: ta_role, enabled: false)
      @topic = @assignment.discussion_topic
      @topic.message = nil
      assign(:topic, @topic)
      assign(:assignment, @assignment)
      assign(:assignment_presenter, AssignmentPresenter.new(@assignment))
      view_context(@course, @ta)
      render "discussion_topics/show"
      expect(response).to have_tag(
        "a[href=\"/courses/#{@course.id}/gradebook/speed_grader?assignment_id=#{@assignment.id}\"]"
      )
    end

    it "renders a speedgrader link if user can view all grades but not manage grades" do
      course_with_teacher
      course_with_ta(course: @course)
      assignment_model(course: @course, submission_types: "discussion_topic")
      @course.account.role_overrides.create!(permission: "manage_grades", role: ta_role, enabled: false)
      @topic = @assignment.discussion_topic
      @topic.message = nil
      assign(:topic, @topic)
      assign(:assignment, @assignment)
      assign(:assignment_presenter, AssignmentPresenter.new(@assignment))
      view_context(@course, @ta)
      render "discussion_topics/show"
      expect(response).to have_tag(
        "a[href=\"/courses/#{@course.id}/gradebook/speed_grader?assignment_id=#{@assignment.id}\"]"
      )
    end

    it "does not render a speedgrader link if user can neither manage grades nor view all grades" do
      course_with_teacher
      course_with_ta(course: @course)
      assignment_model(course: @course, submission_types: "discussion_topic")
      @course.account.role_overrides.create!(permission: "view_all_grades", role: ta_role, enabled: false)
      @course.account.role_overrides.create!(permission: "manage_grades", role: ta_role, enabled: false)
      @topic = @assignment.discussion_topic
      @topic.message = nil
      assign(:topic, @topic)
      assign(:assignment, @assignment)
      assign(:assignment_presenter, AssignmentPresenter.new(@assignment))
      assign(:discussion_presenter, DiscussionTopicPresenter.new(@topic, @user))
      view_context(@course, @ta)
      render "discussion_topics/show"
      expect(response).not_to have_tag(
        "a[href=\"/courses/#{@course.id}/gradebook/speed_grader?assignment_id=#{@assignment.id}\"]"
      )
    end
  end
end
