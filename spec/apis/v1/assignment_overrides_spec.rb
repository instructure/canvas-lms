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

require File.expand_path(File.dirname(__FILE__) + '/../api_spec_helper')

describe AssignmentOverridesController, type: :request do
  def validate_override_json(override, json)
    json['id'].should == override.id
    json['assignment_id'].should == override.assignment_id
    json['title'].should == override.title

    if override.due_at_overridden
      json['due_at'].should == override.due_at.iso8601
      json['all_day'].should == override.all_day
      json['all_day_date'].should == override.all_day_date.to_s
    else
      json.should_not have_key 'due_at'
      json.should_not have_key 'all_day'
      json.should_not have_key 'all_day_date'
    end

    if override.unlock_at_overridden
      json['unlock_at'].should == override.unlock_at.iso8601
    else
      json.should_not have_key 'unlock_at'
    end

    if override.lock_at_overridden
      json['lock_at'].should == override.lock_at.iso8601
    else
      json.should_not have_key 'lock_at'
    end

    case override.set
    when Array
      json['student_ids'].should == override.set.map(&:id)
      json.should_not have_key 'group_id'
      json.should_not have_key 'course_section_id'
    when Group
      json['group_id'].should == override.set_id
      json.should_not have_key 'student_ids'
      json.should_not have_key 'course_section_id'
    when CourseSection
      json['course_section_id'].should == override.set_id
      json.should_not have_key 'student_ids'
      json.should_not have_key 'group_id'
    end
  end

  def expect_errors(errors)
    assert_status(400)
    json = JSON.parse(response.body)
    json.should == {"errors" => errors}
  end

  def expect_error(error)
    expect_errors([error])
  end

  context "index" do
    before :each do
      course_with_teacher(:active_all => true)
      assignment_model(:course => @course)
      assignment_override_model(:assignment => @assignment)
      @override.set = @course.default_section
      @override.save!
    end

    it "should include visible overrides" do
      json = api_call(:get, "/api/v1/courses/#{@course.id}/assignments/#{@assignment.id}/overrides.json",
                      :controller => 'assignment_overrides', :action => 'index', :format => 'json',
                      :course_id => @course.id.to_s,
                      :assignment_id => @assignment.id.to_s)

      json.size.should == 1
    end

    it "should exclude deleted overrides" do
      @override.destroy

      json = api_call(:get, "/api/v1/courses/#{@course.id}/assignments/#{@assignment.id}/overrides.json",
                      :controller => 'assignment_overrides', :action => 'index', :format => 'json',
                      :course_id => @course.id.to_s,
                      :assignment_id => @assignment.id.to_s)

      json.size.should == 0
    end

    it "should include overrides outside the user's sections if user is admin" do
      Enrollment.limit_privileges_to_course_section!(@course, @teacher, true)

      @override.set = @course.course_sections.create!
      @override.save!

      @course.sections_visible_to(@teacher).should_not include @override.set
      json = api_call(:get, "/api/v1/courses/#{@course.id}/assignments/#{@assignment.id}/overrides.json",
                      :controller => 'assignment_overrides', :action => 'index', :format => 'json',
                      :course_id => @course.id.to_s,
                      :assignment_id => @assignment.id.to_s)

      json.size.should == 1
    end

    it "should have formatted overrides" do
      json = api_call(:get, "/api/v1/courses/#{@course.id}/assignments/#{@assignment.id}/overrides.json",
                      :controller => 'assignment_overrides', :action => 'index', :format => 'json',
                      :course_id => @course.id.to_s,
                      :assignment_id => @assignment.id.to_s)
      validate_override_json(@override, json.first)
    end
  end

  context "show" do
    before :each do
      course_with_teacher(:active_all => true)
      assignment_model(:course => @course, :group_category => 'category')
      assignment_override_model(:assignment => @assignment)
      @override.set = @course.default_section
      @override.save!
    end

    def raw_api_show_override(course, assignment, override)
      raw_api_call(:get, "/api/v1/courses/#{course.id}/assignments/#{assignment.id}/overrides/#{override.id}.json",
                   :controller => 'assignment_overrides', :action => 'show', :format => 'json',
                   :course_id => course.id.to_s, :assignment_id => assignment.id.to_s, :id => override.id.to_s)
    end

    def api_show_override(course, assignment, override)
      api_call(:get, "/api/v1/courses/#{course.id}/assignments/#{assignment.id}/overrides/#{override.id}.json",
               :controller => 'assignment_overrides', :action => 'show', :format => 'json',
               :course_id => course.id.to_s, :assignment_id => assignment.id.to_s, :id => override.id.to_s)
    end

    describe 'as an account admin not enrolled in the class' do
      before :each do
        account_admin_user(:account => Account.site_admin, :active_all => true)
        user_session(@admin)
      end

      it 'it works' do
        json = api_show_override(@course, @assignment, @override)
        validate_override_json(@override, json)
      end
    end

    it "should return the override json" do
      json = api_show_override(@course, @assignment, @override)
      validate_override_json(@override, json)
    end

    it "should 404 for non-visible override" do
      @override.destroy
      raw_api_show_override(@course, @assignment, @override)
      assert_status(404)
    end

    it "should exclude due_at/all_day/all_day_date/lock_at/unlock_at when not overridden" do
      json = api_show_override(@course, @assignment, @override)
      validate_override_json(@override, json)
    end

    it "should include unlock_at when overridden" do
      @override.override_unlock_at(4.days.ago)
      @override.save!

      json = api_show_override(@course, @assignment, @override)
      validate_override_json(@override, json)
    end

    it "should include lock_at when overridden" do
      @override.override_lock_at(4.days.ago)
      @override.save!

      json = api_show_override(@course, @assignment, @override)
      validate_override_json(@override, json)
    end

    it "should include due_at/all_day/all_day_date when due_at is overridden" do
      @override.override_due_at(4.days.ago)
      @override.save!

      json = api_show_override(@course, @assignment, @override)
      validate_override_json(@override, json)
    end

    it "should include proper set fields when set is a group" do
      @assignment.group_category = @course.group_categories.create!(name: "foo")
      @assignment.save!

      @group = @course.groups.create!(:name => 'my group', :group_category => @assignment.group_category)
      @group.add_user(@teacher, 'accepted')
      @course.groups_visible_to(@teacher).should include @group

      @override.reload
      @override.set = @group
      @override.save!

      json = api_show_override(@course, @assignment, @override)
      validate_override_json(@override, json)
    end

    it "should include proper set fields when set is adhoc" do
      student_in_course({:course => @course, :workflow_state => 'active'})

      @override.set = nil
      @override.set_type = 'ADHOC'
      @override.save!

      @override_student = @override.assignment_override_students.build
      @override_student.user = @student
      @override_student.save!

      json = api_show_override(@course, @assignment, @override)
      validate_override_json(@override, json)
    end
  end

  context "group alias" do
    before :each do
      course_with_teacher(:active_all => true)
      assignment_model(:course => @course, :group_category => 'category')
      group_model(:context => @course, :group_category => @assignment.group_category)
      assignment_override_model(:assignment => @assignment)
      @override.set = @group
      @override.save!
      @group.add_user(@teacher, 'accepted')
    end

    it "should redirect in nominal case" do
      raw_api_call(:get, "/api/v1/groups/#{@group.id}/assignments/#{@assignment.id}/override.json",
                   :controller => 'assignment_overrides', :action => 'group_alias', :format => 'json',
                   :group_id => @group.id.to_s,
                   :assignment_id => @assignment.id.to_s)
      response.should be_redirect
      response.location.should match "/api/v1/courses/#{@course.id}/assignments/#{@assignment.id}/overrides/#{@override.id}"
    end

    it "should 404 for non-visible group" do
      @original_teacher = @teacher
      course_model
      @other_group = @course.groups.create!

      @user = @original_teacher
      raw_api_call(:get, "/api/v1/groups/#{@other_group.id}/assignments/#{@assignment.id}/override.json",
                   :controller => 'assignment_overrides', :action => 'group_alias', :format => 'json',
                   :group_id => @other_group.id.to_s,
                   :assignment_id => @assignment.id.to_s)
      assert_status(404)
    end

    it "should 404 for unconnected group/assignment" do
      course_with_teacher(:user => @teacher, :active_all => true)
      @other_group = @course.groups.create!

      raw_api_call(:get, "/api/v1/groups/#{@other_group.id}/assignments/#{@assignment.id}/override.json",
                   :controller => 'assignment_overrides', :action => 'group_alias', :format => 'json',
                   :group_id => @other_group.id.to_s,
                   :assignment_id => @assignment.id.to_s)
      assert_status(404)
    end
  end

  context "section alias" do
    before :each do
      course_with_teacher(:active_all => true)
      assignment_model(:course => @course)
      assignment_override_model(:assignment => @assignment)
      @override.set = @course.default_section
      @override.save!
    end

    it "should redirect in nominal case" do
      raw_api_call(:get, "/api/v1/sections/#{@course.default_section.id}/assignments/#{@assignment.id}/override.json",
                   :controller => 'assignment_overrides', :action => 'section_alias', :format => 'json',
                   :course_section_id => @course.default_section.id.to_s,
                   :assignment_id => @assignment.id.to_s)
      response.should be_redirect
      response.location.should match "/api/v1/courses/#{@course.id}/assignments/#{@assignment.id}/overrides/#{@override.id}"
    end

    it "should 404 for non-visible section" do
      Enrollment.limit_privileges_to_course_section!(@course, @teacher, true)
      section = @course.course_sections.create!

      raw_api_call(:get, "/api/v1/sections/#{section.id}/assignments/#{@assignment.id}/override.json",
                   :controller => 'assignment_overrides', :action => 'section_alias', :format => 'json',
                   :course_section_id => section.id.to_s,
                   :assignment_id => @assignment.id.to_s)
      assert_status(404)
    end

    it "should 404 for unconnected section/assignment" do
      course_with_teacher(:user => @teacher, :active_all => true)

      raw_api_call(:get, "/api/v1/sections/#{@course.default_section.id}/assignments/#{@assignment.id}/override.json",
                   :controller => 'assignment_overrides', :action => 'section_alias', :format => 'json',
                   :course_section_id => @course.default_section.id.to_s,
                   :assignment_id => @assignment.id.to_s)
      assert_status(404)
    end
  end

  context "create" do
    def raw_api_create_override(course, assignment, data)
      raw_api_call(:post, "/api/v1/courses/#{course.id}/assignments/#{assignment.id}/overrides.json",
        { :controller => 'assignment_overrides', :action => 'create', :format => 'json',
          :course_id => course.id.to_s, :assignment_id => assignment.id.to_s },
        data)
    end

    def api_create_override(course, assignment, data)
      @user = @teacher
      api_call(:post, "/api/v1/courses/#{course.id}/assignments/#{assignment.id}/overrides.json",
        { :controller => 'assignment_overrides', :action => 'create', :format => 'json',
          :course_id => course.id.to_s, :assignment_id => assignment.id.to_s },
        data)
    end

    before :each do
      course_with_teacher(:active_all => true)
      assignment_model(:course => @course)
    end

    it "should error when missing set info" do
      raw_api_create_override(@course, @assignment, :assignment_override => { :due_at => 2.days.ago.iso8601 })
      expect_error("one of student_ids, group_id, or course_section_id is required")
    end

    context "adhoc" do
      before :each do
        @student = student_in_course(:course => @course, :user => user_with_pseudonym).user
        @title = 'adhoc title'
        @user = @teacher
      end

      it "should create an adhoc assignment override" do
        api_create_override(@course, @assignment, :assignment_override => { :student_ids => [@student.id], :title => @title })

        @override = @assignment.assignment_overrides(true).first
        @override.should_not be_nil
        @override.set.should == [@student]
      end

      it "should set the adhoc override title" do
        api_create_override(@course, @assignment, :assignment_override => { :student_ids => [@student.id], :title => @title })

        @override = @assignment.assignment_overrides(true).first
        @override.title.should == @title
      end

      it "should recognize sis ids for an adhoc assignment override" do
        api_create_override(@course, @assignment, :assignment_override => { :student_ids => ["sis_login_id:#{@student.pseudonym.unique_id}"], :title => @title })

        @override = @assignment.assignment_overrides(true).first
        @override.set.should == [@student]
      end

      it "should error with wrong data type for student_ids" do
        raw_api_create_override(@course, @assignment, :assignment_override => { :student_ids => 'bad data', :title => @title })
        expect_error("invalid student_ids \"bad data\"")
      end

      it "should error unless all student ids are found for an adhoc assignment override" do
        @bad_id = @student.id + 1

        raw_api_create_override(@course, @assignment, :assignment_override => { :student_ids => [@student.id, @bad_id], :title => @title })
        expect_error("unknown student ids: [\"#{@bad_id}\"]")
      end

      it "should error without a title for an adhoc assignment override" do
        raw_api_create_override(@course, @assignment, :assignment_override => { :student_ids => [@student.id] })
        expect_error('title required with student_ids')
      end

      it "should error if the assignment is a group assignment" do
        @assignment.group_category = @course.group_categories.create!(name: "foo")
        @assignment.save!

        raw_api_create_override(@course, @assignment, :assignment_override => { :student_ids => [@student.id], :title => @title })
        expect_error('student_ids are not valid for group assignments')
      end
    end

    context "group" do
      before :each do
        @assignment.group_category = @course.group_categories.create!(name: "foo")
        @assignment.save!
        @group = group_model(:context => @course, :group_category => @assignment.group_category)
      end

      it "should create a group assignment override" do
        api_create_override(@course, @assignment, :assignment_override => { :group_id => @group.id })

        @override = @assignment.assignment_overrides(true).first
        @override.should_not be_nil
        @override.set.should == @group
      end

      it "should error on invalid group_id" do
        @bad_id = @group.id + 1

        raw_api_create_override(@course, @assignment, :assignment_override => { :group_id => @bad_id })
        expect_error("unknown group id \"#{@bad_id}\"")
      end

      it "should error if the assignment is not a group assignment" do
        @assignment.group_category = nil
        @assignment.save!

        raw_api_create_override(@course, @assignment, :assignment_override => { :group_id => @group.id })
        expect_error('group_id is not valid for non-group assignments')
      end
    end

    context "section" do
      it "should create a section assignment override" do
        api_create_override(@course, @assignment, :assignment_override => { :course_section_id => @course.default_section.id })

        @override = @assignment.assignment_overrides(true).first
        @override.should_not be_nil
        @override.set.should == @course.default_section
      end

      it "should error on invalid course_section_id" do
        @original_course = @course
        @original_teacher = @teacher
        course_model
        @user = @original_teacher

        raw_api_create_override(@original_course, @assignment, :assignment_override => { :course_section_id => @course.default_section.id })
        expect_error("unknown section id \"#{@course.default_section.id}\"")
      end

      it "should not error if the assignment is a group assignment" do
        @assignment.group_category = @course.group_categories.create!(name: "foo")
        @assignment.save!

        api_create_override(@course, @assignment, :assignment_override => { :course_section_id => @course.default_section.id })

        @override = @assignment.assignment_overrides(true).first
        @override.should_not be_nil
        @override.set.should == @course.default_section
      end
    end

    context "set precedence" do
      it "should ignore group_id if there are student_ids" do
        @student = student_in_course(:course => @course, :user => user_with_pseudonym).user
        @group = group_model(:context => @course)
        @title = 'adhoc title'
        @user = @teacher

        api_create_override(@course, @assignment, :assignment_override => { :student_ids => [@student.id], :title => @title, :group_id => @group.id })

        @override = @assignment.assignment_overrides(true).first
        @override.set.should == [@student]
      end

      it "should ignore course_section_id if there are student_ids" do
        @student = student_in_course(:course => @course, :user => user_with_pseudonym).user
        @title = 'adhoc title'
        @user = @teacher

        api_create_override(@course, @assignment, :assignment_override => { :student_ids => [@student.id], :title => @title, :course_section_id => @course.default_section.id })

        @override = @assignment.assignment_overrides(true).first
        @override.set.should == [@student]
      end

      it "should ignore course_section_id if there is a group_id" do
        @assignment.group_category = @course.group_categories.create!(name: "foo")
        @assignment.save!
        @group = group_model(:context => @course, :group_category => @assignment.group_category)

        api_create_override(@course, @assignment, :assignment_override => { :group_id => @group.id, :course_section_id => @course.default_section.id })

        @override = @assignment.assignment_overrides(true).first
        @override.set.should == @group
      end
    end

    it "should error if you try and duplicate a set" do
      assignment_override_model(:assignment => @assignment)
      @override.set = @course.default_section
      @override.save!

      raw_api_create_override(@course, @assignment, :assignment_override => { :course_section_id => @course.default_section.id })
      expect_errors("set_id" => [{ "message"=>"taken", "attribute"=>"set_id", "type"=>"taken" }])
    end

    it "should error if you try and duplicate a student in an adhoc set" do
      assignment_override_model(:assignment => @assignment)
      @student = student_in_course(:course => @course).user
      @override_student = @override.assignment_override_students.build
      @override_student.user = @student
      @override_student.save!
      @user = @teacher

      raw_api_create_override(@course, @assignment, :assignment_override => { :student_ids => [@student.id], :title => 'adhoc title' })
      expect_errors("assignment_override_students" => [{ "attribute"=>"assignment_override_students", "type"=>"invalid", "message"=>"invalid" }])
    end

    context "overridden due_at" do
      it "should set the override due_at" do
        @due_at = 2.days.ago

        api_create_override(@course, @assignment, :assignment_override => { :course_section_id => @course.default_section.id, :due_at => @due_at.iso8601 })

        @override = @assignment.assignment_overrides(true).first
        @override.due_at_overridden.should be_true
        @override.due_at.to_i.should == @due_at.to_i
        @override.unlock_at_overridden.should be_false
        @override.lock_at_overridden.should be_false
      end

      it "should set a nil override due_at" do
        api_create_override(@course, @assignment, :assignment_override => { :course_section_id => @course.default_section.id, :due_at => nil })

        @override = @assignment.assignment_overrides(true).first
        @override.due_at_overridden.should be_true
        @override.due_at.should be_nil
      end

      it "should error on invalid due_at" do
        raw_api_create_override(@course, @assignment, :assignment_override => { :course_section_id => @course.default_section.id, :due_at => 'bad data' })
        expect_error("invalid due_at \"bad data\"")
      end
    end

    context "overridden unlock_at" do
      it "should set the override unlock_at" do
        @unlock_at = 2.days.ago

        api_create_override(@course, @assignment, :assignment_override => { :course_section_id => @course.default_section.id, :unlock_at => @unlock_at.iso8601 })

        @override = @assignment.assignment_overrides(true).first
        @override.due_at_overridden.should be_false
        @override.unlock_at_overridden.should be_true
        @override.unlock_at.to_i.should == @unlock_at.to_i
        @override.lock_at_overridden.should be_false
      end

      it "should set a nil override unlock_at" do
        api_create_override(@course, @assignment, :assignment_override => { :course_section_id => @course.default_section.id, :unlock_at => nil })

        @override = @assignment.assignment_overrides(true).first
        @override.unlock_at_overridden.should be_true
        @override.unlock_at.should be_nil
      end

      it "should error on invalid unlock_at" do
        raw_api_create_override(@course, @assignment, :assignment_override => { :course_section_id => @course.default_section.id, :unlock_at => 'bad data' })
        expect_error("invalid unlock_at \"bad data\"")
      end
    end

    context "overridden lock_at" do
      it "should set the override lock_at" do
        @lock_at = 2.days.ago

        api_create_override(@course, @assignment, :assignment_override => { :course_section_id => @course.default_section.id, :lock_at => @lock_at.iso8601 })

        @override = @assignment.assignment_overrides(true).first
        @override.due_at_overridden.should be_false
        @override.unlock_at_overridden.should be_false
        @override.lock_at_overridden.should be_true
        @override.lock_at.to_i.should == @lock_at.to_i
      end

      it "should set a nil override lock_at" do
        api_create_override(@course, @assignment, :assignment_override => { :course_section_id => @course.default_section.id, :lock_at => nil })

        @override = @assignment.assignment_overrides(true).first
        @override.lock_at_overridden.should be_true
        @override.lock_at.should be_nil
      end

      it "should error on invalid lock_at" do
        raw_api_create_override(@course, @assignment, :assignment_override => { :course_section_id => @course.default_section.id, :lock_at => 'bad data' })
        expect_error("invalid lock_at \"bad data\"")
      end
    end

    it "should return the override json" do
      json = api_create_override(@course, @assignment, :assignment_override => { :course_section_id => @course.default_section.id, :due_at => 2.days.ago.iso8601 })

      @override = @assignment.assignment_overrides(true).first
      validate_override_json(@override, json)
    end
  end

  context "update" do
    def raw_api_update_override(course, assignment, override, data)
      raw_api_call(:put, "/api/v1/courses/#{course.id}/assignments/#{assignment.id}/overrides/#{override.id}.json",
        { :controller => 'assignment_overrides', :action => 'update', :format => 'json',
          :course_id => course.id.to_s, :assignment_id => assignment.id.to_s, :id => override.id.to_s },
        data)
    end

    def api_update_override(course, assignment, override, data)
      @user = @teacher
      api_call(:put, "/api/v1/courses/#{course.id}/assignments/#{assignment.id}/overrides/#{override.id}.json",
        { :controller => 'assignment_overrides', :action => 'update', :format => 'json',
          :course_id => course.id.to_s, :assignment_id => assignment.id.to_s, :id => override.id.to_s },
        data)
    end

    before :each do
      course_with_teacher(:active_all => true)
      assignment_model(:course => @course)
      assignment_override_model(:assignment => @assignment)
    end

    it "should not error without set info" do
      @override.set = @course.default_section
      @override.save!

      api_update_override(@course, @assignment, @override, :assignment_override => { :due_at => 2.days.ago.iso8601 })
    end

    it "should not change values not specified" do
      @override.set = @course.default_section
      @override.save!

      api_update_override(@course, @assignment, @override, :assignment_override => { :dummy => 'ignored' })

      @override.reload
      @override.set.should == @course.default_section
      @override.title.should == @course.default_section.name
      @override.due_at_overridden.should be_false
      @override.unlock_at_overridden.should be_false
      @override.lock_at_overridden.should be_false
    end

    context "adhoc override" do
      before :each do
        @student = student_in_course(:course => @course).user
        @title = 'adhoc title'
        @user = @teacher

        @override.title = @title
        @override_student = @override.assignment_override_students.build
        @override_student.user = @student
        @override.save!
      end

      it "should ignore group_id and section_id" do
        api_update_override(@course, @assignment, @override, :assignment_override => { :group_id => group_model.id })
        @override.reload
        @override.set.should == [@student]

        api_update_override(@course, @assignment, @override, :assignment_override => { :course_section_id => @course.default_section.id })
        @override.reload
        @override.set.should == [@student]
      end

      it "should allow changing the students in the set" do
        @other_student = student_in_course(:course => @course).user
        api_update_override(@course, @assignment, @override, :assignment_override => { :student_ids => [@other_student.id] })
        @override.reload
        @override.set.should == [@other_student]
      end

      it "should allow changing the title" do
        @new_title = "new #@title"
        api_update_override(@course, @assignment, @override, :assignment_override => { :title => @new_title })
        @override.reload
        @override.title.should == @new_title
      end

      it "should error if you try and duplicate a student in an adhoc set" do
        @original_override = @override
        @original_override.set = @student
        assignment_override_model(:assignment => @assignment)
        @student = student_in_course(:course => @course).user
        @override_student = @override.assignment_override_students.build
        @override_student.user = @student
        @override_student.save!
        @user = @teacher

        raw_api_update_override(@course, @assignment, @original_override, :assignment_override => { :student_ids => [@student.id] })
        expect_errors("assignment_override_students" => [{ "attribute"=>"assignment_override_students", "type"=>"invalid", "message"=>"invalid" }])
      end
    end

    context "group override" do
      before :each do
        @assignment.group_category = @course.group_categories.create!(name: "foo")
        @assignment.save!
        @group = group_model(:context => @course, :group_category => @assignment.group_category)

        @override.reload
        @override.set = @group
        @override.save!
      end

      it "should ignore student_ids, group_id, and section_id" do
        @original_group = @group
        @student = student_in_course(:course => @course).user
        @user = @teacher
        @original_group.add_user(@user, 'accepted')

        api_update_override(@course, @assignment, @override, :assignment_override => { :student_ids => [@student.id] })
        @override.reload
        @override.set.should == @original_group

        api_update_override(@course, @assignment, @override, :assignment_override => { :group_id => @group.id })
        @override.reload
        @override.set.should == @original_group

        api_update_override(@course, @assignment, @override, :assignment_override => { :course_section_id => @course.default_section.id })
        @override.reload
        @override.set.should == @original_group
      end

      it "should not allow changing the title" do
        @new_title = "new title"
        @group.add_user(@user, 'accepted')
        api_update_override(@course, @assignment, @override, :assignment_override => { :title => @new_title })
        @override.reload
        @override.title.should == @group.name
      end
    end

    context "section override" do
      before :each do
        @override.set = @course.default_section
        @override.save!
      end

      it "should ignore student_ids, group_id, and section_id" do
        @student = student_in_course(:course => @course).user
        @group = group_model(:context => @course)
        @other_section = @course.course_sections.create!
        @user = @teacher

        api_update_override(@course, @assignment, @override, :assignment_override => { :student_ids => [@student.id] })
        @override.reload
        @override.set.should == @course.default_section

        api_update_override(@course, @assignment, @override, :assignment_override => { :group_id => @group.id })
        @override.reload
        @override.set.should == @course.default_section

        api_update_override(@course, @assignment, @override, :assignment_override => { :course_section_id => @other_section.id })
        @override.reload
        @override.set.should == @course.default_section
      end

      it "should not allow changing the title" do
        @new_title = "new title"
        api_update_override(@course, @assignment, @override, :assignment_override => { :title => @new_title })
        @override.reload
        @override.title.should == @course.default_section.name
      end
    end

    context "overridden due_at" do
      before :each do
        @override.set = @course.default_section
        @override.save!

        @due_at = 2.days.ago
      end

      it "should set the override due_at" do
        @override.clear_due_at_override
        @override.save!

        api_update_override(@course, @assignment, @override, :assignment_override => { :due_at => @due_at.iso8601 })

        @override.reload
        @override.due_at_overridden.should be_true
        @override.due_at.to_i.should == @due_at.to_i
      end

      it "should set a nil override due_at" do
        @override.clear_due_at_override
        @override.save!

        api_update_override(@course, @assignment, @override, :assignment_override => { :due_at => nil })

        @override.reload
        @override.due_at_overridden.should be_true
        @override.due_at.should be_nil
      end

      it "should clear a previous override if unspecified" do
        @override.override_due_at(@due_at)
        @override.save!

        api_update_override(@course, @assignment, @override, :assignment_override => {})

        @override.reload
        @override.due_at_overridden.should be_false
      end

      it "should error on invalid due_at" do
        raw_api_update_override(@course, @assignment, @override, :assignment_override => { :due_at => 'bad data' })
        expect_error("invalid due_at \"bad data\"")
      end
    end

    context "overridden unlock_at" do
      before :each do
        @override.set = @course.default_section
        @override.save!

        @unlock_at = 2.days.ago
        @unlock_at -= (@unlock_at.to_f % 1) # shave of usecs
      end

      it "should set the override unlock_at" do
        @override.clear_unlock_at_override
        @override.save!

        api_update_override(@course, @assignment, @override, :assignment_override => { :unlock_at => @unlock_at.iso8601 })

        @override.reload
        @override.unlock_at_overridden.should be_true
        @override.unlock_at.to_i.should == @unlock_at.to_i
      end

      it "should set a nil override unlock_at" do
        @override.clear_unlock_at_override
        @override.save!

        api_update_override(@course, @assignment, @override, :assignment_override => { :unlock_at => nil })

        @override.reload
        @override.unlock_at_overridden.should be_true
        @override.unlock_at.should be_nil
      end

      it "should clear a previous override if unspecified" do
        @override.override_unlock_at(@unlock_at)
        @override.save!

        api_update_override(@course, @assignment, @override, :assignment_override => {})

        @override.reload
        @override.unlock_at_overridden.should be_false
      end

      it "should error on invalid unlock_at" do
        raw_api_update_override(@course, @assignment, @override, :assignment_override => { :unlock_at => 'bad data' })
        expect_error("invalid unlock_at \"bad data\"")
      end
    end

    context "overridden lock_at" do
      before :each do
        @override.set = @course.default_section
        @override.save!

        @lock_at = 2.days.ago
        @lock_at -= (@lock_at.to_f % 1) # shave of usecs
      end

      it "should set the override lock_at" do
        @override.clear_lock_at_override
        @override.save!

        api_update_override(@course, @assignment, @override, :assignment_override => { :lock_at => @lock_at.iso8601 })

        @override.reload
        @override.lock_at_overridden.should be_true
        @override.lock_at.to_i.should == @lock_at.to_i
      end

      it "should set a nil override lock_at" do
        @override.clear_lock_at_override
        @override.save!

        api_update_override(@course, @assignment, @override, :assignment_override => { :lock_at => nil })

        @override.reload
        @override.lock_at_overridden.should be_true
        @override.lock_at.should be_nil
      end

      it "should clear a previous override if unspecified" do
        @override.override_lock_at(@lock_at)
        @override.save!

        api_update_override(@course, @assignment, @override, :assignment_override => {})

        @override.reload
        @override.lock_at_overridden.should be_false
      end

      it "should error on invalid lock_at" do
        raw_api_update_override(@course, @assignment, @override, :assignment_override => { :lock_at => 'bad data' })
        expect_error("invalid lock_at \"bad data\"")
      end
    end

    it "should return the override json" do
      @override.set = @course.default_section
      @override.save!

      json = api_update_override(@course, @assignment, @override, :assignment_override => { :due_at => 2.days.ago.iso8601 })

      @override.reload
      validate_override_json(@override, json)
    end
  end

  context "destroy" do
    before :each do
      course_with_teacher(:active_all => true)
      assignment_model(:course => @course, :group_category => 'category')
      assignment_override_model(:assignment => @assignment)
      @override.set = @course.default_section
      @override.save!
    end

    it "should delete the override" do
      api_call(:delete, "/api/v1/courses/#{@course.id}/assignments/#{@assignment.id}/overrides/#{@override.id}.json",
               :controller => 'assignment_overrides', :action => 'destroy', :format => 'json',
               :course_id => @course.id.to_s, :assignment_id => @assignment.id.to_s, :id => @override.id.to_s)
      @override.reload
      @override.should be_deleted
    end

    it "should return the override details" do
      json = api_call(:delete, "/api/v1/courses/#{@course.id}/assignments/#{@assignment.id}/overrides/#{@override.id}.json",
                      :controller => 'assignment_overrides', :action => 'destroy', :format => 'json',
                      :course_id => @course.id.to_s, :assignment_id => @assignment.id.to_s, :id => @override.id.to_s)
      @override.reload
      validate_override_json(@override, json)
    end

    it "should 404 for non-visible override" do
      @override.destroy
      raw_api_call(:delete, "/api/v1/courses/#{@course.id}/assignments/#{@assignment.id}/overrides/#{@override.id}.json",
                   :controller => 'assignment_overrides', :action => 'destroy', :format => 'json',
                   :course_id => @course.id.to_s, :assignment_id => @assignment.id.to_s, :id => @override.id.to_s)
      assert_status(404)
    end
  end
end
