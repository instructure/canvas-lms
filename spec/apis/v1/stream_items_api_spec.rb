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

require File.expand_path(File.dirname(__FILE__) + '/../api_spec_helper')
require File.expand_path(File.dirname(__FILE__) + '/../../sharding_spec_helper')

describe UsersController, type: :request do
  include Api
  include Api::V1::Assignment

  before :once do
    course_with_student(:active_all => true)
  end

  it "should check for auth" do
    get("/api/v1/users/self/activity_stream")
    assert_status(401)

    @course = factory_with_protected_attributes(Course, course_valid_attributes)
    raw_api_call(:get, "/api/v1/courses/#{@course.id}/activity_stream",
                :controller => "courses", :action => "activity_stream", :format => "json", :course_id => @course.to_param)
    assert_status(401)
  end

  it "should return the activity stream" do
    json = api_call(:get, "/api/v1/users/activity_stream.json",
                    { :controller => "users", :action => "activity_stream", :format => 'json' })
    expect(json.size).to eq 0
    google_docs_collaboration_model(:user_id => @user.id)
    @context = @course
    @topic1 = discussion_topic_model
    # introduce a dangling StreamItemInstance
    StreamItem.where(:id => @user.visible_stream_item_instances.last.stream_item_id).delete_all
    json = api_call(:get, "/api/v1/users/activity_stream.json",
                    { :controller => "users", :action => "activity_stream", :format => 'json' })
    expect(json.size).to eq 1
  end

  it "should return the activity stream summary" do
    @context = @course
    discussion_topic_model
    discussion_topic_model(:user => @user)
    announcement_model
    conversation(User.create, @user)
    Notification.create(:name => 'Assignment Due Date Changed', :category => "TestImmediately")
    Assignment.any_instance.stubs(:created_at).returns(4.hours.ago)
    assignment_model(:course => @course)
    @assignment.update_attribute(:due_at, 1.week.from_now)
    json = api_call(:get, "/api/v1/users/self/activity_stream/summary.json",
                    { :controller => "users", :action => "activity_stream_summary", :format => 'json' })

    expect(json).to eq [
                    {"type" => "Announcement", "count" => 1, "unread_count" => 1, "notification_category" => nil},
                    {"type" => "Conversation", "count" => 1, "unread_count" => 0, "notification_category" => nil}, # conversations don't currently set the unread state on stream items
                    {"type" => "DiscussionTopic", "count" => 2, "unread_count" => 1, "notification_category" => nil},
                    {"type" => "Message", "count" => 1, "unread_count" => 0, "notification_category" => "TestImmediately"} # check a broadcast-policy-based one
                   ]
  end

  context "cross-shard activity stream summary" do
    specs_require_sharding
    it "should return the activity stream summary with cross-shard items" do
      @student = user(:active_all => true)
      @shard1.activate do
        @account = Account.create!
        course(:active_all => true, :account => @account)
        @course.enroll_student(@student).accept!
        @context = @course
        discussion_topic_model
        discussion_topic_model(:user => @user)
        announcement_model
        conversation(User.create, @user)
        Notification.create(:name => 'Assignment Due Date Changed', :category => "TestImmediately")
        Assignment.any_instance.stubs(:created_at).returns(4.hours.ago)
        assignment_model(:course => @course)
        @assignment.update_attribute(:due_at, 1.week.from_now)
        @assignment.update_attribute(:due_at, 2.weeks.from_now)
        # manually set the pre-datafixup state for one of them
        val = StreamItem.where(:asset_type => "Message", :id => @user.visible_stream_item_instances.map(&:stream_item)).
          limit(1).update_all(:notification_category => nil)
      end
      json = api_call(:get, "/api/v1/users/self/activity_stream/summary.json",
        { :controller => "users", :action => "activity_stream_summary", :format => 'json' })

      expect(json).to eq [
            {"type" => "Announcement", "count" => 1, "unread_count" => 1, "notification_category" => nil},
            {"type" => "Conversation", "count" => 1, "unread_count" => 0, "notification_category" => nil}, # conversations don't currently set the unread state on stream items
            {"type" => "DiscussionTopic", "count" => 2, "unread_count" => 1, "notification_category" => nil},
            {"type" => "Message", "count" => 2, "unread_count" => 0, "notification_category" => "TestImmediately"} # check a broadcast-policy-based one
          ]
    end
  end

  it "should still return notification_category in the the activity stream summary if not set (yet)" do
    # TODO: can remove this spec as well as the code in lib/api/v1/stream_item once the datafixup has been run
    @context = @course
    Notification.create(:name => 'Assignment Due Date Changed', :category => "TestImmediately")
    Assignment.any_instance.stubs(:created_at).returns(4.hours.ago)
    assignment_model(:course => @course)
    @assignment.update_attribute(:due_at, 1.week.from_now)
    @assignment.update_attribute(:due_at, 2.weeks.from_now)
    # manually set the pre-datafixup state for one of them
    StreamItem.where(:id => @user.visible_stream_item_instances.first.stream_item).update_all(:notification_category => nil)
    json = api_call(:get, "/api/v1/users/self/activity_stream/summary.json",
      { :controller => "users", :action => "activity_stream_summary", :format => 'json' })

    expect(json).to eq [
          {"type" => "Message", "count" => 2, "unread_count" => 0, "notification_category" => "TestImmediately"} # check a broadcast-policy-based one
        ]
  end

  it "should format DiscussionTopic" do
    @context = @course
    discussion_topic_model
    @topic.require_initial_post = true
    @topic.save
    @topic.reply_from(:user => @user, :text => 'hai')
    json = api_call(:get, "/api/v1/users/activity_stream.json",
                    { :controller => "users", :action => "activity_stream", :format => 'json' })
    expect(json).to eq [{
      'id' => StreamItem.last.id,
      'discussion_topic_id' => @topic.id,
      'title' => "value for title",
      'message' => 'value for message',
      'type' => 'DiscussionTopic',
      'read_state' => StreamItemInstance.last.read?,
      'context_type' => "Course",
      'created_at' => StreamItem.last.created_at.as_json,
      'updated_at' => StreamItem.last.updated_at.as_json,
      'require_initial_post' => true,
      'user_has_posted' => true,
      'html_url' => "http://www.example.com/courses/#{@context.id}/discussion_topics/#{@topic.id}",

      'total_root_discussion_entries' => 1,
      'root_discussion_entries' => [
        {
          'user' => { 'user_id' => @user.id, 'user_name' => 'User' },
          'message' => 'hai',
        },
      ],
      'course_id' => @course.id,
    }]
  end

  it "should not return discussion entries if user has not posted" do
    @context = @course
    course_with_teacher(:course => @context, :active_all => true)
    discussion_topic_model
    @user = @student
    @topic.require_initial_post = true
    @topic.save
    @topic.reply_from(:user => @teacher, :text => 'hai')
    json = api_call(:get, "/api/v1/users/activity_stream.json",
                    { :controller => "users", :action => "activity_stream", :format => 'json' })
    expect(json.first['require_initial_post']).to eq true
    expect(json.first['user_has_posted']).to eq false
    expect(json.first['root_discussion_entries']).to eq []
  end

  it "should return discussion entries to admin without posting " do
    @context = @course
    course_with_teacher(:course => @context, :name => "Teach", :active_all => true)
    discussion_topic_model
    @topic.require_initial_post = true
    @topic.save
    @topic.reply_from(:user => @student, :text => 'hai')
    json = api_call(:get, "/api/v1/users/activity_stream.json",
                    { :controller => "users", :action => "activity_stream", :format => 'json' })
    expect(json.first['require_initial_post']).to eq true
    expect(json.first['user_has_posted']).to eq true
    expect(json.first['root_discussion_entries']).to eq [
            {
              'user' => { 'user_id' => @student.id, 'user_name' => 'User' },
              'message' => 'hai',
            },
          ]
  end

  it "should translate user content in discussion topic" do
    should_translate_user_content(@course) do |user_content|
      @context = @course
      discussion_topic_model(:message => user_content)
      json = api_call(:get, "/api/v1/users/activity_stream.json",
                      { :controller => "users", :action => "activity_stream", :format => 'json' })
      json.first['message']
    end
  end

  it "should translate user content in discussion entry" do
    should_translate_user_content(@course) do |user_content|
      @context = @course
      discussion_topic_model
      @topic.reply_from(:user => @user, :html => user_content)
      json = api_call(:get, "/api/v1/users/activity_stream.json",
                      { :controller => "users", :action => "activity_stream", :format => 'json' })
      json.first['root_discussion_entries'].first['message']
    end
  end

  it "should format Announcement" do
    @context = @course
    announcement_model
    @a.reply_from(:user => @user, :text => 'hai')
    json = api_call(:get, "/api/v1/users/activity_stream.json",
                    { :controller => "users", :action => "activity_stream", :format => 'json' })
    expect(json).to eq [{
      'id' => StreamItem.last.id,
      'announcement_id' => @a.id,
      'title' => "value for title",
      'message' => 'value for message',
      'type' => 'Announcement',
      'read_state' => StreamItemInstance.last.read?,
      'context_type' => "Course",
      'created_at' => StreamItem.last.created_at.as_json,
      'updated_at' => StreamItem.last.updated_at.as_json,
      'require_initial_post' => nil,
      'user_has_posted' => nil,
      'html_url' => "http://www.example.com/courses/#{@context.id}/announcements/#{@a.id}",

      'total_root_discussion_entries' => 1,
      'root_discussion_entries' => [
        {
          'user' => { 'user_id' => @user.id, 'user_name' => 'User' },
          'message' => 'hai',
        },
      ],
      'course_id' => @course.id,
    }]
  end

  it "should translate user content in announcement messages" do
    should_translate_user_content(@course) do |user_content|
      @context = @course
      announcement_model(:message => user_content)
      json = api_call(:get, "/api/v1/users/activity_stream.json",
                      { :controller => "users", :action => "activity_stream", :format => 'json' })
      json.first['message']
    end
  end

  it "should translate user content in announcement discussion entries" do
    should_translate_user_content(@course) do |user_content|
      @context = @course
      announcement_model
      @a.reply_from(:user => @user, :html => user_content)
      json = api_call(:get, "/api/v1/users/activity_stream.json",
                      { :controller => "users", :action => "activity_stream", :format => 'json' })
      json.first['root_discussion_entries'].first['message']
    end
  end

  it "should format Conversation" do
    @sender = User.create!(:name => 'sender')
    @conversation = Conversation.initiate([@user, @sender], false)
    @conversation.add_message(@sender, "hello")
    @message = @conversation.conversation_messages.last
    json = api_call(:get, "/api/v1/users/activity_stream.json",
                    { :controller => "users", :action => "activity_stream", :format => 'json' }).first
    expect(json).to eq({
      'id' => StreamItem.last.id,
      'conversation_id' => @conversation.id,
      'type' => 'Conversation',
      'read_state' => StreamItemInstance.last.read?,
      'created_at' => StreamItem.last.created_at.as_json,
      'updated_at' => StreamItem.last.updated_at.as_json,
      'title' => nil,
      'message' => nil,

      'private' => false,
      'html_url' => "http://www.example.com/conversations/#{@conversation.id}",

      'participant_count' => 2
    })
  end

  it "should format Message" do
    message_model(:user => @user, :to => 'dashboard', :notification => notification_model)
    json = api_call(:get, "/api/v1/users/activity_stream.json",
                    { :controller => "users", :action => "activity_stream", :format => 'json' })
    expect(json).to eq [{
      'id' => StreamItem.last.id,
      'message_id' => @message.id,
      'title' => "value for subject",
      'message' => 'value for body',
      'type' => 'Message',
      'read_state' => StreamItemInstance.last.read?,
      'created_at' => StreamItem.last.created_at.as_json,
      'updated_at' => StreamItem.last.updated_at.as_json,

      'notification_category' => 'TestImmediately',
      'url' => nil,
      'html_url' => nil,
    }]
  end

  it "should format graded Submission with comments" do
    #set @domain_root_account
    @domain_root_account = Account.default

    @assignment = @course.assignments.create!(:title => 'assignment 1', :description => 'hai', :points_possible => '14.2', :submission_types => 'online_text_entry')
    @teacher = User.create!(:name => 'teacher')
    @course.enroll_teacher(@teacher)
    @sub = @assignment.grade_student(@user, { :grade => '12', :grader => @teacher}).first
    @sub.workflow_state = 'submitted'
    @sub.submission_comments.create!(:comment => 'c1', :author => @teacher, :recipient_id => @user.id)
    @sub.submission_comments.create!(:comment => 'c2', :author => @user, :recipient_id => @teacher.id)
    @sub.save!
    json = api_call(:get, "/api/v1/users/activity_stream.json",
                    { :controller => "users", :action => "activity_stream", :format => 'json' })
    @assignment.reload
    assign_json = assignment_json(@assignment, @user, session,
                                  include_discussion_topic: false)
    assign_json['created_at'] = @assignment.created_at.as_json
    assign_json['updated_at'] = @assignment.updated_at.as_json
    assign_json['title'] = @assignment.title
    expect(json).to eq [{
      'id' => StreamItem.last.id,
      'submission_id' => @sub.id,
      'title' => "assignment 1",
      'message' => nil,
      'type' => 'Submission',
      'read_state' => StreamItemInstance.last.read?,
      'created_at' => StreamItem.last.created_at.as_json,
      'updated_at' => StreamItem.last.updated_at.as_json,
      'grade' => '12',
      'excused' => false,
      'grader_id' => @teacher.id,
      'graded_at' => @sub.graded_at.as_json,
      'score' => 12,
      'html_url' => "http://www.example.com/courses/#{@course.id}/assignments/#{@assignment.id}/submissions/#{@user.id}",
      'workflow_state' => 'graded',
      'late' => false,
      'assignment' => assign_json,
      'assignment_id' => @assignment.id,
      'attempt' => nil,
      'body' => nil,
      'grade_matches_current_submission' => true,
      'preview_url' => "http://www.example.com/courses/#{@course.id}/assignments/#{@assignment.id}/submissions/#{@user.id}?preview=1&version=1",
      'submission_type' => nil,
      'submitted_at' => nil,
      'url' => nil,
      'user_id' => @sub.user_id,

      'submission_comments' => [{
        'body' => 'c1',
        'comment' => 'c1',
        'author' => {
          'id' => @teacher.id,
          'display_name' => 'teacher',
          'html_url' => "http://www.example.com/courses/#{@course.id}/users/#{@teacher.id}",
          'avatar_image_url' => User.avatar_fallback_url(nil, request)
        },
        'author_name' => 'teacher',
        'author_id' => @teacher.id,
        'created_at' => @sub.submission_comments[0].created_at.as_json,
        'id' => @sub.submission_comments[0].id
      },
      {
        'body' => 'c2',
        'comment' => 'c2',
        'author' => {
          'id' => @user.id,
          'display_name' => 'User',
          'html_url' => "http://www.example.com/courses/#{@course.id}/users/#{@user.id}",
          'avatar_image_url' => User.avatar_fallback_url(nil, request)
        },
        'author_name' => 'User',
        'author_id' => @user.id,
        'created_at' => @sub.submission_comments[1].created_at.as_json,
        'id' => @sub.submission_comments[1].id
      },],

      'course' => {
        'name' => @course.name,
        'end_at' => @course.end_at,
        'account_id' => @course.account_id,
        'root_account_id' => @course.root_account_id,
        'enrollment_term_id' => @course.enrollment_term_id,
        'start_at' => @course.start_at.as_json,
        'grading_standard_id'=>nil,
        'id' => @course.id,
        'course_code' => @course.course_code,
        'calendar' => { 'ics' => "http://www.example.com/feeds/calendars/course_#{@course.uuid}.ics" },
        'hide_final_grades' => false,
        'html_url' => course_url(@course, :host => HostUrl.context_host(@course)),
        'default_view' => 'feed',
        'workflow_state' => 'available',
        'public_syllabus' => false,
        'is_public' => @course.is_public,
        'is_public_to_auth_users' => @course.is_public_to_auth_users,
        'storage_quota_mb' => @course.storage_quota_mb,
        'apply_assignment_group_weights' => false,
        'restrict_enrollments_to_course_dates' => false
      },

      'user' => {
        "name"=>"User", "sortable_name"=>"User", "id"=>@sub.user_id, "short_name"=>"User"
      },

      'context_type' => 'Course',
      'course_id' => @course.id,
    }]
  end

  it "should format ungraded Submission with comments" do
    #set @domain_root_account
    @domain_root_account = Account.default

    @assignment = @course.assignments.create!(:title => 'assignment 1', :description => 'hai', :points_possible => '14.2', :submission_types => 'online_text_entry')
    @teacher = User.create!(:name => 'teacher')
    @course.enroll_teacher(@teacher)
    @sub = @assignment.grade_student(@user, { :grade => nil }).first
    @sub.workflow_state = 'submitted'
    @sub.submission_comments.create!(:comment => 'c1', :author => @teacher, :recipient_id => @user.id)
    @sub.submission_comments.create!(:comment => 'c2', :author => @user, :recipient_id => @teacher.id)
    @sub.save!
    json = api_call(:get, "/api/v1/users/activity_stream.json",
                    { :controller => "users", :action => "activity_stream", :format => 'json' })
    @assignment.reload
    assign_json = assignment_json(@assignment, @user, session,
                                  include_discussion_topic: false)
    assign_json['created_at'] = @assignment.created_at.as_json
    assign_json['updated_at'] = @assignment.updated_at.as_json
    assign_json['title'] = @assignment.title
    expect(json).to eq [{
      'id' => StreamItem.last.id,
      'submission_id' => @sub.id,
      'title' => "assignment 1",
      'message' => nil,
      'type' => 'Submission',
      'read_state' => StreamItemInstance.last.read?,
      'created_at' => StreamItem.last.created_at.as_json,
      'updated_at' => StreamItem.last.updated_at.as_json,
      'grade' => nil,
      'excused' => nil,
      'grader_id' => nil,
      'graded_at' => nil,
      'score' => nil,
      'html_url' => "http://www.example.com/courses/#{@course.id}/assignments/#{@assignment.id}/submissions/#{@user.id}",
      'workflow_state' => 'unsubmitted',
      'late' => false,
      'assignment' => assign_json,
      'assignment_id' => @assignment.id,
      'attempt' => nil,
      'body' => nil,
      'grade_matches_current_submission' => nil,
      'preview_url' => "http://www.example.com/courses/#{@course.id}/assignments/#{@assignment.id}/submissions/#{@user.id}?preview=1&version=1",
      'submission_type' => nil,
      'submitted_at' => nil,
      'url' => nil,
      'user_id' => @sub.user_id,

      'submission_comments' => [{
        'body' => 'c1',
        'comment' => 'c1',
        'author' => {
          'id' => @teacher.id,
          'display_name' => 'teacher',
          'html_url' => "http://www.example.com/courses/#{@course.id}/users/#{@teacher.id}",
          'avatar_image_url' => User.avatar_fallback_url(nil, request)
        },
        'author_name' => 'teacher',
        'author_id' => @teacher.id,
        'created_at' => @sub.submission_comments[0].created_at.as_json,
        'id' => @sub.submission_comments[0].id
      },
      {
        'body' => 'c2',
        'comment' => 'c2',
        'author' => {
          'id' => @user.id,
          'display_name' => 'User',
          'html_url' => "http://www.example.com/courses/#{@course.id}/users/#{@user.id}",
          'avatar_image_url' => User.avatar_fallback_url(nil, request)
        },
        'author_name' => 'User',
        'author_id' => @user.id,
        'created_at' => @sub.submission_comments[1].created_at.as_json,
        'id' => @sub.submission_comments[1].id
      },],

      'course' => {
        'name' => @course.name,
        'end_at' => @course.end_at,
        'account_id' => @course.account_id,
        'root_account_id' => @course.root_account_id,
        'enrollment_term_id' => @course.enrollment_term_id,
        'start_at' => @course.start_at.as_json,
        'grading_standard_id'=>nil,
        'id' => @course.id,
        'course_code' => @course.course_code,
        'calendar' => { 'ics' => "http://www.example.com/feeds/calendars/course_#{@course.uuid}.ics" },
        'hide_final_grades' => false,
        'html_url' => course_url(@course, :host => HostUrl.context_host(@course)),
        'default_view' => 'feed',
        'workflow_state' => 'available',
        'public_syllabus' => false,
        'is_public' => @course.is_public,
        'is_public_to_auth_users' => @course.is_public_to_auth_users,
        'storage_quota_mb' => @course.storage_quota_mb,
        'apply_assignment_group_weights' => false,
        'restrict_enrollments_to_course_dates' => false
      },

      'user' => {
        "name"=>"User", "sortable_name"=>"User", "id"=>@sub.user_id, "short_name"=>"User"
      },

      'context_type' => 'Course',
      'course_id' => @course.id,
    }]
  end

  it "should format graded Submission without comments" do
    @assignment = @course.assignments.create!(:title => 'assignment 1', :description => 'hai', :points_possible => '14.2', :submission_types => 'online_text_entry')
    @teacher = User.create!(:name => 'teacher')
    @course.enroll_teacher(@teacher)
    @sub = @assignment.grade_student(@user, { :grade => '12' }).first
    @sub.workflow_state = 'submitted'
    @sub.save!
    json = api_call(:get, "/api/v1/users/activity_stream.json",
                    { :controller => "users", :action => "activity_stream", :format => 'json' })

    expect(json[0]['grade']).to eq '12'
    expect(json[0]['score']).to eq 12
    expect(json[0]['workflow_state']).to eq 'graded'
    expect(json[0]['submission_comments']).to eq []
  end

  it "should not format ungraded Submission without comments" do
    @assignment = @course.assignments.create!(:title => 'assignment 1', :description => 'hai', :points_possible => '14.2', :submission_types => 'online_text_entry')
    @teacher = User.create!(:name => 'teacher')
    @course.enroll_teacher(@teacher)
    @sub = @assignment.grade_student(@user, { :grade => nil }).first
    @sub.workflow_state = 'submitted'
    @sub.save!
    json = api_call(:get, "/api/v1/users/activity_stream.json",
                    { :controller => "users", :action => "activity_stream", :format => 'json' })
    expect(json).to eq []
  end

  it "should format Collaboration" do
    google_docs_collaboration_model(:user_id => @user.id, :title => 'hey')
    json = api_call(:get, "/api/v1/users/activity_stream.json",
                    { :controller => "users", :action => "activity_stream", :format => 'json' })
    expect(json).to eq [{
      'id' => StreamItem.last.id,
      'collaboration_id' => @collaboration.id,
      'title' => "hey",
      'message' => nil,
      'type' => 'Collaboration',
      'read_state' => StreamItemInstance.last.read?,
      'context_type' => 'Course',
      'course_id' => @course.id,
      'html_url' => "http://www.example.com/courses/#{@course.id}/collaborations/#{@collaboration.id}",
      'created_at' => StreamItem.last.created_at.as_json,
      'updated_at' => StreamItem.last.updated_at.as_json,
    }]
  end

  it "should format WebConference" do
    WebConference.stubs(:plugins).returns(
        [OpenObject.new(:id => "big_blue_button", :settings => {:domain => "bbb.instructure.com", :secret_dec => "secret"}, :valid_settings? => true, :enabled? => true),]
    )
    @conference = BigBlueButtonConference.create!(:title => 'myconf', :user => @user, :description => 'mydesc', :conference_type => 'big_blue_button', :context => @course)
    json = api_call(:get, "/api/v1/users/activity_stream.json",
                    { :controller => "users", :action => "activity_stream", :format => 'json' })
    expect(json).to eq [{
      'id' => StreamItem.last.id,
      'web_conference_id' => @conference.id,
      'title' => "myconf",
      'type' => 'WebConference',
      'read_state' => StreamItemInstance.last.read?,
      'message' => 'mydesc',
      'context_type' => 'Course',
      'course_id' => @course.id,
      'html_url' => "http://www.example.com/courses/#{@course.id}/conferences/#{@conference.id}",
      'created_at' => StreamItem.last.created_at.as_json,
      'updated_at' => StreamItem.last.updated_at.as_json,
    }]
  end

  it "should format AssessmentRequest" do
    assignment = assignment_model(:course => @course)
    submission = submission_model(assignment: assignment, user: @student)
    assessor_submission = submission_model(assignment: assignment, user: @user)
    assessment_request = AssessmentRequest.create!(assessor: @user, asset: submission,
                                                    user: @student, assessor_asset: assessor_submission)
    assessment_request.workflow_state = 'assigned'
    assessment_request.save

    json = api_call(:get, "/api/v1/users/activity_stream.json",
                    { :controller => "users", :action => "activity_stream", :format => 'json' })

    expect(json[0]['id']).to eq StreamItem.last.id
    expect(json[0]['title']).to eq "Peer Review for #{assignment.title}"
    expect(json[0]['type']).to eq 'AssessmentRequest'
    expect(json[0]['message']).to eq nil
    expect(json[0]['context_type']).to eq 'Course'
    expect(json[0]['course_id']).to eq @course.id
    expect(json[0]['assessment_request_id']).to eq assessment_request.id
    expect(json[0]['html_url']).to eq "http://www.example.com/courses/#{@course.id}/assignments/#{assignment.id}/submissions/#{assessment_request.user_id}"
    expect(json[0]['created_at']).to eq StreamItem.last.created_at.as_json
    expect(json[0]['updated_at']).to eq StreamItem.last.updated_at.as_json
  end

  it "should return the course-specific activity stream" do
    @course1 = @course
    @course2 = course_with_student(:user => @user, :active_all => true).course
    @context = @course1
    @topic1 = discussion_topic_model
    @context = @course2
    @topic2 = discussion_topic_model
    json = api_call(:get, "/api/v1/users/activity_stream.json",
                    { :controller => "users", :action => "activity_stream", :format => 'json' })
    expect(json.size).to eq 2
    expect(response.headers['Link']).to be_present

    json = api_call(:get, "/api/v1/users/activity_stream.json?per_page=1",
                    { :controller => "users", :action => "activity_stream", :format => 'json', :per_page => '1' })
    expect(json.size).to eq 1
    expect(response.headers['Link']).to be_present

    json = api_call(:get, "/api/v1/courses/#{@course2.id}/activity_stream.json",
                    { :controller => "courses", :action => "activity_stream", :course_id => @course2.to_param, :format => 'json' })
    expect(json.size).to eq 1
    expect(json.first['discussion_topic_id']).to eq @topic2.id
    expect(response.headers['Link']).to be_present
  end

  it "should return the group-specific activity stream" do
    group_with_user
    @group1 = @group
    group_with_user(:user => @user)
    @group2 = @group

    @context = @group1
    @topic1 = discussion_topic_model
    @context = @group2
    @topic2 = discussion_topic_model

    json = api_call(:get, "/api/v1/users/activity_stream.json",
                    { :controller => "users", :action => "activity_stream", :format => 'json' })
    expect(json.size).to eq 2
    expect(response.headers['Link']).to be_present

    json = api_call(:get, "/api/v1/groups/#{@group1.id}/activity_stream.json",
                    { :controller => "groups", :action => "activity_stream", :group_id => @group1.to_param, :format => 'json' })
    expect(json.size).to eq 1
    expect(json.first['discussion_topic_id']).to eq @topic1.id
    expect(response.headers['Link']).to be_present
  end

  context "stream items" do
    it "should hide the specified stream_item" do
      discussion_topic_model
      expect(@user.stream_item_instances.where(:hidden => false).count).to eq 1

      json = api_call(:delete, "/api/v1/users/self/activity_stream/#{StreamItem.last.id}",
                      {:action => "ignore_stream_item", :controller => "users", :format => 'json', :id => StreamItem.last.id.to_param})

      expect(@user.stream_item_instances.where(:hidden => false).count).to eq 0
      expect(@user.stream_item_instances.where(:hidden => true).count).to eq 1
      expect(json).to eq({'hidden' => true})
    end

    it "should hide all of the stream items" do
      3.times do |n|
        dt = discussion_topic_model title: "Test #{n}"
        dt.discussion_subentries.create! :message => "test", :user => @user
      end
      expect(@user.stream_item_instances.where(:hidden => false).count).to eq 3

      json = api_call(:delete, "/api/v1/users/self/activity_stream",
                      {:action => "ignore_all_stream_items", :controller => "users", :format => 'json'})

      expect(@user.stream_item_instances.where(:hidden => false).count).to eq 0
      expect(@user.stream_item_instances.where(:hidden => true).count).to eq 3
      expect(json).to eq({'hidden' => true})
    end
  end
end
