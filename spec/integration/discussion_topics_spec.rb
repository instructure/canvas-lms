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

require "nokogiri"

describe "discussion_topics" do
  def discussion_assignment
    assignment_model(course: @course, submission_types: "discussion_topic", title: "Assignment Discussion")
    @topic = DiscussionTopic.where(assignment_id: @assignment).first
  end

  it "shows assignment group discussions without errors" do
    course_with_student_logged_in(course: @course, active_all: true)
    group_assignment_discussion(course: @course)
    @group.users << @user

    get "/groups/#{@group.id}/discussion_topics/#{@topic.id}"
    expect(response).to be_successful

    post "/groups/#{@group.id}/discussion_entries", params: { discussion_entry: { discussion_topic_id: @topic.id, message: "frist!!1" } }
    expect(response).to be_redirect

    get "/groups/#{@group.id}/discussion_topics/#{@topic.id}"
    expect(response).to be_successful
  end

  it "shows a course name for group subtopics" do
    course_with_student_logged_in(active_all: true)
    @course.update_attribute(:short_name, "some name")
    group_assignment_discussion(course: @course)
    @group.users << @user

    get "/groups/#{@group.id}/discussion_topics/#{@topic.id}"
    expect(response).to be_successful
    doc = Nokogiri::HTML5(response.body)
    link_text = doc.at_css("span.discussion-subtitle a").text
    expect(link_text).to eq @course.short_name
  end

  it "does not allow concluded students to update topic" do
    student_enrollment = course_with_student(course: @course, active_all: true)
    @topic = DiscussionTopic.new(context: @course, title: "will this work?", user: @user)
    @topic.save!
    expect(@topic.grants_right?(@user, :update)).to be
    student_enrollment.send(:conclude)
    AdheresToPolicy::Cache.clear
    expect(@topic.grants_right?(@user, :update)).not_to be
  end

  it "allows teachers to edit concluded students topics" do
    course_with_teacher(course: @course, user: @teacher, active_enrollment: true)
    student_enrollment = course_with_student(course: @course, user: @student, active_enrollment: true)
    @topic = DiscussionTopic.new(context: @course, title: "will this work?", user: @student)
    @topic.save!
    expect(@topic.grants_right?(@teacher, :update)).to be
    student_enrollment.send(:conclude)
    AdheresToPolicy::Cache.clear
    expect(@topic.grants_right?(@teacher, :update)).to be
  end

  it "shows speed grader button" do
    course_with_teacher_logged_in(active_all: true)
    discussion_assignment

    get "/courses/#{@course.id}/discussion_topics/#{@topic.id}"
    expect(response).to be_successful
    doc = Nokogiri::HTML5(response.body)
    expect(doc.at_css(".admin-links .icon-speed-grader")).not_to be_nil
  end

  it "shows peer reviews button" do
    course_with_teacher_logged_in(active_all: true)
    discussion_assignment
    @assignment.peer_reviews = true
    @assignment.save

    get "/courses/#{@course.id}/discussion_topics/#{@topic.id}"
    expect(response).to be_successful
    doc = Nokogiri::HTML5(response.body)
    expect(doc.at_css(".admin-links .icon-peer-review")).not_to be_nil
  end
end
