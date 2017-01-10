#
# Copyright (C) 2013 Instructure, Inc.
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

require File.expand_path(File.dirname(__FILE__) + '/../../../spec_helper.rb')

describe Api::V1::PageView do
  include Api::V1::PageView

  before do
    @request_id = SecureRandom.uuid
    RequestContextGenerator.stubs( :request_id => @request_id )

    @domain_root_account = Account.default

    course_with_teacher(account: @domain_root_account)
    course_with_student(course: @course)

    @page_views = []
    (1..5).each do |i|
      @page_views << PageView.new { |p|
        p.assign_attributes({
          :request_id => @request_id,
          :remote_ip => '10.10.10.10',
          :user => @student,
          :created_at => i.days.ago,
          :updated_at => i.days.ago,
          :context_type => 'Course',
          :context_id => @course.id,
          :asset_type => 'asset',
          :asset_id => 12345,
          :user_agent => 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_8_5) AppleWebKit/536.30.1 (KHTML, like Gecko) Version/6.0.5 Safari/536.30.1',
          :render_time => 0.369,
          :participated => false,
          :user_request => true,
          :interaction_seconds => 7.21,
          :action => "index",
          :controller => "controller",
          :account_id => @domain_root_account.id
        })
      }
    end
    @page_view = @page_views.first

    PageView.stubs(
      :find_by_id => @page_view,
      :find_all_by_id => @page_views
    )
  end

  it "should be formatted as a page view hash" do
    page_view = page_view_json(@page_view, @student, @session)

    expect(page_view[:id]).to eq @page_view.request_id
    expect(page_view[:created_at]).to eq @page_view.created_at.in_time_zone
    expect(page_view[:updated_at]).to eq @page_view.updated_at
    expect(page_view[:remote_ip]).to eq @page_view.remote_ip
    expect(page_view[:context_type]).to eq @page_view.context_type
    expect(page_view[:user_agent]).to eq @page_view.user_agent
    expect(page_view[:render_time]).to eq @page_view.render_time
    expect(page_view[:participated]).to eq @page_view.participated
    expect(page_view[:user_request]).to eq @page_view.user_request
    expect(page_view[:interaction_seconds]).to eq @page_view.interaction_seconds
    expect(page_view[:contributed]).to eq false
    expect(page_view[:action]).to eq @page_view.action
    expect(page_view[:controller]).to eq @page_view.controller

    expect(page_view[:links][:user]).to eq Shard.relative_id_for(@page_view.user, Shard.current, Shard.current)
    expect(page_view[:links][:real_user]).to eq Shard.relative_id_for(@page_view.real_user, Shard.current, Shard.current)
    expect(page_view[:links][:context]).to eq @page_view.context_id
    expect(page_view[:links][:asset]).to eq @page_view.asset_id
    expect(page_view[:links][:account]).to eq @page_view.account_id
  end

  it "should be formatted as an array of page view hashes" do
    expect(page_views_json(@page_views, @student, @session).size).to eql(@page_views.size)
  end
end
