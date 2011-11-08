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

describe ConferencesController do
  before do
    # these specs need an enabled web conference plugin
    @plugin = PluginSetting.find_or_create_by_name('dim_dim')
    @plugin.update_attribute(:settings, { :domain => 'www.example.com' })
  end

  describe "GET 'index'" do
    it "should require authorization" do
      course_with_student(:active_all => true)
      get 'index', :course_id => @course.id
      assert_unauthorized
    end
    
    it "should redirect 'disabled', if disabled by the teacher" do
      course_with_student_logged_in(:active_all => true)
      @course.update_attribute(:tab_configuration, [{'id'=>12,'hidden'=>true}])
      get 'index', :course_id => @course.id
      response.should be_redirect
      flash[:notice].should match(/That page has been disabled/)
    end
    
    it "should assign variables" do
      course_with_student_logged_in(:active_all => true)
      get 'index', :course_id => @course.id
      response.should be_success
    end

    it "should not redirect from group context" do
      course_with_student_logged_in(:active_all => true)
      @group = @course.groups.create!(:name => "some group")
      @group.add_user(@user)
      get 'index', :group_id => @group.id
      response.should be_success
    end
  end

  describe "POST 'create'" do
    it "should require authorization" do
      course_with_teacher(:active_all => true)
      post 'create', :course_id => @course.id, :web_conference => {:title => "My Conference", :conference_type => 'DimDim'}
      assert_unauthorized
    end
    
    it "should create a conference" do
      course_with_teacher_logged_in(:active_all => true)
      post 'create', :course_id => @course.id, :web_conference => {:title => "My Conference", :conference_type => 'DimDim'}, :format => 'json'
      response.should be_success
    end
  end

  describe "POST 'update'" do
    it "should require authorization" do
      course_with_teacher(:active_all => true)
      post 'create', :course_id => @course.id, :web_conference => {:title => "My Conference", :conference_type => 'DimDim'}
      assert_unauthorized
    end
    
    it "should update a conference" do
      course_with_teacher_logged_in(:active_all => true)
      @conference = @course.web_conferences.create(:conference_type => 'DimDim')
      post 'update', :course_id => @course.id, :id => @conference, :web_conference => {:title => "Something else"}, :format => 'json'
      response.should be_success
    end
  end
  
end
