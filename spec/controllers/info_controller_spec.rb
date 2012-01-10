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

describe InfoController do

  describe "POST 'record_error'" do
    it "should be successful" do
      post 'record_error'
      assert_recorded_error
      
      post 'record_error', :error => {:title => 'ugly', :message => 'bacon', :fried_ham => 'stupid'}
      assert_recorded_error
    end

    it "should be successful for teacher feedback too" do
      course_with_student_logged_in(:active_all => true)
      post 'record_error', "feedback_type"=>"teacher", "comments"=>"OHAI", "subject"=>"help me.", "course_id"=>@course.id, "error"=>{"comments"=>"OHAI", "subject"=>"help me.", "backtrace"=>"Posted as a _PROBLEM_", "email"=>""}, "email"=>""
      assert_recorded_error("Thanks for your feedback!  Your teacher has been notified.")
    end
    
  end
  
  describe "GET 'avatar_image_url'" do
    it "should redirect to no_pic if no avatar is set" do
      course_with_student_logged_in(:active_all => true)
      get 'avatar_image_url', :user_id  => @user.id
      response.should redirect_to '/images/no_pic.gif'
    end
    it "should handle passing a fallback" do
      course_with_student_logged_in(:active_all => true)
      get 'avatar_image_url', :user_id  => @user.id, :fallback => "/my/custom/fallback/url.png"
      response.should redirect_to '/my/custom/fallback/url.png'
    end
    it "should handle passing a fallback when avatars are enabled" do
      course_with_student_logged_in(:active_all => true)
      @account = Account.default
      @account.enable_service(:avatars)
      @account.save!
      @account.service_enabled?(:avatars).should be_true
      get 'avatar_image_url', :user_id  => @user.id, :fallback => "https://test.domain/my/custom/fallback/url.png"
      response.should redirect_to "https://secure.gravatar.com/avatar/000?s=50&d=https%3A%2F%2Ftest.domain%2Fmy%2Fcustom%2Ffallback%2Furl.png"
    end
  end

  def assert_recorded_error(msg = "Thanks for your help!  We'll get right on this")
    flash[:notice].should eql(msg)
    response.should be_redirect
    response.should redirect_to(root_url)
  end

  describe "GET 'health_check'" do
    it "should work" do
      get 'health_check'
      response.should be_success
      response.body.should == 'canvas ok'
    end
  end
end
