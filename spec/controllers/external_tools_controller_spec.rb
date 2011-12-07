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

describe ExternalToolsController do
  describe "GET 'retrieve'" do
    it "should require authentication" do
      course_with_teacher(:active_all => true)
      user_model
      user_session(@user)
      get 'retrieve', :course_id => @course.id
      assert_unauthorized
    end
    
    it "should find tools matching by exact url" do
      course_with_teacher_logged_in(:active_all => true)
      tool = @course.context_external_tools.new(:name => "bob", :consumer_key => "bob", :shared_secret => "bob")
      tool.url = "http://www.example.com/basic_lti"
      tool.save!
      get 'retrieve', :course_id => @course.id, :url => "http://www.example.com/basic_lti"
      response.should be_success
      assigns[:tool].should == tool
      assigns[:tool_settings].should_not be_nil
    end
    
    it "should find tools matching by domain" do
      course_with_teacher_logged_in(:active_all => true)
      tool = @course.context_external_tools.new(:name => "bob", :consumer_key => "bob", :shared_secret => "bob")
      tool.domain = "example.com"
      tool.save!
      get 'retrieve', :course_id => @course.id, :url => "http://www.example.com/basic_lti"
      response.should be_success
      assigns[:tool].should == tool
      assigns[:tool_settings].should_not be_nil
    end
    
    it "should redirect if no matching tools are found" do
      course_with_teacher_logged_in(:active_all => true)
      get 'retrieve', :course_id => @course.id, :url => "http://www.example.com"
      response.should be_redirect
      flash[:error].should == "Couldn't find valid settings for this link"
    end
  end
  
  describe "GET 'resource_selection'" do
    it "should require authentication" do
      course_with_teacher(:active_all => true)
      user_model
      user_session(@user)
      get 'resource_selection', :course_id => @course.id, :external_tool_id => 0
      assert_unauthorized
    end
    
    it "should redirect if no matching tools are found" do
      course_with_teacher_logged_in(:active_all => true)
      tool = @course.context_external_tools.new(:name => "bob", :consumer_key => "bob", :shared_secret => "bob")
      tool.url = "http://www.example.com/basic_lti"
      # this tool exists, but isn't properly configured
      tool.save!
      get 'resource_selection', :course_id => @course.id, :external_tool_id => tool.id
      response.should be_redirect
      flash[:error].should == "Couldn't find valid settings for this tool"
    end
    
    it "should find a valid tool if one exists" do
      course_with_teacher_logged_in(:active_all => true)
      tool = @course.context_external_tools.new(:name => "bob", :consumer_key => "bob", :shared_secret => "bob")
      tool.url = "http://www.example.com/basic_lti"
      tool.settings[:resource_selection] = {
        :url => "http://#{HostUrl.default_host}/selection_test",
        :selection_width => 400,
        :selection_height => 400
      }
      tool.save!
      get 'resource_selection', :course_id => @course.id, :external_tool_id => tool.id
      response.should be_success
      assigns[:tool].should == tool
    end
  end
end
