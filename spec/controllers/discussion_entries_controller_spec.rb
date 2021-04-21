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
      get 'show', params: {:course_id => @course.id, :id => @entry.id}
      assert_unauthorized
    end

    it "should require course to be published for students" do
      user_session(@student)
      @course.claim
      get 'show', params: {:course_id => @course.id, :id => @entry.id}
      assert_unauthorized
    end

    it "should assign variables" do
      user_session(@student)
      get 'show', params: {:course_id => @course.id, :id => @entry.id}, :format => :json
      # response.should be_successful
      expect(assigns[:entry]).not_to be_nil
      expect(assigns[:entry]).to eql(@entry)
    end
  end

  describe "POST 'create'" do
    it "should require authorization" do
      post 'create', params: {:course_id => @course.id, :discussion_entry => {:discussion_topic_id => @topic.id, :message => "yo"}}
      assert_unauthorized
    end

    it "should create a message" do
      user_session(@student)
      post 'create', params: {:course_id => @course.id, :discussion_entry => {:discussion_topic_id => @topic.id, :message => "yo"}}
      expect(assigns[:topic]).to eql(@topic)
      expect(assigns[:entry]).not_to be_nil
      expect(assigns[:entry].message).to eql("yo")
      expect(response).to be_redirect
    end

    it "should attach a file if authorized" do
      user_session(@teacher)
      post 'create', params: {:course_id => @course.id, :discussion_entry => {:discussion_topic_id => @topic.id, :message => "yo"}, :attachment => {:uploaded_data => default_uploaded_data}}
      expect(assigns[:topic]).to eql(@topic)
      expect(assigns[:entry]).not_to be_nil
      expect(assigns[:entry].message).to eql("yo")
      expect(assigns[:entry].attachment).not_to be_nil
      expect(response).to be_redirect
    end

    it "should NOT attach a file if not authorized" do
      @course.allow_student_forum_attachments = false
      @course.save!
      user_session(@student)
      post 'create', params: {:course_id => @course.id, :discussion_entry => {:discussion_topic_id => @topic.id, :message => "yo"}, :attachment => {:uploaded_data => default_uploaded_data}}
      expect(assigns[:topic]).to eql(@topic)
      expect(assigns[:entry]).not_to be_nil
      expect(assigns[:entry].message).to eql("yo")
      expect(assigns[:entry].attachment).to be_nil
      expect(response).to be_redirect
    end

    it "should create a submission if the topic has an assignment" do
      course_with_student_logged_in(active_all: true, :course => @course)
      assignment_model(:course => @course)
      @topic.assignment = @assignment
      @topic.save
      expect(@student.submissions.not_placeholder).to be_empty

      post 'create', params: {:course_id => @course.id, :discussion_entry => {:discussion_topic_id => @topic.id, :message => "yo"}}
      expect(response).to be_redirect

      @student.reload
      expect(@student.submissions.not_placeholder.size).to eq 1
      expect(@student.submissions.not_placeholder.first.submission_type).to eq 'discussion_topic'
    end
  end

  describe "PUT 'update'" do
    it "should require authorization" do
      put 'update', params: {:course_id => @course.id, :id => @entry.id, :discussion_entry => {}}
      assert_unauthorized
    end

    it "should update the entry" do
      user_session(@teacher)
      put 'update', params: {:course_id => @course.id, :id => @entry.id, :discussion_entry => {:message => "ahem"}}
      expect(response).to be_redirect
      expect(assigns[:entry]).to eql(@entry)
      expect(assigns[:entry].message).to eql("ahem")
    end

    it "should attach a new file to the entry" do
      user_session(@teacher)
      put 'update', params: {:course_id => @course.id, :id => @entry.id, :discussion_entry => {:message => "ahem"}, :attachment => {:uploaded_data => default_uploaded_data}}
      expect(response).to be_redirect
      expect(assigns[:entry]).to eql(@entry)
      expect(assigns[:entry].message).to eql("ahem")
      expect(assigns[:entry].attachment).not_to be_nil
    end

    it "should replace the file on the entry" do
      user_session(@teacher)
      @a = @course.attachments.create!(:uploaded_data => default_uploaded_data)
      @entry.attachment = @a
      @entry.save
      put 'update', params: {:course_id => @course.id, :id => @entry.id, :discussion_entry => {:message => "ahem"}, :attachment => {:uploaded_data => default_uploaded_data}}
      expect(response).to be_redirect
      expect(assigns[:entry]).to eql(@entry)
      expect(assigns[:entry].message).to eql("ahem")
      expect(assigns[:entry].attachment).not_to be_nil
      expect(assigns[:entry].attachment).not_to eql(@a)
    end

    it "should remove the file from the entry" do
      user_session(@teacher)
      @a = @course.attachments.create!(:uploaded_data => default_uploaded_data)
      @entry.attachment = @a
      @entry.save
      put 'update', params: {:course_id => @course.id, :id => @entry.id, :discussion_entry => {:message => "ahem", :remove_attachment => '1'}}
      expect(response).to be_redirect
      expect(assigns[:entry]).to eql(@entry)
      expect(assigns[:entry].message).to eql("ahem")
      expect(assigns[:entry].attachment).to be_nil
    end

    it "should not replace the file to the entry if not authorized" do
      @course.allow_student_forum_attachments = false
      @course.save!
      user_session(@student)
      put 'update', params: {:course_id => @course.id, :id => @entry.id, :discussion_entry => {:message => "ahem"}, :attachment => {:uploaded_data => default_uploaded_data}}
      expect(response).to be_redirect
      expect(assigns[:entry]).to eql(@entry)
      expect(assigns[:entry].message).to eql("ahem")
      expect(assigns[:entry].attachment).to be_nil
    end

    it "should set the editor_id to whoever edited to entry" do
      user_session(@teacher)
      @entry = @topic.discussion_entries.build(:message => "test")
      @entry.user = @student
      @entry.save!
      expect(@entry.user).to eql(@student)
      expect(@entry.editor).to eql(nil)
      put 'update', params: {:course_id => @course.id, :id => @entry.id, :discussion_entry => {:message => "new message"}}
      expect(response).to be_redirect
      expect(assigns[:entry].editor).to eql(@teacher)
      expect(assigns[:entry].user).to eql(@student)
    end
  end

  describe "DELETE 'destroy'" do
    it "should require authorization" do
      delete 'destroy', params: {:course_id => @course.id, :id => @entry.id}
      assert_unauthorized
    end

    it "should delete the entry" do
      user_session(@teacher)
      delete 'destroy', params: {:course_id => @course.id, :id => @entry.id}
      expect(response).to be_redirect

      @entry.reload
      expect(@entry.editor).to eql(@teacher)

      @topic.reload
      expect(@topic.discussion_entries).not_to be_empty
      expect(@topic.discussion_entries.active).to be_empty
    end
  end

  describe "GET 'public_feed.rss'" do
    before :once do
      @entry.destroy
    end

    it "should require authorization" do
      get 'public_feed', params: {:discussion_topic_id => @topic.id, :feed_code => @enrollment.feed_code + "x"}, :format => 'rss'
      expect(assigns[:problem]).to eql("The verification code does not match any currently enrolled user.")
    end

    it "should require the podcast to be enabled" do
      get 'public_feed', params: {:discussion_topic_id => @topic.id, :feed_code => @enrollment.feed_code}, :format => 'rss'
      expect(assigns[:problem]).to eql("Podcasts have not been enabled for this topic.")
    end

    it "should return a valid RSS feed" do
      @topic.update_attribute(:podcast_enabled, true)
      get 'public_feed', params: {:discussion_topic_id => @topic.id, :feed_code => @enrollment.feed_code}, :format => 'rss'
      expect(assigns[:entries]).not_to be_nil
      require 'rss/2.0'
      rss = RSS::Parser.parse(response.body, false) rescue nil
      expect(rss).not_to be_nil
      expect(rss.channel.title).to eql("some topic Posts Podcast Feed")
      expect(rss.items.length).to eql(0)
    end

    it "should leave out deleted media comments" do
      topic_with_media_reply
      @topic.update_attribute(:podcast_has_student_posts, true)
      @mo1.destroy
      get 'public_feed', params: {:discussion_topic_id => @topic.id, :feed_code => @enrollment.feed_code}, :format => 'rss'
      require 'rss/2.0'
      rss = RSS::Parser.parse(response.body, false) rescue nil
      expect(rss).not_to be_nil
      expect(rss.channel.title).to eql("some topic Posts Podcast Feed")
      expect(rss.items.length).to eql(0)
    end

    it "should include media comments generated with rce enhancements" do
      topic_with_media_reply
      @topic.update_attribute(:podcast_has_student_posts, true)
      @entry.update_attribute(:message, "<iframe data-media-id=\"#{@mo1.media_id}\"></iframe>")
      get 'public_feed', params: {:discussion_topic_id => @topic.id, :feed_code => @enrollment.feed_code}, :format => 'rss'
      require 'rss/2.0'
      rss = RSS::Parser.parse(response.body, false) rescue nil
      expect(rss).not_to be_nil
      expect(rss.channel.title).to eql("some topic Posts Podcast Feed")
      expect(rss.items.length).to eql(1)
      expected_url = "courses/#{@course.id}/media_download.mp4?type=mp4&entryId=#{@mo1.media_id}&redirect=1"
      expect(rss.items.first.enclosure.url).to end_with(expected_url)
    end

    it "should leave out media objects if the attachment is already included" do
      topic_with_media_reply
      @topic.update_attribute(:podcast_has_student_posts, true)

      @a = attachment_model(:context => @course, :filename => 'test.mp4', :content_type => 'video')
      @a.media_entry_id = @mo1.media_id
      @a.save!
      @topic.discussion_entries.create!(:user => @student, :message => " /courses/#{@course.id}/files/#{@a.id}/download ")

      get 'public_feed', params: {:discussion_topic_id => @topic.id, :feed_code => @enrollment.feed_code}, :format => 'rss'
      require 'rss/2.0'
      rss = RSS::Parser.parse(response.body, false) rescue nil
      expect(rss).not_to be_nil
      expect(rss.channel.title).to eql("some topic Posts Podcast Feed")
      expect(rss.items.length).to eql(1)
      expected_url = "courses/#{@course.id}/files/#{@a.id}/download.mp4?verifier=#{@a.uuid}"
      expect(rss.items.first.enclosure.url).to end_with(expected_url)
    end

    it "should include student entries if enabled" do
      topic_with_media_reply
      @topic.update_attribute(:podcast_has_student_posts, true)
      get 'public_feed', params: {:discussion_topic_id => @topic.id, :feed_code => @enrollment.feed_code}, :format => 'rss'
      expect(assigns[:entries]).not_to be_nil
      expect(assigns[:entries]).not_to be_empty
      require 'rss/2.0'
      rss = RSS::Parser.parse(response.body, false) rescue nil
      expect(rss).not_to be_nil
      expect(rss.channel.title).to eql("some topic Posts Podcast Feed")
      expect(rss.items.length).to eql(1)
      expected_url = "courses/#{@course.id}/media_download.mp4?type=mp4&entryId=#{@mo1.media_id}&redirect=1"
      expect(rss.items.first.enclosure.url).to end_with(expected_url)
      expect(assigns[:discussion_entries]).not_to be_empty
      expect(assigns[:discussion_entries][0]).to eql(@entry)
    end

    it "should include student entries when media is from user context if enabled" do
      @topic.update_attribute(:podcast_enabled, true)
      @student_mo1 = @student.media_objects.build(:media_id => 'asdf', :title => 'asdf')
      @student_mo1.data = {:extensions => {:mp4 => {:size => 100, :extension => 'mp4'}}}
      @student_mo1.save!
      @entry = @topic.discussion_entries.create!(:user => @student, :message => " media_comment_asdf ")
      @entry.update_attribute(:message, "<iframe data-media-id=\"#{@student_mo1.media_id}\"></iframe>")
      @topic.update_attribute(:podcast_has_student_posts, true)
      get 'public_feed', params: {:discussion_topic_id => @topic.id, :feed_code => @enrollment.feed_code}, :format => 'rss'
      expect(assigns[:entries]).not_to be_nil
      expect(assigns[:entries]).not_to be_empty
      require 'rss/2.0'
      rss = RSS::Parser.parse(response.body, false) rescue nil
      expect(rss).not_to be_nil
      expect(rss.channel.title).to eql("some topic Posts Podcast Feed")
      expect(rss.items.length).to eql(1)
      expected_url = "users/#{@student.id}/media_download.mp4?type=mp4&entryId=#{@student_mo1.media_id}&redirect=1"
      expect(rss.items.first.enclosure.url).to end_with(expected_url)
      expect(assigns[:discussion_entries]).not_to be_empty
      expect(assigns[:discussion_entries][0]).to eql(@entry)
    end

    it "should not include media objects from another course if enabled" do
      @topic.update_attribute(:podcast_enabled, true)
      @other_course = Course.create!
      @other_mo = @other_course.media_objects.build(:media_id => 'asdf', :title => 'asdf')
      @other_mo.data = {:extensions => {:mp4 => {:size => 100, :extension => 'mp4'}}}
      @other_mo.save!
      @entry = @topic.discussion_entries.create!(:user => @teacher, :message => " media_comment_asdf ")
      @entry.update_attribute(:message, "<iframe data-media-id=\"#{@other_mo.media_id}\"></iframe>")

      get 'public_feed', params: {:discussion_topic_id => @topic.id, :feed_code => @enrollment.feed_code}, :format => 'rss'
      expect(assigns[:entries]).not_to be_nil
      expect(assigns[:entries]).not_to be_empty
      require 'rss/2.0'
      rss = RSS::Parser.parse(response.body, false) rescue nil
      expect(rss).not_to be_nil
      expect(rss.channel.title).to eql("some topic Posts Podcast Feed")
      expect(rss.items.length).to eql(0)
      expect(assigns[:discussion_entries]).not_to be_empty
      expect(assigns[:discussion_entries][0]).to eql(@entry)
    end

    it "should not include student entries if locked" do
      topic_with_media_reply
      @topic.update_attribute(:podcast_has_student_posts, true)
      @topic.update_attribute(:delayed_post_at, 2.days.from_now)
      expect(@topic.locked_for?(@student)).not_to eql(nil)
      get 'public_feed', params: {:discussion_topic_id => @topic.id, :feed_code => @enrollment.feed_code}, :format => 'rss'
      expect(assigns[:entries]).not_to be_nil
      expect(assigns[:entries]).not_to be_empty
      require 'rss/2.0'
      rss = RSS::Parser.parse(response.body, false) rescue nil
      expect(rss).not_to be_nil
      expect(rss.channel.title).to eql("some topic Posts Podcast Feed")
      expect(rss.items.length).to eql(0)
      expect(assigns[:discussion_entries]).to be_empty
    end

    it "should not include student entries if initial post is required but missing" do
      topic_with_media_reply
      @user = user_model
      @enrollment = @course.enroll_student(@user)
      @enrollment.accept!
      @topic.update_attribute(:podcast_has_student_posts, true)
      @topic.update_attribute(:require_initial_post, true)
      expect(@topic.locked_for?(@user)).not_to eql(nil)
      get 'public_feed', params: {:discussion_topic_id => @topic.id, :feed_code => @enrollment.feed_code}, :format => 'rss'
      expect(assigns[:entries]).not_to be_nil
      expect(assigns[:entries]).not_to be_empty
      require 'rss/2.0'
      rss = RSS::Parser.parse(response.body, false) rescue nil
      expect(rss).not_to be_nil
      expect(rss.channel.title).to eql("some topic Posts Podcast Feed")
      expect(rss.items.length).to eql(0)
      expect(assigns[:discussion_entries]).to be_empty
    end

    it "should include student entries if initial post is required and given" do
      topic_with_media_reply
      @topic.update_attribute(:podcast_has_student_posts, true)
      @topic.update_attribute(:require_initial_post, true)
      get 'public_feed', params: {:discussion_topic_id => @topic.id, :feed_code => @enrollment.feed_code}, :format => 'rss'
      expect(assigns[:entries]).not_to be_nil
      expect(assigns[:entries]).not_to be_empty
      require 'rss/2.0'
      rss = RSS::Parser.parse(response.body, false) rescue nil
      expect(rss).not_to be_nil
      expect(rss.channel.title).to eql("some topic Posts Podcast Feed")
      expect(rss.items.length).to eql(1)
      expect(assigns[:discussion_entries]).not_to be_empty
      expect(assigns[:discussion_entries][0]).to eql(@entry)
    end

    it "should not include student entries if disabled" do
      topic_with_media_reply
      get 'public_feed', params: {:discussion_topic_id => @topic.id, :feed_code => @enrollment.feed_code}, :format => 'rss'
      expect(assigns[:entries]).not_to be_nil
      require 'rss/2.0'
      rss = RSS::Parser.parse(response.body, false) rescue nil
      expect(rss).not_to be_nil
      expect(rss.channel.title).to eql("some topic Posts Podcast Feed")
      expect(rss.items.length).to eql(0)
    end

    it "should not error if data is missing and kaltura is unresponsive" do
      mock_client = double
      allow(mock_client).to receive(:startSession)
      allow(mock_client).to receive(:mediaGet).and_return(nil)
      allow(mock_client).to receive(:flavorAssetGetByEntryId).and_return(nil)
      allow(mock_client).to receive(:media_sources).and_return(nil)
      allow(CanvasKaltura::ClientV3).to receive(:new).and_return(mock_client)

      topic_with_media_reply
      @topic.update_attribute(:podcast_has_student_posts, true)
      @mo1.data = nil
      @mo1.save!

      get 'public_feed', params: {:discussion_topic_id => @topic.id, :feed_code => @enrollment.feed_code}, :format => 'rss'
      expect(assigns[:entries]).not_to be_nil
      require 'rss/2.0'
      rss = RSS::Parser.parse(response.body, false) rescue nil
      expect(rss).not_to be_nil
      expect(rss.channel.title).to eql("some topic Posts Podcast Feed")
      expect(rss.items.length).to eql(0)
    end

    it 'respects podcast_has_student_posts for course discussions' do
      @topic.update(podcast_enabled: true, podcast_has_student_posts: false)
      get 'public_feed', params: {:discussion_topic_id => @topic.id, :feed_code => @enrollment.feed_code}, :format => 'rss'
      expect(assigns[:discussion_entries].length).to eql 0
    end

    it 'always returns student entries for group discussions' do
      group_category
      membership = group_with_user(group_category: @group_category, user: @student)
      @topic = @group.discussion_topics.create(title: "group topic", user: @teacher)
      @entry = @topic.discussion_entries.create(message: "some message", user: @student)

      @topic.update(podcast_enabled: true, podcast_has_student_posts: false)
      get 'public_feed', params: {:discussion_topic_id => @topic.id, :feed_code => membership.feed_code}, :format => 'rss'
      expect(assigns[:discussion_entries].length).to eql 1
    end
  end
end
