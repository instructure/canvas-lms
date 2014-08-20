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

    it "should not choke on non-integer ids" do
      post 'record_error', :error => {:id => 'garbage'}
      assert_recorded_error
      ErrorReport.last.message.should_not == "Error Report Creation failed"
    end

    it "should not return nil.id if report creation failed" do
      ErrorReport.expects(:where).once.raises("failed!")
      post 'record_error', :format => 'json', :error => {:id => 1}
      JSON.parse(response.body).should == { 'logged' => true, 'id' => nil }
    end

    it "should not record the user as nil.id if report creation failed" do
      ErrorReport.expects(:where).once.raises("failed!")
      post 'record_error', :error => {:id => 1}
      ErrorReport.last.user_id.should be_nil
    end

    it "should record the user if report creation failed" do
      user = User.create!
      user_session(user)
      ErrorReport.expects(:where).once.raises("failed!")
      post 'record_error', :error => {:id => 1}
      ErrorReport.last.user_id.should == user.id
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

    it "should respond_to json" do
      request.accept = "application/json"
      Canvas.stubs(:revision).returns("Test Proc")
      get "health_check"
      response.should be_success
      JSON.parse(response.body).should == { "status" => "canvas ok", "revision" => "Test Proc" }
    end
  end

  describe "GET 'help_links'" do
    it "should work" do
      get 'help_links'
      response.should be_success
    end

    it "should set the locale for translated help link text from the current user" do
      user = User.create!(locale: 'es')
      user_session(user)
      # create and save account instance so that we don't invoke I18n's
      # localizer lambda in a request filter prior to loading necessary
      # users, accounts, context etc.
      Account.default
      get 'help_links'
      (I18n.locale.to_s).should == 'es'
    end
  end
end
