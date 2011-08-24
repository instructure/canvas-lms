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

describe "Users API", :type => :integration do
  before do
    @admin = account_admin_user
    course_with_student
    @student = @user
    @user = @admin
    user_with_pseudonym(:user => @user)
  end

  it "should return page view history" do
    page_view_model(:user => @student)
    page_view_model(:user => @student)
    page_view_model(:user => @student)
    Setting.set('api_max_per_page', '2')
    json = api_call(:get, "/api/v1/users/#{@student.id}/page_views?per_page=1000",
                       { :controller => "page_views", :action => "index", :user_id => @student.to_param, :format => 'json', :per_page => '1000' })
    json.size.should == 2
    json.each { |j| j['url'].should == "http://www.example.com/courses/1" }
    json = api_call(:get, "/api/v1/users/#{@student.id}/page_views?page=2",
                       { :controller => "page_views", :action => "index", :user_id => @student.to_param, :format => 'json', :page => '2' })
    json.size.should == 1
    json.each { |j| j['url'].should == "http://www.example.com/courses/1" }
  end
end

