#
# Copyright (C) 2012 Instructure, Inc.
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

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe DiscussionEntriesController do
  before :once do
    course_with_teacher(:active_all => true)
    student_in_course(:active_all => true)
    @topic = @course.discussion_topics.create(:title => "some topic")
    @entry = @topic.discussion_entries.create(:message => "some message", :user => @student)
  end

  def topic_with_media_reply
    @topic.update_attribute(:podcast_enabled, true)
    @mo1 = @course.media_objects.build(:media_id => 'asdf', :title => 'asdf')
    @mo1.data = {:extensions => {:mp4 => {
      :size => 100, 
      :extension => 'mp4'
    }}}
    @mo1.save!
    @entry = @topic.discussion_entries.create!(:user => @student, :message => " media_comment_asdf ")
  end

  describe "GET 'show'" do
    it "should require authorization" do
      get 'show', :course_id => @course.id, :id => @entry.id
      assert_unauthorized
    end
    
    it "should assign variables" do
      user_session(@student)
      get 'show', :course_id => @course.id, :id => @entry.id, :format => :json
      # response.should be_success
      assigns[:entry].should_not be_nil
      assigns[:entry].should eql(@entry)
    end
  end
  
  describe "POST 'create'" do
    it "should require authorization" do
      post 'create', :course_id => @course.id, :discussion_entry => {:discussion_topic_id => @topic.id, :message => "yo"}
      assert_unauthorized
    end
    
    it "should create a message" do
      user_session(@student)
      post 'create', :course_id => @course.id, :discussion_entry => {:discussion_topic_id => @topic.id, :message => "yo"}
      assigns[:topic].should eql(@topic)
      assigns[:entry].should_not be_nil
      assigns[:entry].message.should eql("yo")
      response.should be_redirect
    end
    
    it "should attach a file if authorized" do
      user_session(@teacher)
      post 'create', :course_id => @course.id, :discussion_entry => {:discussion_topic_id => @topic.id, :message => "yo"}, :attachment => {:uploaded_data => default_uploaded_data}
      assigns[:topic].should eql(@topic)
      assigns[:entry].should_not be_nil
      assigns[:entry].message.should eql("yo")
      assigns[:entry].attachment.should_not be_nil
      response.should be_redirect
    end
    
    it "should NOT attach a file if not authorized" do
      user_session(@student)
      post 'create', :course_id => @course.id, :discussion_entry => {:discussion_topic_id => @topic.id, :message => "yo"}, :attachment => {:uploaded_data => default_uploaded_data}
      assigns[:topic].should eql(@topic)
      assigns[:entry].should_not be_nil
      assigns[:entry].message.should eql("yo")
      assigns[:entry].attachment.should be_nil
      response.should be_redirect
    end

    it "should create a submission if the topic has an assignment" do
      course_with_student_logged_in(active_all: true, :course => @course)
      assignment_model(:course => @course)
      @topic.assignment = @assignment
      @topic.save
      @student.submissions.should be_empty

      post 'create', :course_id => @course.id, :discussion_entry => {:discussion_topic_id => @topic.id, :message => "yo"}
      response.should be_redirect

      @student.reload
      @student.submissions.size.should == 1
      @student.submissions.first.submission_type.should == 'discussion_topic'
    end
  end
  
  describe "PUT 'update'" do
    it "should require authorization" do
      put 'update', :course_id => @course.id, :id => @entry.id, :discussion_entry => {}
      assert_unauthorized
    end
    
    it "should update the entry" do
      user_session(@teacher)
      put 'update', :course_id => @course.id, :id => @entry.id, :discussion_entry => {:message => "ahem"}
      response.should be_redirect
      assigns[:entry].should eql(@entry)
      assigns[:entry].message.should eql("ahem")
    end
    
    it "should attach a new file to the entry" do
      user_session(@teacher)
      put 'update', :course_id => @course.id, :id => @entry.id, :discussion_entry => {:message => "ahem"}, :attachment => {:uploaded_data => default_uploaded_data}
      response.should be_redirect
      assigns[:entry].should eql(@entry)
      assigns[:entry].message.should eql("ahem")
      assigns[:entry].attachment.should_not be_nil
    end
    
    it "should replace the file to the entry" do
      user_session(@teacher)
      @a = @course.attachments.create!(:uploaded_data => default_uploaded_data)
      @entry.attachment = @a
      @entry.save
      put 'update', :course_id => @course.id, :id => @entry.id, :discussion_entry => {:message => "ahem"}, :attachment => {:uploaded_data => default_uploaded_data}
      response.should be_redirect
      assigns[:entry].should eql(@entry)
      assigns[:entry].message.should eql("ahem")
      assigns[:entry].attachment.should_not be_nil
      assigns[:entry].attachment.should_not eql(@a)
    end
    
    it "should replace the file to the entry" do
      user_session(@teacher)
      @a = @course.attachments.create!(:uploaded_data => default_uploaded_data)
      @entry.attachment = @a
      @entry.save
      put 'update', :course_id => @course.id, :id => @entry.id, :discussion_entry => {:message => "ahem", :remove_attachment => '1'}
      response.should be_redirect
      assigns[:entry].should eql(@entry)
      assigns[:entry].message.should eql("ahem")
      assigns[:entry].attachment.should be_nil
    end
    
    it "should not replace the file to the entry if not authorized" do
      user_session(@student)
      put 'update', :course_id => @course.id, :id => @entry.id, :discussion_entry => {:message => "ahem"}, :attachment => {:uploaded_data => default_uploaded_data}
      response.should be_redirect
      assigns[:entry].should eql(@entry)
      assigns[:entry].message.should eql("ahem")
      assigns[:entry].attachment.should be_nil
    end
    
    it "should set the editor_id to whoever edited to entry" do
      user_session(@teacher)
      @entry = @topic.discussion_entries.build(:message => "test")
      @entry.user = @student
      @entry.save!
      @entry.user.should eql(@student)
      @entry.editor.should eql(nil)
      put 'update', :course_id => @course.id, :id => @entry.id, :discussion_entry => {:message => "new message"}
      response.should be_redirect
      assigns[:entry].editor.should eql(@teacher)
      assigns[:entry].user.should eql(@student)
    end
  end
  
  describe "DELETE 'destroy'" do
    it "should require authorization" do
      delete 'destroy', :course_id => @course.id, :id => @entry.id
      assert_unauthorized
    end
    
    it "should delete the entry" do
      user_session(@teacher)
      delete 'destroy', :course_id => @course.id, :id => @entry.id
      response.should be_redirect

      @entry.reload
      @entry.editor.should eql(@teacher)

      @topic.reload
      @topic.discussion_entries.should_not be_empty
      @topic.discussion_entries.active.should be_empty
    end
  end
  
  describe "GET 'public_feed.rss'" do
    before :once do
      @entry.destroy
    end

    it "should require authorization" do
      get 'public_feed', :discussion_topic_id => @topic.id, :format => 'rss', :feed_code => @enrollment.feed_code + "x"
      assigns[:problem].should eql("The verification code does not match any currently enrolled user.")
      response.should
    end
    
    it "should require the podcast to be enabled" do
      get 'public_feed', :discussion_topic_id => @topic.id, :format => 'rss', :feed_code => @enrollment.feed_code
      assigns[:problem].should eql("Podcasts have not been enabled for this topic.")
      response.should
    end
    
    it "should return a valid RSS feed" do
      @topic.update_attribute(:podcast_enabled, true)
      get 'public_feed', :discussion_topic_id => @topic.id, :format => 'rss', :feed_code => @enrollment.feed_code
      assigns[:entries].should_not be_nil
      require 'rss/2.0'
      rss = RSS::Parser.parse(response.body, false) rescue nil
      rss.should_not be_nil
      rss.channel.title.should eql("some topic Posts Podcast Feed")
      rss.items.length.should eql(0)
    end

    it "should leave out deleted media comments" do
      topic_with_media_reply
      @topic.update_attribute(:podcast_has_student_posts, true)
      @mo1.destroy
      get 'public_feed', :discussion_topic_id => @topic.id, :format => 'rss', :feed_code => @enrollment.feed_code
      require 'rss/2.0'
      rss = RSS::Parser.parse(response.body, false) rescue nil
      rss.should_not be_nil
      rss.channel.title.should eql("some topic Posts Podcast Feed")
      rss.items.length.should eql(0)
    end
    
    it "should include student entries if enabled" do
      topic_with_media_reply
      @topic.update_attribute(:podcast_has_student_posts, true)
      get 'public_feed', :discussion_topic_id => @topic.id, :format => 'rss', :feed_code => @enrollment.feed_code
      assigns[:entries].should_not be_nil
      assigns[:entries].should_not be_empty
      require 'rss/2.0'
      rss = RSS::Parser.parse(response.body, false) rescue nil
      rss.should_not be_nil
      rss.channel.title.should eql("some topic Posts Podcast Feed")
      rss.items.length.should eql(1)
      assigns[:discussion_entries].should_not be_empty
      assigns[:discussion_entries][0].should eql(@entry)
    end
    
    it "should not include student entries if locked" do
      topic_with_media_reply
      @topic.update_attribute(:podcast_has_student_posts, true)
      @topic.update_attribute(:delayed_post_at, 2.days.from_now)
      @topic.locked_for?(@student).should_not eql(nil)
      get 'public_feed', :discussion_topic_id => @topic.id, :format => 'rss', :feed_code => @enrollment.feed_code
      assigns[:entries].should_not be_nil
      assigns[:entries].should_not be_empty
      require 'rss/2.0'
      rss = RSS::Parser.parse(response.body, false) rescue nil
      rss.should_not be_nil
      rss.channel.title.should eql("some topic Posts Podcast Feed")
      rss.items.length.should eql(0)
      assigns[:discussion_entries].should be_empty
      assigns[:all_discussion_entries].should_not be_empty
    end
    
    it "should not include student entries if initial post is required but missing" do
      topic_with_media_reply
      @user = user_model
      @enrollment = @course.enroll_student(@user)
      @enrollment.accept!
      @topic.update_attribute(:podcast_has_student_posts, true)
      @topic.update_attribute(:require_initial_post, true)
      @topic.locked_for?(@user).should_not eql(nil)
      get 'public_feed', :discussion_topic_id => @topic.id, :format => 'rss', :feed_code => @enrollment.feed_code
      assigns[:entries].should_not be_nil
      assigns[:entries].should_not be_empty
      require 'rss/2.0'
      rss = RSS::Parser.parse(response.body, false) rescue nil
      rss.should_not be_nil
      rss.channel.title.should eql("some topic Posts Podcast Feed")
      rss.items.length.should eql(0)
      assigns[:discussion_entries].should be_empty
      assigns[:all_discussion_entries].should_not be_empty
    end

    it "should include student entries if initial post is required and given" do
      topic_with_media_reply
      @topic.update_attribute(:podcast_has_student_posts, true)
      @topic.update_attribute(:require_initial_post, true)
      get 'public_feed', :discussion_topic_id => @topic.id, :format => 'rss', :feed_code => @enrollment.feed_code
      assigns[:entries].should_not be_nil
      assigns[:entries].should_not be_empty
      require 'rss/2.0'
      rss = RSS::Parser.parse(response.body, false) rescue nil
      rss.should_not be_nil
      rss.channel.title.should eql("some topic Posts Podcast Feed")
      rss.items.length.should eql(1)
      assigns[:discussion_entries].should_not be_empty
      assigns[:discussion_entries][0].should eql(@entry)
    end

    it "should not include student entries if disabled" do
      topic_with_media_reply
      get 'public_feed', :discussion_topic_id => @topic.id, :format => 'rss', :feed_code => @enrollment.feed_code
      assigns[:entries].should_not be_nil
      require 'rss/2.0'
      rss = RSS::Parser.parse(response.body, false) rescue nil
      rss.should_not be_nil
      rss.channel.title.should eql("some topic Posts Podcast Feed")
      rss.items.length.should eql(0)
    end
  end
end
