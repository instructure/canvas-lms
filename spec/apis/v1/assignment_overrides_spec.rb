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
require File.expand_path(File.dirname(__FILE__) + '/../../sharding_spec_helper.rb')

describe AssignmentOverridesController, type: :request do
  def validate_override_json(override, json)
    expect(json['id']).to eq override.id
    expect(json['assignment_id']).to eq override.assignment_id
    expect(json['title']).to eq override.title

    if override.due_at_overridden
      expect(json['due_at']).to eq override.due_at.iso8601
      expect(json['all_day']).to eq override.all_day
      expect(json['all_day_date']).to eq override.all_day_date.to_s
    else
      expect(json).not_to have_key 'due_at'
      expect(json).not_to have_key 'all_day'
      expect(json).not_to have_key 'all_day_date'
    end

    if override.unlock_at_overridden
      expect(json['unlock_at']).to eq override.unlock_at.iso8601
    else
      expect(json).not_to have_key 'unlock_at'
    end

    if override.lock_at_overridden
      expect(json['lock_at']).to eq override.lock_at.iso8601
    else
      expect(json).not_to have_key 'lock_at'
    end

    case override.set
    when Array
      expect(json['student_ids']).to eq override.set.map(&:id)
      expect(json).not_to have_key 'group_id'
      expect(json).not_to have_key 'course_section_id'
    when Group
      expect(json['group_id']).to eq override.set_id
      expect(json).not_to have_key 'student_ids'
      expect(json).not_to have_key 'course_section_id'
    when CourseSection
      expect(json['course_section_id']).to eq override.set_id
      expect(json).not_to have_key 'student_ids'
      expect(json).not_to have_key 'group_id'
    end
  end

  def expect_errors(errors)
    assert_status(400)
    json = JSON.parse(response.body)
    expect(json).to eq({"errors" => errors})
  end

  def expect_error(error)
    expect_errors([error])
  end

  context "index" do
    before :once do
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

      expect(json.size).to eq 1
    end

    it "should exclude deleted overrides" do
      @override.destroy

      json = api_call(:get, "/api/v1/courses/#{@course.id}/assignments/#{@assignment.id}/overrides.json",
                      :controller => 'assignment_overrides', :action => 'index', :format => 'json',
                      :course_id => @course.id.to_s,
                      :assignment_id => @assignment.id.to_s)

      expect(json.size).to eq 0
    end

    it "should include overrides outside the user's sections if user is admin" do
      Enrollment.limit_privileges_to_course_section!(@course, @teacher, true)

      @override.set = @course.course_sections.create!
      @override.save!

      expect(@course.sections_visible_to(@teacher)).not_to include @override.set
      json = api_call(:get, "/api/v1/courses/#{@course.id}/assignments/#{@assignment.id}/overrides.json",
                      :controller => 'assignment_overrides', :action => 'index', :format => 'json',
                      :course_id => @course.id.to_s,
                      :assignment_id => @assignment.id.to_s)

      expect(json.size).to eq 1
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
    before :once do
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
      expect(@course.groups_visible_to(@teacher)).to include @group

      @override.reload
      @override.set = @group
      @override.save!

      json = api_show_override(@course, @assignment, @override)
      validate_override_json(@override, json)
    end

    it "should include proper set fields when set is adhoc" do
      student_in_course({:course => @course, :workflow_state => 'active'})
      create_adhoc_override_for_assignment(@assignment, @student)

      json = api_show_override(@course, @assignment, @override)
      validate_override_json(@override, json)
    end
  end

  context "group alias" do
    before :once do
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
      expect(response).to be_redirect
      expect(response.location).to match "/api/v1/courses/#{@course.id}/assignments/#{@assignment.id}/overrides/#{@override.id}"
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
    before :once do
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
      expect(response).to be_redirect
      expect(response.location).to match "/api/v1/courses/#{@course.id}/assignments/#{@assignment.id}/overrides/#{@override.id}"
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

    before :once do
      course_with_teacher(:active_all => true)
      assignment_model(:course => @course)
    end

    it "should error when missing set info" do
      raw_api_create_override(@course, @assignment, :assignment_override => { :due_at => 2.days.ago.iso8601 })
      expect_error("one of student_ids, group_id, or course_section_id is required")
    end

    context "adhoc" do
      specs_require_sharding

      def mock_sharding_data
        @shard1.activate { @user = User.create!(name: "McShardalot")}
        @course.enroll_student @user
      end

      def validate_global_id
        @override = @assignment.assignment_overrides.reload.first
        expect(@override).not_to be_nil
        expect(@override.set).to eq [@student]
      end

      before :once do
        @student = student_in_course(:course => @course, :user => user_with_pseudonym).user
        @title = 'adhoc title'
        @user = @teacher
      end

      it "should create an adhoc assignment override" do
        api_create_override(@course, @assignment, :assignment_override => { :student_ids => [@student.id], :title => @title })

        @override = @assignment.assignment_overrides.reload.first
        expect(@override).not_to be_nil
        expect(@override.set).to eq [@student]
      end

      it "should create an adhoc assignment override with global id for student" do
        mock_sharding_data
        api_create_override(@course, @assignment, :assignment_override => { :student_ids => [@student.global_id], :title => @title })
        validate_global_id
      end

      it "should create an adhoc assignment override with global id for course" do
        mock_sharding_data
        @course.id = @course.global_id
        api_create_override(@course, @assignment, :assignment_override => { :student_ids => [@student.id], :title => @title })
        validate_global_id
      end

      it "should create an adhoc assignment override with global id for assignment" do
        mock_sharding_data
        @assignment.id = @assignment.global_id
        api_create_override(@course, @assignment, :assignment_override => { :student_ids => [@student.id], :title => @title })
        validate_global_id
      end

      it "should set the adhoc override title" do
        api_create_override(@course, @assignment, :assignment_override => { :student_ids => [@student.id], :title => @title })

        @override = @assignment.assignment_overrides.reload.first
        expect(@override.title).to eq @title
      end

      it "should recognize sis ids for an adhoc assignment override" do
        api_create_override(@course, @assignment, :assignment_override => { :student_ids => ["sis_login_id:#{@student.pseudonym.unique_id}"], :title => @title })

        @override = @assignment.assignment_overrides.reload.first
        expect(@override.set).to eq [@student]
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

      it "should not error if the assignment is a group assignment" do
        @assignment.group_category = @course.group_categories.create!(name: "foo")
        @assignment.save!

        raw_api_create_override(@course, @assignment, :assignment_override => { :student_ids => [@student.id], :title => @title })
        @override = @assignment.assignment_overrides.reload.first
        expect(@override).not_to be_nil
        expect(@override.set).to eq [@student]
      end

      context "title" do
        before :once do
          names = ["Adam Aardvark", "Ben Banana", "Chipmunk Charlie", "Donald Duck", "Erik Erikson", "Freddy Frog"]
          @students = names.map do |name|
            student_in_course(course: @course, :user => user_with_pseudonym(name: name)).user
          end
          @course.reload
        end

        it "should concat students names if there are fewer than 4" do
          student_ids = @students[0..1].map(&:id)
          api_create_override(@course, @assignment, :assignment_override => { :student_ids => student_ids})
          @override = @assignment.assignment_overrides.reload.first
          expect(@override.title).to eq("2 students")
        end

        it "should add an others count if there are more than 4" do
          student_ids = @students.map(&:id)
          api_create_override(@course, @assignment, :assignment_override => { :student_ids => student_ids})
          @override = @assignment.assignment_overrides.reload.first
          expect(@override.title).to eq("6 students")
        end

        it "should alphabetize the students names" do
          reversed_student_ids = @students.reverse.map(&:id)

          api_create_override(@course, @assignment, :assignment_override => { :student_ids => reversed_student_ids})
          @override = @assignment.assignment_overrides.reload.first

          expect(@override.title).to eq("6 students")
        end

        it "should prefer a given title" do
          student_ids = @students.map(&:id)
          api_create_override(
            @course,
            @assignment,
            :assignment_override => { :student_ids => student_ids, title: "Preferred Title"}
          )
          @override = @assignment.assignment_overrides.reload.first
          expect(@override.title).to eq("Preferred Title")
        end
      end
    end

    context "group" do
      before :once do
        @assignment.group_category = @course.group_categories.create!(name: "foo")
        @assignment.save!
        @group = group_model(:context => @course, :group_category => @assignment.group_category)
      end

      it "should create a group assignment override" do
        api_create_override(@course, @assignment, :assignment_override => { :group_id => @group.id })

        @override = @assignment.assignment_overrides.reload.first
        expect(@override).not_to be_nil
        expect(@override.set).to eq @group
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

        @override = @assignment.assignment_overrides.reload.first
        expect(@override).not_to be_nil
        expect(@override.set).to eq @course.default_section
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

        @override = @assignment.assignment_overrides.reload.first
        expect(@override).not_to be_nil
        expect(@override.set).to eq @course.default_section
      end
    end

    context "set precedence" do
      it "should ignore group_id if there are student_ids" do
        @student = student_in_course(:course => @course, :user => user_with_pseudonym).user
        @group = group_model(:context => @course)
        @title = 'adhoc title'
        @user = @teacher

        api_create_override(@course, @assignment, :assignment_override => { :student_ids => [@student.id], :title => @title, :group_id => @group.id })

        @override = @assignment.assignment_overrides.reload.first
        expect(@override.set).to eq [@student]
      end

      it "should ignore course_section_id if there are student_ids" do
        @student = student_in_course(:course => @course, :user => user_with_pseudonym).user
        @title = 'adhoc title'
        @user = @teacher

        api_create_override(@course, @assignment, :assignment_override => { :student_ids => [@student.id], :title => @title, :course_section_id => @course.default_section.id })

        @override = @assignment.assignment_overrides.reload.first
        expect(@override.set).to eq [@student]
      end

      it "should ignore course_section_id if there is a group_id" do
        @assignment.group_category = @course.group_categories.create!(name: "foo")
        @assignment.save!
        @group = group_model(:context => @course, :group_category => @assignment.group_category)

        api_create_override(@course, @assignment, :assignment_override => { :group_id => @group.id, :course_section_id => @course.default_section.id })

        @override = @assignment.assignment_overrides.reload.first
        expect(@override.set).to eq @group
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
      @override_student.workflow_state = "active"
      @override_student.user = @student
      @override_student.save!
      @user = @teacher

      raw_api_create_override(@course, @assignment, :assignment_override => { :student_ids => [@student.id], :title => 'adhoc title' })
      expect_errors("assignment_override_students" => [{
        "attribute"=>"assignment_override_students",
        "type"=>"taken",
        "message"=>"already belongs to an assignment override"
      }])
    end

    context "overridden due_at" do
      it "should set the override due_at" do
        @due_at = 2.days.ago

        api_create_override(@course, @assignment, :assignment_override => { :course_section_id => @course.default_section.id, :due_at => @due_at.iso8601 })

        @override = @assignment.assignment_overrides.reload.first
        expect(@override.due_at_overridden).to be_truthy
        expect(@override.due_at.to_i).to eq @due_at.to_i
        expect(@override.unlock_at_overridden).to be_falsey
        expect(@override.lock_at_overridden).to be_falsey
      end

      it "should set a nil override due_at" do
        api_create_override(@course, @assignment, :assignment_override => { :course_section_id => @course.default_section.id, :due_at => nil })

        @override = @assignment.assignment_overrides.reload.first
        expect(@override.due_at_overridden).to be_truthy
        expect(@override.due_at).to be_nil
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

        @override = @assignment.assignment_overrides.reload.first
        expect(@override.due_at_overridden).to be_falsey
        expect(@override.unlock_at_overridden).to be_truthy
        expect(@override.unlock_at.to_i).to eq @unlock_at.to_i
        expect(@override.lock_at_overridden).to be_falsey
      end

      it "should set a nil override unlock_at" do
        api_create_override(@course, @assignment, :assignment_override => { :course_section_id => @course.default_section.id, :unlock_at => nil })

        @override = @assignment.assignment_overrides.reload.first
        expect(@override.unlock_at_overridden).to be_truthy
        expect(@override.unlock_at).to be_nil
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

        @override = @assignment.assignment_overrides.reload.first
        expect(@override.due_at_overridden).to be_falsey
        expect(@override.unlock_at_overridden).to be_falsey
        expect(@override.lock_at_overridden).to be_truthy
        expect(@override.lock_at.to_i).to eq @lock_at.to_i
      end

      it "should set a nil override lock_at" do
        api_create_override(@course, @assignment, :assignment_override => { :course_section_id => @course.default_section.id, :lock_at => nil })

        @override = @assignment.assignment_overrides.reload.first
        expect(@override.lock_at_overridden).to be_truthy
        expect(@override.lock_at).to be_nil
      end

      it "should error on invalid lock_at" do
        raw_api_create_override(@course, @assignment, :assignment_override => { :course_section_id => @course.default_section.id, :lock_at => 'bad data' })
        expect_error("invalid lock_at \"bad data\"")
      end
    end

    it "should return the override json" do
      json = api_create_override(@course, @assignment, :assignment_override => { :course_section_id => @course.default_section.id, :due_at => 2.days.ago.iso8601 })

      @override = @assignment.assignment_overrides.reload.first
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

    before :once do
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
      expect(@override.set).to eq @course.default_section
      expect(@override.title).to eq @course.default_section.name
      expect(@override.due_at_overridden).to be_falsey
      expect(@override.unlock_at_overridden).to be_falsey
      expect(@override.lock_at_overridden).to be_falsey
    end

    context "adhoc override" do
      before :once do
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
        expect(@override.set).to eq [@student]

        api_update_override(@course, @assignment, @override, :assignment_override => { :course_section_id => @course.default_section.id })
        @override.reload
        expect(@override.set).to eq [@student]
      end

      it "should allow changing the students in the set" do
        @other_student = student_in_course(:course => @course).user
        api_update_override(@course, @assignment, @override, :assignment_override => { :student_ids => [@other_student.id] })
        @override.reload
        expect(@override.set).to eq [@other_student]
      end

      it "should not change the title when only changing the due date" do
        api_update_override(@course, @assignment, @override, :assignment_override => { :due_at => 1.day.from_now })
        @override.reload
        expect(@override.title).to eq @title
      end

      it "should relock modules when changing overrides" do
        # but only for the students they affect
        @assignment.only_visible_to_overrides = true
        @assignment.save!

        mod = @course.context_modules.create!
        tag = mod.add_item({:id => @assignment.id, :type => "assignment"})
        mod.completion_requirements = {tag.id => {:type => 'must_submit'}}
        mod.save!

        @old_student = @student
        @new_student = student_in_course(:course => @course).user
        @other_student = student_in_course(:course => @course).user

        prog = mod.evaluate_for(@old_student)
        expect(prog).to be_unlocked # since they can see the assignment

        new_prog = mod.evaluate_for(@new_student)
        expect(new_prog).to be_completed # since they can't see the assignment yet

        other_prog = mod.evaluate_for(@other_student)
        expect_any_instantiation_of(other_prog).to receive(:evaluate!).never

        api_update_override(@course, @assignment, @override, :assignment_override => { :student_ids => [@new_student.id] })

        prog.reload
        expect(prog).to be_completed # now they can't see it anymore

        new_prog.reload
        expect(new_prog).to be_unlocked # now they can
      end

      it "recomputes grades when changing overrides" do
        @assignment.update_attributes! only_visible_to_overrides: true, points_possible: 10
        other_assignment = @course.assignments.create! points_possible: 10, context: @course

        student1 = @student
        student2 = student_in_course(:course => @course).user
        other_assignment.grade_student(student1, grade: 10, grader: @teacher)
        other_assignment.grade_student(student2, grade: 10, grader: @teacher)

        e1 = student1.enrollments.first
        e2 = student2.enrollments.first
        expect(e1.computed_final_score).to eq 50
        expect(e2.computed_final_score).to eq 100

        api_update_override(@course, @assignment, @override, :assignment_override => { :student_ids => [student2.id] })
        expect(e1.reload.computed_final_score).to eq 100
        expect(e2.reload.computed_final_score).to eq 50

      end

      it "runs DueDateCacher after changing overrides" do
        always_override_student = @student
        remove_override_student = student_in_course(:course => @course).user
        @override.assignment_override_students.create!(user: remove_override_student)
        @override.reload

        expect(DueDateCacher).to receive(:recompute).with(@assignment, hash_including(update_grades: false))
        api_update_override(@course, @assignment, @override,
          :assignment_override => { :student_ids => [always_override_student.id] })

        @override.reload
        expect(@override.assignment_override_students.map(&:user_id)).to eq([always_override_student.id])
      end

      it "should allow changing the title" do
        @new_title = "new #{@title}"
        api_update_override(@course, @assignment, @override, :assignment_override => { :title => @new_title })
        @override.reload
        expect(@override.title).to eq @new_title
      end

      it "should error if you try and duplicate a student in an adhoc set" do
        @original_override = @override
        @original_override.set = @student
        assignment_override_model(:assignment => @assignment)
        @student = student_in_course(:course => @course).user
        @override_student = @override.assignment_override_students.build
        @override_student.workflow_state = "active"
        @override_student.user = @student
        @override_student.save!
        @user = @teacher

        raw_api_update_override(@course, @assignment, @original_override, :assignment_override => { :student_ids => [@student.id] })
        expect_errors("assignment_override_students" => [{
          "attribute"=>"assignment_override_students",
          "type"=>"taken",
          "message"=>"already belongs to an assignment override"
        }])
      end
    end

    context "group override" do
      before :once do
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
        expect(@override.set).to eq @original_group

        api_update_override(@course, @assignment, @override, :assignment_override => { :group_id => @group.id })
        @override.reload
        expect(@override.set).to eq @original_group

        api_update_override(@course, @assignment, @override, :assignment_override => { :course_section_id => @course.default_section.id })
        @override.reload
        expect(@override.set).to eq @original_group
      end

      it "should not allow changing the title" do
        @new_title = "new title"
        @group.add_user(@user, 'accepted')
        api_update_override(@course, @assignment, @override, :assignment_override => { :title => @new_title })
        @override.reload
        expect(@override.title).to eq @group.name
      end
    end

    context "section override" do
      before :once do
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
        expect(@override.set).to eq @course.default_section

        api_update_override(@course, @assignment, @override, :assignment_override => { :group_id => @group.id })
        @override.reload
        expect(@override.set).to eq @course.default_section

        api_update_override(@course, @assignment, @override, :assignment_override => { :course_section_id => @other_section.id })
        @override.reload
        expect(@override.set).to eq @course.default_section
      end

      it "should not allow changing the title" do
        @new_title = "new title"
        api_update_override(@course, @assignment, @override, :assignment_override => { :title => @new_title })
        @override.reload
        expect(@override.title).to eq @course.default_section.name
      end
    end

    context "overridden due_at" do
      before :once do
        @override.set = @course.default_section
        @override.save!

        @due_at = 2.days.ago
      end

      it "should set the override due_at" do
        @override.clear_due_at_override
        @override.save!

        api_update_override(@course, @assignment, @override, :assignment_override => { :due_at => @due_at.iso8601 })

        @override.reload
        expect(@override.due_at_overridden).to be_truthy
        expect(@override.due_at.to_i).to eq @due_at.to_i
      end

      it "should set a nil override due_at" do
        @override.clear_due_at_override
        @override.save!

        api_update_override(@course, @assignment, @override, :assignment_override => { :due_at => nil })

        @override.reload
        expect(@override.due_at_overridden).to be_truthy
        expect(@override.due_at).to be_nil
      end

      it "should clear a previous override if unspecified" do
        @override.override_due_at(@due_at)
        @override.save!

        api_update_override(@course, @assignment, @override, :assignment_override => {})

        @override.reload
        expect(@override.due_at_overridden).to be_falsey
      end

      it "should error on invalid due_at" do
        raw_api_update_override(@course, @assignment, @override, :assignment_override => { :due_at => 'bad data' })
        expect_error("invalid due_at \"bad data\"")
      end
    end

    context "overridden unlock_at" do
      before :once do
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
        expect(@override.unlock_at_overridden).to be_truthy
        expect(@override.unlock_at.to_i).to eq @unlock_at.to_i
      end

      it "should set a nil override unlock_at" do
        @override.clear_unlock_at_override
        @override.save!

        api_update_override(@course, @assignment, @override, :assignment_override => { :unlock_at => nil })

        @override.reload
        expect(@override.unlock_at_overridden).to be_truthy
        expect(@override.unlock_at).to be_nil
      end

      it "should clear a previous override if unspecified" do
        @override.override_unlock_at(@unlock_at)
        @override.save!

        api_update_override(@course, @assignment, @override, :assignment_override => {})

        @override.reload
        expect(@override.unlock_at_overridden).to be_falsey
      end

      it "should error on invalid unlock_at" do
        raw_api_update_override(@course, @assignment, @override, :assignment_override => { :unlock_at => 'bad data' })
        expect_error("invalid unlock_at \"bad data\"")
      end
    end

    context "overridden lock_at" do
      before :once do
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
        expect(@override.lock_at_overridden).to be_truthy
        expect(@override.lock_at.to_i).to eq @lock_at.to_i
      end

      it "should set a nil override lock_at" do
        @override.clear_lock_at_override
        @override.save!

        api_update_override(@course, @assignment, @override, :assignment_override => { :lock_at => nil })

        @override.reload
        expect(@override.lock_at_overridden).to be_truthy
        expect(@override.lock_at).to be_nil
      end

      it "should clear a previous override if unspecified" do
        @override.override_lock_at(@lock_at)
        @override.save!

        api_update_override(@course, @assignment, @override, :assignment_override => {})

        @override.reload
        expect(@override.lock_at_overridden).to be_falsey
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
    before :once do
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
      expect(@override).to be_deleted
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

  context 'batch operations' do
    before :once do
      course_with_teacher(:active_all => true)
      @a, @b = 2.times.map { assignment_model(:course => @course) }
      @a1, @a2 = 2.times.map do
        student_in_course
        create_adhoc_override_for_assignment(@a, @student)
      end
      @b1, @b2, @b3 = 3.times.map do
        create_section_override_for_assignment(@b, course_section: @course.course_sections.create!)
      end
      @user = @teacher
    end

    def args_for(assignment, override = nil, attrs = {})
      args = {assignment_id: assignment.id}
      args[:id] = override.id if override.present?
      args.deep_merge(attrs)
    end

    describe "batch_retrieve" do
      def call_batch_retrieve(overrides_array, opts = {})
        api_call(:get, "/api/v1/courses/#{@course.id}/assignments/overrides.json", {
                    controller: 'assignment_overrides', action: 'batch_retrieve', format: 'json',
                    course_id: @course.id.to_s
                  },
                  { assignment_overrides: overrides_array },
                  {},
                  opts)
      end

      def matched_ids(json)
        json.map {|override_json| override_json.try(:[], 'id')}
      end

      it "should fail if no overrides requested" do
        call_batch_retrieve({}, expected_status: 400)
      end

      it "should fail if overrides incorrectly specified" do
        json = call_batch_retrieve([@a1.id, @a2.id], expected_status: 400)
        expect(json['errors']).to eq ['must specify an array with entry format { id, assignment_id }']
      end

      it "should fail if override ids incorrectly specified" do
        json = call_batch_retrieve([{ assignment: @a.id, override: @a1.id }], expected_status: 400)
        expect(json['errors']).to eq ['must specify an array with entry format { id, assignment_id }']
      end

      it "should retrieve multiple overrides in order" do
        json = call_batch_retrieve([
          args_for(@a, @a1),
          args_for(@b, @b1),
          args_for(@a, @a2)
        ])
        expect(matched_ids(json)).to eq [@a1.id, @b1.id, @a2.id]
        json.each do |override_json|
          override = [@a1, @b1, @a2].find { |o| o.id == override_json['id'] }
          validate_override_json(override, override_json)
        end
      end

      it "accepts a map that looks like an array" do
        json = call_batch_retrieve({
          "0" => { assignment_id: @a.id, id: @a1.id },
          "1" => { assignment_id: @b.id, id: @b1.id }
        })
        expect(matched_ids(json)).to eq [@a1.id, @b1.id]
      end

      it "should apply visibility on overrides" do
        student_in_section @b1.set
        json = call_batch_retrieve([
          args_for(@a, @a1),
          args_for(@b, @b1)
        ])
        expect(matched_ids(json)).to match_array [nil, @b1.id]
      end

      it "should omit non-existent overrides" do
        @a1.destroy!
        json = call_batch_retrieve([
          args_for(@a, @a1),
          args_for(@a, @a2)
        ])
        expect(matched_ids(json)).to eq [nil, @a2.id]
      end

      it "should omit non-existent assignments" do
        @a.destroy!
        json = call_batch_retrieve([
          args_for(@a, @a1),
          args_for(@b, @b1),
          args_for(@b, @b2)
        ])
        expect(matched_ids(json)).to eq [nil, @b1.id, @b2.id]
      end
    end

    describe "batch_update" do
      def call_batch_update(overrides_array, opts = {})
        api_call(:put, "/api/v1/courses/#{@course.id}/assignments/overrides.json", {
                    controller: 'assignment_overrides', action: 'batch_update', format: 'json',
                    course_id: @course.id.to_s
                  },
                  {assignment_overrides: overrides_array},
                  {}, # headers
                  opts)
      end

      it "should fail unless override ids are specified" do
        json = call_batch_update([
          args_for(@a, nil, title: 'foo')
        ], expected_status: 400)
        expect(json['errors'][0]).to eq ["must specify an override id"]
      end


      it "should fail for user without permissions" do
        student_in_course
        call_batch_update({ @a.id => [{ id: @a1.id, due_at: Time.zone.now.to_s }]}, expected_status: 401)
      end

      it "should fail if ids not present" do
        json = call_batch_update([
          args_for(@a, nil, title: 'foo'),
          { title: 'bar', id: @b2.id, due_at: 'foo' }
        ], expected_status: 400)
        expect(json['errors'][0]).to eq ['must specify an override id']
        expect(json['errors'][1]).to eq ['must specify an assignment id']
      end

      it "should fail if attributes are invalid" do
        json = call_batch_update([
          args_for(@a, @a1, due_at: 'foo')
        ], expected_status: 400)
        expect(json['errors'][0]).to eq ['invalid due_at "foo"']
      end

      it "should fail if records not found" do
        @a.destroy!
        @b1.destroy!
        json = call_batch_update([
          args_for(@a, @a1, title: 'foo'),
          args_for(@b, @b1, title: 'bar')
        ], expected_status: 400)
        expect(json['errors'][0]).to eq ['assignment not found']
        expect(json['errors'][1]).to eq ['override not found']
      end

      it "should fail and not update if updates are invalid" do
        old_title = @a1.title
        new_title = "a" * (2 * ActiveRecord::Base.maximum_string_length)
        old_due_at = @b1.due_at

        json = call_batch_update([
          args_for(@b, @b1, due_at: Time.zone.now.to_s),
          args_for(@a, @a1, title: new_title)
        ], expected_status: 400)
        expect(json['errors'][0]).to be nil
        expect(json['errors'][1].to_s).to match(/too_long/)
        expect(@a1.reload.title).to eq old_title
        expect(@b1.reload.due_at).to eq old_due_at
      end

      it "should succeed if formatted correctly" do
        new_date = Time.zone.now.tomorrow
        json = call_batch_update([
          args_for(@a, @a1, due_at: new_date.to_s),
          args_for(@b, @b1, unlock_at: new_date.to_s),
          args_for(@a, @a2, lock_at: new_date.to_s)
        ])
        expect(@a1.reload.due_at.to_date).to eq new_date.to_date
        expect(@b1.reload.unlock_at.to_date).to eq new_date.to_date
        expect(@a2.reload.lock_at.to_date).to eq new_date.to_date
        validate_override_json(@a1, json[0])
        validate_override_json(@b1, json[1])
        validate_override_json(@a2, json[2])
      end
    end

    describe "batch_create" do
      def call_batch_create(overrides_array, opts = {})
        api_call(:post, "/api/v1/courses/#{@course.id}/assignments/overrides.json", {
                    controller: 'assignment_overrides', action: 'batch_create', format: 'json',
                    course_id: @course.id.to_s
                  },
                  {assignment_overrides: overrides_array},
                  {}, # headers
                  opts)
      end

      it "should fail if override ids are specified" do
        json = call_batch_create([
          args_for(@a, @a1, title: 'foo')
        ], expected_status: 400)
        expect(json['errors'][0]).to eq ['may not specify an override id']
      end

      it "should succeed if formatted correctly" do
        section = @course.course_sections.create!
        student = student_in_section(section)
        date = Time.zone.now.tomorrow
        @user = @teacher

        json = call_batch_create([
          args_for(@a, nil, course_section_id: section.id, due_at: date),
          args_for(@b, nil, course_section_id: section.id, unlock_at: date),
          args_for(@a, nil, student_ids: [student.id], title: 'foo')
        ])
        override1 = @a.assignment_overrides.find(json[0]['id'])
        override2 = @b.assignment_overrides.find(json[1]['id'])
        override3 = @a.assignment_overrides.find(json[2]['id'])
        validate_override_json(override1, json[0])
        validate_override_json(override2, json[1])
        validate_override_json(override3, json[2])
      end
    end
  end
end
