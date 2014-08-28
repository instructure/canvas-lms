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
    @request_id = CanvasUUID.generate
    RequestContextGenerator.stubs( :request_id => @request_id )

    @domain_root_account = Account.default

    course_with_teacher(account: @domain_root_account)
    course_with_student_logged_in(course: @course)

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
        }, :without_protection => true)
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

    page_view[:id].should == @page_view.request_id
    page_view[:created_at].should == @page_view.created_at.in_time_zone
    page_view[:updated_at].should == @page_view.updated_at
    page_view[:remote_ip].should == @page_view.remote_ip
    page_view[:context_type].should == @page_view.context_type
    page_view[:user_agent].should == @page_view.user_agent
    page_view[:render_time].should == @page_view.render_time
    page_view[:participated].should == @page_view.participated
    page_view[:user_request].should == @page_view.user_request
    page_view[:interaction_seconds].should == @page_view.interaction_seconds
    page_view[:contributed].should == false
    page_view[:action].should == @page_view.action
    page_view[:controller].should == @page_view.controller

    page_view[:links][:user].should == Shard.relative_id_for(@page_view.user, Shard.current, Shard.current)
    page_view[:links][:real_user].should == Shard.relative_id_for(@page_view.real_user, Shard.current, Shard.current)
    page_view[:links][:context].should == @page_view.context_id
    page_view[:links][:asset].should == @page_view.asset_id
    page_view[:links][:account].should == @page_view.account_id
  end

  it "should be formatted as an array of page view hashes" do
    page_views_json(@page_views, @student, @session).size.should eql(@page_views.size)
  end
end
