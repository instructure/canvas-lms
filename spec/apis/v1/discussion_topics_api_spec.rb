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

class TestCourseApi
  include Api
  include Api::V1::DiscussionTopics
  def feeds_topic_format_path(topic_id, code, format); "feeds_topic_format_path(#{topic_id.inspect}, #{code.inspect}, #{format.inspect})"; end
  def named_context_url(*args); "named_context_url(#{args.inspect[1..-2]})"; end
end

describe Api::V1::DiscussionTopics do
  before do
    @test_api = TestCourseApi.new
    course_with_teacher(:active_all => true, :user => user_with_pseudonym)
    @me = @user
    student_in_course(:active_all => true, :course => @course)
    @topic = @course.discussion_topics.create
  end

  it 'should render a podcast_url using the discussion topic\'s context if there is no @context_enrollment/@context' do
    @topic.update_attribute :podcast_enabled, true
    data = nil
    lambda {
      data = @test_api.discussion_topic_api_json(@topic, @topic.context, @me, {})
    }.should_not raise_error
    data[:podcast_url].should match /feeds_topic_format_path/
  end

  it "should set can_post_attachments" do
    data = @test_api.discussion_topic_api_json(@topic, @topic.context, @me, nil)
    data[:permissions][:attach].should == true # teachers can always attach

    data = @test_api.discussion_topic_api_json(@topic, @topic.context, @student, nil)
    data[:permissions][:attach].should == false # students can't attach by default

    @topic.context.update_attribute(:allow_student_forum_attachments, true)
    data = @test_api.discussion_topic_api_json(@topic, @topic.context, @student, nil)
    data[:permissions][:attach].should == true
  end
end

