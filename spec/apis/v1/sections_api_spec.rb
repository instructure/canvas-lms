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
  describe '#index' do
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

    it "should return sections but not students if user has :read but not :read_roster, :view_all_grades, or :manage_grades" do
      RoleOverride.create!(:context => Account.default, :permission => 'read_roster', :enrollment_type => 'TaEnrollment', :enabled => false)
      RoleOverride.create!(:context => Account.default, :permission => 'view_all_grades', :enrollment_type => 'TaEnrollment', :enabled => false)
      RoleOverride.create!(:context => Account.default, :permission => 'manage_grades', :enrollment_type => 'TaEnrollment', :enabled => false)
      enrollment = course_with_ta(:active_all => true)
      enrollment.update_attribute(:limit_privileges_to_course_section, true)

      @course.grants_right?(@ta, :read).should be_true
      @course.grants_right?(@ta, :read_roster).should be_false
      @course.grants_right?(@ta, :view_all_grades).should be_false
      @course.grants_right?(@ta, :manage_grades).should be_false

      route_params = {
        :controller => 'sections',
        :action => 'index',
        :course_id => @course.to_param,
        :format => 'json'
      }
      json = api_call(:get,
                      "/api/v1/courses/#{@course.id}/sections.json",
                      route_params,
                      { :include => ['students'] })

      json.first["name"].should == @course.default_section.name
      json.first.keys.include?("students").should be_false
    end
  end

  describe "#show" do
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
          'sis_section_id' => nil,
          'start_at' => nil,
          'end_at' => nil
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
          'sis_section_id' => 'my_section',
          'start_at' => nil,
          'end_at' => nil
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
          'sis_section_id' => nil,
          'start_at' => nil,
          'end_at' => nil
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
          'sis_section_id' => 'my_section',
          'start_at' => nil,
          'end_at' => nil
        }
      end

      it "should not be accessible if the associated course is not accessible" do
        @course.destroy
        json = api_call(:get, "#{@path_prefix}/#{@section.id}", @path_params.merge({ :id => @section.to_param }), {}, {}, :expected_status => 404)
      end
    end
  end

  describe "#create" do
    before do
      course
      @path_prefix = "/api/v1/courses/#{@course.id}/sections"
      @path_params = { :controller => 'sections', :action => 'create', :course_id => @course.to_param, :format => 'json' }
    end

    context "as teacher" do
      before do
        course_with_teacher_logged_in :course => @course
      end

      it "should create a section with default parameters" do
        json = api_call(:post, @path_prefix, @path_params)
        @course.reload
        @course.active_course_sections.find_by_id(json['id'].to_i).should_not be_nil
      end

      it "should find the course by SIS ID" do
        @course.update_attribute :sis_source_id, "SISCOURSE"
        json = api_call(:post, "/api/v1/courses/sis_course_id:SISCOURSE/sections",
          { :controller => 'sections', :action => 'create', :course_id => "sis_course_id:SISCOURSE", :format => 'json' })
        @course.reload
        @course.active_course_sections.find_by_id(json['id'].to_i).should_not be_nil
      end

      it "should create a section with custom parameters" do
        json = api_call(:post, @path_prefix, @path_params, { :course_section =>
          { :name => 'Name', :start_at => '2011-01-01T01:00Z', :end_at => '2011-07-01T01:00Z' }})
        @course.reload
        section = @course.active_course_sections.find(json['id'].to_i)
        section.name.should == 'Name'
        section.sis_source_id.should be_nil
        section.start_at.should == Time.parse('2011-01-01T01:00Z')
        section.end_at.should == Time.parse('2011-07-01T01:00Z')
      end

      it "should fail if the context is deleted" do
        @course.destroy
        api_call(:post, @path_prefix, @path_params, {}, {}, :expected_status => 404)
      end

      it "should ignore the sis source id parameter" do
        json = api_call(:post, @path_prefix, @path_params, { :course_section =>
                                                                 { :name => 'Name', :start_at => '2011-01-01T01:00Z', :end_at => '2011-07-01T01:00Z', :sis_section_id => 'fail' }})
        @course.reload
        section = @course.active_course_sections.find(json['id'].to_i)
        section.name.should == 'Name'
        section.sis_source_id.should be_nil
      end
    end

    context "as student" do
      before do
        course_with_student_logged_in(:course => @course)
      end

      it "should disallow creating a section" do
        api_call(:post, @path_prefix, @path_params, {}, {}, :expected_status => 401)
      end
    end

    context "as admin" do
      before do
        site_admin_user
        user_session(@admin)
      end

      it "should set the sis source id" do
        json = api_call(:post, @path_prefix, @path_params, { :course_section =>
          { :name => 'Name', :start_at => '2011-01-01T01:00Z', :end_at => '2011-07-01T01:00Z', :sis_section_id => 'fail' }})
        @course.reload
        section = @course.active_course_sections.find(json['id'].to_i)
        section.name.should == 'Name'
        section.sis_source_id.should == 'fail'
      end
    end
  end

  describe "#update" do
    before do
      course
      @section = @course.course_sections.create! :name => "Test Section"
      @section.update_attribute(:sis_source_id, "SISsy")
      @path_prefix = "/api/v1/sections"
      @path_params = { :controller => 'sections', :action => 'update', :format => 'json' }
    end

    context "as teacher" do
      before do
        course_with_teacher_logged_in :course => @course
      end

      it "should modify section data by id" do
        json = api_call(:put, "#@path_prefix/#{@section.id}", @path_params.merge(:id => @section.to_param), { :course_section =>
          { :name => 'New Name', :start_at => '2012-01-01T01:00Z', :end_at => '2012-07-01T01:00Z' }})
        json['id'].should == @section.id
        @section.reload
        @section.name.should == 'New Name'
        @section.sis_source_id.should == 'SISsy'
        @section.start_at.should == Time.parse('2012-01-01T01:00Z')
        @section.end_at.should == Time.parse('2012-07-01T01:00Z')
      end

      it "should modify section data by sis id" do
        json = api_call(:put, "#@path_prefix/sis_section_id:SISsy", @path_params.merge(:id => "sis_section_id:SISsy"), { :course_section =>
          { :name => 'New Name', :start_at => '2012-01-01T01:00Z', :end_at => '2012-07-01T01:00Z' }})
        json['id'].should == @section.id
        @section.reload
        @section.name.should == 'New Name'
        @section.sis_source_id.should == 'SISsy'
        @section.start_at.should == Time.parse('2012-01-01T01:00Z')
        @section.end_at.should == Time.parse('2012-07-01T01:00Z')
      end

      it "should behave gracefully if the course_section parameter is missing" do
        json = api_call(:put, "#@path_prefix/#{@section.id}", @path_params.merge(:id => @section.to_param))
        json['id'].should == @section.id
      end

      it "should fail if the section is deleted" do
        @section.destroy
        api_call(:put, "#@path_prefix/#{@section.id}", @path_params.merge(:id => @section.to_param),
                 { :course_section => { :name => 'New Name' } }, {}, :expected_status => 404)
      end

      it "should fail if the context is deleted" do
        @course.destroy
        api_call(:put, "#@path_prefix/#{@section.id}", @path_params.merge(:id => @section.to_param),
                 { :course_section => { :name => 'New Name' } }, {}, :expected_status => 404)
      end

      it "should ignore the sis id parameter" do
        json = api_call(:put, "#@path_prefix/#{@section.id}", @path_params.merge(:id => @section.to_param), { :course_section =>
          { :name => 'New Name', :start_at => '2012-01-01T01:00Z', :end_at => '2012-07-01T01:00Z', :sis_section_id => 'NEWSIS' }})
        json['id'].should == @section.id
        @section.reload
        @section.name.should == 'New Name'
        @section.sis_source_id.should == 'SISsy'
      end
    end

    context "as student" do
      before do
        course_with_student_logged_in(:course => @course)
      end

      it "should disallow modifying a section" do
        api_call(:put, "#@path_prefix/#{@section.id}", @path_params.merge(:id => @section.to_param),
                 { :course_section => { :name => 'New Name' } }, {}, :expected_status => 401)
      end
    end

    context "as admin" do
      before do
        site_admin_user
        user_session(@admin)
      end

      it "should set the sis id" do
        json = api_call(:put, "#@path_prefix/#{@section.id}", @path_params.merge(:id => @section.to_param), { :course_section =>
          { :name => 'New Name', :start_at => '2012-01-01T01:00Z', :end_at => '2012-07-01T01:00Z', :sis_section_id => 'NEWSIS' }})
        json['id'].should == @section.id
        @section.reload
        @section.name.should == 'New Name'
        @section.sis_source_id.should == 'NEWSIS'
      end
    end
  end

  describe "#delete" do
    before do
      course
      @section = @course.course_sections.create! :name => "Test Section"
      @section.update_attribute(:sis_source_id, "SISsy")
      @path_prefix = "/api/v1/sections"
      @path_params = { :controller => 'sections', :action => 'destroy', :format => 'json' }
    end

    context "as teacher" do
      before do
        course_with_teacher_logged_in :course => @course
      end

      it "should delete a section by id" do
        json = api_call(:delete, "#@path_prefix/#{@section.id}", @path_params.merge(:id => @section.to_param))
        json['id'].should == @section.id
        @section.reload.should be_deleted
      end

      it "should delete a section by sis id" do
        json = api_call(:delete, "#@path_prefix/sis_section_id:SISsy", @path_params.merge(:id => "sis_section_id:SISsy"))
        json['id'].should == @section.id
        @section.reload.should be_deleted
      end

      it "should fail to delete a section with enrollments" do
        @section.enroll_user(user_model, 'StudentEnrollment', 'active')
        @user = @teacher
        api_call(:delete, "#@path_prefix/#{@section.id}", @path_params.merge(:id => @section.to_param), {}, {}, :expected_status => 400)
      end

      it "should fail if the section is deleted" do
        @section.destroy
        api_call(:delete, "#@path_prefix/#{@section.id}", @path_params.merge(:id => @section.to_param), {}, {}, :expected_status => 404)
      end

      it "should fail if the context is deleted" do
        @course.destroy
        api_call(:delete, "#@path_prefix/#{@section.id}", @path_params.merge(:id => @section.to_param), {}, {}, :expected_status => 404)
      end
    end

    context "as student" do
      before do
        course_with_student_logged_in :course => @course
      end

      it "should disallow deleting a section" do
        api_call(:delete, "#@path_prefix/#{@section.id}", @path_params.merge(:id => @section.to_param), {}, {}, :expected_status => 401)
      end
    end
  end

  describe "#crosslist" do
    before do
      @dest_course = course
      course
      @section = @course.course_sections.create!
      @params = { :controller => 'sections', :action => 'crosslist', :format => 'json' }
    end

    context "as admin" do
      before do
        site_admin_user
        user_session(@admin)
      end

      it "should cross-list a section" do
        @course.active_course_sections.should be_include(@section)
        @dest_course.active_course_sections.should_not be_include(@section)

        json = api_call(:post, "/api/v1/sections/#{@section.id}/crosslist/#{@dest_course.id}",
                        @params.merge(:id => @section.to_param, :new_course_id => @dest_course.to_param))
        json['id'].should == @section.id
        json['course_id'].should == @dest_course.id
        json['nonxlist_course_id'].should == @course.id

        @course.reload.active_course_sections.should_not be_include(@section)
        @dest_course.reload.active_course_sections.should be_include(@section)
      end

      it "should work with sis IDs" do
        @dest_course.update_attribute(:sis_source_id, "dest_course")
        @section.update_attribute(:sis_source_id, "the_section")

        @course.active_course_sections.should be_include(@section)
        @dest_course.active_course_sections.should_not be_include(@section)

        json = api_call(:post, "/api/v1/sections/sis_section_id:the_section/crosslist/sis_course_id:dest_course",
                        @params.merge(:id => "sis_section_id:the_section", :new_course_id => "sis_course_id:dest_course"))
        json['id'].should == @section.id
        json['course_id'].should == @dest_course.id
        json['nonxlist_course_id'].should == @course.id

        @course.reload.active_course_sections.should_not be_include(@section)
        @dest_course.reload.active_course_sections.should be_include(@section)
      end


      it "should fail if the section is deleted" do
        @section.destroy
        api_call(:post, "/api/v1/sections/#{@section.id}/crosslist/#{@dest_course.id}",
                 @params.merge(:id => @section.to_param, :new_course_id => @dest_course.to_param), {}, {}, :expected_status => 404)
      end

      it "should fail if the destination course is deleted" do
        @dest_course.destroy
        api_call(:post, "/api/v1/sections/#{@section.id}/crosslist/#{@dest_course.id}",
                 @params.merge(:id => @section.to_param, :new_course_id => @dest_course.to_param), {}, {}, :expected_status => 404)
      end

      it "should fail if the destination course is under a different root account" do
        foreign_account = Account.create!
        foreign_course = foreign_account.courses.create!
        api_call(:post, "/api/v1/sections/#{@section.id}/crosslist/#{foreign_course.id}",
                 @params.merge(:id => @section.to_param, :new_course_id => foreign_course.to_param), {}, {}, :expected_status => 404)
      end
    end

    context "as teacher" do
      before do
        course_with_teacher_logged_in :course => @course
      end

      it "should disallow cross-listing a section" do
        api_call(:post, "/api/v1/sections/#{@section.id}/crosslist/#{@dest_course.id}",
                 @params.merge(:id => @section.to_param, :new_course_id => @dest_course.to_param), {}, {}, :expected_status => 401)
      end
    end
  end

  describe "#uncrosslist" do
    before do
      @dest_course = course
      course
      @section = @course.course_sections.create!
      @section.crosslist_to_course(@dest_course)
      @params = { :controller => 'sections', :action => 'uncrosslist', :format => 'json' }
    end

    context "as admin" do
      before do
        site_admin_user
        user_session(@admin)
      end

      it "should un-crosslist a section" do
        @course.active_course_sections.should_not be_include @section
        @dest_course.active_course_sections.should be_include @section

        json = api_call(:delete, "/api/v1/sections/#{@section.id}/crosslist",
                 @params.merge(:id => @section.to_param))
        json['id'].should == @section.id
        json['course_id'].should == @course.id
        json['nonxlist_course_id'].should be_nil

        @course.reload.active_course_sections.should be_include @section
        @dest_course.reload.active_course_sections.should_not be_include @section
      end

      it "should work by SIS ID" do
        @dest_course.update_attribute(:sis_source_id, "dest_course")
        @section.update_attribute(:sis_source_id, "the_section")

        @course.active_course_sections.should_not be_include @section
        @dest_course.active_course_sections.should be_include @section

        json = api_call(:delete, "/api/v1/sections/sis_section_id:the_section/crosslist",
                        @params.merge(:id => "sis_section_id:the_section"))
        json['id'].should == @section.id
        json['course_id'].should == @course.id
        json['nonxlist_course_id'].should be_nil

        @course.reload.active_course_sections.should be_include @section
        @dest_course.reload.active_course_sections.should_not be_include @section
      end

      it "should fail if the section is not crosslisted" do
        other_section = @course.course_sections.create! :name => 'other section'
        json = api_call(:delete, "/api/v1/sections/#{other_section.id}/crosslist",
                        @params.merge(:id => other_section.to_param), {}, {}, :expected_status => 400)
      end

      it "should fail if the section is deleted" do
        @section.destroy
        api_call(:delete, "/api/v1/sections/#{@section.id}/crosslist",
                 @params.merge(:id => @section.to_param), {}, {}, :expected_status => 404)
      end

      it "should un-delete the original course" do
        @course.destroy
        api_call(:delete, "/api/v1/sections/#{@section.id}/crosslist",
                 @params.merge(:id => @section.to_param))
        @course.reload.should be_claimed
      end

      it "should fail if the crosslisted course is deleted" do
        @dest_course.destroy
        api_call(:delete, "/api/v1/sections/#{@section.id}/crosslist",
                 @params.merge(:id => @section.to_param), {}, {}, :expected_status => 404)
      end
    end

    context "as teacher" do
      before do
        course_with_teacher_logged_in(:course => @course)
      end

      it "should disallow un-crosslisting" do
        json = api_call(:delete, "/api/v1/sections/#{@section.id}/crosslist",
                        @params.merge(:id => @section.to_param), {}, {}, :expected_status => 401)
      end
    end
  end
end
