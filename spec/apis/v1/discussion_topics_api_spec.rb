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

describe DiscussionTopicsController, :type => :integration do
  before(:each) do
    course_with_teacher(:active_all => true, :user => user_with_pseudonym)
  end

  it "should return discussion topic list" do
    attachment = create_attachment(@course)
    @topic = create_topic(@course, :title => "Topic 1", :message => "<p>content here</p>", :podcast_enabled => true, :attachment => attachment)
    sub = create_subtopic(@topic, :title => "Sub topic", :message => "<p>i'm subversive</p>")

    json = api_call(:get, "/api/v1/courses/#{@course.id}/discussion_topics.json",
                    {:controller => 'discussion_topics', :action => 'index', :format => 'json', :course_id => @course.id.to_s})

    # get rid of random characters in podcast url
    json.last["podcast_url"].gsub!(/_[^.]*/, '_randomness')
    json.last.should ==
                 {"podcast_url"=>"/feeds/topics/#{@topic.id}/enrollment_randomness.rss",
                  "require_initial_post"=>nil,
                  "title"=>"Topic 1",
                  "discussion_subentry_count"=>0,
                  "assignment_id"=>nil,
                  "delayed_post_at"=>nil,
                  "id"=>@topic.id,
                  "user_name"=>"User Name",
                  "last_reply_at"=>@topic.last_reply_at.as_json,
                  "message"=>"<p>content here</p>",
                  "posted_at"=>@topic.posted_at.as_json,
                  "root_topic_id"=>nil,
                  "url" => "http://www.example.com/courses/#{@course.id}/discussion_topics/#{@topic.id}",
                  "attachments"=>[{"content-type"=>"unknown/unknown",
                                   "url"=>"http://www.example.com/files/#{attachment.id}/download?download_frd=1&verifier=#{attachment.uuid}",
                                   "filename"=>"content.txt",
                                   "display_name"=>"content.txt"}],
                  "topic_children"=>[sub.id]}
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
    json.first.should == {"podcast_url"=>nil,
                          "require_initial_post"=>nil,
                          "title"=>"Group Topic 1",
                          "discussion_subentry_count"=>0,
                          "assignment_id"=>nil,
                          "delayed_post_at"=>nil,
                          "id"=>gtopic.id,
                          "user_name"=>"User Name",
                          "last_reply_at"=>gtopic.last_reply_at.as_json,
                          "message"=>"<p>content here</p>",
                          "url" => "http://www.example.com/groups/#{group.id}/discussion_topics/#{gtopic.id}",
                          "attachments"=>
                                  [{"content-type"=>"unknown/unknown",
                                    "url"=>"http://www.example.com/files/#{attachment.id}/download?download_frd=1&verifier=#{attachment.uuid}",
                                    "filename"=>"content.txt",
                                    "display_name"=>"content.txt"}],
                          "posted_at"=>gtopic.posted_at.as_json,
                          "root_topic_id"=>nil,
                          "topic_children"=>[]}
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
        "user_id" => @user.id,
        "user_name" => @user.name,
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

    it "should not allow reply-to-reply" do
      top_entry = create_entry(@topic, :message => 'top-level message')
      sub_entry = create_reply(top_entry, :message => 'reply message')
      raw_api_call(
        :post, "/api/v1/courses/#{@course.id}/discussion_topics/#{@topic.id}/entries/#{sub_entry.id}/replies.json",
        { :controller => 'discussion_topics_api', :action => 'add_reply', :format => 'json',
          :course_id => @course.id.to_s, :topic_id => @topic.id.to_s, :entry_id => sub_entry.id.to_s },
        { :message => @message })
      response.should_not be_success
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

    it "should silently ignore attachments on replies to top-level entries" do
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
      @entry.attachment.should be_nil
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
      entry_json['attachment']['url'].should == "http://www.example.com/files/#{@attachment.id}/download?download_frd=1&verifier=#{@attachment.uuid}"
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
  topic = context.discussion_topics.build(opts)
  topic.attachment = attachment if attachment
  topic.save!
  topic
end

def create_subtopic(topic, opts={})
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
  opts[:discussion_topic] = entry.discussion_topic
  reply = entry.discussion_subentries.build(opts)
  reply.created_at = created_at if created_at
  reply.save!
  reply
end
