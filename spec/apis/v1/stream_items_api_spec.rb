# frozen_string_literal: true

#
# Copyright (C) 2011 - 2012 Instructure, Inc.
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

require_relative "../api_spec_helper"

describe UsersController, type: :request do
  include Api
  include Api::V1::Assignment

  before :once do
    course_with_student(active_all: true)
  end

  it "checks for auth" do
    get("/api/v1/users/self/activity_stream")
    assert_status(401)

    @course = factory_with_protected_attributes(Course, course_valid_attributes)
    raw_api_call(:get,
                 "/api/v1/courses/#{@course.id}/activity_stream",
                 controller: "courses",
                 action: "activity_stream",
                 format: "json",
                 course_id: @course.to_param)
    assert_status(401)
  end

  it "returns the activity stream" do
    json = api_call(:get,
                    "/api/v1/users/activity_stream.json",
                    { controller: "users", action: "activity_stream", format: "json" })
    expect(json.size).to eq 0
    google_docs_collaboration_model(user_id: @user.id)
    @context = @course
    @topic1 = discussion_topic_model
    # introduce a dangling StreamItemInstance
    StreamItem.where(id: @user.visible_stream_item_instances.last.stream_item_id).delete_all
    json = api_call(:get,
                    "/api/v1/users/activity_stream.json",
                    { controller: "users", action: "activity_stream", format: "json" })
    expect(json.size).to eq 1
  end

  it "returns the activity stream summary" do
    @context = @course
    discussion_topic_model
    discussion_topic_model(user: @user)
    announcement_model
    conversation(User.create, @user)
    Notification.create(name: "Assignment Due Date Changed", category: "TestImmediately")
    allow_any_instance_of(Assignment).to receive(:created_at).and_return(4.hours.ago)
    assignment_model(course: @course)
    @assignment.update_attribute(:due_at, 1.week.from_now)
    json = api_call(:get,
                    "/api/v1/users/self/activity_stream/summary.json",
                    { controller: "users", action: "activity_stream_summary", format: "json" })

    expect(json).to eq [
      { "type" => "Announcement", "count" => 1, "unread_count" => 1, "notification_category" => nil },
      { "type" => "Conversation", "count" => 1, "unread_count" => 0, "notification_category" => nil }, # conversations don't currently set the unread state on stream items
      { "type" => "DiscussionTopic", "count" => 2, "unread_count" => 1, "notification_category" => nil },
      { "type" => "Message", "count" => 1, "unread_count" => 0, "notification_category" => "TestImmediately" } # check a broadcast-policy-based one
    ]
  end

  context "cross-shard activity stream" do
    specs_require_sharding
    it "returns the activity stream summary with cross-shard items" do
      @student = user_factory(active_all: true)
      @shard1.activate do
        @account = Account.create!
        course_factory(active_all: true, account: @account)
        @course.enroll_student(@student).accept!
        @context = @course
        discussion_topic_model
        discussion_topic_model(user: @user)
        announcement_model
        conversation(User.create, @user)
        Notification.create(name: "Assignment Due Date Changed", category: "TestImmediately")
        allow_any_instance_of(Assignment).to receive(:created_at).and_return(4.hours.ago)
        assignment_model(course: @course)
        @assignment.update_attribute(:due_at, 1.week.from_now)
        @assignment.update_attribute(:due_at, 2.weeks.from_now)
      end
      json = api_call(:get,
                      "/api/v1/users/self/activity_stream/summary.json",
                      { controller: "users", action: "activity_stream_summary", format: "json" })

      expect(json).to eq [
        { "type" => "Announcement", "count" => 1, "unread_count" => 1, "notification_category" => nil },
        { "type" => "Conversation", "count" => 1, "unread_count" => 0, "notification_category" => nil }, # conversations don't currently set the unread state on stream items
        { "type" => "DiscussionTopic", "count" => 2, "unread_count" => 1, "notification_category" => nil },
        { "type" => "Message", "count" => 2, "unread_count" => 0, "notification_category" => "TestImmediately" } # check a broadcast-policy-based one
      ]
    end

    it "filters the activity stream to currently active courses if requested" do
      @student = user_factory(active_all: true)
      @shard1.activate do
        @account = Account.create!
        @course1 = course_factory(active_all: true, account: @account)
        @course1.enroll_student(@student).accept!
        @course2 = course_factory(active_all: true, account: @account)
        @course2.enroll_student(@student).accept!
        @dt1 = discussion_topic_model(context: @course1)
        @dt2 = discussion_topic_model(context: @course2)
        @course2.update(start_at: 2.weeks.ago, conclude_at: 1.week.ago, restrict_enrollments_to_course_dates: true)
      end
      json = api_call(:get,
                      "/api/v1/users/self/activity_stream",
                      { controller: "users", action: "activity_stream", format: "json" })
      expect(json.pluck("discussion_topic_id")).to match_array([@dt1.id, @dt2.id])

      json = api_call(:get,
                      "/api/v1/users/self/activity_stream?only_active_courses=1",
                      { controller: "users", action: "activity_stream", format: "json", only_active_courses: "1" })
      expect(json.pluck("discussion_topic_id")).to eq([@dt1.id])
    end

    it "filters the activity stream summary to currently active courses if requested" do
      @student = user_factory(active_all: true)
      @shard1.activate do
        @account = Account.create!
        @course1 = course_factory(active_all: true, account: @account)
        @course1.enroll_student(@student).accept!
        @course2 = course_factory(active_all: true, account: @account)
        course2_enrollment = @course2.enroll_student(@student)
        course2_enrollment.accept!
        @dt1 = discussion_topic_model(context: @course1)
        @dt2 = discussion_topic_model(context: @course2)
        course2_enrollment.destroy!
      end
      json = api_call(:get,
                      "/api/v1/users/self/activity_stream/summary",
                      { controller: "users", action: "activity_stream_summary", format: "json" })
      expect(json).to eq [
        { "type" => "DiscussionTopic", "count" => 2, "unread_count" => 2, "notification_category" => nil }
      ]

      json = api_call(:get,
                      "/api/v1/users/self/activity_stream/summary?only_active_courses=true",
                      { controller: "users", action: "activity_stream_summary", format: "json", only_active_courses: "true" })
      expect(json).to eq [
        { "type" => "DiscussionTopic", "count" => 1, "unread_count" => 1, "notification_category" => nil }
      ]
    end

    it "finds cross-shard submission comments" do
      @student = user_factory(active_all: true)
      course_factory(active_all: true)
      @course.enroll_student(@student).accept!
      @assignment = @course.assignments.create!(title: "assignment 1", description: "hai", points_possible: "14.2", submission_types: "online_text_entry")
      @shard1.activate do
        @teacher = user_factory(active_all: true)
      end
      @course.enroll_teacher(@teacher).accept!
      @sub = @assignment.grade_student(@student, grade: nil, grader: @teacher).first
      @sub.workflow_state = "submitted"
      @sub.submission_comments.create!(comment: "c1", author: @teacher)
      @sub.submission_comments.create!(comment: "c2", author: @student)
      @sub.save!

      json = api_call(:get,
                      "/api/v1/users/self/activity_stream?asset_type=Submission",
                      { controller: "users", action: "activity_stream", format: "json", asset_type: "Submission" })

      expect(json.count).to eq 1
      expect(json.first["submission_comments"].count).to eq 2

      json = api_call(:get,
                      "/api/v1/users/self/activity_stream?asset_type=Submission&submission_user_id=#{@student.id}",
                      { controller: "users", action: "activity_stream", format: "json", asset_type: "Submission", submission_user_id: @student.id.to_s })

      expect(json.count).to eq 1
      expect(json.first["submission_comments"].count).to eq 2
    end
  end

  it "formats DiscussionTopic" do
    @context = @course
    discussion_topic_model
    @topic.require_initial_post = true
    @topic.save
    @topic.reply_from(user: @user, text: "hai")
    json = api_call(:get,
                    "/api/v1/users/activity_stream.json",
                    { controller: "users", action: "activity_stream", format: "json" })
    expect(json).to eq [{
      "id" => StreamItem.last.id,
      "discussion_topic_id" => @topic.id,
      "title" => "value for title",
      "message" => "value for message",
      "type" => "DiscussionTopic",
      "read_state" => StreamItemInstance.last.read?,
      "context_type" => "Course",
      "created_at" => StreamItem.last.created_at.as_json,
      "updated_at" => StreamItem.last.updated_at.as_json,
      "require_initial_post" => true,
      "user_has_posted" => true,
      "html_url" => "http://www.example.com/courses/#{@context.id}/discussion_topics/#{@topic.id}",

      "total_root_discussion_entries" => 1,
      "root_discussion_entries" => [
        {
          "user" => { "user_id" => @user.id, "user_name" => "User" },
          "message" => "hai",
        },
      ],
      "course_id" => @course.id,
    }]
  end

  it "does not return discussion entries if user has not posted" do
    @context = @course
    course_with_teacher(course: @context, active_all: true)
    discussion_topic_model
    @user = @student
    @topic.require_initial_post = true
    @topic.save
    @topic.reply_from(user: @teacher, text: "hai")
    json = api_call(:get,
                    "/api/v1/users/activity_stream.json",
                    { controller: "users", action: "activity_stream", format: "json" })
    expect(json.first["require_initial_post"]).to be true
    expect(json.first["user_has_posted"]).to be false
    expect(json.first["root_discussion_entries"]).to eq []
  end

  it "returns discussion entries to admin without posting" do
    @context = @course
    course_with_teacher(course: @context, name: "Teach", active_all: true)
    discussion_topic_model
    @topic.require_initial_post = true
    @topic.save
    @topic.reply_from(user: @student, text: "hai")
    json = api_call(:get,
                    "/api/v1/users/activity_stream.json",
                    { controller: "users", action: "activity_stream", format: "json" })
    expect(json.first["require_initial_post"]).to be true
    expect(json.first["user_has_posted"]).to be true
    expect(json.first["root_discussion_entries"]).to eq [
      {
        "user" => { "user_id" => @student.id, "user_name" => "User" },
        "message" => "hai",
      },
    ]
  end

  it "translates user content in discussion topic" do
    should_translate_user_content(@course) do |user_content|
      @context = @course
      discussion_topic_model(message: user_content)
      json = api_call(:get,
                      "/api/v1/users/activity_stream.json",
                      { controller: "users", action: "activity_stream", format: "json" })
      json.first["message"]
    end
  end

  it "translates user content in discussion entry" do
    should_translate_user_content(@course) do |user_content|
      @context = @course
      discussion_topic_model
      @topic.reply_from(user: @user, html: user_content)
      json = api_call(:get,
                      "/api/v1/users/activity_stream.json",
                      { controller: "users", action: "activity_stream", format: "json" })
      json.first["root_discussion_entries"].first["message"]
    end
  end

  it "formats Announcement" do
    @context = @course
    announcement_model
    @a.reply_from(user: @user, text: "hai")
    json = api_call(:get,
                    "/api/v1/users/activity_stream.json",
                    { controller: "users", action: "activity_stream", format: "json" })
    expect(json).to eq [{
      "id" => StreamItem.last.id,
      "announcement_id" => @a.id,
      "title" => "value for title",
      "message" => "value for message",
      "type" => "Announcement",
      "read_state" => StreamItemInstance.last.read?,
      "context_type" => "Course",
      "created_at" => StreamItem.last.created_at.as_json,
      "updated_at" => StreamItem.last.updated_at.as_json,
      "require_initial_post" => false,
      "user_has_posted" => nil,
      "html_url" => "http://www.example.com/courses/#{@context.id}/announcements/#{@a.id}",

      "total_root_discussion_entries" => 1,
      "root_discussion_entries" => [
        {
          "user" => { "user_id" => @user.id, "user_name" => "User" },
          "message" => "hai",
        },
      ],
      "course_id" => @course.id,
    }]
  end

  it "translates user content in announcement messages" do
    should_translate_user_content(@course) do |user_content|
      @context = @course
      announcement_model(message: user_content)
      json = api_call(:get,
                      "/api/v1/users/activity_stream.json",
                      { controller: "users", action: "activity_stream", format: "json" })
      json.first["message"]
    end
  end

  it "translates user content in announcement discussion entries" do
    should_translate_user_content(@course) do |user_content|
      @context = @course
      announcement_model
      @a.reply_from(user: @user, html: user_content)
      json = api_call(:get,
                      "/api/v1/users/activity_stream.json",
                      { controller: "users", action: "activity_stream", format: "json" })
      json.first["root_discussion_entries"].first["message"]
    end
  end

  it "formats Conversation" do
    @sender = User.create!(name: "sender")
    @conversation = Conversation.initiate([@user, @sender], false)
    @message = @conversation.add_message(@sender, "hello")
    # should use the conversation participant's read state for the conversation
    read_state = @conversation.conversation_participants.find_by(user_id: @user).read?

    json = api_call(:get,
                    "/api/v1/users/activity_stream.json",
                    { controller: "users", action: "activity_stream", format: "json" }).first
    expect(json).to eq({
                         "id" => StreamItem.last.id,
                         "conversation_id" => @conversation.id,
                         "type" => "Conversation",
                         "read_state" => read_state,
                         "created_at" => StreamItem.last.created_at.as_json,
                         "updated_at" => StreamItem.last.updated_at.as_json,
                         "title" => nil,
                         "message" => nil,
                         "private" => false,
                         "html_url" => "http://www.example.com/conversations/#{@conversation.id}",
                         "participant_count" => 2,
                         "latest_messages" => [
                           { "id" => @message.id,
                             "created_at" => @message.created_at.as_json,
                             "author_id" => @sender.id,
                             "message" => "hello",
                             "participating_user_ids" => [@user.id, @sender.id] }
                         ]
                       })

    @conversation.conversation_participants.where(user_id: @user).first.remove_messages(@message)
    # should update the latest messages and not show them the one they can't see anymore
    json = api_call(:get,
                    "/api/v1/users/activity_stream.json",
                    { controller: "users", action: "activity_stream", format: "json" }).first
    expect(json["latest_messages"]).to be_blank
  end

  it "uses the conversation participant's read state for the conversation" do
    @sender = User.create!(name: "sender")
    @conversation = Conversation.initiate([@user, @sender], false)
    @message = @conversation.add_message(@sender, "hello")
    conversation_participant = @conversation.conversation_participants.find_by(user_id: @user)

    conversation_participant.update(workflow_state: "unread")
    json = api_call(:get,
                    "/api/v1/users/activity_stream.json",
                    { controller: "users", action: "activity_stream", format: "json" }).first
    expect(json).to eq({
                         "id" => StreamItem.last.id,
                         "conversation_id" => @conversation.id,
                         "type" => "Conversation",
                         "read_state" => false,
                         "created_at" => StreamItem.last.created_at.as_json,
                         "updated_at" => StreamItem.last.updated_at.as_json,
                         "title" => nil,
                         "message" => nil,
                         "private" => false,
                         "html_url" => "http://www.example.com/conversations/#{@conversation.id}",
                         "participant_count" => 2,
                         "latest_messages" => [
                           { "id" => @message.id,
                             "created_at" => @message.created_at.as_json,
                             "author_id" => @sender.id,
                             "message" => "hello",
                             "participating_user_ids" => [@user.id, @sender.id] }
                         ]
                       })

    conversation_participant.update(workflow_state: "read")
    json = api_call(:get,
                    "/api/v1/users/activity_stream.json",
                    { controller: "users", action: "activity_stream", format: "json" }).first
    expect(json).to eq({
                         "id" => StreamItem.last.id,
                         "conversation_id" => @conversation.id,
                         "type" => "Conversation",
                         "read_state" => true,
                         "created_at" => StreamItem.last.created_at.as_json,
                         "updated_at" => StreamItem.last.updated_at.as_json,
                         "title" => nil,
                         "message" => nil,
                         "private" => false,
                         "html_url" => "http://www.example.com/conversations/#{@conversation.id}",
                         "participant_count" => 2,
                         "latest_messages" => [
                           { "id" => @message.id,
                             "created_at" => @message.created_at.as_json,
                             "author_id" => @sender.id,
                             "message" => "hello",
                             "participating_user_ids" => [@user.id, @sender.id] }
                         ]
                       })
  end

  it "formats Message" do
    message_model(user: @user, to: "dashboard", notification: notification_model)
    json = api_call(:get,
                    "/api/v1/users/activity_stream.json",
                    { controller: "users", action: "activity_stream", format: "json" })
    expect(json).to eq [{
      "id" => StreamItem.last.id,
      "message_id" => @message.id,
      "title" => "value for subject",
      "message" => "value for body",
      "type" => "Message",
      "read_state" => StreamItemInstance.last.read?,
      "created_at" => StreamItem.last.created_at.as_json,
      "updated_at" => StreamItem.last.updated_at.as_json,

      "notification_category" => "TestImmediately",
      "url" => nil,
      "html_url" => nil,
    }]
  end

  it "formats graded Submission with comments" do
    # set @domain_root_account
    @domain_root_account = Account.default
    @domain_root_account.update(default_time_zone: "America/Denver")

    @assignment = @course.assignments.create!(title: "assignment 1", description: "hai", points_possible: "14.2", submission_types: "online_text_entry")
    @teacher = User.create!(name: "teacher")
    @course.enroll_teacher(@teacher)
    @sub = @assignment.grade_student(@user, { grade: "12", grader: @teacher }).first
    @sub.workflow_state = "submitted"
    @sub.submission_comments.create!(comment: "c1", author: @teacher)
    @sub.submission_comments.create!(comment: "c2", author: @user)
    @sub.save!
    json = api_call(:get,
                    "/api/v1/users/activity_stream.json",
                    { controller: "users", action: "activity_stream", format: "json" })
    @assignment.reload
    assign_json = assignment_json(@assignment,
                                  @user,
                                  session,
                                  include_discussion_topic: false)
    assign_json["created_at"] = @assignment.created_at.as_json
    assign_json["updated_at"] = @assignment.updated_at.as_json
    assign_json["title"] = @assignment.title
    expect(json).to eql [{
      "id" => StreamItem.last.id,
      "submission_id" => @sub.id,
      "cached_due_date" => nil,
      "custom_grade_status_id" => nil,
      "title" => "assignment 1",
      "message" => nil,
      "type" => "Submission",
      "read_state" => StreamItemInstance.last.read?,
      "created_at" => StreamItem.last.created_at.as_json,
      "updated_at" => StreamItem.last.updated_at.as_json,
      "grade" => "12",
      "entered_grade" => "12",
      "grading_period_id" => @sub.grading_period_id,
      "excused" => false,
      "grader_id" => @teacher.id,
      "graded_at" => @sub.graded_at.as_json,
      "posted_at" => @sub.posted_at.as_json,
      "score" => 12.0,
      "redo_request" => false,
      "entered_score" => 12.0,
      "html_url" => "http://www.example.com/courses/#{@course.id}/assignments/#{@assignment.id}/submissions/#{@user.id}",
      "workflow_state" => "graded",
      "late" => false,
      "missing" => false,
      "assignment" => assign_json,
      "assignment_id" => @assignment.id,
      "attempt" => nil,
      "body" => nil,
      "grade_matches_current_submission" => true,
      "preview_url" => "http://www.example.com/courses/#{@course.id}/assignments/#{@assignment.id}/submissions/#{@user.id}?preview=1&version=1",
      "submission_type" => nil,
      "submitted_at" => nil,
      "late_policy_status" => nil,
      "points_deducted" => nil,
      "seconds_late" => 0,
      "sticker" => nil,
      "url" => nil,
      "user_id" => @sub.user_id,
      "extra_attempts" => nil,

      "submission_comments" => [
        {
          "attempt" => nil,
          "body" => "c1",
          "comment" => "c1",
          "author" => {
            "id" => @teacher.id,
            "anonymous_id" => @teacher.id.to_s(36),
            "display_name" => "teacher",
            "pronouns" => nil,
            "html_url" => "http://www.example.com/courses/#{@course.id}/users/#{@teacher.id}",
            "avatar_image_url" => User.avatar_fallback_url(nil, request)
          },
          "author_name" => "teacher",
          "author_id" => @teacher.id,
          "created_at" => @sub.submission_comments[0].created_at.as_json,
          "edited_at" => nil,
          "id" => @sub.submission_comments[0].id
        },
        {
          "attempt" => nil,
          "body" => "c2",
          "comment" => "c2",
          "author" => {
            "id" => @user.id,
            "anonymous_id" => @user.id.to_s(36),
            "display_name" => "User",
            "pronouns" => nil,
            "html_url" => "http://www.example.com/courses/#{@course.id}/users/#{@user.id}",
            "avatar_image_url" => User.avatar_fallback_url(nil, request)
          },
          "author_name" => "User",
          "author_id" => @user.id,
          "created_at" => @sub.submission_comments[1].created_at.as_json,
          "edited_at" => nil,
          "id" => @sub.submission_comments[1].id
        }
      ],
      "course" => {
        "name" => @course.name,
        "end_at" => @course.end_at,
        "account_id" => @course.account_id,
        "root_account_id" => @course.root_account_id,
        "enrollment_term_id" => @course.enrollment_term_id,
        "created_at" => @course.created_at.as_json,
        "start_at" => @course.start_at.as_json,
        "grading_standard_id" => nil,
        "grade_passback_setting" => nil,
        "id" => @course.id,
        "course_code" => @course.course_code,
        "calendar" => { "ics" => "http://www.example.com/feeds/calendars/course_#{@course.uuid}.ics" },
        "hide_final_grades" => false,
        "html_url" => course_url(@course, host: HostUrl.context_host(@course)),
        "default_view" => "modules",
        "workflow_state" => "available",
        "public_syllabus" => false,
        "public_syllabus_to_auth" => false,
        "is_public" => @course.is_public,
        "is_public_to_auth_users" => @course.is_public_to_auth_users,
        "storage_quota_mb" => @course.storage_quota_mb,
        "apply_assignment_group_weights" => false,
        "restrict_enrollments_to_course_dates" => false,
        "time_zone" => "America/Denver",
        "uuid" => @course.uuid,
        "blueprint" => false,
        "license" => nil,
        "homeroom_course" => false,
        "course_color" => nil,
        "friendly_name" => nil
      },

      "user" => {
        "name" => "User", "sortable_name" => "User", "id" => @sub.user_id, "short_name" => "User", "created_at" => @user.created_at.iso8601
      },

      "context_type" => "Course",
      "course_id" => @course.id,
    }]
  end

  it "formats ungraded Submission with comments" do
    @domain_root_account = Account.default
    @domain_root_account.update(default_time_zone: "America/Denver")

    @assignment = @course.assignments.create!(title: "assignment 1", description: "hai", points_possible: "14.2", submission_types: "online_text_entry")
    @assignment.unmute!
    @teacher = User.create!(name: "teacher")
    @course.enroll_teacher(@teacher)
    @sub = @assignment.grade_student(@user, grade: nil, grader: @teacher).first
    @sub.workflow_state = "submitted"
    @sub.submission_comments.create!(comment: "c1", author: @teacher)
    @sub.submission_comments.create!(comment: "c2", author: @user)
    @sub.save!
    json = api_call(:get,
                    "/api/v1/users/activity_stream.json",
                    { controller: "users", action: "activity_stream", format: "json" })
    @assignment.reload
    assign_json = assignment_json(@assignment,
                                  @user,
                                  session,
                                  include_discussion_topic: false)
    assign_json["created_at"] = @assignment.created_at.as_json
    assign_json["updated_at"] = @assignment.updated_at.as_json
    assign_json["title"] = @assignment.title
    expect(json).to eql [{
      "id" => StreamItem.last.id,
      "submission_id" => @sub.id,
      "cached_due_date" => nil,
      "custom_grade_status_id" => nil,
      "title" => "assignment 1",
      "message" => nil,
      "type" => "Submission",
      "read_state" => StreamItemInstance.last.read?,
      "created_at" => StreamItem.last.created_at.as_json,
      "updated_at" => StreamItem.last.updated_at.as_json,
      "grade" => nil,
      "entered_grade" => nil,
      "grading_period_id" => @sub.grading_period_id,
      "excused" => false,
      "grader_id" => @teacher.id,
      "graded_at" => nil,
      "posted_at" => @sub.posted_at.as_json,
      "redo_request" => false,
      "score" => nil,
      "entered_score" => nil,
      "html_url" => "http://www.example.com/courses/#{@course.id}/assignments/#{@assignment.id}/submissions/#{@user.id}",
      "workflow_state" => "unsubmitted",
      "late" => false,
      "missing" => false,
      "assignment" => assign_json,
      "assignment_id" => @assignment.id,
      "attempt" => nil,
      "body" => nil,
      "grade_matches_current_submission" => true,
      "preview_url" => "http://www.example.com/courses/#{@course.id}/assignments/#{@assignment.id}/submissions/#{@user.id}?preview=1&version=1",
      "submission_type" => nil,
      "submitted_at" => nil,
      "late_policy_status" => nil,
      "points_deducted" => nil,
      "seconds_late" => 0,
      "sticker" => nil,
      "url" => nil,
      "user_id" => @sub.user_id,
      "extra_attempts" => nil,

      "submission_comments" => [
        {
          "attempt" => nil,
          "body" => "c1",
          "comment" => "c1",
          "author" => {
            "id" => @teacher.id,
            "anonymous_id" => @teacher.id.to_s(36),
            "display_name" => "teacher",
            "html_url" => "http://www.example.com/courses/#{@course.id}/users/#{@teacher.id}",
            "avatar_image_url" => User.avatar_fallback_url(nil, request),
            "pronouns" => nil
          },
          "author_name" => "teacher",
          "author_id" => @teacher.id,
          "created_at" => @sub.submission_comments[0].created_at.as_json,
          "edited_at" => nil,
          "id" => @sub.submission_comments[0].id
        },
        {
          "attempt" => nil,
          "body" => "c2",
          "comment" => "c2",
          "author" => {
            "id" => @user.id,
            "anonymous_id" => @user.id.to_s(36),
            "display_name" => "User",
            "html_url" => "http://www.example.com/courses/#{@course.id}/users/#{@user.id}",
            "pronouns" => nil,
            "avatar_image_url" => User.avatar_fallback_url(nil, request)
          },
          "author_name" => "User",
          "author_id" => @user.id,
          "created_at" => @sub.submission_comments[1].created_at.as_json,
          "edited_at" => nil,
          "id" => @sub.submission_comments[1].id
        }
      ],
      "course" => {
        "name" => @course.name,
        "end_at" => @course.end_at,
        "account_id" => @course.account_id,
        "root_account_id" => @course.root_account_id,
        "enrollment_term_id" => @course.enrollment_term_id,
        "start_at" => @course.start_at.as_json,
        "created_at" => @course.created_at.as_json,
        "grading_standard_id" => nil,
        "grade_passback_setting" => nil,
        "id" => @course.id,
        "course_code" => @course.course_code,
        "calendar" => { "ics" => "http://www.example.com/feeds/calendars/course_#{@course.uuid}.ics" },
        "hide_final_grades" => false,
        "html_url" => course_url(@course, host: HostUrl.context_host(@course)),
        "default_view" => "modules",
        "workflow_state" => "available",
        "public_syllabus" => false,
        "public_syllabus_to_auth" => false,
        "is_public" => @course.is_public,
        "is_public_to_auth_users" => @course.is_public_to_auth_users,
        "storage_quota_mb" => @course.storage_quota_mb,
        "apply_assignment_group_weights" => false,
        "restrict_enrollments_to_course_dates" => false,
        "time_zone" => "America/Denver",
        "uuid" => @course.uuid,
        "blueprint" => false,
        "license" => nil,
        "homeroom_course" => false,
        "course_color" => nil,
        "friendly_name" => nil
      },

      "user" => {
        "name" => "User", "sortable_name" => "User", "id" => @sub.user_id, "short_name" => "User", "created_at" => @user.created_at.iso8601
      },
      "context_type" => "Course",
      "course_id" => @course.id,
    }]
  end

  it "formats graded Submission without comments" do
    @assignment = @course.assignments.create!(title: "assignment 1", description: "hai", points_possible: "14.2", submission_types: "online_text_entry")
    @teacher = User.create!(name: "teacher")
    @course.enroll_teacher(@teacher)
    @sub = @assignment.grade_student(@user, grade: "12", grader: @teacher).first
    @sub.workflow_state = "submitted"
    @sub.save!
    json = api_call(:get,
                    "/api/v1/users/activity_stream.json",
                    { controller: "users", action: "activity_stream", format: "json" })

    expect(json[0]["grade"]).to eq "12"
    expect(json[0]["score"]).to eq 12
    expect(json[0]["workflow_state"]).to eq "graded"
    expect(json[0]["submission_comments"]).to eq []
  end

  it "does not format ungraded Submission without comments" do
    @assignment = @course.assignments.create!(title: "assignment 1", description: "hai", points_possible: "14.2", submission_types: "online_text_entry")
    @teacher = User.create!(name: "teacher")
    @course.enroll_teacher(@teacher)
    @sub = @assignment.grade_student(@user, grade: nil, grader: @teacher).first
    @sub.workflow_state = "submitted"
    @sub.save!
    json = api_call(:get,
                    "/api/v1/users/activity_stream.json",
                    { controller: "users", action: "activity_stream", format: "json" })
    expect(json).to eq []
  end

  it "formats Collaboration" do
    google_docs_collaboration_model(user_id: @user.id, title: "hey")
    json = api_call(:get,
                    "/api/v1/users/activity_stream.json",
                    { controller: "users", action: "activity_stream", format: "json" })
    expect(json).to eq [{
      "id" => StreamItem.last.id,
      "collaboration_id" => @collaboration.id,
      "title" => "hey",
      "message" => nil,
      "type" => "Collaboration",
      "read_state" => StreamItemInstance.last.read?,
      "context_type" => "Course",
      "course_id" => @course.id,
      "html_url" => "http://www.example.com/courses/#{@course.id}/collaborations/#{@collaboration.id}",
      "created_at" => StreamItem.last.created_at.as_json,
      "updated_at" => StreamItem.last.updated_at.as_json,
    }]
  end

  it "formats WebConference" do
    allow(WebConference).to receive(:plugins).and_return(
      [OpenObject.new(id: "big_blue_button", settings: { domain: "bbb.instructure.com", secret_dec: "secret" }, valid_settings?: true, enabled?: true),]
    )
    @conference = BigBlueButtonConference.create!(title: "myconf", user: @user, description: "mydesc", conference_type: "big_blue_button", context: @course)
    json = api_call(:get,
                    "/api/v1/users/activity_stream.json",
                    { controller: "users", action: "activity_stream", format: "json" })
    expect(json).to eq [{
      "id" => StreamItem.last.id,
      "web_conference_id" => @conference.id,
      "title" => "myconf",
      "type" => "WebConference",
      "read_state" => StreamItemInstance.last.read?,
      "message" => "mydesc",
      "context_type" => "Course",
      "course_id" => @course.id,
      "html_url" => "http://www.example.com/courses/#{@course.id}/conferences/#{@conference.id}",
      "created_at" => StreamItem.last.created_at.as_json,
      "updated_at" => StreamItem.last.updated_at.as_json,
    }]
  end

  it "formats AssessmentRequest" do
    assignment = assignment_model(course: @course)
    submission = submission_model(assignment:, user: @student)
    assessor_submission = submission_model(assignment:, user: @user)
    assessment_request = AssessmentRequest.create!(assessor: @user,
                                                   asset: submission,
                                                   user: @student,
                                                   assessor_asset: assessor_submission)
    assessment_request.workflow_state = "assigned"
    assessment_request.save

    json = api_call(:get,
                    "/api/v1/users/activity_stream.json",
                    { controller: "users", action: "activity_stream", format: "json" })

    expect(json[0]["id"]).to eq StreamItem.last.id
    expect(json[0]["title"]).to eq "Peer Review for #{assignment.title}"
    expect(json[0]["type"]).to eq "AssessmentRequest"
    expect(json[0]["message"]).to be_nil
    expect(json[0]["context_type"]).to eq "Course"
    expect(json[0]["course_id"]).to eq @course.id
    expect(json[0]["assessment_request_id"]).to eq assessment_request.id
    expect(json[0]["html_url"]).to eq "http://www.example.com/courses/#{@course.id}/assignments/#{assignment.id}/submissions/#{assessment_request.user_id}"
    expect(json[0]["created_at"]).to eq StreamItem.last.created_at.as_json
    expect(json[0]["updated_at"]).to eq StreamItem.last.updated_at.as_json
  end

  it "returns the course-specific activity stream" do
    @course1 = @course
    @course2 = course_with_student(user: @user, active_all: true).course
    @context = @course1
    @topic1 = discussion_topic_model
    @context = @course2
    @topic2 = discussion_topic_model
    json = api_call(:get,
                    "/api/v1/users/activity_stream.json",
                    { controller: "users", action: "activity_stream", format: "json" })
    expect(json.size).to eq 2
    expect(response.headers["Link"]).to be_present

    json = api_call(:get,
                    "/api/v1/users/activity_stream.json?per_page=1",
                    { controller: "users", action: "activity_stream", format: "json", per_page: "1" })
    expect(json.size).to eq 1
    expect(response.headers["Link"]).to be_present

    json = api_call(:get,
                    "/api/v1/courses/#{@course2.id}/activity_stream.json",
                    { controller: "courses", action: "activity_stream", course_id: @course2.to_param, format: "json" })
    expect(json.size).to eq 1
    expect(json.first["discussion_topic_id"]).to eq @topic2.id
    expect(response.headers["Link"]).to be_present
  end

  it "returns the group-specific activity stream" do
    group_with_user
    @group1 = @group
    group_with_user(user: @user)
    @group2 = @group

    @context = @group1
    @topic1 = discussion_topic_model
    @context = @group2
    @topic2 = discussion_topic_model

    json = api_call(:get,
                    "/api/v1/users/activity_stream.json",
                    { controller: "users", action: "activity_stream", format: "json" })
    expect(json.size).to eq 2
    expect(response.headers["Link"]).to be_present

    json = api_call(:get,
                    "/api/v1/groups/#{@group1.id}/activity_stream.json",
                    { controller: "groups", action: "activity_stream", group_id: @group1.to_param, format: "json" })
    expect(json.size).to eq 1
    expect(json.first["discussion_topic_id"]).to eq @topic1.id
    expect(response.headers["Link"]).to be_present
  end

  context "stream items" do
    it "hides the specified stream_item" do
      discussion_topic_model
      expect(@user.stream_item_instances.where(hidden: false).count).to eq 1

      json = api_call(:delete,
                      "/api/v1/users/self/activity_stream/#{StreamItem.last.id}",
                      { action: "ignore_stream_item", controller: "users", format: "json", id: StreamItem.last.id.to_param })

      expect(@user.stream_item_instances.where(hidden: false).count).to eq 0
      expect(@user.stream_item_instances.where(hidden: true).count).to eq 1
      expect(json).to eq({ "hidden" => true })
    end

    it "hides all of the stream items" do
      3.times do |n|
        dt = discussion_topic_model title: "Test #{n}"
        dt.discussion_subentries.create! message: "test", user: @user
      end
      expect(@user.stream_item_instances.where(hidden: false).count).to eq 3

      json = api_call(:delete,
                      "/api/v1/users/self/activity_stream",
                      { action: "ignore_all_stream_items", controller: "users", format: "json" })

      expect(@user.stream_item_instances.where(hidden: false).count).to eq 0
      expect(@user.stream_item_instances.where(hidden: true).count).to eq 3
      expect(json).to eq({ "hidden" => true })
    end
  end

  it "returns DiscussionEntry stream item with correct data" do
    @user = user_factory
    @teacher = user_factory

    dt = discussion_topic_model

    entry = dt.discussion_entries.new(user_id: @user, message: "you've been mentioned")
    entry.mentions.new(user_id: @teacher, root_account_id: dt.root_account_id)
    entry.save!

    dt.generate_stream_items([@user])

    json = api_call(:get,
                    "/api/v1/users/self/activity_stream?only_active_courses=1",
                    { controller: "users", action: "activity_stream", format: "json", only_active_courses: "1" })

    expect(json.last["type"]).to eq("DiscussionEntry")
    expect(json.last["message"]).to eq("you've been mentioned")
    expect(json.last["author_name"]).to eq("value for name")
  end
end
