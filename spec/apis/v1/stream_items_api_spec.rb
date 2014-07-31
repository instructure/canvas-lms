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

describe UsersController, type: :request do
  include Api
  include Api::V1::Assignment

  before do
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
    json.size.should == 0
    google_docs_collaboration_model(:user_id => @user.id)
    @context = @course
    @topic1 = discussion_topic_model
    # introduce a dangling StreamItemInstance
    StreamItem.where(:id => @user.visible_stream_item_instances.last.stream_item_id).delete_all
    json = api_call(:get, "/api/v1/users/activity_stream.json",
                    { :controller => "users", :action => "activity_stream", :format => 'json' })
    json.size.should == 1
  end

  it "should return the activity stream summary" do
    @context = @course
    discussion_topic_model
    discussion_topic_model(:user => @user)
    conversation(User.create, @user)
    Notification.create(:name => 'Assignment Due Date Changed', :category => "TestImmediately")
    Assignment.any_instance.stubs(:created_at).returns(4.hours.ago)
    assignment_model(:course => @course)
    @assignment.update_attribute(:due_at, 1.week.from_now)
    json = api_call(:get, "/api/v1/users/self/activity_stream/summary.json",
                    { :controller => "users", :action => "activity_stream_summary", :format => 'json' })
    json.should == [{"type" => "Conversation", "count" => 1, "unread_count" => 0, "notification_category" => nil}, # conversations don't currently set the unread state on stream items
                    {"type" => "DiscussionTopic", "count" => 2, "unread_count" => 1, "notification_category" => nil},
                    {"type" => "Message", "count" => 1, "unread_count" => 0, "notification_category" => "TestImmediately"} # check a broadcast-policy-based one
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
    json.should == [{
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
    json.first['require_initial_post'].should == true
    json.first['user_has_posted'].should == false
    json.first['root_discussion_entries'].should == []
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
    json.first['require_initial_post'].should == true
    json.first['user_has_posted'].should == true
    json.first['root_discussion_entries'].should == [
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
    json.should == [{
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
    json.should == {
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
    }
  end

  it "should format Message" do
    message_model(:user => @user, :to => 'dashboard', :notification => notification_model)
    json = api_call(:get, "/api/v1/users/activity_stream.json",
                    { :controller => "users", :action => "activity_stream", :format => 'json' })
    json.should == [{
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
    json.should == [{
      'id' => StreamItem.last.id,
      'title' => "assignment 1",
      'message' => nil,
      'type' => 'Submission',
      'read_state' => StreamItemInstance.last.read?,
      'created_at' => StreamItem.last.created_at.as_json,
      'updated_at' => StreamItem.last.updated_at.as_json,
      'grade' => '12',
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
      'preview_url' => "http://www.example.com/courses/#{@course.id}/assignments/#{@assignment.id}/submissions/#{@user.id}?preview=1",
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
          'avatar_image_url' => User.avatar_fallback_url
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
          'avatar_image_url' => User.avatar_fallback_url
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
        'start_at' => @course.start_at.as_json,
        'id' => @course.id,
        'course_code' => @course.course_code,
        'calendar' => { 'ics' => "http://www.example.com/feeds/calendars/course_#{@course.uuid}.ics" },
        'hide_final_grades' => false,
        'html_url' => course_url(@course, :host => HostUrl.context_host(@course)),
        'default_view' => 'feed',
        'workflow_state' => 'available',
        'public_syllabus' => false,
        'storage_quota_mb' => @course.storage_quota_mb,
        'apply_assignment_group_weights' => false
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
    json.should == [{
      'id' => StreamItem.last.id,
      'title' => "assignment 1",
      'message' => nil,
      'type' => 'Submission',
      'read_state' => StreamItemInstance.last.read?,
      'created_at' => StreamItem.last.created_at.as_json,
      'updated_at' => StreamItem.last.updated_at.as_json,
      'grade' => nil,
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
      'preview_url' => "http://www.example.com/courses/#{@course.id}/assignments/#{@assignment.id}/submissions/#{@user.id}?preview=1",
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
          'avatar_image_url' => User.avatar_fallback_url
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
          'avatar_image_url' => User.avatar_fallback_url
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
        'start_at' => @course.start_at.as_json,
        'id' => @course.id,
        'course_code' => @course.course_code,
        'calendar' => { 'ics' => "http://www.example.com/feeds/calendars/course_#{@course.uuid}.ics" },
        'hide_final_grades' => false,
        'html_url' => course_url(@course, :host => HostUrl.context_host(@course)),
        'default_view' => 'feed',
        'workflow_state' => 'available',
        'public_syllabus' => false,
        'storage_quota_mb' => @course.storage_quota_mb,
        'apply_assignment_group_weights' => false
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

    json[0]['grade'].should == '12'
    json[0]['score'].should == 12
    json[0]['workflow_state'].should == 'graded'
    json[0]['submission_comments'].should == []
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
    json.should == []
  end

  it "should format Collaboration" do
    google_docs_collaboration_model(:user_id => @user.id, :title => 'hey')
    json = api_call(:get, "/api/v1/users/activity_stream.json",
                    { :controller => "users", :action => "activity_stream", :format => 'json' })
    json.should == [{
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
    json.should == [{
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

  it "should return the course-specific activity stream" do
    @course1 = @course
    @course2 = course_with_student(:user => @user, :active_all => true).course
    @context = @course1
    @topic1 = discussion_topic_model
    @context = @course2
    @topic2 = discussion_topic_model
    json = api_call(:get, "/api/v1/users/activity_stream.json",
                    { :controller => "users", :action => "activity_stream", :format => 'json' })
    json.size.should == 2
    response.headers['Link'].should be_present

    json = api_call(:get, "/api/v1/users/activity_stream.json?per_page=1",
                    { :controller => "users", :action => "activity_stream", :format => 'json', :per_page => '1' })
    json.size.should == 1
    response.headers['Link'].should be_present

    json = api_call(:get, "/api/v1/courses/#{@course2.id}/activity_stream.json",
                    { :controller => "courses", :action => "activity_stream", :course_id => @course2.to_param, :format => 'json' })
    json.size.should == 1
    json.first['discussion_topic_id'].should == @topic2.id
    response.headers['Link'].should be_present
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
    json.size.should == 2
    response.headers['Link'].should be_present

    json = api_call(:get, "/api/v1/groups/#{@group1.id}/activity_stream.json",
                    { :controller => "groups", :action => "activity_stream", :group_id => @group1.to_param, :format => 'json' })
    json.size.should == 1
    json.first['discussion_topic_id'].should == @topic1.id
    response.headers['Link'].should be_present
  end

  context "stream items" do
    it "should hide the specified stream_item" do
      discussion_topic_model
      @user.stream_item_instances.where(:hidden => false).count.should == 1

      json = api_call(:delete, "/api/v1/users/self/activity_stream/#{StreamItem.last.id}",
                      {:action => "ignore_stream_item", :controller => "users", :format => 'json', :id => StreamItem.last.id.to_param})

      @user.stream_item_instances.where(:hidden => false).count.should == 0
      @user.stream_item_instances.where(:hidden => true).count.should == 1
      json.should == {'hidden' => true}
    end

    it "should hide all of the stream items" do
      3.times do |n|
        dt = discussion_topic_model title: "Test #{n}"
        dt.discussion_subentries.create! :message => "test", :user => @user
      end
      @user.stream_item_instances.where(:hidden => false).count.should == 3

      json = api_call(:delete, "/api/v1/users/self/activity_stream",
                      {:action => "ignore_all_stream_items", :controller => "users", :format => 'json'})

      @user.stream_item_instances.where(:hidden => false).count.should == 0
      @user.stream_item_instances.where(:hidden => true).count.should == 3
      json.should == {'hidden' => true}
    end
  end
end
