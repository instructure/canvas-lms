#
# Copyright (C) 2012 - 2014 Instructure, Inc.
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

describe SectionsController, type: :request do
  describe '#index' do
    USER_API_FIELDS = %w(id name sortable_name short_name)

    before :once do
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
      RoleOverride.create!(:context => Account.default, :permission => 'read_sis', :role => teacher_role, :enabled => false)

      @user = @me
      json = api_call(:get, "/api/v1/courses/#{@course2.id}/sections.json",
                      { :controller => 'sections', :action => 'index', :course_id => @course2.to_param, :format => 'json' }, { :include => ['students'] })
      expect(json.size).to eq 2
      expect(json.find { |s| s['name'] == section1.name }['students']).to eq api_json_response([user1], :only => USER_API_FIELDS)
      expect(json.find { |s| s['name'] == section2.name }['students']).to eq api_json_response([user2], :only => USER_API_FIELDS)
    end

    it "should not return deleted sections" do
      section1 = @course2.default_section
      section2 = @course2.course_sections.create!(:name => 'Section B')
      section2.destroy
      section2.save!
      json = api_call(:get, "/api/v1/courses/#{@course2.id}/sections.json",
                      { :controller => 'sections', :action => 'index', :course_id => @course2.to_param, :format => 'json' }, { :include => ['students'] })
      expect(json.size).to eq 1
    end

    it "should return sections but not students if user has :read but not :read_roster, :view_all_grades, or :manage_grades" do
      RoleOverride.create!(:context => Account.default, :permission => 'read_roster', :role => ta_role, :enabled => false)
      RoleOverride.create!(:context => Account.default, :permission => 'view_all_grades', :role => ta_role, :enabled => false)
      RoleOverride.create!(:context => Account.default, :permission => 'manage_grades', :role => ta_role, :enabled => false)
      enrollment = course_with_ta(:active_all => true)
      enrollment.update_attribute(:limit_privileges_to_course_section, true)

      expect(@course.grants_right?(@ta, :read)).to be_truthy
      expect(@course.grants_right?(@ta, :read_roster)).to be_falsey
      expect(@course.grants_right?(@ta, :view_all_grades)).to be_falsey
      expect(@course.grants_right?(@ta, :manage_grades)).to be_falsey

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

      expect(json.first["name"]).to eq @course.default_section.name
      expect(json.first.keys.include?("students")).to be_falsey
    end
  end

  describe "#show" do
    before :once do
      course_with_teacher
      @section = @course.default_section
    end

    context "scoped by course" do
      before do
        @path_prefix = "/api/v1/courses/#{@course.id}/sections"
        @path_params = { :controller => 'sections', :action => 'show', :course_id => @course.to_param, :format => 'json' }
      end

      it "should be accessible from the course" do
        json = api_call(:get, "#{@path_prefix}/#{@section.id}", @path_params.merge({ :id => @section.to_param }))
        expect(json).to eq({
          'id' => @section.id,
          'name' => @section.name,
          'course_id' => @course.id,
          'nonxlist_course_id' => nil,
          'start_at' => nil,
          'end_at' => nil
        })
      end

      it "should be accessible from the course context via sis id" do
        @section.update_attribute(:sis_source_id, 'my_section')
        json = api_call(:get, "#{@path_prefix}/sis_section_id:my_section", @path_params.merge({ :id => 'sis_section_id:my_section' }))
        expect(json).to eq({
          'id' => @section.id,
          'name' => @section.name,
          'course_id' => @course.id,
          'nonxlist_course_id' => nil,
          'start_at' => nil,
          'end_at' => nil
        })
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
        expect(json).to eq({
          'id' => @section.id,
          'name' => @section.name,
          'course_id' => @course.id,
          'nonxlist_course_id' => nil,
          'start_at' => nil,
          'end_at' => nil
        })
      end

      it "should be accessible without a course context via sis id" do
        @section.update_attribute(:sis_source_id, 'my_section')
        json = api_call(:get, "#{@path_prefix}/sis_section_id:my_section", @path_params.merge({ :id => "sis_section_id:my_section" }))
        expect(json).to eq({
          'id' => @section.id,
          'name' => @section.name,
          'course_id' => @course.id,
          'nonxlist_course_id' => nil,
          'start_at' => nil,
          'end_at' => nil
        })
      end

      it "should be accessible without a course context via integration id" do
        @section.update_attribute(:integration_id, 'my_section')
        json = api_call(:get, "#{@path_prefix}/sis_integration_id:my_section", @path_params.merge({ :id => "sis_integration_id:my_section" }))
        expect(json).to eq({
            'id' => @section.id,
            'name' => @section.name,
            'course_id' => @course.id,
            'nonxlist_course_id' => nil,
            'start_at' => nil,
            'end_at' => nil
        })
      end

      it "should not be accessible if the associated course is not accessible" do
        @course.destroy
        json = api_call(:get, "#{@path_prefix}/#{@section.id}", @path_params.merge({ :id => @section.to_param }), {}, {}, :expected_status => 404)
      end
    end

    context "as an admin" do
      before :once do
        site_admin_user
        @section = @course.default_section
        @path_prefix = "/api/v1/courses/#{@course.id}/sections"
        @path_params = { :controller => 'sections', :action => 'show', :course_id => @course.to_param, :format => 'json' }
      end

      it "should show sis information" do
        json = api_call(:get, "#{@path_prefix}/#{@section.id}", @path_params.merge({ :id => @section.to_param }))
        expect(json).to eq({
          'id' => @section.id,
          'name' => @section.name,
          'course_id' => @course.id,
          'sis_course_id' => @course.sis_source_id,
          'sis_section_id' => @section.sis_source_id,
          'sis_import_id' => @section.sis_batch_id,
          'integration_id' => nil,
          'nonxlist_course_id' => nil,
          'start_at' => nil,
          'end_at' => nil
        })
      end
    end
  end

  describe "#create" do
    before :once do
      course
      @path_prefix = "/api/v1/courses/#{@course.id}/sections"
      @path_params = { :controller => 'sections', :action => 'create', :course_id => @course.to_param, :format => 'json' }
    end

    context "as teacher" do
      before :once do
        course_with_teacher :course => @course
      end

      it "should create a section with default parameters" do
        json = api_call(:post, @path_prefix, @path_params)
        @course.reload
        expect(@course.active_course_sections.where(id: json['id'].to_i)).to be_exists
      end

      it "should find the course by SIS ID" do
        @course.update_attribute :sis_source_id, "SISCOURSE"
        json = api_call(:post, "/api/v1/courses/sis_course_id:SISCOURSE/sections",
          { :controller => 'sections', :action => 'create', :course_id => "sis_course_id:SISCOURSE", :format => 'json' })
        @course.reload
        expect(@course.active_course_sections.where(id: json['id'].to_i)).to be_exists
      end

      it "should create a section with custom parameters" do
        json = api_call(:post, @path_prefix, @path_params, { :course_section =>
          { :name => 'Name', :start_at => '2011-01-01T01:00Z', :end_at => '2011-07-01T01:00Z' }})
        @course.reload
        section = @course.active_course_sections.find(json['id'].to_i)
        expect(section.name).to eq 'Name'
        expect(section.sis_source_id).to be_nil
        expect(section.start_at).to eq Time.parse('2011-01-01T01:00Z')
        expect(section.end_at).to eq Time.parse('2011-07-01T01:00Z')
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
        expect(section.name).to eq 'Name'
        expect(section.sis_source_id).to be_nil
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
      end

      it "should set the sis source id" do
        json = api_call(:post, @path_prefix, @path_params, { :course_section =>
          { :name => 'Name', :start_at => '2011-01-01T01:00Z', :end_at => '2011-07-01T01:00Z', :sis_section_id => 'fail' }})
        @course.reload
        section = @course.active_course_sections.find(json['id'].to_i)
        expect(section.name).to eq 'Name'
        expect(section.sis_source_id).to eq 'fail'
        expect(section.sis_batch_id).to eq nil
      end
    end
  end

  describe "#update" do
    before :once do
      course
      @section = @course.course_sections.create! :name => "Test Section"
      @section.update_attribute(:sis_source_id, "SISsy")
      @path_prefix = "/api/v1/sections"
      @path_params = { :controller => 'sections', :action => 'update', :format => 'json' }
    end

    context "as teacher" do
      before :once do
        course_with_teacher :course => @course
      end

      it "should modify section data by id" do
        json = api_call(:put, "#@path_prefix/#{@section.id}", @path_params.merge(:id => @section.to_param), { :course_section =>
          { :name => 'New Name', :start_at => '2012-01-01T01:00Z', :end_at => '2012-07-01T01:00Z' }})
        expect(json['id']).to eq @section.id
        @section.reload
        expect(@section.name).to eq 'New Name'
        expect(@section.sis_source_id).to eq 'SISsy'
        expect(@section.start_at).to eq Time.parse('2012-01-01T01:00Z')
        expect(@section.end_at).to eq Time.parse('2012-07-01T01:00Z')
      end

      it "should modify section data by sis id" do
        json = api_call(:put, "#@path_prefix/sis_section_id:SISsy", @path_params.merge(:id => "sis_section_id:SISsy"), { :course_section =>
          { :name => 'New Name', :start_at => '2012-01-01T01:00Z', :end_at => '2012-07-01T01:00Z' }})
        expect(json['id']).to eq @section.id
        @section.reload
        expect(@section.name).to eq 'New Name'
        expect(@section.sis_source_id).to eq 'SISsy'
        expect(@section.start_at).to eq Time.parse('2012-01-01T01:00Z')
        expect(@section.end_at).to eq Time.parse('2012-07-01T01:00Z')
      end

      it "should behave gracefully if the course_section parameter is missing" do
        json = api_call(:put, "#@path_prefix/#{@section.id}", @path_params.merge(:id => @section.to_param))
        expect(json['id']).to eq @section.id
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
        expect(json['id']).to eq @section.id
        @section.reload
        expect(@section.name).to eq 'New Name'
        expect(@section.sis_source_id).to eq 'SISsy'
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
      end

      it "should set the sis id" do
        json = api_call(:put, "#@path_prefix/#{@section.id}", @path_params.merge(:id => @section.to_param), { :course_section =>
          { :name => 'New Name', :start_at => '2012-01-01T01:00Z', :end_at => '2012-07-01T01:00Z', :sis_section_id => 'NEWSIS' }})
        expect(json['id']).to eq @section.id
        @section.reload
        expect(@section.name).to eq 'New Name'
        expect(@section.sis_source_id).to eq 'NEWSIS'
      end
    end
  end

  describe "#delete" do
    before :once do
      course
      @section = @course.course_sections.create! :name => "Test Section"
      @section.update_attribute(:sis_source_id, "SISsy")
      @path_prefix = "/api/v1/sections"
      @path_params = { :controller => 'sections', :action => 'destroy', :format => 'json' }
    end

    context "as teacher" do
      before :once do
        course_with_teacher :course => @course
      end

      it "should delete a section by id" do
        json = api_call(:delete, "#@path_prefix/#{@section.id}", @path_params.merge(:id => @section.to_param))
        expect(json['id']).to eq @section.id
        expect(@section.reload).to be_deleted
      end

      it "should delete a section by sis id" do
        json = api_call(:delete, "#@path_prefix/sis_section_id:SISsy", @path_params.merge(:id => "sis_section_id:SISsy"))
        expect(json['id']).to eq @section.id
        expect(@section.reload).to be_deleted
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
    before :once do
      @dest_course = course
      course
      @section = @course.course_sections.create!
      @params = { :controller => 'sections', :action => 'crosslist', :format => 'json' }
    end

    context "as admin" do
      before :once do
        site_admin_user
      end

      it "should cross-list a section" do
        expect(@course.active_course_sections).to be_include(@section)
        expect(@dest_course.active_course_sections).not_to be_include(@section)

        json = api_call(:post, "/api/v1/sections/#{@section.id}/crosslist/#{@dest_course.id}",
                        @params.merge(:id => @section.to_param, :new_course_id => @dest_course.to_param))
        expect(json['id']).to eq @section.id
        expect(json['course_id']).to eq @dest_course.id
        expect(json['nonxlist_course_id']).to eq @course.id

        expect(@course.reload.active_course_sections).not_to be_include(@section)
        expect(@dest_course.reload.active_course_sections).to be_include(@section)
      end

      it "should work with sis IDs" do
        @dest_course.update_attribute(:sis_source_id, "dest_course")
        @section.update_attribute(:sis_source_id, "the_section")
        @sis_batch = @section.root_account.sis_batches.create
        SisBatch.where(id: @sis_batch).update_all(workflow_state: 'imported')
        @section.sis_batch_id = @sis_batch.id
        @section.save!

        expect(@course.active_course_sections).to be_include(@section)
        expect(@dest_course.active_course_sections).not_to be_include(@section)

        json = api_call(:post, "/api/v1/sections/sis_section_id:the_section/crosslist/sis_course_id:dest_course",
                        @params.merge(:id => "sis_section_id:the_section", :new_course_id => "sis_course_id:dest_course"))
        expect(json['id']).to eq @section.id
        expect(json['course_id']).to eq @dest_course.id
        expect(json['nonxlist_course_id']).to eq @course.id
        expect(json['sis_import_id']).to eq @sis_batch.id

        expect(@course.reload.active_course_sections).not_to be_include(@section)
        expect(@dest_course.reload.active_course_sections).to be_include(@section)
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

      it "should confirm crosslist by sis id" do
        user_session(@admin)
        @dest_course.update_attribute(:sis_source_id, "blargh")
        raw_api_call(:get, "/courses/#{@course.id}/sections/#{@section.id}/crosslist/confirm/#{@dest_course.sis_source_id}",
                 @params.merge(:action => 'crosslist_check', :course_id => @course.to_param, :section_id => @section.to_param, :new_course_id => @dest_course.sis_source_id))
        json = JSON.parse response.body.gsub(/\Awhile\(1\)\;/, '')
        expect(json['course']['id']).to eql @dest_course.id
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
    before :once do
      @dest_course = course
      course
      @section = @course.course_sections.create!
      @section.crosslist_to_course(@dest_course)
      @params = { :controller => 'sections', :action => 'uncrosslist', :format => 'json' }
    end

    context "as admin" do
      before :once do
        site_admin_user
      end

      it "should un-crosslist a section" do
        expect(@course.active_course_sections).not_to be_include @section
        expect(@dest_course.active_course_sections).to be_include @section

        json = api_call(:delete, "/api/v1/sections/#{@section.id}/crosslist",
                 @params.merge(:id => @section.to_param))
        expect(json['id']).to eq @section.id
        expect(json['course_id']).to eq @course.id
        expect(json['nonxlist_course_id']).to be_nil

        expect(@course.reload.active_course_sections).to be_include @section
        expect(@dest_course.reload.active_course_sections).not_to be_include @section
      end

      it "should work by SIS ID" do
        @dest_course.update_attribute(:sis_source_id, "dest_course")
        @section.update_attribute(:sis_source_id, "the_section")

        expect(@course.active_course_sections).not_to be_include @section
        expect(@dest_course.active_course_sections).to be_include @section

        json = api_call(:delete, "/api/v1/sections/sis_section_id:the_section/crosslist",
                        @params.merge(:id => "sis_section_id:the_section"))
        expect(json['id']).to eq @section.id
        expect(json['course_id']).to eq @course.id
        expect(json['nonxlist_course_id']).to be_nil

        expect(@course.reload.active_course_sections).to be_include @section
        expect(@dest_course.reload.active_course_sections).not_to be_include @section
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
        expect(@course.reload).to be_claimed
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
