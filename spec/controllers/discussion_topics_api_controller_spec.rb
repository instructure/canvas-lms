#
# Copyright (C) 2012 - present Instructure, Inc.
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

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe DiscussionTopicsApiController do
  describe 'POST add_entry' do
    before :once do
      Setting.set('enable_page_views', 'db')
      course_with_student :active_all => true
      @topic = @course.discussion_topics.create!(:title => 'discussion')
    end

    before :each do
      user_session(@student)
      allow(controller).to receive_messages(:form_authenticity_token => 'abc', :form_authenticity_param => 'abc')
      post 'add_entry', params: {:topic_id => @topic.id, :course_id => @course.id, :user_id => @user.id, :message => 'message', :read_state => 'read'}, :format => 'json'
    end

    it 'creates a new discussion entry' do
      entry = assigns[:entry]
      expect(entry.discussion_topic).to eq @topic
      expect(entry.id).not_to be_nil
      expect(entry.message).to eq 'message'
    end

    it 'logs an asset access record for the discussion topic' do
      accessed_asset = assigns[:accessed_asset]
      expect(accessed_asset[:code]).to eq @topic.asset_string
      expect(accessed_asset[:category]).to eq 'topics'
      expect(accessed_asset[:level]).to eq 'participate'
    end

    it 'registers a page view' do
      page_view = assigns[:page_view]
      expect(page_view).not_to be_nil
      expect(page_view.http_method).to eq 'post'
      expect(page_view.url).to match %r{^http://test\.host/api/v1/courses/\d+/discussion_topics}
      expect(page_view.participated).to be_truthy
    end
  end

  context "add_entry file quota" do
    before :each do
      course_with_student :active_all => true
      @course.allow_student_forum_attachments = true
      @course.save!
      @topic = @course.discussion_topics.create!(:title => 'discussion')
      user_session(@student)
      allow(controller).to receive_messages(:form_authenticity_token => 'abc', :form_authenticity_param => 'abc')
    end

    it "uploads attachment to submissions folder if topic is graded" do
      assignment_model(:course => @course)
      @topic.assignment = @assignment
      @topic.save
      Setting.set('user_default_quota', -1)
      expect(@student.attachments.count).to eq 0

      post 'add_entry', params: {:topic_id => @topic.id, :course_id => @course.id, :user_id => @user.id, :message => 'message',
        :read_state => 'read', :attachment => default_uploaded_data}, :format => 'json'

      expect(response).to be_success
      expect(@student.attachments.count).to eq 1
      expect(@student.attachments.first.folder.for_submissions?).to be_truthy
      expect(@student.attachments.pluck(:filename)).to include(default_uploaded_data.original_filename)
    end

    it "fails if attachment a file over student quota (not course)" do
      Setting.set('user_default_quota', -1)

      post 'add_entry', params: {:topic_id => @topic.id, :course_id => @course.id, :user_id => @user.id, :message => 'message',
        :read_state => 'read', :attachment => default_uploaded_data}, :format => 'json'

      expect(response).to_not be_success
      expect(response.body).to include("User storage quota exceeded")
    end

    it "succeeds otherwise" do
      post 'add_entry', params: {:topic_id => @topic.id, :course_id => @course.id, :user_id => @user.id, :message => 'message',
        :read_state => 'read', :attachment => default_uploaded_data}, :format => 'json'

      expect(response).to be_success
    end

    it "uses instfs to store attachment if instfs is enabled" do
      allow(InstFS).to receive(:enabled?).and_return(true)
      uuid = "1234-abcd"
      allow(InstFS).to receive(:direct_upload).and_return(uuid)
      post 'add_entry', params: {:topic_id => @topic.id, :course_id => @course.id, :user_id => @user.id, :message => 'message',
        :read_state => 'read', :attachment => default_uploaded_data}, :format => 'json'
      expect(@student.attachments.first.instfs_uuid).to eq(uuid)
    end
  end
end
