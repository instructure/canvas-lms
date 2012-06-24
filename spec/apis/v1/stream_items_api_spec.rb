#
# Copyright (C) 2011 Instructure, Inc.
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

describe UsersController, :type => :integration do
  before do
    course_with_student(:active_all => true)
  end

  it "should check for auth" do
    get("/api/v1/users/self/activity_stream")
    response.status.should == '401 Unauthorized'
    JSON.parse(response.body).should == {"message"=>"Invalid access token.", "status"=>"unauthorized"}

    @course = factory_with_protected_attributes(Course, course_valid_attributes)
    raw_api_call(:get, "/api/v1/courses/#{@course.id}/activity_stream",
                :controller => "courses", :action => "activity_stream", :format => "json", :course_id => @course.to_param)
    response.status.should == '401 Unauthorized'
    JSON.parse(response.body).should == {"message"=>"You are not authorized to perform that action.", "status"=>"unauthorized"}
  end

  it "should return the activity stream" do
    json = api_call(:get, "/api/v1/users/activity_stream.json",
                    { :controller => "users", :action => "activity_stream", :format => 'json' })
    json.size.should == 0
    google_docs_collaboration_model(:user_id => @user.id)
    @context = @course
    @topic1 = discussion_topic_model
    # introduce a dangling StreamItemInstance
    StreamItem.delete_all(:id => @user.visible_stream_item_instances.last.stream_item_id)
    json = api_call(:get, "/api/v1/users/activity_stream.json",
                    { :controller => "users", :action => "activity_stream", :format => 'json' })
    json.size.should == 1
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

  it "should format Conversation" do
    @sender = User.create!(:name => 'sender')
    @conversation = Conversation.initiate([@user.id, @sender.id], false)
    @conversation.add_message(@sender, "hello")
    @message = @conversation.conversation_messages.last
    json = api_call(:get, "/api/v1/users/activity_stream.json",
                    { :controller => "users", :action => "activity_stream", :format => 'json' }).first
    json.should == {
      'id' => StreamItem.last.id,
      'conversation_id' => @conversation.id,
      'type' => 'Conversation',
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
      'created_at' => StreamItem.last.created_at.as_json,
      'updated_at' => StreamItem.last.updated_at.as_json,

      'notification_category' => 'TestImmediately',
      'url' => nil,
      'html_url' => nil,
    }]
  end

  it "should format graded Submission with comments" do
    @assignment = @course.assignments.create!(:title => 'assignment 1', :description => 'hai', :points_possible => '14.2', :submission_types => 'online_text_entry')
    @teacher = User.create!(:name => 'teacher')
    @course.enroll_teacher(@teacher)
    @sub = @assignment.grade_student(@user, { :grade => '12' }).first
    @sub.workflow_state = 'submitted'
    @sub.submission_comments.create!(:comment => 'c1', :author => @teacher, :recipient_id => @user.id)
    @sub.submission_comments.create!(:comment => 'c2', :author => @user, :recipient_id => @teacher.id)
    @sub.save!
    json = api_call(:get, "/api/v1/users/activity_stream.json",
                    { :controller => "users", :action => "activity_stream", :format => 'json' })
    json.should == [{
      'id' => StreamItem.last.id,
      'title' => "assignment 1",
      'message' => nil,
      'type' => 'Submission',
      'created_at' => StreamItem.last.created_at.as_json,
      'updated_at' => StreamItem.last.updated_at.as_json,
      'grade' => '12',
      'score' => 12,
      'html_url' => "http://www.example.com/courses/#{@course.id}/assignments/#{@assignment.id}/submissions/#{@user.id}",

      'assignment' => {
        'title' => 'assignment 1',
        'id' => @assignment.id,
        'points_possible' => 14.2,
      },
      
      'submission_comments' => [{
        'body' => '<p>c1</p>',
        'user_name' => 'teacher',
        'user_id' => @teacher.id,
      },
      {
        'body' => '<p>c2</p>',
        'user_name' => 'User',
        'user_id' => @user.id,
      },],

      'context_type' => 'Course',
      'course_id' => @course.id,
    }]
  end
  
  it "should format ungraded Submission with comments" do
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
    json.should == [{
      'id' => StreamItem.last.id,
      'title' => "assignment 1",
      'message' => nil,
      'type' => 'Submission',
      'created_at' => StreamItem.last.created_at.as_json,
      'updated_at' => StreamItem.last.updated_at.as_json,
      'grade' => nil,
      'score' => nil,
      'html_url' => "http://www.example.com/courses/#{@course.id}/assignments/#{@assignment.id}/submissions/#{@user.id}",

      'assignment' => {
        'title' => 'assignment 1',
        'id' => @assignment.id,
        'points_possible' => 14.2,
      },
      
      'submission_comments' => [{
        'body' => '<p>c1</p>',
        'user_name' => 'teacher',
        'user_id' => @teacher.id,
      },
      {
        'body' => '<p>c2</p>',
        'user_name' => 'User',
        'user_id' => @user.id,
      },],

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
    json.should == [{
      'id' => StreamItem.last.id,
      'title' => "assignment 1",
      'message' => nil,
      'type' => 'Submission',
      'created_at' => StreamItem.last.created_at.as_json,
      'updated_at' => StreamItem.last.updated_at.as_json,
      'grade' => '12',
      'score' => 12,
      'html_url' => "http://www.example.com/courses/#{@course.id}/assignments/#{@assignment.id}/submissions/#{@user.id}",

      'assignment' => {
        'title' => 'assignment 1',
        'id' => @assignment.id,
        'points_possible' => 14.2,
      },

      'context_type' => 'Course',
      'course_id' => @course.id,
    }]
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
      'message' => 'mydesc',
      'context_type' => 'Course',
      'course_id' => @course.id,
      'html_url' => "http://www.example.com/courses/#{@course.id}/conferences/#{@conference.id}",
      'created_at' => StreamItem.last.created_at.as_json,
      'updated_at' => StreamItem.last.updated_at.as_json,
    }]
  end

  it "should format CollectionItem" do
    @user1 = @user
    group_with_user
    @user2 = @user
    @user = @user1
    @coll = @group.collections.create!
    UserFollow.create_follow(@user1, @coll)
    @item = collection_item_model(:collection => @coll, :user => @user2)

    json = api_call(:get, "/api/v1/users/activity_stream.json",
                    { :controller => "users", :action => "activity_stream", :format => 'json' })
    json.should == [{
      'id' => StreamItem.last.id,
      'title' => @item.data.title,
      'type' => 'CollectionItem',
      'message' => @item.data.description,
      'created_at' => StreamItem.last.created_at.as_json,
      'updated_at' => StreamItem.last.updated_at.as_json,
      'collection_item' => {
        'id' => @item.id,
        'collection_id' => @item.collection_id,
        'user' => {
          'id' => @item.user.id,
          'display_name' => @item.user.short_name,
          'avatar_image_url' => "http://www.example.com/images/users/#{User.avatar_key(@item.user.id)}",
          'html_url' => (@item.user == @user) ? "http://www.example.com/profile" : "http://www.example.com/users/#{@item.user.id}",
        },
        'item_type' => @item.collection_item_data.item_type,
        'link_url' => @item.collection_item_data.link_url,
        'post_count' => @item.collection_item_data.post_count,
        'upvote_count' => @item.collection_item_data.upvote_count,
        'upvoted_by_user' => false,
        'root_item_id' => @item.collection_item_data.root_item_id,
        'image_url' => "http://www.example.com/images/thumbnails/#{@item.data.image_attachment.id}/#{@item.data.image_attachment.uuid}?size=640x%3E",
        'image_pending' => @item.data.image_pending,
        'html_preview' => @item.data.html_preview,
        'user_comment' => @item.user_comment,
        'url' => "http://www.example.com/api/v1/collections/items/#{@item.id}",
        'created_at' => @item.created_at.iso8601,
        'description' => @item.data.description,
        'title' => @item.data.title,
      }
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
end