describe DiscussionTopicsController, :type => :integration do
  before(:each) do
    course_with_teacher(:active_all => true, :user => user_with_pseudonym)
  end

  context "create topic" do
    it "should check permissions" do
      @user = user(:active_all => true)
      api_call(:post, "/api/v1/courses/#{@course.id}/discussion_topics",
               { :controller => "discussion_topics", :action => "create", :format => "json", :course_id => @course.to_param },
               { :title => "hai", :message => "test message" }, {}, :expected_status => 401)
    end

    it "should make a basic topic" do
      api_call(:post, "/api/v1/courses/#{@course.id}/discussion_topics",
               { :controller => "discussion_topics", :action => "create", :format => "json", :course_id => @course.to_param },
               { :title => "test title", :message => "test <b>message</b>" })
      @topic = @course.discussion_topics.last(:order => :id)
      @topic.title.should == "test title"
      @topic.message.should == "test <b>message</b>"
      @topic.threaded?.should be_false
      @topic.post_delayed?.should be_false
      @topic.podcast_enabled?.should be_false
      @topic.podcast_has_student_posts?.should be_false
      @topic.require_initial_post?.should be_false
    end

    it "should post an announcment" do
      api_call(:post, "/api/v1/courses/#{@course.id}/discussion_topics",
               { :controller => "discussion_topics", :action => "create", :format => "json", :course_id => @course.to_param },
               { :title => "test title", :message => "test <b>message</b>", :is_announcement => true })
      @topic = @course.announcements.last(:order => :id)
      @topic.title.should == "test title"
      @topic.message.should == "test <b>message</b>"
    end

    it "should create a topic with all the bells and whistles" do
      post_at = 1.month.from_now
      api_call(:post, "/api/v1/courses/#{@course.id}/discussion_topics",
               { :controller => "discussion_topics", :action => "create", :format => "json", :course_id => @course.to_param },
               { :title => "test title", :message => "test <b>message</b>", :discussion_type => "threaded", :delayed_post_at => post_at.as_json, :podcast_has_student_posts => '1', :require_initial_post => '1' })
      @topic = @course.discussion_topics.last(:order => :id)
      @topic.title.should == "test title"
      @topic.message.should == "test <b>message</b>"
      @topic.threaded?.should == true
      @topic.post_delayed?.should == true
      @topic.delayed_post_at.to_i.should == post_at.to_i
      @topic.podcast_enabled?.should == true
      @topic.podcast_has_student_posts?.should == true
      @topic.require_initial_post?.should == true
    end

    it "should allow creating a discussion assignment" do
      due_date = 1.week.from_now
      api_call(:post, "/api/v1/courses/#{@course.id}/discussion_topics",
               { :controller => "discussion_topics", :action => "create", :format => "json", :course_id => @course.to_param },
               { :title => "test title", :message => "test <b>message</b>", :assignment => { :points_possible => 15, :grading_type => "percent", :due_at => due_date.as_json, :name => "override!" } })
      @topic = @course.discussion_topics.last(:order => :id)
      @topic.title.should == "test title"
      @topic.assignment.should be_present
      @topic.assignment.points_possible.should == 15
      @topic.assignment.grading_type.should == "percent"
      @topic.assignment.due_at.to_i.should == due_date.to_i
      @topic.assignment.submission_types.should == "discussion_topic"
      @topic.assignment.title.should == "test title"
    end
  end

  context "show topic(s)" do
    before do
      @attachment = create_attachment(@course)
      @topic = create_topic(@course, :title => "Topic 1", :message => "<p>content here</p>", :podcast_enabled => true, :attachment => @attachment)
      @sub = create_subtopic(@topic, :title => "Sub topic", :message => "<p>i'm subversive</p>")
      @response_json =
                 {"read_state"=>"read",
                  "unread_count"=>0,
                  "podcast_url"=>"/feeds/topics/#{@topic.id}/enrollment_randomness.rss",
                  "require_initial_post"=>nil,
                  "title"=>"Topic 1",
                  "discussion_subentry_count"=>0,
                  "assignment_id"=>nil,
                  "delayed_post_at"=>nil,
                  "id"=>@topic.id,
                  "user_name"=>@user.name,
                  "last_reply_at"=>@topic.last_reply_at.as_json,
                  "message"=>"<p>content here</p>",
                  "posted_at"=>@topic.posted_at.as_json,
                  "root_topic_id"=>nil,
                  "url" => "http://www.example.com/courses/#{@course.id}/discussion_topics/#{@topic.id}",
                  "html_url" => "http://www.example.com/courses/#{@course.id}/discussion_topics/#{@topic.id}",
                  "attachments"=>[{"content-type"=>"unknown/unknown",
                                   "url"=>"http://www.example.com/files/#{@attachment.id}/download?download_frd=1&verifier=#{@attachment.uuid}",
                                   "filename"=>"content.txt",
                                   "display_name"=>"content.txt",
                                   "id"=>@attachment.id,
                                   "size"=>@attachment.size,
                  }],
                  "topic_children"=>[@sub.id],
                  "discussion_type" => 'side_comment',
                  "permissions" => { "attach" => true }}
    end

    it "should return discussion topic list" do
      json = api_call(:get, "/api/v1/courses/#{@course.id}/discussion_topics.json",
                      {:controller => 'discussion_topics', :action => 'index', :format => 'json', :course_id => @course.id.to_s})

      json.size.should == 2
      # get rid of random characters in podcast url
      json.last["podcast_url"].gsub!(/_[^.]*/, '_randomness')
      json.last.should == @response_json
    end

    it "should return an individual topic" do
      json = api_call(:get, "/api/v1/courses/#{@course.id}/discussion_topics/#{@topic.id}",
                      {:controller => 'discussion_topics_api', :action => 'show', :format => 'json', :course_id => @course.id.to_s, :topic_id => @topic.id.to_s})

      # get rid of random characters in podcast url
      json["podcast_url"].gsub!(/_[^.]*/, '_randomness')
      json.should == @response_json
    end

    it "should delete a topic" do
        json = api_call(:delete, "/api/v1/courses/#{@course.id}/discussion_topics/#{@topic.id}",
                        {:controller => 'discussion_topics', :action => 'destroy', :format => 'json', :course_id => @course.id.to_s, :topic_id => @topic.id.to_s})
        @topic.reload.should be_deleted
    end
  end

  it "should translate user content in topics" do
    should_translate_user_content(@course) do |user_content|
      @topic = create_topic(@course, :title => "Topic 1", :message => user_content)
      json = api_call(
        :get, "/api/v1/courses/#{@course.id}/discussion_topics",
        { :controller => 'discussion_topics', :action => 'index', :format => 'json', :course_id => @course.id.to_s })
      json.size.should == 1
      json.first['message']
    end
  end

  it "should paginate and return proper pagination headers for courses" do
    7.times { |i| @course.discussion_topics.create!(:title => i.to_s, :message => i.to_s) }
    @course.discussion_topics.count.should == 7
    json = api_call(:get, "/api/v1/courses/#{@course.id}/discussion_topics.json?per_page=3",
                    {:controller => 'discussion_topics', :action => 'index', :format => 'json', :course_id => @course.id.to_s, :per_page => '3'})

    json.length.should == 3
    response.headers['Link'].should == [
      %{</api/v1/courses/#{@course.id}/discussion_topics?page=2&per_page=3>; rel="next"},
      %{</api/v1/courses/#{@course.id}/discussion_topics?page=1&per_page=3>; rel="first"},
      %{</api/v1/courses/#{@course.id}/discussion_topics?page=3&per_page=3>; rel="last"}
    ].join(',')

    # get the last page
    json = api_call(:get, "/api/v1/courses/#{@course.id}/discussion_topics.json?page=3&per_page=3",
                    {:controller => 'discussion_topics', :action => 'index', :format => 'json', :course_id => @course.id.to_s, :page => '3', :per_page => '3'})
    json.length.should == 1
    response.headers['Link'].should == [
      %{</api/v1/courses/#{@course.id}/discussion_topics?page=2&per_page=3>; rel="prev"},
      %{</api/v1/courses/#{@course.id}/discussion_topics?page=1&per_page=3>; rel="first"},
      %{</api/v1/courses/#{@course.id}/discussion_topics?page=3&per_page=3>; rel="last"}
    ].join(',')
  end

  it "should work with groups" do
    group_category = @course.group_categories.create(:name => 'watup')
    group = group_category.groups.create!(:name => "group1", :context => @course)
    attachment = create_attachment(group)
    gtopic = create_topic(group, :title => "Group Topic 1", :message => "<p>content here</p>", :attachment => attachment)

    json = api_call(:get, "/api/v1/groups/#{group.id}/discussion_topics.json",
                    {:controller => 'discussion_topics', :action => 'index', :format => 'json', :group_id => group.id.to_s})
    json.first.should == {"read_state"=>"read",
                          "unread_count"=>0,
                          "podcast_url"=>nil,
                          "require_initial_post"=>nil,
                          "title"=>"Group Topic 1",
                          "discussion_subentry_count"=>0,
                          "assignment_id"=>nil,
                          "delayed_post_at"=>nil,
                          "id"=>gtopic.id,
                          "user_name"=>@user.name,
                          "last_reply_at"=>gtopic.last_reply_at.as_json,
                          "message"=>"<p>content here</p>",
                          "url" => "http://www.example.com/groups/#{group.id}/discussion_topics/#{gtopic.id}",
                          "html_url" => "http://www.example.com/groups/#{group.id}/discussion_topics/#{gtopic.id}",
                          "attachments"=>
                                  [{"content-type"=>"unknown/unknown",
                                    "url"=>"http://www.example.com/files/#{attachment.id}/download?download_frd=1&verifier=#{attachment.uuid}",
                                    "filename"=>"content.txt",
                                    "display_name"=>"content.txt",
                                    "id" => attachment.id,
                                    "size" => attachment.size,
                                  }],
                          "posted_at"=>gtopic.posted_at.as_json,
                          "root_topic_id"=>nil,
                          "topic_children"=>[],
                          "discussion_type" => 'side_comment',
                          "permissions" => { "attach" => true }}
  end

  it "should paginate and return proper pagination headers for groups" do
    group_category = @course.group_categories.create(:name => "watup")
    group = group_category.groups.create!(:name => "group1", :context => @course)
    7.times { |i| create_topic(group, :title => i.to_s, :message => i.to_s) }
    group.discussion_topics.count.should == 7
    json = api_call(:get, "/api/v1/groups/#{group.id}/discussion_topics.json?per_page=3",
                    {:controller => 'discussion_topics', :action => 'index', :format => 'json', :group_id => group.id.to_s, :per_page => '3'})

    json.length.should == 3
    response.headers['Link'].should == [
      %{</api/v1/groups/#{group.id}/discussion_topics?page=2&per_page=3>; rel="next"},
      %{</api/v1/groups/#{group.id}/discussion_topics?page=1&per_page=3>; rel="first"},
      %{</api/v1/groups/#{group.id}/discussion_topics?page=3&per_page=3>; rel="last"}
    ].join(',')

      # get the last page
    json = api_call(:get, "/api/v1/groups/#{group.id}/discussion_topics.json?page=3&per_page=3",
                    {:controller => 'discussion_topics', :action => 'index', :format => 'json', :group_id => group.id.to_s, :page => '3', :per_page => '3'})
    json.length.should == 1
    response.headers['Link'].should == [
      %{</api/v1/groups/#{group.id}/discussion_topics?page=2&per_page=3>; rel="prev"},
      %{</api/v1/groups/#{group.id}/discussion_topics?page=1&per_page=3>; rel="first"},
      %{</api/v1/groups/#{group.id}/discussion_topics?page=3&per_page=3>; rel="last"}
    ].join(',')
  end

  context "creating an entry under a topic" do
    before :each do
      @topic = create_topic(@course, :title => "Topic 1", :message => "<p>content here</p>")
      @message = "my message"
    end

    it "should allow creating an entry under a topic and create it correctly" do
      json = api_call(
        :post, "/api/v1/courses/#{@course.id}/discussion_topics/#{@topic.id}/entries.json",
        { :controller => 'discussion_topics_api', :action => 'add_entry', :format => 'json',
          :course_id => @course.id.to_s, :topic_id => @topic.id.to_s },
        { :message => @message })
      json.should_not be_nil
      json['id'].should_not be_nil
      @entry = DiscussionEntry.find_by_id(json['id'])
      @entry.should_not be_nil
      @entry.discussion_topic.should == @topic
      @entry.user.should == @user
      @entry.parent_entry.should be_nil
      @entry.message.should == @message
    end

    it "should return json representation of the new entry" do
      json = api_call(
        :post, "/api/v1/courses/#{@course.id}/discussion_topics/#{@topic.id}/entries.json",
        { :controller => 'discussion_topics_api', :action => 'add_entry', :format => 'json',
          :course_id => @course.id.to_s, :topic_id => @topic.id.to_s },
        { :message => @message })
      @entry = DiscussionEntry.find_by_id(json['id'])
      json.should == {
        "id" => @entry.id,
        "parent_id" => @entry.parent_id,
        "user_id" => @user.id,
        "user_name" => @user.name,
        "read_state" => "read",
        "message" => @message,
        "created_at" => @entry.created_at.utc.iso8601,
        "updated_at" => @entry.updated_at.as_json,
      }
    end

    it "should allow creating a reply to an existing top-level entry" do
      top_entry = create_entry(@topic, :message => 'top-level message')
      json = api_call(
        :post, "/api/v1/courses/#{@course.id}/discussion_topics/#{@topic.id}/entries/#{top_entry.id}/replies.json",
        { :controller => 'discussion_topics_api', :action => 'add_reply', :format => 'json',
          :course_id => @course.id.to_s, :topic_id => @topic.id.to_s, :entry_id => top_entry.id.to_s },
        { :message => @message })
      @entry = DiscussionEntry.find_by_id(json['id'])
      @entry.parent_entry.should == top_entry
    end

    it "should allow including attachments on top-level entries" do
      data = ActionController::TestUploadedFile.new(File.join(File.dirname(__FILE__), "/../../fixtures/scribd_docs/txt.txt"), "text/plain", true)
      require 'action_controller'
      require 'action_controller/test_process.rb'
      json = api_call(
        :post, "/api/v1/courses/#{@course.id}/discussion_topics/#{@topic.id}/entries.json",
        { :controller => 'discussion_topics_api', :action => 'add_entry', :format => 'json',
          :course_id => @course.id.to_s, :topic_id => @topic.id.to_s },
        { :message => @message, :attachment => data })
      @entry = DiscussionEntry.find_by_id(json['id'])
      @entry.attachment.should_not be_nil
    end

    it "should include attachments on replies to top-level entries" do
      top_entry = create_entry(@topic, :message => 'top-level message')
      require 'action_controller'
      require 'action_controller/test_process.rb'
      data = ActionController::TestUploadedFile.new(File.join(File.dirname(__FILE__), "/../../fixtures/scribd_docs/txt.txt"), "text/plain", true)
      json = api_call(
        :post, "/api/v1/courses/#{@course.id}/discussion_topics/#{@topic.id}/entries/#{top_entry.id}/replies.json",
        { :controller => 'discussion_topics_api', :action => 'add_reply', :format => 'json',
          :course_id => @course.id.to_s, :topic_id => @topic.id.to_s, :entry_id => top_entry.id.to_s },
        { :message => @message, :attachment => data })
      @entry = DiscussionEntry.find_by_id(json['id'])
      @entry.attachment.should_not be_nil
    end

    it "should include attachment info in the json response" do
      data = ActionController::TestUploadedFile.new(File.join(File.dirname(__FILE__), "/../../fixtures/scribd_docs/txt.txt"), "text/plain", true)
      require 'action_controller'
      require 'action_controller/test_process.rb'
      json = api_call(
        :post, "/api/v1/courses/#{@course.id}/discussion_topics/#{@topic.id}/entries.json",
        { :controller => 'discussion_topics_api', :action => 'add_entry', :format => 'json',
          :course_id => @course.id.to_s, :topic_id => @topic.id.to_s },
        { :message => @message, :attachment => data })
      json['attachment'].should_not be_nil
      json['attachment'].should_not be_empty
    end

    it "should create a submission from an entry on a graded topic" do
      @topic.assignment = assignment_model(:course => @course)
      @topic.save

      student_in_course(:active_all => true)
      @user.submissions.should be_empty

      json = api_call(
        :post, "/api/v1/courses/#{@course.id}/discussion_topics/#{@topic.id}/entries.json",
        { :controller => 'discussion_topics_api', :action => 'add_entry', :format => 'json',
          :course_id => @course.id.to_s, :topic_id => @topic.id.to_s },
        { :message => @message })

      @user.reload
      @user.submissions.size.should == 1
      @user.submissions.first.submission_type.should == 'discussion_topic'
    end

    it "should create a submission from a reply on a graded topic" do
      top_entry = create_entry(@topic, :message => 'top-level message')

      @topic.assignment = assignment_model(:course => @course)
      @topic.save

      student_in_course(:active_all => true)
      @user.submissions.should be_empty

      json = api_call(
        :post, "/api/v1/courses/#{@course.id}/discussion_topics/#{@topic.id}/entries/#{top_entry.id}/replies.json",
        { :controller => 'discussion_topics_api', :action => 'add_reply', :format => 'json',
          :course_id => @course.id.to_s, :topic_id => @topic.id.to_s, :entry_id => top_entry.id.to_s },
        { :message => @message })

      @user.reload
      @user.submissions.size.should == 1
      @user.submissions.first.submission_type.should == 'discussion_topic'
    end
  end

  context "listing top-level discussion entries" do
    before :each do
      @topic = create_topic(@course, :title => "topic", :message => "topic")
      @attachment = create_attachment(@course)
      @entry = create_entry(@topic, :message => "first top-level entry", :attachment => @attachment)
      @reply = create_reply(@entry, :message => "reply to first top-level entry")
    end

    it "should return top level entries for a topic" do
      json = api_call(
        :get, "/api/v1/courses/#{@course.id}/discussion_topics/#{@topic.id}/entries.json",
        { :controller => 'discussion_topics_api', :action => 'entries', :format => 'json',
          :course_id => @course.id.to_s, :topic_id => @topic.id.to_s })
      json.size.should == 1
      entry_json = json.first
      entry_json['id'].should == @entry.id
    end

    it "should return attachments on top level entries" do
      json = api_call(
        :get, "/api/v1/courses/#{@course.id}/discussion_topics/#{@topic.id}/entries.json",
        { :controller => 'discussion_topics_api', :action => 'entries', :format => 'json',
          :course_id => @course.id.to_s, :topic_id => @topic.id.to_s })
      entry_json = json.first
      entry_json['attachment'].should_not be_nil
      entry_json['attachment']['url'].should == "http://#{Account.default.domain}/files/#{@attachment.id}/download?download_frd=1&verifier=#{@attachment.uuid}"
    end

    it "should include replies on top level entries" do
      json = api_call(
        :get, "/api/v1/courses/#{@course.id}/discussion_topics/#{@topic.id}/entries.json",
        { :controller => 'discussion_topics_api', :action => 'entries', :format => 'json',
          :course_id => @course.id.to_s, :topic_id => @topic.id.to_s })
      entry_json = json.first
      entry_json['recent_replies'].size.should == 1
      entry_json['has_more_replies'].should be_false
      reply_json = entry_json['recent_replies'].first
      reply_json['id'].should == @reply.id
    end

    it "should sort top-level entries by descending created_at" do
      @older_entry = create_entry(@topic, :message => "older top-level entry", :created_at => Time.now - 1.minute)
      @newer_entry = create_entry(@topic, :message => "newer top-level entry", :created_at => Time.now + 1.minute)
      json = api_call(
        :get, "/api/v1/courses/#{@course.id}/discussion_topics/#{@topic.id}/entries.json",
        { :controller => 'discussion_topics_api', :action => 'entries', :format => 'json',
          :course_id => @course.id.to_s, :topic_id => @topic.id.to_s })
      json.size.should == 3
      json.first['id'].should == @newer_entry.id
      json.last['id'].should == @older_entry.id
    end

    it "should sort replies included on top-level entries by descending created_at" do
      @older_reply = create_reply(@entry, :message => "older reply", :created_at => Time.now - 1.minute)
      @newer_reply = create_reply(@entry, :message => "newer reply", :created_at => Time.now + 1.minute)
      json = api_call(
        :get, "/api/v1/courses/#{@course.id}/discussion_topics/#{@topic.id}/entries.json",
        { :controller => 'discussion_topics_api', :action => 'entries', :format => 'json',
          :course_id => @course.id.to_s, :topic_id => @topic.id.to_s })
      json.size.should == 1
      reply_json = json.first['recent_replies']
      reply_json.size.should == 3
      reply_json.first['id'].should == @newer_reply.id
      reply_json.last['id'].should == @older_reply.id
    end

    it "should paginate top-level entries" do
      # put in lots of entries
      entries = []
      7.times{ |i| entries << create_entry(@topic, :message => i.to_s, :created_at => Time.now + (i+1).minutes) }

      # first page
      json = api_call(
        :get, "/api/v1/courses/#{@course.id}/discussion_topics/#{@topic.id}/entries.json?per_page=3",
        { :controller => 'discussion_topics_api', :action => 'entries', :format => 'json',
          :course_id => @course.id.to_s, :topic_id => @topic.id.to_s, :per_page => '3' })
      json.length.should == 3
      json.map{ |e| e['id'] }.should == entries.last(3).reverse.map{ |e| e.id }
      response.headers['Link'].should == [
        %{</api/v1/courses/#{@course.id}/discussion_topics/#{@topic.id}/entries?page=2&per_page=3>; rel="next"},
        %{</api/v1/courses/#{@course.id}/discussion_topics/#{@topic.id}/entries?page=1&per_page=3>; rel="first"},
        %{</api/v1/courses/#{@course.id}/discussion_topics/#{@topic.id}/entries?page=3&per_page=3>; rel="last"}
      ].join(',')

      # last page
      json = api_call(
        :get, "/api/v1/courses/#{@course.id}/discussion_topics/#{@topic.id}/entries.json?page=3&per_page=3",
        { :controller => 'discussion_topics_api', :action => 'entries', :format => 'json',
          :course_id => @course.id.to_s, :topic_id => @topic.id.to_s, :page => '3', :per_page => '3' })
      json.length.should == 2
      json.map{ |e| e['id'] }.should == [entries.first, @entry].map{ |e| e.id }
      response.headers['Link'].should == [
        %{</api/v1/courses/#{@course.id}/discussion_topics/#{@topic.id}/entries?page=2&per_page=3>; rel="prev"},
        %{</api/v1/courses/#{@course.id}/discussion_topics/#{@topic.id}/entries?page=1&per_page=3>; rel="first"},
        %{</api/v1/courses/#{@course.id}/discussion_topics/#{@topic.id}/entries?page=3&per_page=3>; rel="last"}
      ].join(',')
    end

    it "should only include the first 10 replies for each top-level entry" do
      # put in lots of replies
      replies = []
      12.times{ |i| replies << create_reply(@entry, :message => i.to_s, :created_at => Time.now + (i+1).minutes) }

      # get entry
      json = api_call(
        :get, "/api/v1/courses/#{@course.id}/discussion_topics/#{@topic.id}/entries.json",
        { :controller => 'discussion_topics_api', :action => 'entries', :format => 'json',
          :course_id => @course.id.to_s, :topic_id => @topic.id.to_s })
      json.length.should == 1
      reply_json = json.first['recent_replies']
      reply_json.length.should == 10
      reply_json.map{ |e| e['id'] }.should == replies.last(10).reverse.map{ |e| e.id }
      json.first['has_more_replies'].should be_true
    end
  end

  context "listing replies" do
    before :each do
      @topic = create_topic(@course, :title => "topic", :message => "topic")
      @entry = create_entry(@topic, :message => "top-level entry")
      @reply = create_reply(@entry, :message => "first reply")
    end

    it "should return replies for an entry" do
      json = api_call(
        :get, "/api/v1/courses/#{@course.id}/discussion_topics/#{@topic.id}/entries/#{@entry.id}/replies.json",
        { :controller => 'discussion_topics_api', :action => 'replies', :format => 'json',
          :course_id => @course.id.to_s, :topic_id => @topic.id.to_s, :entry_id => @entry.id.to_s })
      json.size.should == 1
      json.first['id'].should == @reply.id
    end

    it "should translate user content in replies" do
      should_translate_user_content(@course) do |user_content|
        @reply.update_attribute('message', user_content)
        json = api_call(
          :get, "/api/v1/courses/#{@course.id}/discussion_topics/#{@topic.id}/entries/#{@entry.id}/replies.json",
          { :controller => 'discussion_topics_api', :action => 'replies', :format => 'json',
            :course_id => @course.id.to_s, :topic_id => @topic.id.to_s, :entry_id => @entry.id.to_s })
        json.size.should == 1
        json.first['message']
      end
    end

    it "should sort replies by descending created_at" do
      @older_reply = create_reply(@entry, :message => "older reply", :created_at => Time.now - 1.minute)
      @newer_reply = create_reply(@entry, :message => "newer reply", :created_at => Time.now + 1.minute)
      json = api_call(
        :get, "/api/v1/courses/#{@course.id}/discussion_topics/#{@topic.id}/entries/#{@entry.id}/replies.json",
        { :controller => 'discussion_topics_api', :action => 'replies', :format => 'json',
          :course_id => @course.id.to_s, :topic_id => @topic.id.to_s, :entry_id => @entry.id.to_s })
      json.size.should == 3
      json.first['id'].should == @newer_reply.id
      json.last['id'].should == @older_reply.id
    end

    it "should paginate replies" do
      # put in lots of replies
      replies = []
      7.times{ |i| replies << create_reply(@entry, :message => i.to_s, :created_at => Time.now + (i+1).minutes) }

      # first page
      json = api_call(
        :get, "/api/v1/courses/#{@course.id}/discussion_topics/#{@topic.id}/entries/#{@entry.id}/replies.json?per_page=3",
        { :controller => 'discussion_topics_api', :action => 'replies', :format => 'json',
          :course_id => @course.id.to_s, :topic_id => @topic.id.to_s, :entry_id => @entry.id.to_s, :per_page => '3' })
      json.length.should == 3
      json.map{ |e| e['id'] }.should == replies.last(3).reverse.map{ |e| e.id }
      response.headers['Link'].should == [
        %{</api/v1/courses/#{@course.id}/discussion_topics/#{@topic.id}/entries/#{@entry.id}/replies?page=2&per_page=3>; rel="next"},
        %{</api/v1/courses/#{@course.id}/discussion_topics/#{@topic.id}/entries/#{@entry.id}/replies?page=1&per_page=3>; rel="first"},
        %{</api/v1/courses/#{@course.id}/discussion_topics/#{@topic.id}/entries/#{@entry.id}/replies?page=3&per_page=3>; rel="last"}
      ].join(',')

      # last page
      json = api_call(
        :get, "/api/v1/courses/#{@course.id}/discussion_topics/#{@topic.id}/entries/#{@entry.id}/replies.json?page=3&per_page=3",
        { :controller => 'discussion_topics_api', :action => 'replies', :format => 'json',
          :course_id => @course.id.to_s, :topic_id => @topic.id.to_s, :entry_id => @entry.id.to_s, :page => '3', :per_page => '3' })
      json.length.should == 2
      json.map{ |e| e['id'] }.should == [replies.first, @reply].map{ |e| e.id }
      response.headers['Link'].should == [
        %{</api/v1/courses/#{@course.id}/discussion_topics/#{@topic.id}/entries/#{@entry.id}/replies?page=2&per_page=3>; rel="prev"},
        %{</api/v1/courses/#{@course.id}/discussion_topics/#{@topic.id}/entries/#{@entry.id}/replies?page=1&per_page=3>; rel="first"},
        %{</api/v1/courses/#{@course.id}/discussion_topics/#{@topic.id}/entries/#{@entry.id}/replies?page=3&per_page=3>; rel="last"}
      ].join(',')
    end
  end

  # stolen and adjusted from spec/controllers/discussion_topics_controller_spec.rb
  context "require initial post" do
    before(:each) do
      course_with_student(:active_all => true)

      @observer = user(:name => "Observer", :active_all => true)
      e = @course.enroll_user(@observer, 'ObserverEnrollment')
      e.associated_user = @student
      e.save
      @observer.reload

      course_with_teacher(:course => @course, :active_all => true)
      @context = @course
      discussion_topic_model
      @topic.require_initial_post = true
      @topic.save
    end

    it "should allow admins to see posts without posting" do
      @topic.reply_from(:user => @student, :text => 'hai')
      @user = @teacher
      json = api_call(
        :get, "/api/v1/courses/#{@course.id}/discussion_topics/#{@topic.id}/entries.json",
        { :controller => 'discussion_topics_api', :action => 'entries', :format => 'json',
          :course_id => @course.id.to_s, :topic_id => @topic.id.to_s })
      json.length.should == 1
    end

    it "shouldn't allow student who hasn't posted to see" do
      @topic.reply_from(:user => @teacher, :text => 'hai')
      @user = @student
      raw_api_call(
        :get, "/api/v1/courses/#{@course.id}/discussion_topics/#{@topic.id}/entries.json",
        { :controller => 'discussion_topics_api', :action => 'entries', :format => 'json',
          :course_id => @course.id.to_s, :topic_id => @topic.id.to_s })
      response.status.should == '403 Forbidden'
      response.body.should == 'require_initial_post'

      raw_api_call(
        :get, "/api/v1/courses/#{@course.id}/discussion_topics/#{@topic.id}",
        { :controller => 'discussion_topics_api', :action => 'show', :format => 'json',
          :course_id => @course.id.to_s, :topic_id => @topic.id.to_s })
      response.status.should == '403 Forbidden'
      response.body.should == 'require_initial_post'
    end

    it "shouldn't allow student's observer who hasn't posted to see" do
      @topic.reply_from(:user => @teacher, :text => 'hai')
      @user = @observer
      raw_api_call(
        :get, "/api/v1/courses/#{@course.id}/discussion_topics/#{@topic.id}/entries.json",
        { :controller => 'discussion_topics_api', :action => 'entries', :format => 'json',
          :course_id => @course.id.to_s, :topic_id => @topic.id.to_s })
      response.status.should == '403 Forbidden'
      response.body.should == 'require_initial_post'
    end

    it "should allow student who has posted to see" do
      @topic.reply_from(:user => @student, :text => 'hai')
      @user = @student
      json = api_call(
        :get, "/api/v1/courses/#{@course.id}/discussion_topics/#{@topic.id}/entries.json",
        { :controller => 'discussion_topics_api', :action => 'entries', :format => 'json',
          :course_id => @course.id.to_s, :topic_id => @topic.id.to_s })
      json.length.should == 1
    end

    it "should allow student's observer who has posted to see" do
      @topic.reply_from(:user => @student, :text => 'hai')
      @user = @observer
      json = api_call(
        :get, "/api/v1/courses/#{@course.id}/discussion_topics/#{@topic.id}/entries.json",
        { :controller => 'discussion_topics_api', :action => 'entries', :format => 'json',
          :course_id => @course.id.to_s, :topic_id => @topic.id.to_s })
      json.length.should == 1
    end
  end

  context "update entry" do
    before do
      @topic = create_topic(@course, :title => "topic", :message => "topic")
      @entry = create_entry(@topic, :message => "<p>top-level entry</p>")
    end

    it "should 401 if the user can't update" do
      student_in_course(:course => @course, :user => user_with_pseudonym)
      api_call(:put, "/api/v1/courses/#{@course.id}/discussion_topics/#{@topic.id}/entries/#{@entry.id}",
               { :controller => "discussion_entries", :action => "update", :format => "json", :course_id => @course.id.to_s, :topic_id => @topic.id.to_s, :id => @entry.id.to_s }, { :message => 'haxor' }, {}, :expected_status => 401)
      @entry.reload.message.should == '<p>top-level entry</p>'
    end

    it "should 404 if the entry is deleted" do
      @entry.destroy
      api_call(:put, "/api/v1/courses/#{@course.id}/discussion_topics/#{@topic.id}/entries/#{@entry.id}",
               { :controller => "discussion_entries", :action => "update", :format => "json", :course_id => @course.id.to_s, :topic_id => @topic.id.to_s, :id => @entry.id.to_s }, { :message => 'haxor' }, {}, :expected_status => 404)
    end

    it "should update the message" do
      api_call(:put, "/api/v1/courses/#{@course.id}/discussion_topics/#{@topic.id}/entries/#{@entry.id}",
               { :controller => "discussion_entries", :action => "update", :format => "json", :course_id => @course.id.to_s, :topic_id => @topic.id.to_s, :id => @entry.id.to_s }, { :message => '<p>i had a spleling error</p>' })
      @entry.reload.message.should == '<p>i had a spleling error</p>'
    end

    it "should allow passing an plaintext message (undocumented)" do
      # undocumented but used by the dashboard right now (this'll go away eventually)
      api_call(:put, "/api/v1/courses/#{@course.id}/discussion_topics/#{@topic.id}/entries/#{@entry.id}",
               { :controller => "discussion_entries", :action => "update", :format => "json", :course_id => @course.id.to_s, :topic_id => @topic.id.to_s, :id => @entry.id.to_s }, { :plaintext_message => 'i had a spleling error' })
      @entry.reload.message.should == 'i had a spleling error'
    end

    it "should allow teachers to edit student entries" do
      @teacher = @user
      student_in_course(:course => @course, :user => user_with_pseudonym)
      @student = @user
      @user = @teacher
      @entry = create_entry(@topic, :message => 'i am a student', :user => @student)
      @entry.user.should == @student
      @entry.editor.should be_nil

      api_call(:put, "/api/v1/courses/#{@course.id}/discussion_topics/#{@topic.id}/entries/#{@entry.id}",
               { :controller => "discussion_entries", :action => "update", :format => "json", :course_id => @course.id.to_s, :topic_id => @topic.id.to_s, :id => @entry.id.to_s }, { :message => '<p>denied</p>' })
      @entry.reload.message.should == '<p>denied</p>'
      @entry.editor.should == @teacher
    end
  end

  context "delete entry" do
    before do
      @topic = create_topic(@course, :title => "topic", :message => "topic")
      @entry = create_entry(@topic, :message => "top-level entry")
    end

    it "should 401 if the user can't delete" do
      student_in_course(:course => @course, :user => user_with_pseudonym)
      api_call(:delete, "/api/v1/courses/#{@course.id}/discussion_topics/#{@topic.id}/entries/#{@entry.id}",
               { :controller => "discussion_entries", :action => "destroy", :format => "json", :course_id => @course.id.to_s, :topic_id => @topic.id.to_s, :id => @entry.id.to_s }, {}, {}, :expected_status => 401)
      @entry.reload.should_not be_deleted
    end

    it "should soft-delete the entry" do
      raw_api_call(:delete, "/api/v1/courses/#{@course.id}/discussion_topics/#{@topic.id}/entries/#{@entry.id}",
               { :controller => "discussion_entries", :action => "destroy", :format => "json", :course_id => @course.id.to_s, :topic_id => @topic.id.to_s, :id => @entry.id.to_s }, {}, {}, :expected_status => 204)
      response.body.should be_blank
      @entry.reload.should be_deleted
    end

    it "should allow teachers to delete student entries" do
      @teacher = @user
      student_in_course(:course => @course, :user => user_with_pseudonym)
      @student = @user
      @user = @teacher
      @entry = create_entry(@topic, :message => 'i am a student', :user => @student)
      @entry.user.should == @student
      @entry.editor.should be_nil

      raw_api_call(:delete, "/api/v1/courses/#{@course.id}/discussion_topics/#{@topic.id}/entries/#{@entry.id}",
               { :controller => "discussion_entries", :action => "destroy", :format => "json", :course_id => @course.id.to_s, :topic_id => @topic.id.to_s, :id => @entry.id.to_s }, {}, {}, :expected_status => 204)
      @entry.reload.should be_deleted
      @entry.editor.should == @teacher
    end
  end

  context "read/unread state" do
    before(:each) do
      @topic = create_topic(@course, :title => "topic", :message => "topic")
      @entry = create_entry(@topic, :message => "top-level entry")
      @reply = create_reply(@entry, :message => "first reply")
    end

    it "should immediately mark messages you write as 'read'" do
      json = api_call(:get, "/api/v1/courses/#{@course.id}/discussion_topics.json",
                      { :controller => 'discussion_topics', :action => 'index', :format => 'json',
                        :course_id => @course.id.to_s })
      json.first["read_state"].should == "read"
      json.first["unread_count"].should == 0

      json = api_call(
        :get, "/api/v1/courses/#{@course.id}/discussion_topics/#{@topic.id}/entries.json",
        { :controller => 'discussion_topics_api', :action => 'entries', :format => 'json',
          :course_id => @course.id.to_s, :topic_id => @topic.id.to_s })
      json.first["read_state"].should == "read"

      json = api_call(
        :get, "/api/v1/courses/#{@course.id}/discussion_topics/#{@topic.id}/entries/#{@entry.id}/replies.json",
        { :controller => 'discussion_topics_api', :action => 'replies', :format => 'json',
          :course_id => @course.id.to_s, :topic_id => @topic.id.to_s, :entry_id => @entry.id.to_s })
      json.first["read_state"].should == "read"
    end

    it "should be unread by default for a new user" do
      student_in_course(:active_all => true)
      json = api_call(:get, "/api/v1/courses/#{@course.id}/discussion_topics.json",
                      { :controller => 'discussion_topics', :action => 'index', :format => 'json',
                        :course_id => @course.id.to_s })
      json.first["read_state"].should == "unread"
      json.first["unread_count"].should == 2

      json = api_call(
        :get, "/api/v1/courses/#{@course.id}/discussion_topics/#{@topic.id}/entries.json",
        { :controller => 'discussion_topics_api', :action => 'entries', :format => 'json',
          :course_id => @course.id.to_s, :topic_id => @topic.id.to_s })
      json.first["read_state"].should == "unread"

      json = api_call(
        :get, "/api/v1/courses/#{@course.id}/discussion_topics/#{@topic.id}/entries/#{@entry.id}/replies.json",
        { :controller => 'discussion_topics_api', :action => 'replies', :format => 'json',
          :course_id => @course.id.to_s, :topic_id => @topic.id.to_s, :entry_id => @entry.id.to_s })
      json.first["read_state"].should == "unread"
    end

    def call_mark_topic_read(course, topic)
      raw_api_call(:put, "/api/v1/courses/#{course.id}/discussion_topics/#{topic.id}/read.json",
                      { :controller => 'discussion_topics_api', :action => 'mark_topic_read', :format => 'json',
                        :course_id => course.id.to_s, :topic_id => topic.id.to_s })
    end

    def call_mark_topic_unread(course, topic)
      raw_api_call(:delete, "/api/v1/courses/#{course.id}/discussion_topics/#{topic.id}/read.json",
                      { :controller => 'discussion_topics_api', :action => 'mark_topic_unread', :format => 'json',
                        :course_id => course.id.to_s, :topic_id => topic.id.to_s })
    end

    it "should set the read state for a topic" do
      student_in_course(:active_all => true)
      call_mark_topic_read(@course, @topic)
      response.status.should == '204 No Content'
      @topic.read?(@user).should be_true
      @topic.unread_count(@user).should == 2

      call_mark_topic_unread(@course, @topic)
      response.status.should == '204 No Content'
      @topic.read?(@user).should be_false
      @topic.unread_count(@user).should == 2
    end

    it "should be idempotent for setting topic read state" do
      student_in_course(:active_all => true)
      call_mark_topic_read(@course, @topic)
      response.status.should == '204 No Content'
      @topic.read?(@user).should be_true
      @topic.unread_count(@user).should == 2

      call_mark_topic_read(@course, @topic)
      response.status.should == '204 No Content'
      @topic.read?(@user).should be_true
      @topic.unread_count(@user).should == 2
    end

    def call_mark_entry_read(course, topic, entry)
      raw_api_call(:put, "/api/v1/courses/#{course.id}/discussion_topics/#{topic.id}/entries/#{entry.id}/read.json",
                      { :controller => 'discussion_topics_api', :action => 'mark_entry_read', :format => 'json',
                        :course_id => course.id.to_s, :topic_id => topic.id.to_s, :entry_id => entry.id.to_s })
    end

    def call_mark_entry_unread(course, topic, entry)
      raw_api_call(:delete, "/api/v1/courses/#{course.id}/discussion_topics/#{topic.id}/entries/#{entry.id}/read.json",
                      { :controller => 'discussion_topics_api', :action => 'mark_entry_unread', :format => 'json',
                        :course_id => course.id.to_s, :topic_id => topic.id.to_s, :entry_id => entry.id.to_s })
    end

    it "should set the read state for a entry" do
      student_in_course(:active_all => true)
      call_mark_entry_read(@course, @topic, @entry)
      response.status.should == '204 No Content'
      @entry.read?(@user).should be_true
      @topic.unread_count(@user).should == 1

      call_mark_entry_unread(@course, @topic, @entry)
      response.status.should == '204 No Content'
      @entry.read?(@user).should be_false
      @topic.unread_count(@user).should == 2
    end

    it "should be idempotent for setting entry read state" do
      student_in_course(:active_all => true)
      call_mark_entry_read(@course, @topic, @entry)
      response.status.should == '204 No Content'
      @entry.read?(@user).should be_true
      @topic.unread_count(@user).should == 1

      call_mark_entry_read(@course, @topic, @entry)
      response.status.should == '204 No Content'
      @entry.read?(@user).should be_true
      @topic.unread_count(@user).should == 1
    end

    it "should allow mark all as read/unread" do
      student_in_course(:active_all => true)
      raw_api_call(:put, "/api/v1/courses/#{@course.id}/discussion_topics/#{@topic.id}/read_all.json",
                      { :controller => 'discussion_topics_api', :action => 'mark_all_read', :format => 'json',
                        :course_id => @course.id.to_s, :topic_id => @topic.id.to_s })
      response.status.should == '204 No Content'
      @topic.read?(@user).should be_true
      @entry.read?(@user).should be_true
      @topic.unread_count(@user).should == 0

      raw_api_call(:delete, "/api/v1/courses/#{@course.id}/discussion_topics/#{@topic.id}/read_all.json",
                      { :controller => 'discussion_topics_api', :action => 'mark_all_unread', :format => 'json',
                        :course_id => @course.id.to_s, :topic_id => @topic.id.to_s })
      response.status.should == '204 No Content'
      @topic.read?(@user).should be_false
      @entry.read?(@user).should be_false
      @topic.unread_count(@user).should == 2
    end
  end

  describe "threaded discussions" do
    before do
      student_in_course(:active_all => true)
      @topic = create_topic(@course, :threaded => true)
      @entry = create_entry(@topic)
      @sub1 = create_reply(@entry)
      @sub2 = create_reply(@sub1)
      @sub3 = create_reply(@sub2)
      @side2 = create_reply(@entry)
      @entry2 = create_entry(@topic)
    end

    context "in the original API" do
      it "should respond with information on the threaded discussion" do
        json = api_call(:get, "/api/v1/courses/#{@course.id}/discussion_topics",
                 { :controller => "discussion_topics", :action => "index", :format => "json", :course_id => @course.id.to_s })
        json[0]['discussion_type'].should == 'threaded'
      end

      it "should return nested discussions in a flattened format" do
        json = api_call(:get, "/api/v1/courses/#{@course.id}/discussion_topics/#{@topic.id}/entries",
                 { :controller => "discussion_topics_api", :action => "entries", :format => "json", :course_id => @course.id.to_s, :topic_id => @topic.id.to_s })
        json.size.should == 2
        json[0]['id'].should == @entry2.id
        e1 = json[1]
        e1['id'].should == @entry.id
        e1['recent_replies'].map { |r| r['id'] }.should == [@side2.id, @sub3.id, @sub2.id, @sub1.id]
        e1['recent_replies'].map { |r| r['parent_id'] }.should == [@entry.id, @sub2.id, @sub1.id, @entry.id]

        json = api_call(:get, "/api/v1/courses/#{@course.id}/discussion_topics/#{@topic.id}/entries/#{@entry.id}/replies",
                 { :controller => "discussion_topics_api", :action => "replies", :format => "json", :course_id => @course.id.to_s, :topic_id => @topic.id.to_s, :entry_id => @entry.id.to_s })
        json.size.should == 4
        json.map { |r| r['id'] }.should == [@side2.id, @sub3.id, @sub2.id, @sub1.id]
        json.map { |r| r['parent_id'] }.should == [@entry.id, @sub2.id, @sub1.id, @entry.id]
      end

      it "should allow posting a reply to a sub-entry" do
        json = api_call(:post, "/api/v1/courses/#{@course.id}/discussion_topics/#{@topic.id}/entries/#{@sub2.id}/replies",
                 { :controller => "discussion_topics_api", :action => "add_reply", :format => "json", :course_id => @course.id.to_s, :topic_id => @topic.id.to_s, :entry_id => @sub2.id.to_s },
                 { :message => "ohai" })
        json['parent_id'].should == @sub2.id
        @sub4 = DiscussionEntry.last(:order => :id)
        @sub4.id.should == json['id']

        json = api_call(:get, "/api/v1/courses/#{@course.id}/discussion_topics/#{@topic.id}/entries/#{@entry.id}/replies",
                 { :controller => "discussion_topics_api", :action => "replies", :format => "json", :course_id => @course.id.to_s, :topic_id => @topic.id.to_s, :entry_id => @entry.id.to_s })
        json.size.should == 5
        json.map { |r| r['id'] }.should == [@sub4.id, @side2.id, @sub3.id, @sub2.id, @sub1.id]
        json.map { |r| r['parent_id'] }.should == [@sub2.id, @entry.id, @sub2.id, @sub1.id, @entry.id]
      end

      it "should set and return editor_id if editing another user's post" do
      end

      it "should fail if the max entry depth is reached" do
        entry = @entry
        (DiscussionEntry.max_depth - 1).times do
          entry = create_reply(entry)
        end
        json = api_call(:post, "/api/v1/courses/#{@course.id}/discussion_topics/#{@topic.id}/entries/#{entry.id}/replies",
                 { :controller => "discussion_topics_api", :action => "add_reply", :format => "json", :course_id => @course.id.to_s, :topic_id => @topic.id.to_s, :entry_id => entry.id.to_s },
                 { :message => "ohai" }, {}, {:expected_status => 400})
      end
    end

    context "in the updated API" do
      it "should return a paginated entry_list" do
        entries = [@entry2, @sub1, @side2]
        json = api_call(:get, "/api/v1/courses/#{@course.id}/discussion_topics/#{@topic.id}/entry_list?per_page=2",
                  { :controller => "discussion_topics_api", :action => "entry_list", :format => "json", :course_id => @course.id.to_s, :topic_id => @topic.id.to_s, :per_page => '2' },
                 { :ids => entries.map(&:id) })
        json.size.should == 2
        # response order is by id
        json.map { |e| e['id'] }.should == [@sub1.id, @side2.id]
        response['Link'].should match(/next/)
      end

      it "should return deleted entries, but with limited data" do
        @sub1.destroy
        json = api_call(:get, "/api/v1/courses/#{@course.id}/discussion_topics/#{@topic.id}/entry_list",
                  { :controller => "discussion_topics_api", :action => "entry_list", :format => "json", :course_id => @course.id.to_s, :topic_id => @topic.id.to_s },
                 { :ids => @sub1.id })
        json.size.should == 1
        json.first.should == { 'id' => @sub1.id, 'deleted' => true, 'read_state' => 'read', 'parent_id' => @entry.id, 'updated_at' => @sub1.updated_at.as_json, 'created_at' => @sub1.created_at.as_json }
      end
    end
  end

  context "materialized view API" do
    it "should respond with the materialized information about the discussion" do
      topic_with_nested_replies
      # mark a couple entries as read
      @user = @student
      @root2.change_read_state("read", @user)
      @reply3.change_read_state("read", @user)
      # have the teacher edit one of the student's replies
      @reply_reply1.editor = @teacher
      @reply_reply1.update_attributes(:message => '<p>censored</p>')

      @all_entries.each &:reload

      run_transaction_commit_callbacks
      job = Delayed::Job.find_by_strand("materialized_discussion:#{@topic.id}")
      job.should be_present
      run_job(job)

      json = api_call(:get, "/api/v1/courses/#{@course.id}/discussion_topics/#{@topic.id}/view",
                { :controller => "discussion_topics_api", :action => "view", :format => "json", :course_id => @course.id.to_s, :topic_id => @topic.id.to_s })

      json['unread_entries'].size.should == 2 # two marked read, then ones this user wrote are never unread
      json['unread_entries'].sort.should == (@topic.discussion_entries - [@root2, @reply3] - @topic.discussion_entries.select { |e| e.user == @user }).map(&:id).sort

      json['participants'].sort_by { |h| h['id'] }.should == [
        { 'id' => @student.id, 'display_name' => @student.short_name, 'avatar_image_url' => "http://www.example.com/images/users/#{User.avatar_key(@student.id)}", "html_url" => "http://www.example.com/courses/#{@course.id}/users/#{@student.id}" },
        { 'id' => @teacher.id, 'display_name' => @teacher.short_name, 'avatar_image_url' => "http://www.example.com/images/users/#{User.avatar_key(@teacher.id)}", "html_url" => "http://www.example.com/courses/#{@course.id}/users/#{@teacher.id}" },
      ].sort_by { |h| h['id'] }

      reply_reply1_attachment_json = {
        "content-type"=>"application/loser",
        "url"=>"http://#{Account.default.domain}/files/#{@attachment.id}/download?download_frd=1&verifier=#{@attachment.uuid}",
        "filename"=>"unknown.loser",
        "display_name"=>"unknown.loser",
        "id" => @attachment.id,
        "size" => 100,
      }

      json['view'].should == [
        {
          'id' => @root1.id,
          'parent_id' => nil,
          'user_id' => @student.id,
          'message' => "root1",
          'created_at' => @root1.created_at.as_json,
          'updated_at' => @root1.updated_at.as_json,
          'replies' => [
            {
              'id' => @reply1.id,
              'deleted' => true,
              'parent_id' => @root1.id,
              'created_at' => @reply1.created_at.as_json,
              'updated_at' => @reply1.updated_at.as_json,
              'replies' => [ {
                'id' => @reply_reply2.id,
                'parent_id' => @reply1.id,
                'user_id' => @student.id,
                'message' => 'reply_reply2',
                'created_at' => @reply_reply2.created_at.as_json,
                'updated_at' => @reply_reply2.updated_at.as_json,
               } ],
            },
            { 'id' => @reply2.id,
              'parent_id' => @root1.id,
              'user_id' => @teacher.id,
              'message' => "<p><a href=\"http://#{Account.default.domain}/files/#{@reply2_attachment.id}/download?verifier=#{@reply2_attachment.uuid}\">This is a file link</a></p>\n    <p>This is a video:\n      <video poster=\"http://#{Account.default.domain}/media_objects/0_abcde/thumbnail?height=448&amp;type=3&amp;width=550\" data-media_comment_type=\"video\" preload=\"none\" class=\"instructure_inline_media_comment\" data-media_comment_id=\"0_abcde\" controls=\"controls\" src=\"http://#{Account.default.domain}/courses/#{@course.id}/media_download?entryId=0_abcde&amp;redirect=1&amp;type=mp4\"></video>\n    </p>",
              'created_at' => @reply2.created_at.as_json,
              'updated_at' => @reply2.updated_at.as_json,
              'replies' => [ {
                'id' => @reply_reply1.id,
                'parent_id' => @reply2.id,
                'user_id' => @student.id,
                'editor_id' => @teacher.id,
                'message' => '<p>censored</p>',
                'created_at' => @reply_reply1.created_at.as_json,
                'updated_at' => @reply_reply1.updated_at.as_json,
                'attachment' => reply_reply1_attachment_json,
                'attachments' => [reply_reply1_attachment_json]
              } ],
            },
          ],
        },
        {
          'id' => @root2.id,
          'parent_id' => nil,
          'user_id' => @student.id,
          'message' => 'root2',
          'created_at' => @root2.created_at.as_json,
          'updated_at' => @root2.updated_at.as_json,
          'replies' => [
            {
              'id' => @reply3.id,
              'parent_id' => @root2.id,
              'user_id' => @student.id,
              'message' => 'reply3',
              'created_at' => @reply3.created_at.as_json,
              'updated_at' => @reply3.updated_at.as_json,
            },
          ],
        },
      ]
    end

    it "should include new entries if the flag is given" do
      course_with_teacher(:active_all => true)
      student_in_course(:course => @course, :active_all => true)
      @topic = @course.discussion_topics.create!(:title => "title", :message => "message", :user => @teacher, :discussion_type => 'threaded')
      @root1 = @topic.reply_from(:user => @student, :html => "root1")

      run_transaction_commit_callbacks
      job = Delayed::Job.find_by_strand("materialized_discussion:#{@topic.id}")
      job.should be_present
      run_job(job)

      # make everything slightly in the past to test updating
      DiscussionEntry.update_all(:updated_at => 5.minutes.ago)
      @reply1 = @root1.reply_from(:user => @teacher, :html => "reply1")
      @reply2 = @root1.reply_from(:user => @teacher, :html => "reply2")

      json = api_call(:get, "/api/v1/courses/#{@course.id}/discussion_topics/#{@topic.id}/view",
                { :controller => "discussion_topics_api", :action => "view", :format => "json", :course_id => @course.id.to_s, :topic_id => @topic.id.to_s }, { :include_new_entries => '1' })
      json['unread_entries'].size.should == 2
      json['unread_entries'].sort.should == [@reply1.id, @reply2.id]

      json['participants'].map { |h| h['id'] }.sort.should == [@teacher.id, @student.id]

      json['view'].should == [
        'id' => @root1.id,
        'parent_id' => nil,
        'user_id' => @student.id,
        'message' => 'root1',
        'created_at' => @root1.created_at.as_json,
        'updated_at' => @root1.updated_at.as_json,
      ]

      # it's important that these are returned in created_at order
      json['new_entries'].should == [
        {
          'id' => @reply1.id,
          'created_at' => @reply1.created_at.as_json,
          'updated_at' => @reply1.updated_at.as_json,
          'message' => 'reply1',
          'parent_id' => @root1.id,
          'user_id' => @teacher.id,
        },
        {
          'id' => @reply2.id,
          'created_at' => @reply2.created_at.as_json,
          'updated_at' => @reply2.updated_at.as_json,
          'message' => 'reply2',
          'parent_id' => @root1.id,
          'user_id' => @teacher.id,
        },
      ]
    end
  end

  context "collection items" do
    before(:each) do
      @collection = @user.collections.create!(:name => 'test1', :visibility => 'private')
      @item = collection_item_model(:user_comment => "item 1", :user => @collection.context, :collection => @collection, :collection_item_data => collection_item_data_model(:link_url => "http://www.example.com/one"))
    end

    it "should return a discussion topic for an item" do
      json = api_call(:get, "/api/v1/collection_items/#{@item.id}/discussion_topics/self",
        { :collection_item_id => "#{@item.id}", :controller => "discussion_topics_api", :format => "json", :action => "show", :topic_id => "self"})
      json["discussion_subentry_count"].should == 0
      json["posted_at"].should be_nil
    end

    it "should return an empty discussion view for an item" do
      json = api_call(:get, "/api/v1/collection_items/#{@item.id}/discussion_topics/self/view",
        { :collection_item_id => "#{@item.id}", :controller => "discussion_topics_api", :format => "json", :action => "view", :topic_id => "self"})
      json.should == { "participants" => [], "unread_entries" => [], "view" => [], "new_entries" => [] }
      @item.discussion_topic.should be_new_record
    end

    it "should create a discussion topic when someone attempts to comment" do
      message = "oh that is awesome"
      json = nil
      expect {
        json = api_call(
          :post, "/api/v1/collection_items/#{@item.id}/discussion_topics/self/entries.json",
          { :controller => 'discussion_topics_api', :action => 'add_entry', :format => 'json',
            :collection_item_id => @item.id.to_s, :topic_id => "self" },
          { :message => message })
      }.to change(DiscussionTopic, :count).by(1)
      json.should_not be_nil
      json['id'].should_not be_nil
      @entry = DiscussionEntry.find_by_id(json['id'])
      @entry.should_not be_nil
      @entry.message.should == message
      @entry.user.should == @user
      @entry.parent_entry.should be_nil
    end

    it "should return a discussion's details for a collection item after there are posts" do
      @topic = @item.discussion_topic
      @topic.save!
      @entry1 = create_entry(@topic, :message => "loved it")
      @entry2 = create_entry(@topic, :message => "ditto")
      @topic.create_materialized_view
      json = api_call(:get, "/api/v1/collection_items/#{@item.id}/discussion_topics/self/view",
        { :collection_item_id => "#{@item.id}", :controller => "discussion_topics_api", :format => "json", :action => "view", :topic_id => "self"})
      json['participants'].length.should == 1
      json['unread_entries'].length.should == 0
      json['new_entries'].length.should == 0
      json['view'].should == [{
          "created_at" => @entry1.created_at.as_json,
          "updated_at" => @entry1.updated_at.as_json,
          "id" => @entry1.id,
          "user_id" => @user.id,
          "parent_id" => nil,
          "message" => "loved it"
        }, {
          "created_at" => @entry2.created_at.as_json,
          "updated_at" => @entry2.updated_at.as_json,
          "id" => @entry2.id,
          "user_id" => @user.id,
          "parent_id" => nil,
          "message" => "ditto"
      }]
    end

    it "should mark entries as read on a collection item" do
      Collection.update_all({ :visibility => 'public' }, { :id => @collection.id })
      @collection.reload
      topic = @item.discussion_topic
      topic.save!
      entry = create_entry(topic, :message => "loved it")

      student_in_course(:course => @course, :user => user_with_pseudonym)
      entry.read?(@user).should be_false
      json = raw_api_call(:put, "/api/v1/collection_items/#{@item.id}/discussion_topics/self/entries/#{entry.id}/read.json",
                { :controller => 'discussion_topics_api', :action => 'mark_entry_read', :format => 'json',
                  :collection_item_id => @item.id.to_s, :topic_id => "self", :entry_id => entry.id.to_s })
      puts json
      entry.reload.read?(@user).should be_true
    end
  end
end

def create_attachment(context, opts={})
  opts[:uploaded_data] ||= StringIO.new('attachment content')
  opts[:filename] ||= 'content.txt'
  opts[:display_name] ||= opts[:filename]
  opts[:folder] ||= Folder.unfiled_folder(context)
  attachment = context.attachments.build(opts)
  attachment.save!
  attachment
end

def create_topic(context, opts={})
  attachment = opts.delete(:attachment)
  opts[:user] ||= @user
  topic = context.discussion_topics.build(opts)
  topic.attachment = attachment if attachment
  topic.save!
  topic
end

def create_subtopic(topic, opts={})
  opts[:user] ||= @user
  subtopic = topic.context.discussion_topics.build(opts)
  subtopic.root_topic_id = topic.id
  subtopic.save!
  subtopic
end

def create_entry(topic, opts={})
  attachment = opts.delete(:attachment)
  created_at = opts.delete(:created_at)
  opts[:user] ||= @user
  entry = topic.discussion_entries.build(opts)
  entry.attachment = attachment if attachment
  entry.created_at = created_at if created_at
  entry.save!
  entry
end

def create_reply(entry, opts={})
  created_at = opts.delete(:created_at)
  opts[:user] ||= @user
  opts[:html] ||= opts.delete(:message)
  opts[:html] ||= "<p>This is a test message</p>"
  reply = entry.reply_from(opts)
  reply.created_at = created_at if created_at
  reply.save!
  reply
end
