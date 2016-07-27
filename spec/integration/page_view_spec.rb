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

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe "page views" do
  before(:each) do
    Setting.set('enable_page_views', 'db')
  end

  it "should record the context when commenting on a discussion" do
    user_with_pseudonym(active_all: 1)
    course_with_teacher_logged_in(active_all: 1, user: @user)
    @topic = @course.discussion_topics.create!

    post "/api/v1/courses/#{@course.id}/discussion_topics/#{@topic.id}/entries", :message => 'hello'
    expect(response).to be_success

    pv = PageView.last
    expect(pv.context).to eq @course
    expect(pv.controller).to eq 'discussion_topics_api'
    expect(pv.action).to eq 'add_entry'
  end

  it "records the developer key when an access token was used" do
    user_with_pseudonym(active_all: 1)
    course_with_teacher(active_all: 1, user: @user)
    @topic = @course.discussion_topics.create!

    post "/api/v1/courses/#{@course.id}/discussion_topics/#{@topic.id}/entries", :message => 'hello', access_token: @user.access_tokens.create!.full_token
    expect(response).to be_success

    pv = PageView.last
    expect(pv.context).to eq @course
    expect(pv.controller).to eq 'discussion_topics_api'
    expect(pv.action).to eq 'add_entry'
    expect(pv.developer_key).to eq DeveloperKey.default
  end

  describe "update" do
    it "should set the canvas meta header on interaction_seconds update" do
      course_with_teacher_logged_in(:active_all => 1)
      page_view = PageView.new
      page_view.request_id = rand(10000000).to_s
      page_view.user = @user
      page_view.save

      xhr :put, "/page_views/#{page_view.id}", :page_view_token => page_view.token, :interaction_seconds => 42
      expect(response).to be_success
      expect(response['X-Canvas-Meta']).to match(/r=#{page_view.request_id}\|#{page_view.created_at.iso8601(2)}\|42;/)
    end
  end
end
