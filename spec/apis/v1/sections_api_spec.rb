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

require File.expand_path(File.dirname(__FILE__) + '/../api_spec_helper')

describe SectionsController, :type => :integration do
  describe 'index' do
    USER_API_FIELDS = %w(id name sortable_name short_name)

    before do
      course_with_teacher(:active_all => true, :user => user_with_pseudonym(:name => 'UWP'))
      @me = @user
      @course1 = @course
      course_with_student(:user => @user, :active_all => true)
      @course2 = @course
      @course2.update_attribute(:sis_source_id, 'TEST-SIS-ONE.2011')
      @user.pseudonym.update_attribute(:sis_user_id, 'user1')
    end

    it "should return the list of sections for a course" do
      user1 = @user
      user2 = User.create!(:name => 'Zombo')
      section1 = @course2.default_section
      section2 = @course2.course_sections.create!(:name => 'Section B')
      section2.update_attribute :sis_source_id, 'sis-section'
      @course2.enroll_user(user2, 'StudentEnrollment', :section => section2).accept!
      RoleOverride.create!(:context => Account.default, :permission => 'read_sis', :enrollment_type => 'TeacherEnrollment', :enabled => false)

      @user = @me
      json = api_call(:get, "/api/v1/courses/#{@course2.id}/sections.json",
                      { :controller => 'sections', :action => 'index', :course_id => @course2.id.to_s, :format => 'json' }, { :include => ['students'] })
      json.size.should == 2
      json.find { |s| s['name'] == section2.name }['sis_section_id'].should == 'sis-section'
      json.find { |s| s['name'] == section1.name }['students'].should == api_json_response([user1], :only => USER_API_FIELDS)
      json.find { |s| s['name'] == section2.name }['students'].should == api_json_response([user2], :only => USER_API_FIELDS)
    end

    it "should not return deleted sections" do
      section1 = @course2.default_section
      section2 = @course2.course_sections.create!(:name => 'Section B')
      section2.destroy
      section2.save!
      json = api_call(:get, "/api/v1/courses/#{@course2.id}/sections.json",
                      { :controller => 'sections', :action => 'index', :course_id => @course2.id.to_s, :format => 'json' }, { :include => ['students'] })
      json.size.should == 1
    end
  end

  describe "show" do
    it "should be accessible from the course" do
      course_with_teacher_logged_in
      json = api_call(:get, "/api/v1/courses/#{@course.id}/sections/#{@course.default_section.id}",
                      { :controller => 'sections', :action => 'show', :course_id => @course.id.to_s, :id => @course.default_section.id.to_s, :format => 'json' })
      json.should == {
          'id' => @course.default_section.id,
          'name' => @course.default_section.name,
          'course_id' => @course.id,
          'nonxlist_course_id' => nil,
          'sis_section_id' => nil
          }
    end

    it "should be accessible from the course context via sis id" do
      course_with_teacher_logged_in
      @course.default_section.update_attribute(:sis_source_id, 'my_section')
      json = api_call(:get, "/api/v1/courses/#{@course.id}/sections/sis_section_id:my_section",
                      { :controller => 'sections', :action => 'show', :course_id => @course.id.to_s, :id => 'sis_section_id:my_section', :format => 'json' })
      json.should == {
          'id' => @course.default_section.id,
          'name' => @course.default_section.name,
          'course_id' => @course.id,
          'nonxlist_course_id' => nil,
          'sis_section_id' => 'my_section'
          }
    end

    it "should scope course sections to the course" do
      @course1 = course
      @course2 = course
      user
      Account.site_admin.add_user(@user)
      raw_api_call(:get, "/api/v1/courses/#{@course1.id}/sections/#{@course2.default_section.id}",
                      { :controller => 'sections', :action => 'show', :course_id => @course1.id.to_s, :id => @course2.default_section.id.to_s, :format => 'json' })
      response.status.should == '404 Not Found'
    end

    it "should be accessible without a course context" do
      course_with_teacher_logged_in
      json = api_call(:get, "/api/v1/sections/#{@course.default_section.id}",
                      { :controller => 'sections', :action => 'show', :id => @course.default_section.id.to_s, :format => 'json' })
      json.should == {
          'id' => @course.default_section.id,
          'name' => @course.default_section.name,
          'course_id' => @course.id,
          'nonxlist_course_id' => nil,
          'sis_section_id' => nil
          }
    end

    it "should be accessible without a course context via sis id" do
      course_with_teacher_logged_in
      @course.default_section.update_attribute(:sis_source_id, 'my_section')
      json = api_call(:get, "/api/v1/sections/sis_section_id:my_section",
                      { :controller => 'sections', :action => 'show', :id => 'sis_section_id:my_section', :format => 'json' })
      json.should == {
          'id' => @course.default_section.id,
          'name' => @course.default_section.name,
          'course_id' => @course.id,
          'nonxlist_course_id' => nil,
          'sis_section_id' => 'my_section'
          }
    end
  end
end