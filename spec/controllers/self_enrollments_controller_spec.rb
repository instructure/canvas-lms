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

describe SelfEnrollmentsController do
  describe "GET 'new'" do
    before do
      course(:active_all => true)
      @course.update_attribute(:self_enrollment, true)
    end

    it "should render if the course is open for enrollment" do
      get 'new', :self_enrollment_code => @course.self_enrollment_code
      response.should be_success
    end

    it "should do the delegated auth dance" do
      account = account_with_cas({:account => Account.default})
      
      get 'new', :self_enrollment_code => @course.self_enrollment_code
      response.should redirect_to login_url
    end

    it "should not render for an incorrect code" do
      lambda {
        get 'new', :self_enrollment_code => 'abc'
      }.should raise_exception(ActiveRecord::RecordNotFound)
    end

    it "should render even if self_enrollment is disabled" do
      code = @course.self_enrollment_code
      @course.update_attribute(:self_enrollment, false)

      get 'new', :self_enrollment_code => code
      response.should be_success
    end
  end

  describe "POST 'create'" do
    before do
      Account.default.update_attribute(:settings, :self_enrollment => 'any', :open_registration => true)
      course(:active_all => true)
      @course.update_attribute(:self_enrollment, true)
    end

    it "should enroll the currently logged in user" do
      user
      user_session(@user, @pseudonym)

      post 'create', :self_enrollment_code => @course.self_enrollment_code
      response.should be_success
      @user.enrollments.length.should == 1
      @enrollment = @user.enrollments.first
      @enrollment.course.should == @course
      @enrollment.workflow_state.should == 'active'
      @enrollment.should be_self_enrolled
    end

    it "should not enroll an unauthenticated user" do
      post 'create', :self_enrollment_code => @course.self_enrollment_code
      response.should redirect_to(login_url)
    end

    it "should not enroll for an incorrect code" do
      user
      user_session(@user)

      lambda {
        post 'create', :self_enrollment_code => 'abc'
      }.should raise_exception(ActiveRecord::RecordNotFound)
      @user.enrollments.length.should == 0
    end

    it "should not enroll if self_enrollment is disabled" do
      code = @course.self_enrollment_code
      @course.update_attribute(:self_enrollment, false)
      user
      user_session(@user)

      post 'create', :self_enrollment_code => code
      response.status.should =~ /400 Bad Request/
      @user.enrollments.length.should == 0
    end

    it "should not enroll if the course is full" do
      @course.update_attribute(:self_enrollment_limit, 0)
      user
      user_session(@user)

      post 'create', :self_enrollment_code => @course.self_enrollment_code
      response.status.should =~ /400 Bad Request/
      json = JSON.parse(response.body)
      json["user"]["self_enrollment_code"].should be_present
    end
  end
end
