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

describe "site-wide" do
  before do
    consider_all_requests_local(false)
  end

  after do
    consider_all_requests_local(true)
  end

  it "should render 404 when user isn't logged in" do
    Setting.set 'show_feedback_link', 'true'
    get "/dashbo"
    assert_status(404)
  end

  it "should set the x-ua-compatible http header" do
    get "/login"
    response['x-ua-compatible'].should == "IE=Edge,chrome=1"
  end

  it "should set no-cache headers for html requests" do
    get "/login"
    response['Pragma'].should match(/no-cache/)
    response['Cache-Control'].should match(/must-revalidate/)
  end

  it "should NOT set no-cache headers for API/xhr requests" do
    get "/api/v1/courses"
    response['Pragma'].should be_nil
    response['Cache-Control'].should_not match(/must-revalidate/)
  end

  it "should set the x-frame-options http header" do
    get "/login"
    assigns[:files_domain].should be_false
    response['x-frame-options'].should == "SAMEORIGIN"
  end

  it "should not set x-frame-options when on a files domain" do
    user_session user(:active_all => true)
    attachment_model(:context => @user)
    FilesController.any_instance.expects(:files_domain?).returns(true)
    get "http://files-test.host/files/#{@attachment.id}/download"
    response['x-frame-options'].should be_nil
  end

  context "user headers" do
    before(:each) do
      course_with_teacher
      @teacher = @user

      student_in_course
      @student = @user
      user_with_pseudonym :user => @student, :username => 'student@example.com', :password => 'password'
      @student_pseudonym = @pseudonym

      account_admin_user :account => Account.site_admin
      @admin = @user
      user_with_pseudonym :user => @admin, :username => 'admin@example.com', :password => 'password'
    end

    it "should not set the logged in user headers when no one is logged in" do
      get "/"
      response['x-canvas-user-id'].should be_nil
      response['x-canvas-real-user-id'].should be_nil
    end

    it "should set them when a user is logged in" do
      user_session(@student, @student_pseudonym)
      get "/"
      response['x-canvas-user-id'].should == @student.global_id.to_s
      response['x-canvas-real-user-id'].should be_nil
    end

    it "should set them when masquerading" do
      user_session(@admin, @admin.pseudonyms.first)
      post "/users/#{@student.id}/masquerade"
      get "/"
      response['x-canvas-user-id'].should == @student.global_id.to_s
      response['x-canvas-real-user-id'].should == @admin.global_id.to_s
    end
  end

  context "breadcrumbs" do
    it "should be absent for error pages" do
      get "/apagethatdoesnotexist"
      response.body.should_not match(%r{id="breadcrumbs"})
    end

    it "should be absent for error pages with user info" do
      course_with_teacher
      get "/users/#{@user.id}/files/apagethatdoesnotexist"
      response.body.to_s.should_not match(%r{id="breadcrumbs"})
    end
  end

  context "policy cache" do
    it "should clear the in-process policy cache between requests" do
      AdheresToPolicy::Cache.expects(:clear).with(nil).once
      get '/'
    end
  end
end
