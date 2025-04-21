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

  context "posting first to view setting" do
    before(:once) do
      @course = Course.create!
      @student = User.create!
      @teacher = User.create!
      @observer = User.create!

      StudentEnrollment.create!(user: @student, course: @course, workflow_state: "active")
      TeacherEnrollment.create!(user: @teacher, course: @course, workflow_state: "active")

      @observer_enrollment = ObserverEnrollment.create!(
        user: @observer,
        course: @course,
        associated_user: @student,
        workflow_state: "active"
      )

      @context = @course
      discussion_topic_model
      @topic.require_initial_post = true
      @topic.save
    end

    it "allows admins to see posts without posting" do
      @topic.reply_from(user: @student, text: "hai")
      session = user_session(@teacher)
      get "/courses/#{@course.id}/discussion_topics/#{@topic.id}"
      expect(@topic.initial_post_required?(@teacher, session)).to be_falsey
    end

    it "does not allow student who hasn't posted to see" do
      @topic.reply_from(user: @teacher, text: "hai")
      session = user_session(@student)
      get "/courses/#{@course.id}/discussion_topics/#{@topic.id}"
      expect(@topic.initial_post_required?(@student, session)).to be_truthy
    end

    it "does not allow student's observer who hasn't posted to see" do
      @topic.reply_from(user: @teacher, text: "hai")
      session = user_session(@observer)
      get "/courses/#{@course.id}/discussion_topics/#{@topic.id}"
      expect(@topic.initial_post_required?(@observer, session)).to be_truthy
    end
  end

  context "in a homeroom course" do
    before do
      @course = Course.create!
      @teacher = User.create!
      @course.account.enable_as_k5_account!
    end

    it "does not permit replies to assignments" do
      @course.homeroom_course = true
      @course.save!
      user_session(@teacher)
      topic = Announcement.create!(context: @course, title: "Test Announcement", message: "hello world")

      get "/courses/#{@course.id}/discussion_topics/#{topic.id}"
      expect(topic.grants_right?(@teacher, user_session(@teacher), :reply) && !topic.homeroom_announcement?(@course)).to be_falsey
      expect(topic.grants_right?(@teacher, :read_replies) && !topic.homeroom_announcement?(@course)).to be_falsey
    end
  end
end
