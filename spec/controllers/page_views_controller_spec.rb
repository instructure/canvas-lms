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

describe PageViewsController do

  # Factory-like thing for page views.
  def page_view(user, url, options={})
    options.reverse_merge!(:request_id => rand(100000000).to_s,
                           :user_agent => 'Firefox/12.0')
    options.merge!(:url => url)

    user_req = options.delete(:user_request)
    req_id = options.delete(:request_id)
    created_opt = options.delete(:created_at)
    pg = PageView.new(options)
    pg.user = user
    pg.user_request = user_req
    pg.request_id = req_id
    pg.created_at = created_opt
    pg.updated_at = created_opt
    pg.save!
    pg
  end


  context "with enable_page_views" do
    before :each do
      Setting.set('enable_page_views', true)
    end

    describe "GET 'index'" do

      it "should return nothing when HTML and not AJAX" do
        course_with_teacher_logged_in
        get 'index', :user_id => @user.id
        response.should be_success
        response.body.blank?.should == true
      end

      it "should return content when HTML and AJAX" do
        course_with_teacher_logged_in
        get 'index', :user_id => @user.id, :html_xhr => true
        response.should be_success
        response.body.blank?.should == false
      end
    end

    describe "GET 'index' as csv" do
      it "should succeed" do
        course_with_teacher_logged_in
        student_in_course
        page_view(@user, '/somewhere/in/app', :created_at => 2.days.ago)
        get 'index', :user_id => @user.id, :format => 'csv'
        response.should be_success
      end
      it "should succeed order rows by created_at in DESC order" do
        course_with_teacher_logged_in
        student_in_course
        page_view(@user, '/somewhere/in/app', :created_at => '2012-04-30 20:48:04')    # 2nd day
        page_view(@user, '/somewhere/in/app/1', :created_at => '2012-04-29 20:48:04')  # 1st day
        page_view(@user, '/somewhere/in/app/2', :created_at => '2012-05-01 20:48:04')  # 3rd day
        get 'index', :user_id => @user.id, :format => 'csv'
        response.should be_success
        response.body.should match /2012-05-01 20:48:04 UTC.*\n.*2012-04-30 20:48:04 UTC.*\n.*2012-04-29 20:48:04 UTC/
      end
    end
  end
end
