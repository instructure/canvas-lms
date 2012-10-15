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
                      { :controller => 'sections', :action => 'index', :course_id => @course2.to_param, :format => 'json' }, { :include => ['students'] })
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
                      { :controller => 'sections', :action => 'index', :course_id => @course2.to_param, :format => 'json' }, { :include => ['students'] })
      json.size.should == 1
    end
  end

  describe "show" do
    before do
      course_with_teacher_logged_in
      @section = @course.default_section
    end

    context "scoped by course" do
      before do
        @path_prefix = "/api/v1/courses/#{@course.id}/sections"
        @path_params = { :controller => 'sections', :action => 'show', :course_id => @course.to_param, :format => 'json' }
      end

      it "should be accessible from the course" do
        json = api_call(:get, "#{@path_prefix}/#{@section.id}", @path_params.merge({ :id => @section.to_param }))
        json.should == {
          'id' => @section.id,
          'name' => @section.name,
          'course_id' => @course.id,
          'nonxlist_course_id' => nil,
          'sis_section_id' => nil
        }
      end

      it "should be accessible from the course context via sis id" do
        @section.update_attribute(:sis_source_id, 'my_section')
        json = api_call(:get, "#{@path_prefix}/sis_section_id:my_section", @path_params.merge({ :id => 'sis_section_id:my_section' }))
        json.should == {
          'id' => @section.id,
          'name' => @section.name,
          'course_id' => @course.id,
          'nonxlist_course_id' => nil,
          'sis_section_id' => 'my_section'
        }
      end

      it "should scope course sections to the course" do
        @other_course = course
        @other_section = @other_course.default_section
        site_admin_user
        api_call(:get, "#{@path_prefix}/#{@other_section.id}", @path_params.merge({ :id => @other_section.to_param }), {}, {}, :expected_status => 404)
      end
    end

    context "unscoped" do
      before do
        @path_prefix = "/api/v1/sections"
        @path_params = { :controller => 'sections', :action => 'show', :format => 'json' }
      end

      it "should be accessible without a course context" do
        json = api_call(:get, "#{@path_prefix}/#{@section.id}", @path_params.merge({ :id => @section.to_param }))
        json.should == {
          'id' => @section.id,
          'name' => @section.name,
          'course_id' => @course.id,
          'nonxlist_course_id' => nil,
          'sis_section_id' => nil
        }
      end

      it "should be accessible without a course context via sis id" do
        @section.update_attribute(:sis_source_id, 'my_section')
        json = api_call(:get, "#{@path_prefix}/sis_section_id:my_section", @path_params.merge({ :id => "sis_section_id:my_section" }))
        json.should == {
          'id' => @section.id,
          'name' => @section.name,
          'course_id' => @course.id,
          'nonxlist_course_id' => nil,
          'sis_section_id' => 'my_section'
        }
      end

      it "should not be accessible if the associated course is not accessible" do
        @course.destroy
        json = api_call(:get, "#{@path_prefix}/#{@section.id}", @path_params.merge({ :id => @section.to_param }), {}, {}, :expected_status => 404)
      end
    end
  end
end
