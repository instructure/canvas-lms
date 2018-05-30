#
# Copyright (C) 2011 - 2014 Instructure, Inc.
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
require File.expand_path(File.dirname(__FILE__) + '/../../sharding_spec_helper')
require File.expand_path(File.dirname(__FILE__) + '/../file_uploads_spec_helper')

class TestCourseApi
  include Api::V1::Course
  def feeds_calendar_url(feed_code); "feed_calendar_url(#{feed_code.inspect})"; end

  def course_url(course, opts = {}); return "course_url(Course.find(#{course.id}), :host => #{HostUrl.context_host(@course1)})"; end

  def api_user_content(syllabus, course); return "api_user_content(#{syllabus}, #{course.id})"; end

  attr_accessor :master_courses
  def master_courses?
    master_courses
  end
end

describe Api::V1::Course do
  describe '#course_json' do
    before :once do
      @test_api = TestCourseApi.new
      course_with_teacher(:active_all => true, :user => user_with_pseudonym)
      @me = @user
      @course1 = @course
      course_with_student(:user => @user, :active_all => true)
      @course2 = @course
      @course2.update_attribute(:sis_source_id, 'TEST-SIS-ONE.2011')
      @user.pseudonym.update_attribute(:sis_user_id, 'user1')
    end

    let(:teacher_enrollment) { @course1.teacher_enrollments.first }

    it 'should support optionally providing the url' do
      expect(@test_api.course_json(@course1, @me, {}, ['html_url'], [])).to encompass({
        "html_url" => "course_url(Course.find(#{@course1.id}), :host => #{HostUrl.context_host(@course1)})"
      })
      expect(@test_api.course_json(@course1, @me, {}, [], [])).to_not include 'html_url'
    end

    it 'should only include needs_grading_count if requested' do
      expect(@test_api.course_json(@course1, @me, {}, [], [teacher_enrollment])).to_not include 'needs_grading_count'
    end

    it 'should only include is_favorite if requested' do
      expect(@test_api.course_json(@course1, @me, {}, ['favorites'], [teacher_enrollment])).to include 'is_favorite'
    end

    it 'should honor needs_grading_count for teachers' do
      expect(@test_api.course_json(@course1, @me, {}, ['needs_grading_count'], [teacher_enrollment])).to include "needs_grading_count"
    end

    it 'should return storage_quota_used_mb if requested' do
      expect(@test_api.course_json(@course1, @me, {}, ['storage_quota_used_mb'], [teacher_enrollment])).to include "storage_quota_used_mb"
    end

    it 'should not honor needs_grading_count for designers' do
      @designer_enrollment = @course1.enroll_designer(@me)
      @designer_enrollment.accept!
      expect(@test_api.course_json(@course1, @me, {}, ['needs_grading_count'], [@designer_enrollment])).to_not include "needs_grading_count"
    end

    it 'should include apply_assignment_group_weights' do
      expect(@test_api.course_json(@course1, @me, {}, [], [])).to include "apply_assignment_group_weights"
    end

    it "should not show details if user is restricted from access by course dates" do
      @student = student_in_course(:course => @course2).user
      @course2.start_at = 3.weeks.ago
      @course2.conclude_at = 2.weeks.ago
      @course2.restrict_enrollments_to_course_dates = true
      @course2.restrict_student_past_view = true
      @course2.save!

      json = @test_api.course_json(@course2, @student, {}, ['access_restricted_by_date'], @student.student_enrollments)
      expect(json).to eq({"id" => @course2.id, "access_restricted_by_date" => true})
    end

    it "should include course progress" do
      mod = @course2.context_modules.create!(:name => "some module", :require_sequential_progress => true)
      assignment = @course2.assignments.create!(:title => "some assignment")
      tag = mod.add_item({:id => assignment.id, :type => 'assignment'})
      mod.completion_requirements = {tag.id => {:type => 'must_submit'}}
      mod.require_sequential_progress = true
      mod.publish
      mod.save!

      stubbed_url = "redirect_url"
      allow_any_instance_of(CourseProgress).to receive(:course_context_modules_item_redirect_url).
        with(include(course_id: @course2.id, id: tag.id)).
          and_return(stubbed_url)

      json = @test_api.course_json(@course2, @me, {}, ['course_progress'], [])
      expect(json).to include('course_progress')
      expect(json['course_progress']).to eq({
        'requirement_count' => 1,
        'requirement_completed_count' => 0,
        'next_requirement_url' => stubbed_url,
        'completed_at' => nil
      })
    end

    it "should include course progress error unless course is module based" do
      json = @test_api.course_json(@course2, @me, {}, ['course_progress'], [])
      expect(json).to include('course_progress')
      expect(json['course_progress']).to eq({
          'error' => {
              'message' => 'no progress available because this course is not module based (has modules and module completion requirements) or the user is not enrolled as a student in this course'
          }
      })
    end

    it "should include the total amount of invited and active students if 'total_students' flag is given" do
      json = @test_api.course_json(@course2, @me, {}, ['total_students'], [])

      expect(json).to include('total_students')
      expect(json['total_students']).to eq 1
    end

    it "counts students with multiple enrollments once in 'total students'" do
      section = @course2.course_sections.create! name: 'other section'
      @course2.enroll_student @student, section: section, allow_multiple_enrollments: true
      expect(@course2.student_enrollments.count).to eq 2

      json = @test_api.course_json(@course2, @me, {}, ['total_students'], [])
      expect(json).to include('total_students')
      expect(json['total_students']).to eq 1
    end

    it "excludes the student view student in 'total students'" do
      @course2.student_view_student
      json = @test_api.course_json(@course2, @me, {}, ['total_students'], [])

      expect(json).to include('total_students')
      expect(json['total_students']).to eq 1
    end

    it "includes the course nickname if one is set" do
      @me.course_nicknames[@course1.id] = 'nickname'
      json = @test_api.course_json(@course1, @me, {}, [], [])
      expect(json['name']).to eq 'nickname'
      expect(json['original_name']).to eq @course1.name
    end

    describe "total_scores" do
      before(:each) do
        @enrollment.scores.create!(
          current_score: 95.0, final_score: 85.0,
          unposted_current_score: 94.0, unposted_final_score: 84.0
        )
        @course.grading_standard_enabled = true
        @course.save!
      end

      let(:json) { @test_api.course_json(@course1, @me, {}, ['total_scores'], [@enrollment]) }

      let(:expected_result_without_unposted) do
        {
          "type" => "student",
          "role" => student_role.name,
          "role_id" => student_role.id,
          "user_id" => @me.id,
          "enrollment_state" => "active",
          "computed_current_score" => 95.0,
          "computed_final_score" => 85.0,
          "computed_current_grade" => "A",
          "computed_final_grade" => "B"
        }
      end

      let(:expected_result_with_unposted) do
        expected_result_without_unposted.merge({
          "unposted_current_score" => 94.0,
          "unposted_final_score" => 84.0,
          "unposted_current_grade" => "A",
          "unposted_final_grade" => "B"
        })
      end

      it "should include computed scores" do
        expect(json['enrollments']).to eq [expected_result_with_unposted]
      end

      it "should include unposted scores if user has :manage_grades" do
        @course.root_account.role_overrides.create!(permission: 'view_all_grades', role: teacher_role, enabled: false)
        @course.root_account.role_overrides.create!(permission: 'manage_grades', role: teacher_role, enabled: true)

        expect(json['enrollments']).to eq [expected_result_with_unposted]
      end

      it "should include unposted scores if user has :view_all_grades" do
        @course.root_account.role_overrides.create!(permission: 'view_all_grades', role: teacher_role, enabled: true)
        @course.root_account.role_overrides.create!(permission: 'manage_grades', role: teacher_role, enabled: false)

        expect(json['enrollments']).to eq [expected_result_with_unposted]
      end

      it "should not include unposted scores if user does not have permission" do
        @course.root_account.role_overrides.create!(permission: 'view_all_grades', role: teacher_role, enabled: false)
        @course.root_account.role_overrides.create!(permission: 'manage_grades', role: teacher_role, enabled: false)

        expect(json['enrollments']).to eq [expected_result_without_unposted]
      end
    end

    describe "current_grading_period_scores" do
      before(:each) do
        @course.grading_standard_enabled = true
        create_grading_periods_for(@course, grading_periods: [:current, :future])

        current_assignment = @course.assignments.create!(
          title: "Current",
          due_at: 2.days.ago,
          points_possible: 10
        )
        current_assignment.grade_student(@student, grader: @teacher, score: 2)
        unposted_current_assignment = @course.assignments.create!(
          title: "Current",
          due_at: 2.days.ago,
          points_possible: 10,
          muted: true
        )
        unposted_current_assignment.grade_student(@student, grader: @teacher, score: 9)

        future_assignment = @course.assignments.create!(
          title: "Future",
          due_at: 4.months.from_now,
          points_possible: 10,
        )
        future_assignment.grade_student(@student, grader: @teacher, score: 7)

        @course.save!
        @me = @teacher
      end

      let(:json) do
        @test_api.course_json(@course, @me, {}, ['total_scores', 'current_grading_period_scores'], [@enrollment])
      end

      let(:student_enrollment) { json['enrollments'].first }

      let(:expected_fields_without_unposted) do
        {
          "type" => "student",
          "role" => student_role.name,
          "role_id" => student_role.id,
          "user_id" => @student.id,
          "enrollment_state" => "active",
          "computed_current_score" => 45.0,
          "computed_final_score" => 30.0,
          "computed_current_grade" => "F",
          "computed_final_grade" => "F",
          "current_period_computed_current_score" => 20.0,
          "current_period_computed_final_score" => 10.0,
          "current_period_computed_current_grade" => "F",
          "current_period_computed_final_grade" => "F"
        }
      end

      let(:unposted_fields) do
        {
          "unposted_current_score" => 60.0,
          "unposted_final_score" => 60.0,
          "unposted_current_grade" => "F",
          "unposted_final_grade" => "F",
          "current_period_unposted_current_score" => 55.0,
          "current_period_unposted_final_score" => 55.0,
          "current_period_unposted_current_grade" => "F",
          "current_period_unposted_final_grade" => "F"
        }
      end

      let(:expected_fields_with_unposted) { expected_fields_without_unposted.merge(unposted_fields) }

      it "should always include computed scores" do
        expect(student_enrollment).to include(expected_fields_without_unposted)
      end

      it "should include unposted scores if user has :manage_grades" do
        @course.root_account.role_overrides.create!(permission: 'view_all_grades', role: teacher_role, enabled: false)
        @course.root_account.role_overrides.create!(permission: 'manage_grades', role: teacher_role, enabled: true)

        expect(student_enrollment).to include(expected_fields_with_unposted)
      end

      it "should include unposted scores if user has :view_all_grades" do
        @course.root_account.role_overrides.create!(permission: 'view_all_grades', role: teacher_role, enabled: true)
        @course.root_account.role_overrides.create!(permission: 'manage_grades', role: teacher_role, enabled: false)

        expect(student_enrollment).to include(expected_fields_with_unposted)
      end

      it "should not include unposted scores if user does not have permission" do
        @me = @student

        enrollment = student_enrollment
        expect(enrollment).to include(expected_fields_without_unposted)
        expect(enrollment).not_to include(unposted_fields)
      end
    end

    context "master course stuff" do
      before do
        @test_api.master_courses = true
      end

      let(:json) { @test_api.course_json(@course1, @me, {}, [], []) }

      it "should return blueprint status" do
        expect(json["blueprint"]).to eq false
      end

      it "should return blueprint restrictions" do
        template = MasterCourses::MasterTemplate.set_as_master_course(@course1)
        template.update_attribute(:default_restrictions, {:content => true})
        expect(json["blueprint"]).to eq true
        expect(json["blueprint_restrictions"]["content"]).to eq true
      end

      it "should return blueprint restrictions by type" do
        template = MasterCourses::MasterTemplate.set_as_master_course(@course1)
        template.update_attributes(:use_default_restrictions_by_type => true,
          :default_restrictions_by_type =>
            {"Assignment" => {:points => true},
            "Quizzes::Quiz" => {:content => true}})
        expect(json["blueprint"]).to eq true
        expect(json["blueprint_restrictions_by_object_type"]["assignment"]["points"]).to eq true
        expect(json["blueprint_restrictions_by_object_type"]["quiz"]["content"]).to eq true
      end
    end
  end

  describe '#add_helper_dependant_entries' do
    let(:hash) { Hash.new }
    let(:course) { double( :feed_code => 573, :id => 42, :syllabus_body => 'syllabus text' ).as_null_object }
    let(:course_json) { double.as_null_object() }
    let(:api) { TestCourseApi.new }

    let(:result) do
      result_hash = api.add_helper_dependant_entries(hash, course, course_json)
      class << result_hash
        def method_missing(method_name, *args)
          self[method_name.to_s]
        end
      end
      result_hash
    end

    subject { result }

    it { is_expected.to eq hash }

    describe '#calendar' do
      subject { super().calendar }
      it { is_expected.to eq({ 'ics' => "feed_calendar_url(573).ics" }) }
    end

    describe 'when the include options are all set off' do
      let(:course_json){ double( :include_syllabus => false, :include_url => false ) }

      describe '#syllabus_body' do
        subject { super().syllabus_body }
        it { is_expected.to be_nil }
      end

      describe '#html_url' do
        subject { super().html_url }
        it { is_expected.to be_nil }
      end
    end

    describe 'when everything is included' do
      let(:course_json){ double( :include_syllabus => true, :include_url => true ) }

      describe '#syllabus_body' do
        subject { super().syllabus_body }
        it { is_expected.to eq "api_user_content(syllabus text, 42)" }
      end

      describe '#html_url' do
        subject { super().html_url }
        it { is_expected.to eq "course_url(Course.find(42), :host => localhost)" }
      end
    end
  end
end

describe CoursesController, type: :request do
  let(:user_api_fields) { %w(id name sortable_name short_name) }

  before :once do
    course_with_teacher(:active_all => true, :user => user_with_pseudonym(:name => 'UWP'))
    @me = @user
    @course1 = @course
    course_with_student(:user => @user, :active_all => true)
    @course2 = @course
    @course2.update_attribute(:sis_source_id, 'TEST-SIS-ONE.2011')
    @course2.update_attributes(:default_view => 'assignments')
    @user.pseudonym.update_attribute(:sis_user_id, 'user1')
  end

  before :each do
    @course_dates_stubbed = true
    allow_any_instance_of(Course).to receive(:start_at).and_wrap_original { |original| original.call unless @course_dates_stubbed }
    allow_any_instance_of(Course).to receive(:end_at).and_wrap_original { |original| original.call unless @course_dates_stubbed }
  end

  describe "observer viewing a course" do
    before :once do
      @observer_enrollment = course_with_observer(active_all: true)
      @observer = @user
      @observer_course = @course
      @observed_student = create_users(1, return_type: :record).first
      @student_enrollment =
        @observer_course.enroll_student(@observed_student,
                                        :enrollment_state => 'active')
      @assigned_observer_enrollment =
        @observer_course.enroll_user(@observer, "ObserverEnrollment",
                                     :associated_user_id => @observed_student.id)
      @assigned_observer_enrollment.accept
    end

    it "should include observed users in the enrollments in a specific course if requested" do
      json = api_call_as_user(@observer, :get,
                              "/api/v1/courses/#{@observer_course.id}?include[]=observed_users",
                              { :controller => 'courses', :action => 'show',
                                :id => @observer_course.to_param,
                                :format => 'json',
                                :include => [ "observed_users" ] })

      expect(json['enrollments']).to match_array [{
         "type" => "observer",
         "role" => @assigned_observer_enrollment.role.name,
         "role_id" => @assigned_observer_enrollment.role.id,
         "user_id" => @assigned_observer_enrollment.user_id,
         "enrollment_state" => "active",
         "associated_user_id" => @observed_student.id
       }, {
         "type" => "observer",
         "role" => @observer_enrollment.role.name,
         "role_id" => @observer_enrollment.role.id,
         "user_id" => @observer_enrollment.user_id,
         "enrollment_state" => "active"
       }, {
         "type" => "student",
         "role" => @student_enrollment.role.name,
         "role_id" => @student_enrollment.role.id,
         "user_id" => @student_enrollment.user_id,
         "enrollment_state" => "active"
       }]
    end

    it "should include observed users in the enrollments if requested" do
      json = api_call_as_user(@observer, :get,
                              "/api/v1/courses?include[]=observed_users",
                              { :controller => 'courses', :action => 'index',
                                :id => @observer_course.to_param,
                                :format => 'json',
                                :include => [ "observed_users" ] })

      expect(json[0]['enrollments']).to match_array [{
         "type" => "observer",
         "role" => @assigned_observer_enrollment.role.name,
         "role_id" => @assigned_observer_enrollment.role.id,
         "user_id" => @assigned_observer_enrollment.user_id,
         "enrollment_state" => "active",
         "associated_user_id" => @observed_student.id
       }, {
         "type" => "observer",
         "role" => @observer_enrollment.role.name,
         "role_id" => @observer_enrollment.role.id,
         "user_id" => @observer_enrollment.user_id,
         "enrollment_state" => "active"
       }, {
         "type" => "student",
         "role" => @student_enrollment.role.name,
         "role_id" => @student_enrollment.role.id,
         "user_id" => @student_enrollment.user_id,
         "enrollment_state" => "active"
       }]
    end

    it "should not include observed users in the enrollments if not requested" do
      json = api_call_as_user(@observer, :get,
                              "/api/v1/courses",
                              { :controller => 'courses', :action => 'index',
                                :id => @observer_course.to_param,
                                :format => 'json' })

      expect(json[0]['enrollments']).to match_array [{
         "type" => "observer",
         "role" => @assigned_observer_enrollment.role.name,
         "role_id" => @assigned_observer_enrollment.role.id,
         "user_id" => @assigned_observer_enrollment.user_id,
         "enrollment_state" => "active",
         "associated_user_id" => @observed_student.id
       }, {
         "type" => "observer",
         "role" => @observer_enrollment.role.name,
         "role_id" => @observer_enrollment.role.id,
         "user_id" => @observer_enrollment.user_id,
         "enrollment_state" => "active"
       }]
    end
  end

  describe "permissions for courses" do
    describe "undelete_courses" do
      before do
        @path = "/api/v1/accounts/#{@course.account.id}/courses"
        @params = { :controller => 'courses', :action => 'batch_update', :format => 'json', :account_id => Account.default.to_param }
      end

      context "given I have permission" do
        before do
          account_admin_user
        end

        it "returns 200 success" do
          api_call(:put, @path, @params, { :event => 'undelete', :course_ids => [@course.id] })
          expect(response).to be_success
        end
      end

      context "given I don't have permission" do
        before do
          user_model
        end

        it "returns 401 unauthorized access" do
          api_call(:put, @path, @params, { :event => 'offer', :course_ids => [@course.id] },
                   {}, {:expected_status => 401})
        end
      end
    end
  end

  it "should return course list" do
    json = api_call(:get, "/api/v1/courses.json",
            { :controller => 'courses', :action => 'index', :format => 'json' })

    expect(json.length).to eq 2

    courses = json.select { |c| [@course1.id, @course2.id].include?(c['id']) }
    expect(courses.length).to eq 2
  end

  it "returns course list ordered by name (including nicknames)" do
    c1 = course_with_student(course_name: 'def', active_all: true).course
    c2 = course_with_student(user: @student, course_name: 'abc', active_all: true).course
    c3 = course_with_student(user: @student, course_name: 'jkl', active_all: true).course
    c4 = course_with_student(user: @student, course_name: 'xyz', active_all: true).course
    @student.course_nicknames[c4.id] = 'ghi'; @student.save!
    json = api_call(:get, "/api/v1/courses.json", controller: 'courses', action: 'index', format: 'json')
    expect(json.map { |course| course['name'] }).to eq %w(abc def ghi jkl)
  end

  it "should exclude master courses if requested" do
    c1 = course_with_teacher(active_all: true).course
    MasterCourses::MasterTemplate.set_as_master_course(c1)
    c2 = course_with_teacher(user: @teacher, active_all: true).course

    json = api_call(:get, "/api/v1/courses.json", controller: 'courses', action: 'index', format: 'json')
    expect(json.map { |course| course['id'] }).to match_array([c1.id, c2.id])

    json = api_call(:get, "/api/v1/courses.json?exclude_blueprint_courses=1",
      controller: 'courses', action: 'index', format: 'json', exclude_blueprint_courses: '1')
    expect(json.map { |course| course['id'] }).to eq([c2.id])
  end

  describe "user index" do
    specs_require_sharding
    before :once do
      account_admin_user
    end
    it "should return a course list for an observed students" do
      parent = User.create
      parent.as_observer_observation_links.create! do |uo|
        uo.user_id = @me.id
      end
      json = api_call_as_user(parent,:get,"/api/v1/users/#{@me.id}/courses",
                              { :user_id => @me.id, :controller => 'courses', :action => 'user_index',
                                :format => 'json' })
      course_ids= json.select{ |c| c["id"]}
      expect(course_ids.length).to eq 2
    end

    it "should fail if trying to view courses for student that is not observee" do
      # test to make sure it doesn't crash if user has not observees
      parent = User.create
      expect(parent.as_observer_observation_links).to eq []

      api_call_as_user(parent,:get,"/api/v1/users/#{@me.id}/courses",
                      { :user_id => @me.id, :controller => 'courses', :action => 'user_index',
                        :format => 'json' }, {}, {}, {:expected_status => 401})
    end

    it "should return courses from observed user's shard if different than observer" do
      parent = nil
      @shard2.activate do
        a = Account.create
        parent = user_with_pseudonym(name: 'Zombo', username: 'nobody2@example.com', account: a)
        parent.as_observer_observation_links.create! do |uo|
          uo.user_id = @me.id
        end
        parent.save!
      end
      expect(@me.account.id).not_to eq parent.account.id
      json = api_call_as_user(parent,:get,"/api/v1/users/#{@me.id}/courses",
                              { :user_id => @me.id, :controller => 'courses', :action => 'user_index',
                                :format => 'json' })
      course_ids = json.select{ |c| c["id"]}
      expect(course_ids.length).to eq 2
    end

    it "should return courses for a user if requestor is administrator" do
      json = api_call(:get, "/api/v1/users/#{@me.id}/courses",
                     {:user_id => @me.id, :controller => 'courses', :action => 'user_index',
                      :format => 'json' })
      course_ids = json.select{ |c| c["id"]}
      expect(course_ids.length).to eq 2
    end

    it "should return courses for self" do
      json = api_call_as_user(@me, :get, "/api/v1/users/self/courses",
                              { :user_id => "self", :controller => 'courses', :action => 'user_index',
                                  :format => 'json' })
      course_ids = json.select{ |c| c["id"]}
      expect(course_ids.length).to eq 2
    end

    it "should check include permissions against the caller" do
      json = api_call_as_user(@admin, :get, "/api/v1/users/#{@student.id}/courses",
                              { :user_id => @student.to_param, :controller => 'courses', :action => 'user_index',
                                :format => 'json' })
      entry = json.detect { |course| course['id'] == @course.id }
      expect(entry['sis_course_id']).to eq 'TEST-SIS-ONE.2011'
    end

    it "should return course progress for the subject" do
      mod = @course.context_modules.create!(:name => "some module")
      assignment = @course.assignments.create!(:title => "some assignment", :submission_types => ['online_text_entry'])
      tag = mod.add_item({:id => assignment.id, :type => 'assignment'})
      mod.completion_requirements = {tag.id => {:type => 'must_submit'}}
      mod.publish
      mod.save!
      assignment.submit_homework(@student, :submission_type => "online_text_entry", :body => "herp")
      json = api_call_as_user(@admin, :get, "/api/v1/users/#{@student.id}/courses?include[]=course_progress",
                              { :user_id => @student.to_param, :controller => 'courses', :action => 'user_index',
                                :format => 'json', :include => ['course_progress'] })
      entry = json.detect { |course| course['id'] == @course.id }
      expect(entry['course_progress']['requirement_completed_count']).to eq 1
    end

    it "should use the caller's course nickname, not the subject's" do
      @student.course_nicknames[@course.id] = 'terrible'; @student.save!
      @admin.course_nicknames[@course.id] = 'meh'; @admin.save!
      json = api_call_as_user(@admin, :get, "/api/v1/users/#{@student.id}/courses",
                              { :user_id => @student.to_param, :controller => 'courses', :action => 'user_index',
                                :format => 'json' })
      entry = json.detect { |course| course['id'] == @course.id }
      expect(entry['name']).to eq 'meh'
    end
  end

  it 'should paginate the course list' do
    json = api_call(:get, "/api/v1/courses.json?per_page=1",
            { :controller => 'courses', :action => 'index', :format => 'json', :per_page => '1' })
    expect(json.length).to eq 1
    json += api_call(:get, "/api/v1/courses.json?per_page=1&page=2",
            { :controller => 'courses', :action => 'index', :format => 'json', :per_page => '1', :page => '2' })
    expect(json.length).to eq 2
  end

  it 'should not include permissions' do
    # When its asked to return permissions make sure they are not returned for a list of courses
    json = api_call(:get, "/api/v1/courses.json?include[]=permissions",
            { :controller => 'courses', :action => 'index', :format => 'json', :include => [ "permissions" ] })

    expect(json.length).to eq 2

    courses = json.select { |c| c.key?("permissions") }
    expect(courses.length).to eq 0
  end

  describe "course creation" do
    context "an account admin" do
      before :once do
        @account = Account.default
        account_admin_user
        @resource_path = "/api/v1/accounts/#{@account.id}/courses"
        @resource_params = { :controller => 'courses', :action => 'create', :format => 'json', :account_id => @account.id.to_s }
      end

      before do
        @course_dates_stubbed = false
      end

      it "should create a new course" do
        term = @account.enrollment_terms.create
        post_params = {
          'account_id' => @account.id,
          'offer'      => true,
          'course'     => {
            'name'                                 => 'Test Course',
            'course_code'                          => 'Test Course',
            'start_at'                             => '2011-01-01T00:00:00-0700',
            'end_at'                               => '2011-05-01T00:00:00-0700',
            'is_public'                            => true,
            'is_public_to_auth_users'              => false,
            'public_syllabus'                      => true,
            'allow_wiki_comments'                  => true,
            'allow_student_forum_attachments'      => true,
            'open_enrollment'                      => true,
            'term_id'                              => term.id,
            'self_enrollment'                      => true,
            'restrict_enrollments_to_course_dates' => true,
            'hide_final_grades'                    => true,
            'apply_assignment_group_weights'       => true,
            'license'                              => 'Creative Commons',
            'sis_course_id'                        => '12345',
            'public_description'                   => 'Nature is lethal but it doesn\'t hold a candle to man.',
            'course_format'                        => 'online',
            'time_zone'                            => 'America/Juneau'
          }
        }
        course_response = post_params['course'].merge({
          'account_id' => @account.id,
          'root_account_id' => @account.id,
          'enrollment_term_id' => term.id,
          'public_syllabus_to_auth' => false,
          'grading_standard_id' => nil,
          'integration_id' => nil,
          'start_at' => '2011-01-01T07:00:00Z',
          'end_at' => '2011-05-01T07:00:00Z',
          'sis_import_id' => nil,
          'workflow_state' => 'available',
          'default_view' => 'modules',
          'storage_quota_mb' => @account.default_storage_quota_mb
        })
        expect(Auditors::Course).to receive(:record_created).once
        json = api_call(:post, @resource_path, @resource_params, post_params)
        new_course = Course.find(json['id'])
        [:name, :course_code, :start_at, :end_at,
        :is_public, :public_syllabus, :allow_wiki_comments,
        :open_enrollment, :self_enrollment, :license, :sis_course_id,
        :allow_student_forum_attachments, :public_description,
        :restrict_enrollments_to_course_dates].each do |attr|
          expect(new_course.send(attr)).to eq ([:start_at, :end_at].include?(attr) ?
            Time.parse(post_params['course'][attr.to_s]) :
            post_params['course'][attr.to_s])
        end
        expect(new_course.account_id).to eql @account.id
        expect(new_course.enrollment_term_id).to eql term.id
        expect(new_course.workflow_state).to eql 'available'
        expect(new_course.time_zone.tzinfo.name).to eql 'America/Juneau'
        course_response.merge!(
          'id' => new_course.id,
          'calendar' => { 'ics' => "http://www.example.com/feeds/calendars/course_#{new_course.uuid}.ics" },
          'uuid' => new_course.uuid
        )
        course_response.delete 'term_id' #not included in the response
        expect(json).to eql course_response
      end

      it "should allow enrollment_term_id on course create" do
        term = @account.enrollment_terms.create
        post_params = {
          'account_id' => @account.id,
          'offer'      => true,
          'course'     => {
            'name'                                 => 'Test Course',
            'course_code'                          => 'Test Course',
            'start_at'                             => '2011-01-01T00:00:00-0700',
            'end_at'                               => '2011-05-01T00:00:00-0700',
            'is_public'                            => true,
            'is_public_to_auth_users'              => false,
            'public_syllabus'                      => true,
            'allow_wiki_comments'                  => true,
            'allow_student_forum_attachments'      => true,
            'open_enrollment'                      => true,
            'enrollment_term_id'                   => term.id,
            'self_enrollment'                      => true,
            'restrict_enrollments_to_course_dates' => true,
            'hide_final_grades'                    => true,
            'apply_assignment_group_weights'       => true,
            'license'                              => 'Creative Commons',
            'sis_course_id'                        => '12345',
            'sis_import_id'                        => nil,
            'public_description'                   => 'Nature is lethal but it doesn\'t hold a candle to man.',
            'time_zone'                            => 'America/Chicago'
          }
        }
        course_response = post_params['course'].merge({
          'account_id' => @account.id,
          'root_account_id' => @account.id,
          'enrollment_term_id' => term.id,
          'public_syllabus_to_auth' => false,
          'grading_standard_id' => nil,
          'integration_id' => nil,
          'start_at' => '2011-01-01T07:00:00Z',
          'end_at' => '2011-05-01T07:00:00Z',
          'workflow_state' => 'available',
          'default_view' => 'modules',
          'storage_quota_mb' => @account.default_storage_quota_mb
        })
        json = api_call(:post, @resource_path, @resource_params, post_params)
        new_course = Course.find(json['id'])
        expect(new_course.enrollment_term_id).to eql term.id
        course_response.merge!(
          'id' => new_course.id,
          'calendar' => { 'ics' => "http://www.example.com/feeds/calendars/course_#{new_course.uuid}.ics" },
          'uuid' => new_course.uuid
        )
        expect(json).to eql course_response
      end

      it 'should process html content in syllabus_body on create' do
        should_process_incoming_user_content(@course) do |content|
          json = api_call(:post, @resource_path,
            @resource_params,
            { :account_id => @account.id, :offer => true, :course => { :name => 'Test Course', :syllabus_body => content } }
          )
          new_course = Course.find(json['id'])
          new_course.syllabus_body
        end
      end

      it "should offer a course if passed the 'offer' parameter" do
        expect(Auditors::Course).to receive(:record_published).once
        json = api_call(:post, @resource_path,
          @resource_params,
          { :account_id => @account.id, :offer => true, :course => { :name => 'Test Course' } }
        )
        new_course = Course.find(json['id'])
        expect(new_course).to be_available
      end

      it "doesn't offer a course if passed a false 'offer' parameter" do
        json = api_call(:post, @resource_path,
                        @resource_params,
                        { :account_id => @account.id, :offer => false, :course => { :name => 'Test Course' } }
        )
        new_course = Course.find(json['id'])
        expect(new_course).not_to be_available
      end

      it "should allow setting sis_course_id without offering the course" do
        expect(Auditors::Course).to receive(:record_created).once
        expect(Auditors::Course).to receive(:record_published).never
        json = api_call(:post, @resource_path,
          @resource_params,
          { :account_id => @account.id, :course => { :name => 'Test Course', :sis_course_id => '9999' } }
        )
        new_course = Course.find(json['id'])
        expect(new_course.sis_source_id).to eq '9999'
      end

      context "sis reactivation" do
        it "should allow reactivating deleting courses using sis_course_id" do
          old_course = @account.courses.build(:name => "Test")
          old_course.sis_source_id = '9999'
          old_course.save!
          old_course.destroy

          json = api_call(:post, @resource_path,
            @resource_params,
            { :account_id => @account.id, :course => { :name => 'Test Course', :sis_course_id => '9999' },
              :enable_sis_reactivation => '1' }
          )
          expect(old_course).to eq Course.find(json['id'])
          old_course.reload
          expect(old_course).to be_claimed
          expect(old_course.sis_source_id).to eq '9999'
        end

        it "should raise an error trying to reactivate an active course" do
          old_course = @account.courses.build(:name => "Test")
          old_course.sis_source_id = '9999'
          old_course.save!

          api_call(:post, @resource_path,
            @resource_params,
            { :account_id => @account.id, :course => { :name => 'Test Course', :sis_course_id => '9999' },
              :enable_sis_reactivation => '1' }, {}, {:expected_status => 400}
          )
        end

        it "should carry on if there's no course to reactivate" do
          json = api_call(:post, @resource_path,
            @resource_params,
            { :account_id => @account.id, :course => { :name => 'Test Course', :sis_course_id => '9999' },
              :enable_sis_reactivation => '1'}
          )
          new_course = Course.find(json['id'])
          expect(new_course.sis_source_id).to eq '9999'
        end
      end

      it "should set the apply_assignment_group_weights flag" do
        json = api_call(:post, @resource_path,
          @resource_params,
          { :account_id => @account.id, :course => { :name => 'Test Course', :apply_assignment_group_weights => true } }
        )
        new_course = Course.find(json['id'])
        expect(new_course.apply_group_weights?).to be_truthy
      end

      it "should set the storage quota" do
        json = api_call(:post, @resource_path,
                        @resource_params,
                        { :account_id => @account.id, :course => { :storage_quota_mb => 12345 } }
        )
        new_course = Course.find(json['id'])
        expect(new_course.storage_quota_mb).to eq 12345
      end

      context "without :manage_storage_quotas" do
        before :once do
          @role = custom_account_role 'lamer', :account => @account
          @account.role_overrides.create! :permission => 'manage_courses', :enabled => true,
                                          :role => @role
          user_factory
          @account.account_users.create!(user: @user, role: @role)
        end

        it "should ignore storage_quota" do
          json = api_call(:post, @resource_path,
                          @resource_params,
                          { :account_id => @account.id, :course => { :storage_quota => 12345 } }
          )
          new_course = Course.find(json['id'])
          expect(new_course.storage_quota).to eq @account.default_storage_quota
        end

        it "should ignore storage_quota_mb" do
          json = api_call(:post, @resource_path,
                          @resource_params,
                          { :account_id => @account.id, :course => { :storage_quota_mb => 12345 } }
          )
          new_course = Course.find(json['id'])
          expect(new_course.storage_quota_mb).to eq @account.default_storage_quota_mb
        end
      end
    end

    context "a user without permissions" do
      it "should return 401 Unauthorized if a user lacks permissions" do
        course_with_student(:active_all => true)
        account = Account.default
        raw_api_call(:post, "/api/v1/accounts/#{account.id}/courses",
          { :controller => 'courses', :action => 'create', :format => 'json', :account_id => account.id.to_s },
          {
            :account_id => account.id,
            :course => {
              :name => 'Test Course'
            }
          }
        )
        assert_status(401)
      end
    end
  end

  describe "course update" do
    before :once do
      account_admin_user
      @term = @course.root_account.enrollment_terms.create
      @path   = "/api/v1/courses/#{@course.id}"
      @params = { :controller => 'courses', :action => 'update', :format => 'json', :id => @course.to_param }
      @new_values = { 'course' => {
        'name' => 'New Name',
        'course_code' => 'NEW-001',
        'sis_course_id' => 'NEW12345',
        'integration_id' => nil,
        'start_at' => '2012-03-01T00:00:00Z',
        'end_at' => '2012-03-30T23:59:59Z',
        'license' => 'public_domain',
        'is_public' => true,
        'term_id' => @term.id,
        'public_syllabus' => true,
        'public_description' => 'new description',
        'allow_wiki_comments' => true,
        'allow_student_forum_attachments' => true,
        'open_enrollment' => true,
        'self_enrollment' => true,
        'hide_final_grades' => false,
        'apply_assignment_group_weights' => true,
        'restrict_enrollments_to_course_dates' => true,
        'default_view' => 'syllabus',
        'course_format' => 'on_campus',
        'time_zone' => 'Pacific/Honolulu'
      }, 'offer' => true }
    end

    before do
      @course_dates_stubbed = false
    end

    context "an account admin" do
      it "should be able to update a course" do
        @course.root_account.allow_self_enrollment!
        expect(Auditors::Course).to receive(:record_updated).once

        json = api_call(:put, @path, @params, @new_values)
        @course.reload

        expect(json['name']).to eql @new_values['course']['name']
        expect(json['course_code']).to eql @new_values['course']['course_code']
        expect(json['start_at']).to eql @new_values['course']['start_at']
        expect(json['end_at']).to eql @new_values['course']['end_at']
        expect(json['sis_course_id']).to eql @new_values['course']['sis_course_id']
        expect(json['default_view']).to eql @new_values['course']['default_view']
        expect(json['time_zone']).to eql @new_values['course']['time_zone']

        expect(@course.name).to eql @new_values['course']['name']
        expect(@course.course_code).to eql @new_values['course']['course_code']
        expect(@course.start_at.strftime('%Y-%m-%dT%H:%M:%SZ')).to eql @new_values['course']['start_at']
        expect(@course.end_at.strftime('%Y-%m-%dT%H:%M:%SZ')).to eql @new_values['course']['end_at']
        expect(@course.sis_course_id).to eql @new_values['course']['sis_course_id']
        expect(@course.enrollment_term_id).to eq @term.id
        expect(@course.license).to eq 'public_domain'
        expect(@course.is_public).to be_truthy
        expect(@course.public_syllabus).to be_truthy
        expect(@course.public_syllabus_to_auth).to be_falsey
        expect(@course.public_description).to eq 'new description'
        expect(@course.allow_wiki_comments).to be_truthy
        expect(@course.allow_student_forum_attachments).to be_truthy
        expect(@course.open_enrollment).to be_truthy
        expect(@course.self_enrollment).to be_truthy
        expect(@course.restrict_enrollments_to_course_dates).to be_truthy
        expect(@course.workflow_state).to eq 'available'
        expect(@course.apply_group_weights?).to eq true
        expect(@course.default_view).to eq 'syllabus'
        expect(@course.course_format).to eq 'on_campus'
        expect(@course.time_zone.tzinfo.name).to eq 'Pacific/Honolulu'
      end

      it "should not be able to update default_view to arbitrary values" do
        json = api_call(:put, @path, @params, {'course' => {'default_view' => 'somethingsilly'}}, {}, {:expected_status => 400})
        expect(json["errors"]["default_view"].first['message']).to eq "Home page is not valid"
      end

      it "should not be able to update default_view to 'wiki' without a front page" do
        expect(@course.wiki.front_page).to be_nil
        json = api_call(:put, @path, @params, {'course' => {'default_view' => 'wiki'}}, {}, {:expected_status => 400})
        expect(json["errors"]["default_view"].first['message']).to eq "A Front Page is required"
      end

      it "should be able to update default_view to 'wiki' with a front page" do
        wp = @course.wiki_pages.create!(:title => "something")
        wp.set_as_front_page!
        json = api_call(:put, @path, @params, {'course' => {'default_view' => 'wiki'}}, {}, {:expected_status => 200})
        expect(@course.reload.default_view).to eq 'wiki'
      end

      it "should not change dates that aren't given" do
        @course.update_attribute(:conclude_at, '2013-01-01T23:59:59Z')
        @new_values['course'].delete('end_at')
        api_call(:put, @path, @params, @new_values)
        @course.reload
        expect(@course.end_at.strftime('%Y-%m-%dT%T%z')).to eq '2013-01-01T23:59:59+0000'
      end

      it "should accept enrollment_term_id for updating the term" do
        @new_values['course'].delete('term_id')
        @new_values['course']['enrollment_term_id'] = @term.id
        api_call(:put, @path, @params, @new_values)
        @course.reload
        expect(@course.enrollment_term_id).to eq @term.id
      end

      it "should allow a date to be deleted" do
        @course.update_attribute(:conclude_at, Time.now)
        @new_values['course']['end_at'] = nil
        api_call(:put, @path, @params, @new_values)
        @course.reload
        expect(@course.end_at).to be_nil
      end

      it "should allow updating only the offer parameter" do
        @course.workflow_state = "claimed"
        @course.save!
        api_call(:put, @path, @params, {:offer => 1})
        @course.reload
        expect(@course.workflow_state).to eq "available"
      end

      it "should be able to update the storage_quota" do
        json = api_call(:put, @path, @params, :course => { :storage_quota_mb => 123 })
        @course.reload
        expect(@course.storage_quota_mb).to eq 123
      end

      it "should update the apply_assignment_group_weights flag from true to false" do
        @course.apply_assignment_group_weights = true
        @course.save
        json = api_call(:put, @path, @params, :course => { :apply_assignment_group_weights =>  false})
        @course.reload
        expect(@course.apply_group_weights?).to be_falsey
      end

      it "should update the grading standard with account level standard" do
        @standard = @course.account.grading_standards.create!(:title => "account standard", :standard_data => {:a => {:name => 'A', :value => '95'}, :b => {:name => 'B', :value => '80'}, :f => {:name => 'F', :value => ''}})
        json = api_call(:put, @path, @params, :course => { :grading_standard_id => @standard.id})
        @course.reload
        expect(@course.grading_standard).to eq @standard
      end

      it "should update the grading standard with course level standard" do
        @standard = @course.grading_standards.create!(:title => "course standard", :standard_data => {:a => {:name => 'A', :value => '95'}, :b => {:name => 'B', :value => '80'}, :f => {:name => 'F', :value => ''}})
        json = api_call(:put, @path, @params, :course => { :grading_standard_id => @standard.id})
        @course.reload
        expect(@course.grading_standard).to eq @standard
      end

      it "should update a sub account grading standard" do
        sub_account = @course.account.sub_accounts.create!
        c2 = sub_account.courses.create!
        @path   = "/api/v1/courses/#{c2.id}"
        @params[:id] = c2.to_param
        @standard = sub_account.grading_standards.create!(:title => "sub account standard", :standard_data => {:a => {:name => 'A', :value => '95'}, :b => {:name => 'B', :value => '80'}, :f => {:name => 'F', :value => ''}})
        json = api_call(:put, @path, @params, :course => { :grading_standard_id => @standard.id})
        c2.reload
        expect(c2.grading_standard).to eq @standard
      end

      it "should update the grading standard with account standard from sub account" do
        sub_account = @course.account.sub_accounts.create!
        c2 = sub_account.courses.create!
        @path   = "/api/v1/courses/#{c2.id}"
        @params[:id] = c2.to_param
        @standard = @course.account.grading_standards.create!(:title => "sub account standard", :standard_data => {:a => {:name => 'A', :value => '95'}, :b => {:name => 'B', :value => '80'}, :f => {:name => 'F', :value => ''}})
        json = api_call(:put, @path, @params, :course => { :grading_standard_id => @standard.id})
        c2.reload
        expect(c2.grading_standard).to eq @standard
      end

      it "should not update grading standard from sub account not on account chain" do
        sub_account = @course.account.sub_accounts.create!
        sub_account2 = @course.account.sub_accounts.create!
        c2 = sub_account.courses.create!
        @path   = "/api/v1/courses/#{c2.id}"
        @params[:id] = c2.to_param
        @standard = sub_account2.grading_standards.create!(:title => "sub account standard", :standard_data => {:a => {:name => 'A', :value => '95'}, :b => {:name => 'B', :value => '80'}, :f => {:name => 'F', :value => ''}})
        json = api_call(:put, @path, @params, :course => { :grading_standard_id => @standard.id})
        c2.reload
        expect(c2.grading_standard).to eq nil
      end

      it "should not delete existing grading standard when invalid standard provided" do
        sub_account = @course.account.sub_accounts.create!
        sub_account2 = @course.account.sub_accounts.create!
        c2 = sub_account.courses.create!
        @path   = "/api/v1/courses/#{c2.id}"
        @params[:id] = c2.to_param
        @standard = sub_account.grading_standards.create!(:title => "sub account standard", :standard_data => {:a => {:name => 'A', :value => '95'}, :b => {:name => 'B', :value => '80'}, :f => {:name => 'F', :value => ''}})
        @standard2 = sub_account2.grading_standards.create!(:title => "sub account standard 2", :standard_data => {:a => {:name => 'A', :value => '95'}, :b => {:name => 'B', :value => '80'}, :f => {:name => 'F', :value => ''}})
        c2.grading_standard = @standard
        c2.save!
        json = api_call(:put, @path, @params, :course => { :grading_standard_id => @standard2.id})
        c2.reload
        expect(c2.grading_standard).to eq @standard
      end

      it "should remove a grading standard if an empty value is passed" do
        @standard = @course.account.grading_standards.create!(:title => "account standard", :standard_data => {:a => {:name => 'A', :value => '95'}, :b => {:name => 'B', :value => '80'}, :f => {:name => 'F', :value => ''}})
        @course.grading_standard = @standard
        @course.save!
        json = api_call(:put, @path, @params, :course => { :grading_standard_id => nil})
        @course.reload
        expect(@course.grading_standard).to eq nil
      end

      it "should not remove a grading standard if no value is passed" do
        @standard = @course.account.grading_standards.create!(:title => "account standard", :standard_data => {:a => {:name => 'A', :value => '95'}, :b => {:name => 'B', :value => '80'}, :f => {:name => 'F', :value => ''}})
        @course.grading_standard = @standard
        @course.save!
        json = api_call(:put, @path, @params, :course => {})
        @course.reload
        expect(@course.grading_standard).to eq @standard
      end

      context "when an assignment is due in a closed grading period" do
        before(:once) do
          @course.update_attributes(group_weighting_scheme: "equal")
          @grading_period_group = Factories::GradingPeriodGroupHelper.new.create_for_account(@course.root_account)
          term = @course.enrollment_term
          term.grading_period_group = @grading_period_group
          term.save!
          Factories::GradingPeriodHelper.new.create_for_group(@grading_period_group, {
            start_date: 2.weeks.ago, end_date: 2.days.ago, close_date: 1.day.ago
          })
          @group = @course.assignment_groups.create!(name: 'group')
          @assignment = @course.assignments.create!({
            title: 'assignment', assignment_group: @group, due_at: 1.week.ago
          })
        end

        it "can change apply_assignment_group_weights with a term change" do
          @term.grading_period_group = @grading_period_group
          @term.save!
          raw_api_call(:put, @path, @params, @new_values)
          expect(response.code).to eql '200'
          @course.reload
          expect(@course.group_weighting_scheme).to eql("percent")
        end

        it "can change apply_assignment_group_weights without a term change" do
          @new_values["course"].delete("enrollment_term_id")
          @new_values["course"].delete("term_id")
          raw_api_call(:put, @path, @params, @new_values)
          expect(response.code).to eql '200'
          @course.reload
          expect(@course.group_weighting_scheme).to eql("percent")
        end

        it "can change group_weighting_scheme with a term change" do
          @term.grading_period_group = @grading_period_group
          @term.save!
          @new_values["course"].delete("apply_assignment_group_weights")
          @new_values["course"]["group_weighting_scheme"] = "percent"
          raw_api_call(:put, @path, @params, @new_values)
          expect(response.code).to eql '200'
          @course.reload
          expect(@course.group_weighting_scheme).to eql("percent")
        end

        it "can change group_weighting_scheme without a term change" do
          @new_values["course"].delete("enrollment_term_id")
          @new_values["course"].delete("term_id")
          @new_values["course"].delete("apply_assignment_group_weights")
          @new_values["course"]["group_weighting_scheme"] = "percent"
          raw_api_call(:put, @path, @params, @new_values)
          expect(response.code).to eql '200'
          @course.reload
          expect(@course.group_weighting_scheme).to eql("percent")
        end

        it 'cannot change group_weighting_scheme if any effective due dates in the whole course are in a closed grading period' do
          expect_any_instance_of(Course).to receive(:any_assignment_in_closed_grading_period?).and_return(true)
          @new_values["course"]["group_weighting_scheme"] = "percent"
          teacher_in_course(course: @course, active_all: true)
          raw_api_call(:put, @path, @params, @new_values)
          expect(response.code).to eql '401'
          @course.reload
          expect(@course.group_weighting_scheme).not_to eql("percent")
        end
      end
    end

    context "a designer" do
      before(:once) do
        course_with_designer(:course => @course, :active_all => true)
        @standard = @course.account.grading_standards.create!(:title => "account standard", :standard_data => {:a => {:name => 'A', :value => '95'}, :b => {:name => 'B', :value => '80'}, :f => {:name => 'F', :value => ''}})
      end

      it "should require :manage_grades rights if the grading standard is changing" do
        json = api_call_as_user(@designer, :put, @path, @params, { :course => { :grading_standard_id => @standard.id, :apply_assignment_group_weights => true } }, {}, { :expected_status => 401 })
      end

      it "should not require :manage_grades rights if the grading standard is not changing" do
        @course.grading_standard = @standard
        @course.save!
        json = api_call_as_user(@designer, :put, @path, @params, :course => { :grading_standard_id => @standard.id, :apply_assignment_group_weights => true })
        @course.reload
        expect(@course.apply_group_weights?).to eq true
        expect(@course.grading_standard).to eq @standard
      end

      it "should not require :manage_grades rights if the grading standard isn't changing (null)" do
        json = api_call_as_user(@designer, :put, @path, @params, :course => { :grading_standard_id => nil, :apply_assignment_group_weights => true })
        @course.reload
        expect(@course.apply_group_weights?).to eq true
        expect(@course.grading_standard).to be_nil
      end
    end

    context "a teacher" do
      before :once do
        user_factory
        enrollment = @course.enroll_teacher(@user)
        enrollment.accept!
        @new_values['course'].delete('sis_course_id')
      end

      it "should be able to update a course" do
        json = api_call(:put, @path, @params, @new_values)

        expect(json['name']).to eql @new_values['course']['name']
        expect(json['course_code']).to eql @new_values['course']['course_code']
        expect(json['start_at']).to eql @new_values['course']['start_at']
        expect(json['end_at']).to eql @new_values['course']['end_at']
        expect(json['default_view']).to eql @new_values['course']['default_view']
        expect(json['apply_assignment_group_weights']).to eql @new_values['course']['apply_assignment_group_weights']
      end

      it 'should process html content in syllabus_body on update' do
        should_process_incoming_user_content(@course) do |content|
          json = api_call(:put, @path, @params, {'course' => {'syllabus_body' => content}})

          @course.reload
          @course.syllabus_body
        end
      end

      it "should not be able to update the storage quota (bytes)" do
        json = api_call(:put, @path, @params, :course => { :storage_quota => 123.megabytes })
        @course.reload
        expect(@course.storage_quota).to eq @course.account.default_storage_quota
      end

      it "should not be able to update the storage quota (mb)" do
        json = api_call(:put, @path, @params, :course => { :storage_quota_mb => 123 })
        @course.reload
        expect(@course.storage_quota_mb).to eq @course.account.default_storage_quota_mb
      end

      it "should not be able to update the sis id" do
        original_sis = @course.sis_source_id
        raw_api_call(:put, @path, @params, @new_values.merge(:sis_course_id => 'NEW123'))
        @course.reload
        expect(@course.sis_source_id).to eql original_sis
      end

      context "when an assignment is due in a closed grading period" do
        before :once do
          @course.update_attributes(group_weighting_scheme: "equal")
          @grading_period_group = Factories::GradingPeriodGroupHelper.new.create_for_account(@course.root_account)
          term = @course.enrollment_term
          term.grading_period_group = @grading_period_group
          term.save!
          Factories::GradingPeriodHelper.new.create_for_group(@grading_period_group, {
            start_date: 2.weeks.ago, end_date: 2.days.ago, close_date: 1.day.ago
          })
          @group = @course.assignment_groups.create!(name: 'group')
          @assignment = @course.assignments.create!({
            title: 'assignment', assignment_group: @group, due_at: 1.week.ago
          })
        end

        it "cannot change apply_assignment_group_weights with a term change" do
          @term.grading_period_group = @grading_period_group
          @term.save!
          raw_api_call(:put, @path, @params, @new_values)
          expect(response.code).to eql '401'
          @course.reload
          expect(@course.group_weighting_scheme).to eql("equal")
        end

        it "cannot change apply_assignment_group_weights without a term change" do
          @new_values["course"].delete("enrollment_term_id")
          @new_values["course"].delete("term_id")
          raw_api_call(:put, @path, @params, @new_values)
          expect(response.code).to eql '401'
          @course.reload
          expect(@course.group_weighting_scheme).to eql("equal")
        end

        it "cannot change group_weighting_scheme with a term change" do
          @term.grading_period_group = @grading_period_group
          @term.save!
          @new_values["course"].delete("apply_assignment_group_weights")
          @new_values["course"]["group_weighting_scheme"] = "percent"
          raw_api_call(:put, @path, @params, @new_values)
          expect(response.code).to eql '401'
          @course.reload
          expect(@course.group_weighting_scheme).to eql("equal")
        end

        it "cannot change group_weighting_scheme without a term change" do
          @new_values["course"].delete("enrollment_term_id")
          @new_values["course"].delete("term_id")
          @new_values["course"].delete("apply_assignment_group_weights")
          @new_values["course"]["group_weighting_scheme"] = "percent"
          raw_api_call(:put, @path, @params, @new_values)
          expect(response.code).to eql '401'
          @course.reload
          expect(@course.group_weighting_scheme).to eql("equal")
        end

        it "succeeds when apply_assignment_group_weights is not changed" do
          @new_values['course']['apply_assignment_group_weights'] = false
          raw_api_call(:put, @path, @params, @new_values)
          expect(response.code).to eql '200'
          @course.reload
          expect(@course.group_weighting_scheme).to eql("equal")
        end

        it "succeeds when group_weighting_scheme is not changed" do
          @new_values["course"].delete("apply_assignment_group_weights")
          @new_values["course"]["group_weighting_scheme"] = "equal"
          raw_api_call(:put, @path, @params, @new_values)
          expect(response.code).to eql '200'
          @course.reload
          expect(@course.group_weighting_scheme).to eql("equal")
        end

        it "ignores deleted assignments" do
          @assignment.destroy
          raw_api_call(:put, @path, @params, @new_values)
          expect(response.code).to eql '200'
          @course.reload
          expect(@course.group_weighting_scheme).to eql("percent")
        end
      end
    end

    context "an unauthorized user" do
      before { user_factory }

      it "should return 401 unauthorized" do
        raw_api_call(:put, @path, @params, @new_values)
        expect(response.code).to eql '401'
      end
    end
  end

  describe "course deletion" do
    before :once do
      account_admin_user
      @path = "/api/v1/courses/#{@course.id}"
      @params = { :controller => 'courses', :action => 'destroy', :format => 'json', :id => @course.id.to_s }
    end
    context "an authorized user" do
      it "should be able to delete a course" do
        expect(Auditors::Course).to receive(:record_deleted).once
        json = api_call(:delete, @path, @params, { :event => 'delete' })
        expect(json).to eq({ 'delete' => true })
        @course.reload
        expect(@course.workflow_state).to eql 'deleted'
      end

      it "should not clear sis_id for course" do
        @course.sis_source_id = 'sis_course_3'
        @course.save
        json = api_call(:delete, @path, @params, { :event => 'delete' })
        expect(json).to eq({ 'delete' => true })
        @course.reload
        expect(@course.workflow_state).to eq 'deleted'
        expect(@course.sis_source_id).to eq 'sis_course_3'
      end

      it "should conclude when completing a course" do
        expect(Auditors::Course).to receive(:record_concluded).once
        json = api_call(:delete, @path, @params, { :event => 'conclude' })
        expect(json).to eq({ 'conclude' => true })

        @course.reload
        expect(@course.workflow_state).to eql 'completed'
      end

      it "should return 400 if params[:event] is missing" do
        json = raw_api_call(:delete, @path, @params)
        expect(response.code).to eql '400'
        expect(JSON.parse(response.body)).to eq({
          'message' => 'Only "delete" and "conclude" events are allowed.'
        })

      end

      it "should return 400 if an unknown event type is used" do
        raw_api_call(:delete, @path, @params, { :event => 'rm -rf like a boss' })
        expect(response.code).to eql '400'
        expect(JSON.parse(response.body)).to eq({
          'message' => 'Only "delete" and "conclude" events are allowed.'
        })
      end
    end
    context "an unauthorized user" do
      it "should return 401" do
        @user = @student
        raw_api_call(:delete, @path, @params, { :event => 'conclude' })
        expect(response.code).to eql '401'
      end
    end
  end

  describe "reset content" do
    before :once do
      @user = @teacher
      @path = "/api/v1/courses/#{@course.id}/reset_content"
      @params = { :controller => 'courses', :action => 'reset_content', :format => 'json', :course_id => @course.id.to_s }
    end
    context "an authorized user" do
      it "should be able to reset a course" do
        expect(Auditors::Course).to receive(:record_reset).once.
          with(@course, anything, @user, anything)

        json = api_call(:post, @path, @params)
        @course.reload
        expect(@course.workflow_state).to eql 'deleted'
        new_course = Course.find(json['id'])
        expect(new_course.workflow_state).to eql 'claimed'
        expect(json['workflow_state']).to eql 'unpublished'
      end
    end
    context "an unauthorized user" do
      it "should return 401" do
        @user = @student
        raw_api_call(:post, @path, @params)
        expect(response.code).to eql '401'
      end
    end
  end

  describe "batch edit" do
    before :once do
      @account = Account.default
      account_admin_user
      theuser = @user
      @path = "/api/v1/accounts/#{@account.id}/courses"
      @params = { :controller => 'courses', :action => 'batch_update', :format => 'json', :account_id => @account.to_param }
      @course1 = course_model :sis_source_id => 'course1', :account => @account, :workflow_state => 'created'
      @course2 = course_model :sis_source_id => 'course2', :account => @account, :workflow_state => 'created'
      @course3 = course_model :sis_source_id => 'course3', :account => @account, :workflow_state => 'created'
      @user = theuser
    end

    context "an authorized user" do
      let(:course_ids){ [@course1.id, @course2.id, @course3.id] }
      it "should delete multiple courses" do
        expect(Auditors::Course).to receive(:record_deleted).exactly(course_ids.length).times
        api_call(:put, @path, @params, { :event => 'delete', :course_ids => course_ids })
        run_jobs
        [@course1, @course2, @course3].each { |c| expect(c.reload).to be_deleted }
      end

      it "should conclude multiple courses" do
        expect(Auditors::Course).to receive(:record_concluded).exactly(course_ids.length).times
        api_call(:put, @path, @params, { :event => 'conclude', :course_ids => course_ids })
        run_jobs
        [@course1, @course2, @course3].each { |c| expect(c.reload).to be_completed }
      end

      it "should publish multiple courses" do
        expect(Auditors::Course).to receive(:record_published).exactly(course_ids.length).times
        api_call(:put, @path, @params, { :event => 'offer', :course_ids => course_ids })
        run_jobs
        [@course1, @course2, @course3].each { |c| expect(c.reload).to be_available }
      end

      it "should accept sis ids" do
        course_ids = ['sis_course_id:course1', 'sis_course_id:course2', 'sis_course_id:course3']
        expect(Auditors::Course).to receive(:record_published).exactly(course_ids.length).times
        api_call(:put, @path, @params, { :event => 'offer', :course_ids => course_ids })
        run_jobs
        [@course1, @course2, @course3].each { |c| expect(c.reload).to be_available }
      end

      it 'should undelete courses' do
        [@course1, @course2].each { |c| c.destroy }
        expect(Auditors::Course).to receive(:record_restored).twice
        api_call(:put, @path, @params, { :event => 'undelete', :course_ids => [@course1.id, 'sis_course_id:course2'] })
        run_jobs
        [@course1, @course2].each { |c| expect(c.reload).to be_claimed }
      end

      it "should not conclude deleted courses" do
        @course1.destroy
        expect(Auditors::Course).to receive(:record_concluded).once
        api_call(:put, @path, @params, { :event => 'conclude', :course_ids => [@course1.id, @course2.id] })
        run_jobs
        expect(@course1.reload).to be_deleted
        expect(@course2.reload).to be_completed
      end

      it "should not publish deleted courses" do
        @course1.destroy
        expect(Auditors::Course).to receive(:record_published).once
        api_call(:put, @path, @params, { :event => 'offer', :course_ids => [@course1.id, @course2.id] })
        run_jobs
        expect(@course1.reload).to be_deleted
        expect(@course2.reload).to be_available
      end

      it "should update progress" do
        json = api_call(:put, @path, @params, { :event => 'conclude', :course_ids => ['sis_course_id:course1', 'sis_course_id:course2', 'sis_course_id:course3']})
        progress = Progress.find(json['id'])
        expect(progress).to be_queued
        expect(progress.completion).to eq 0
        expect(progress.user_id).to eq @user.id
        expect(progress.delayed_job_id).not_to be_nil
        run_jobs
        progress.reload
        expect(progress).to be_completed
        expect(progress.completion).to eq 100.0
        expect(progress.message).to eq "3 courses processed"
        [@course1, @course2, @course3].each { |c| expect(c.reload).to be_completed }
      end

      it "should return 400 if :course_ids is missing" do
        api_call(:put, @path, @params, {}, {}, {:expected_status => 400})
      end

      it "should return 400 if :event is missing" do
        api_call(:put, @path, @params, { :course_ids => [@course1.id, @course2.id, @course3.id] },
                 {}, {:expected_status => 400})
      end

      it "should return 400 if :event is invalid" do
        api_call(:put, @path, @params, { :event => 'assimilate', :course_ids => [@course1.id, @course2.id, @course3.id] },
                 {}, {:expected_status => 400})
      end

      it "should return 403 if the list of courses is too long" do
        api_call(:put, @path, @params, { :event => 'offer', :course_ids => (1..501).to_a },
                 {}, {:expected_status => 403})
      end

      it "should deal gracefully with an invalid course id" do
        @course2.enrollments.each(&:destroy_permanently!)
        @course2.course_account_associations.scope.delete_all
        @course2.course_sections.scope.delete_all
        @course2.reload.destroy_permanently!
        json = api_call(:put, @path + "?event=offer&course_ids[]=#{@course1.id}&course_ids[]=#{@course2.id}",
                        @params.merge(:event => 'offer', :course_ids => [@course1.id.to_s, @course2.id.to_s]))
        run_jobs
        expect(@course1.reload).to be_available
        progress = Progress.find(json['id'])
        expect(progress).to be_completed
        expect(progress.message).to be_include "1 course processed"
        expect(progress.message).to be_include "The course was not found: #{@course2.id}"
      end

      it "should not update courses in another account" do
        theUser = @user
        otherAccount = account_model :root_account_id => nil
        otherCourse = course_model :account => otherAccount
        @user = theUser
        json = api_call(:put, @path + "?event=offer&course_ids[]=#{@course1.id}&course_ids[]=#{otherCourse.id}",
                        @params.merge(:event => 'offer', :course_ids => [@course1.id.to_s, otherCourse.id.to_s]))
        run_jobs
        expect(@course1.reload).to be_available
        progress = Progress.find(json['id'])
        expect(progress).to be_completed
        expect(progress.message).to be_include "1 course processed"
        expect(progress.message).to be_include "The course was not found: #{otherCourse.id}"
      end

      it "should succeed when publishing already published courses" do
        @course1.offer!
        expect(Auditors::Course).to receive(:record_published).twice
        json = api_call(:put, @path, @params, { :event => 'offer', :course_ids => course_ids })
        run_jobs
        progress = Progress.find(json['id'])
        expect(progress.message).to be_include "3 courses processed"
        [@course1, @course2, @course3].each { |c| expect(c.reload).to be_available }
      end

      it "should succeed when concluding already concluded courses" do
        @course1.complete!
        @course2.complete!
        expect(Auditors::Course).to receive(:record_concluded).once
        json = api_call(:put, @path, @params, { :event => 'conclude', :course_ids => course_ids })
        run_jobs
        progress = Progress.find(json['id'])
        expect(progress.message).to be_include "3 courses processed"
        [@course1, @course2, @course3].each { |c| expect(c.reload).to be_completed }
      end

      it "should be able to unconclude courses" do
        @course1.complete!
        @course2.complete!
        expect(Auditors::Course).to receive(:record_unconcluded).twice
        json = api_call(:put, @path, @params, { :event => 'offer', :course_ids => course_ids })
        run_jobs
        progress = Progress.find(json['id'])
        expect(progress.message).to be_include "3 courses processed"
        [@course1, @course2, @course3].each { |c| expect(c.reload).to be_available }
      end

      it "should report a failure if no updates succeeded" do
        @course2.enrollments.each(&:destroy_permanently!)
        @course2.course_account_associations.scope.delete_all
        @course2.course_sections.scope.delete_all
        @course2.reload.destroy_permanently!
        json = api_call(:put, @path + "?event=offer&course_ids[]=#{@course2.id}",
                        @params.merge(:event => 'offer', :course_ids => [@course2.id.to_s]))
        run_jobs
        progress = Progress.find(json['id'])
        expect(progress).to be_failed
        expect(progress.message).to be_include "0 courses processed"
        expect(progress.message).to be_include "The course was not found: #{@course2.id}"
      end

      it "should report a failure if an exception is raised outside course update" do
        allow_any_instance_of(Progress).to receive(:complete!).and_raise "crazy exception"
        json = api_call(:put, @path + "?event=offer&course_ids[]=#{@course2.id}",
                        @params.merge(:event => 'offer', :course_ids => [@course2.id.to_s]))
        run_jobs
        progress = Progress.find(json['id'])
        expect(progress).to be_failed
        expect(progress.message).to be_include "crazy exception"
      end
    end

    context "an unauthorized user" do
      it "should return 401" do
        user_model
        api_call(:put, @path, @params, { :event => 'offer', :course_ids => [@course1.id] },
                 {}, {:expected_status => 401})
      end
    end
  end

  it "includes section enrollments if requested" do
    json = api_call(:get, "/api/v1/courses.json",
      { :controller => 'courses', :action => 'index', :format => 'json' },
      { :include => ['sections'] })

    json.sort_by! { |e| e['id'] }
    course1_section_json = json.first['sections']

    section = @course1.course_sections.first
    expect(course1_section_json.size).to eq 1
    expect(course1_section_json.first['id']).to eq section.id
    expect(course1_section_json.first['enrollment_role']).to eq 'TeacherEnrollment'
    expect(course1_section_json.first['name']).to eq section.name
    expect(course1_section_json.first['start_at']).to eq section.start_at
    expect(course1_section_json.first['end_at']).to eq section.end_at

    course2_section_json = json.last['sections']

    section = @course2.course_sections.first
    expect(course2_section_json.size).to eq 1
    expect(course2_section_json.first['id']).to eq section.id
    expect(course2_section_json.first['enrollment_role']).to eq 'StudentEnrollment'
    expect(course2_section_json.first['name']).to eq section.name
    expect(course2_section_json.first['start_at']).to eq section.start_at
    expect(course2_section_json.first['end_at']).to eq section.end_at
  end

  it 'includes account if requested' do
    json = api_call(:get, "/api/v1/courses.json", {controller: 'courses', action: 'index', format: 'json'}, {include: ['account']})
    expect(json.first.dig('account', 'name')).to eq 'Default Account'
  end

  it 'includes subaccount_name if requested for backwards compatibility' do
    json = api_call(:get, "/api/v1/courses.json", {controller: 'courses', action: 'index', format: 'json'}, {include: ['subaccount']})
    expect(json.first['subaccount_name']).to eq 'Default Account'
  end

  it "should include term name in course list if requested" do
    [@course1.enrollment_term, @course2.enrollment_term].each do |term|
      term.start_at = 1.day.ago
      term.end_at = 2.days.from_now
      term.save!
    end

    json = api_call(:get, "/api/v1/courses.json",
                    { :controller => 'courses', :action => 'index', :format => 'json' },
                    { :include => ['term'] })

    # course1
    courses = json.select { |c| c['id'] == @course1.id }
    expect(courses.length).to eq 1
    expect(courses[0]).to include('term')
    expect(courses[0]['term']).to include(
      'id' => @course1.enrollment_term_id,
      'name' => @course1.enrollment_term.name,
      'workflow_state' => 'active',
    )

    # course2
    courses = json.select { |c| c['id'] == @course2.id }
    expect(courses.length).to eq 1
    expect(courses[0]).to include('term')
    expect(courses[0]['term']).to include(
      'id' => @course2.enrollment_term_id,
      'name' => @course2.enrollment_term.name,
      'workflow_state' => 'active',
    )
  end

  describe "term dates" do
    before do
      @course2.enrollment_term.set_overrides(@course1.account, 'StudentEnrollment' =>
          {start_at: '2014-01-01T00:00:00Z', end_at: '2014-12-31T00:00:00Z'})
    end

    it "should return overridden term dates from index" do
      json = api_call_as_user(@student, :get, "/api/v1/courses.json",
                      { :controller => 'courses', :action => 'index', :format => 'json' },
                      { :include => ['term'] })
      course_json = json.detect { |c| c['id'] == @course2.id }
      expect(course_json['term']['start_at']).to eq '2014-01-01T00:00:00Z'
      expect(course_json['term']['end_at']).to eq '2014-12-31T00:00:00Z'
    end

    it "should return overridden term dates from show" do
      json = api_call_as_user(@student, :get, "/api/v1/courses/#{@course2.id}",
                      { :controller => 'courses', :action => 'show', :id => @course.to_param, :format => 'json' },
                      { :include => ['term'] })
      expect(json['term']['start_at']).to eq '2014-01-01T00:00:00Z'
      expect(json['term']['end_at']).to eq '2014-12-31T00:00:00Z'
    end
  end

  it "should return public_syllabus if requested" do
    @course1.public_syllabus = true
    @course1.save
    @course2.public_syllabus = true
    @course2.save

    json = api_call(:get, "/api/v1/courses.json", { :controller => 'courses', :action => 'index', :format => 'json' })
    json.each { |course| expect(course['public_syllabus']).to be_truthy }
  end

  it "should return public_syllabus_to_auth if requested" do
    @course1.public_syllabus_to_auth = true
    @course1.save
    @course2.public_syllabus_to_auth = true
    @course2.save

    json = api_call(:get, "/api/v1/courses.json", { :controller => 'courses', :action => 'index', :format => 'json' })
    json.each { |course| expect(course['public_syllabus_to_auth']).to be_truthy }
  end


  describe "scores" do
    before(:once) do
      @course2.grading_standard_enabled = true
      @course2.save
    end

    def courses_api_index_call(includes: ['total_scores'])
      api_call(
        :get, "/api/v1/courses.json",
        { controller: 'courses', action: 'index', format: 'json' },
        { include: includes }
      )
    end

    def enrollment(json_response)
      course2 = json_response.find { |course| course['id'] == @course2.id }
      course2['enrollments'].first
    end

    context "include total scores" do
      before(:once) do
        student_enrollment = @course2.all_student_enrollments.first
        student_enrollment.scores.create!(current_score: 80, final_score: 70, unposted_current_score: 10)
      end

      it "includes scores in course list if requested" do
        json_response = courses_api_index_call
        expect(enrollment(json_response)).to include(
          'type' => 'student',
          'computed_current_score' => 80,
          'computed_final_score' => 70,
          'computed_final_grade' => @course2.score_to_grade(70)
        )
      end

      it "does not include unposted scores for a self-viewing user" do
        json_response = courses_api_index_call
        expect(enrollment(json_response)).not_to include(
          'unposted_current_score',
          'unposted_current_grade',
          'unposted_final_score',
          'unposted_final_grade'
        )
      end

      it "does not include scores in course list, even if requested, if final grades are hidden" do
        @course2.hide_final_grades = true
        @course2.save
        json_response = courses_api_index_call
        enrollment_json = enrollment(json_response)
        expect(enrollment_json).to include 'type' => 'student'
        expect(enrollment_json).not_to include(
          'computed_current_score',
          'computed_final_score',
          'computed_final_grade'
        )
      end
    end

    context "include current grading period scores" do
      let(:grading_period_keys) do
        [ 'multiple_grading_periods_enabled',
          'has_grading_periods',
          'totals_for_all_grading_periods_option',
          'current_period_computed_current_score',
          'current_period_computed_final_score',
          'current_period_computed_current_grade',
          'current_period_computed_final_grade',
          'current_grading_period_title',
          'current_grading_period_id' ]
      end

      before(:once) do
        create_grading_periods_for(
          @course2, grading_periods: [:old, :current, :future]
        )
      end

      it "includes current grading period scores if 'total_scores' " \
      "and 'current_grading_period_scores' are requested" do
        json_response = courses_api_index_call(includes: ['total_scores', 'current_grading_period_scores'])
        enrollment_json = enrollment(json_response)
        expect(enrollment_json).to include(*grading_period_keys)
        current_grading_period_title = 'Course Period 2: current period'
        expect(enrollment_json['current_grading_period_title']).to eq(current_grading_period_title)
      end

      it "ignores soft-deleted grading periods when determining the current grading period" do
        GradingPeriod.current_period_for(@course2).destroy
        json_response = courses_api_index_call(includes: ['total_scores', 'current_grading_period_scores'])
        current_period_id = enrollment(json_response)['current_grading_period_id']
        expect(current_period_id).to be_nil
      end

      it "does not include current grading period scores if 'total_scores' are " \
      "not requested, even if 'current_grading_period_scores' are requested" do
        json_response = courses_api_index_call(includes: ['current_grading_period_scores'])
        enrollment_json = enrollment(json_response)
        expect(enrollment_json).to_not include(*grading_period_keys)
      end

      it "does not include current grading period scores if final grades are hidden, " \
      " even if 'total_scores' and 'current_grading_period_scores' are requested" do
        @course2.hide_final_grades = true
        @course2.save
        json_response = courses_api_index_call(includes: ['total_scores', 'current_grading_period_scores'])
        enrollment_json = enrollment(json_response)
        expect(enrollment_json).not_to include(*grading_period_keys)
      end

      it "returns true for 'has_grading_periods' on the enrollment " \
      "JSON if the course has grading periods" do
        json_response = courses_api_index_call(includes: ['total_scores', 'current_grading_period_scores'])
        enrollment_json = enrollment(json_response)
        expect(enrollment_json['has_grading_periods']).to be true
        expect(enrollment_json['multiple_grading_periods_enabled']).to be true
      end

      it "returns 'has_grading_periods' and 'has_weighted_grading_periods' keys at the course-level " \
      "on the JSON response if 'current_grading_period_scores' are requested" do
        course_json_response = courses_api_index_call(includes: ['total_scores', 'current_grading_period_scores']).first
        expect(course_json_response).to have_key 'has_grading_periods'
        expect(course_json_response).to have_key 'multiple_grading_periods_enabled'
        expect(course_json_response).to have_key 'has_weighted_grading_periods'
      end

      it "does not return 'has_grading_periods' and 'has_weighted_grading_periods' keys at the course-level " \
      "on the JSON response if 'current_grading_period_scores' are not requested" do
        course_json_response = courses_api_index_call.first
        expect(course_json_response).not_to have_key 'has_grading_periods'
        expect(course_json_response).not_to have_key 'multiple_grading_periods_enabled'
        expect(course_json_response).not_to have_key 'has_weighted_grading_periods'
      end

      context "computed scores" do
        before(:once) do
          assignment_in_current_period = @course2.assignments.create!(
            title: "In current grading period - graded",
            due_at: 2.days.from_now,
            points_possible: 10
          )
          assignment_in_current_period.grade_student(@student, grader: @teacher, score: 9)
          @course2.assignments.create!(
            title: "In current grading period - not graded",
            due_at: 2.days.from_now,
            points_possible: 10
          )
        end

        context "all assignments for the course fall within the current grading period" do
          it "current grading period scores match computed scores" do
            json_response = courses_api_index_call(includes: ['total_scores', 'current_grading_period_scores'])
            enrollment_json = enrollment(json_response)

            current_period_current_score = enrollment_json['current_period_computed_current_score']
            current_score = enrollment_json['computed_current_score']
            expect(current_period_current_score).to eq(current_score)

            current_period_final_score = enrollment_json['current_period_computed_final_score']
            final_score = enrollment_json['computed_final_score']
            expect(current_period_final_score).to eq(final_score)
          end

          it "current grading period grades match computed grades" do
            json_response = courses_api_index_call(includes: ['total_scores', 'current_grading_period_scores'])
            enrollment_json = enrollment(json_response)

            current_period_current_grade = enrollment_json['current_period_computed_current_grade']
            current_grade = enrollment_json['computed_current_grade']
            expect(current_period_current_grade).to eq(current_grade)

            current_period_final_grade = enrollment_json['current_period_computed_final_grade']
            final_grade = enrollment_json['computed_final_grade']
            expect(current_period_final_grade).to eq(final_grade)
          end
        end

        context "assignments span across many grading periods" do
          before(:once) do
            assignment_in_future_grading_period = @course2.assignments.create!(
              title: "In future grading period",
              due_at: 3.months.from_now,
              points_possible: 10
            )
            assignment_in_future_grading_period.grade_student(@student, grader: @teacher, score: 10)
          end

          it "current grading period scores and grades do not match computed scores and grades" do
            json_response = courses_api_index_call(includes: ['total_scores', 'current_grading_period_scores'])
            enrollment_json = enrollment(json_response)
            expect(enrollment_json['current_period_computed_current_score'])
              .to_not eq(enrollment_json['computed_current_score'])
            expect(enrollment_json['current_period_computed_final_score'])
              .to_not eq(enrollment_json['computed_final_score'])
            expect(enrollment_json['current_period_computed_current_grade'])
              .to_not eq(enrollment_json['computed_current_grade'])
            expect(enrollment_json['current_period_computed_final_grade'])
              .to_not eq(enrollment_json['computed_final_grade'])
          end

          it "current grading period scores are correct" do
            json_response = courses_api_index_call(includes: ['total_scores', 'current_grading_period_scores'])
            enrollment_json = enrollment(json_response)

            expect(enrollment_json['current_period_computed_current_score']).to eq(90)
            expect(enrollment_json['current_period_computed_final_score']).to eq(45)
          end

          it "current grading period grades are correct" do
            json_response = courses_api_index_call(includes: ['total_scores', 'current_grading_period_scores'])
            enrollment_json = enrollment(json_response)

            expect(enrollment_json['current_period_computed_current_grade']).to eq('A-')
            expect(enrollment_json['current_period_computed_final_grade']).to eq('F')
          end
        end
      end
    end
  end

  it "should only return teacher enrolled courses on ?enrollment_type=teacher" do
    json = api_call(:get, "/api/v1/courses.json?enrollment_type=teacher",
            { :controller => 'courses', :action => 'index', :format => 'json', :enrollment_type => 'teacher' })

    # course1 (only care about teacher)
    expect(json.length).to eq 1
    expect(json[0]).to include(
      'enrollments',
      'id' => @course1.id,
    )
    expect(json[0]['enrollments'].length).to eq 1
    expect(json[0]['enrollments'][0]).to include(
      'type' => 'teacher',
    )
  end

  describe "enrollment_role" do
    before :once do
      @role = Account.default.roles.build :name => 'SuperTeacher'
      @role.base_role_type = 'TeacherEnrollment'
      @role.save!
      @course3 = course_factory
      @course3.enroll_user(@me, 'TeacherEnrollment', { :role => @role, :active_all => true })
    end

    it "should return courses with all teacher types on ?enrollment_type=teacher" do
      json = api_call(:get, "/api/v1/courses.json?enrollment_type=teacher",
               { :controller => 'courses', :action => 'index', :format => 'json', :enrollment_type => 'teacher' })
      expect(json.collect{ |c| c['id'].to_i }.sort).to eq [@course1.id, @course3.id].sort
    end

    it "should return only courses with vanilla TeacherEnrollments on ?enrollment_role=TeacherEnrollment" do
      json = api_call(:get, "/api/v1/courses.json?enrollment_role=TeacherEnrollment",
                      { :controller => 'courses', :action => 'index', :format => 'json', :enrollment_role => 'TeacherEnrollment' })
      expect(json.collect{ |c| c['id'].to_i }).to eq [@course1.id]
    end

    it "should return courses by custom role" do
      json = api_call(:get, "/api/v1/courses.json?enrollment_role=SuperTeacher",
                      { :controller => 'courses', :action => 'index', :format => 'json', :enrollment_role => 'SuperTeacher' })
      expect(json.collect{ |c| c['id'].to_i }).to eq [@course3.id]
      expect(json[0]['enrollments']).to eq [{ 'type' => 'teacher', 'role' => 'SuperTeacher', 'role_id' => @role.id, 'user_id' => @me.id, 'enrollment_state' => 'invited' }]
    end
  end

  describe "enrollment_state" do
    before :once do
      @course2.start_at = 1.day.from_now
      @course2.conclude_at = 2.days.from_now
      @course2.restrict_enrollments_to_course_dates = true
      @course2.save! # pending_active

      @course3 = course_factory(active_all: true)
      @course3.enroll_user(@me, 'StudentEnrollment') #invited

      @course4 = course_factory(active_all: true)
      @course4.enroll_user(@me, 'StudentEnrollment')
      @course4.start_at = 2.days.ago
      @course4.conclude_at = 1.day.ago
      @course4.restrict_enrollments_to_course_dates = true
      @course4.save! # completed
    end

    it "should return courses with active enrollments" do
      json = api_call(:get, "/api/v1/courses.json?enrollment_state=active",
        { :controller => 'courses', :action => 'index', :format => 'json', :enrollment_state => 'active' })
      expect(json.collect{ |c| c['id'].to_i }).to eq [@course1.id]
    end

    it "should return courses with invited or pending enrollments" do
      json = api_call(:get, "/api/v1/courses.json?enrollment_state=invited_or_pending",
        { :controller => 'courses', :action => 'index', :format => 'json', :enrollment_state => 'invited_or_pending' })
      expect(json.collect{ |c| c['id'].to_i }.sort).to eq [@course2.id, @course3.id].sort
    end

    it "should return courses with completed enrollments" do
      json = api_call(:get, "/api/v1/courses.json?enrollment_state=completed",
        { :controller => 'courses', :action => 'index', :format => 'json', :enrollment_state => 'completed' })
      expect(json.collect{ |c| c['id'].to_i }).to eq [@course4.id]
    end

    it "should return active observed student enrollments if requested" do
      @student = user_factory(active_all: true)
      @student_enroll = @course1.enroll_user(@student, "StudentEnrollment")
      @student_enroll.accept!
      @observer = user_factory(active_all: true)
      @course1.enroll_user(@observer, "ObserverEnrollment", :associated_user_id => @student.id)

      json = api_call_as_user(@observer, :get,
        "/api/v1/courses.json?include[]=observed_users&enrollment_state=active",
        { :controller => 'courses', :action => 'index',
          :id => @observer_course.to_param, :format => 'json', :include => [ "observed_users" ], :enrollment_state => 'active' })

      expect(json.first['enrollments'].count).to eq 2
      student_enroll_json = json.first['enrollments'].detect{|e| e["type"] == "student"}
      expect(student_enroll_json["user_id"]).to eq @student.id

      @student_enroll.start_at = 3.days.ago
      @student_enroll.end_at = 2.days.ago
      @student_enroll.save! # soft-conclude

      json = api_call_as_user(@observer, :get,
        "/api/v1/courses.json?include[]=observed_users&enrollment_state=active",
        { :controller => 'courses', :action => 'index',
          :id => @observer_course.to_param, :format => 'json', :include => [ "observed_users" ], :enrollment_state => 'active' })

      expect(json.first['enrollments'].count).to eq 1
    end
  end

  describe "course state" do
    before :once do
      @role = Account.default.roles.build :name => 'SuperTeacher'
      @role.base_role_type = 'TeacherEnrollment'
      @role.save!
      @course3 = course_factory
      @course3.enroll_user(@me, 'TeacherEnrollment', { :role => @role, :active_all => true })
      @course4 = course_factory
      @course4.enroll_user(@me, 'TaEnrollment')
      @course4.workflow_state = 'created'
      @course4.save
    end

    it "should return only courses with state available on ?state[]=available" do
      json = api_call(:get, "/api/v1/courses.json",
                      { :controller => 'courses', :action => 'index', :format => 'json' },
                      { :state => ['available'] })
      expect(json.collect{ |c| c['id'].to_i }.sort).to eq [@course1.id, @course2.id].sort
      json.collect{ |c| c['workflow_state']}.each do |s|
        expect(%w{available}).to include(s)
      end
    end

    it "should return only courses with state unpublished on ?state[]=unpublished" do
      json = api_call(:get, "/api/v1/courses.json",
                      { :controller => 'courses', :action => 'index', :format => 'json' },
                      { :state => ['unpublished'] })
      expect(json.collect{ |c| c['id'].to_i }.sort).to eq [@course3.id,@course4.id].sort
      json.collect{ |c| c['workflow_state']}.each do |s|
        expect(%w{unpublished}).to include(s)
      end
    end

    it "should return only courses with state unpublished and available on ?state[]=unpublished, available" do
      json = api_call(:get, "/api/v1/courses.json",
                      { :controller => 'courses', :action => 'index', :format => 'json' },
                      { :state => ['unpublished','available'] })
      expect(json.collect{ |c| c['id'].to_i }.sort).to eq [@course1.id, @course2.id, @course3.id, @course4.id].sort
      json.collect{ |c| c['workflow_state']}.each do |s|
        expect(%w{available unpublished}).to include(s)
      end
    end

    it "should return courses by custom role and state unpublished" do
      json = api_call(:get, "/api/v1/courses.json?enrollment_role=SuperTeacher",
                      { :controller => 'courses', :action => 'index', :format => 'json', :enrollment_role => 'SuperTeacher' },
                      { :state => ['unpublished'] })
      expect(json.collect{ |c| c['id'].to_i }).to eq [@course3.id]
      expect(json[0]['enrollments']).to eq [{ 'type' => 'teacher', 'role' => 'SuperTeacher', 'role_id' => @role.id, 'user_id' => @me.id, 'enrollment_state' => 'invited' }]
      json.collect{ |c| c['workflow_state']}.each do |s|
        expect(%w{unpublished}).to include(s)
      end
    end

    it "should not return courses with invited StudentEnrollment or ObserverEnrollment when state[]=unpublished" do
      @course4.enrollments.each do |e|
        e.type = 'StudentEnrollment'
        e.role_id = student_role.id
        e.save!
      end
      json = api_call(:get, "/api/v1/courses.json",
                      { :controller => 'courses', :action => 'index', :format => 'json' },
                      { :state => ['unpublished'] })
      expect(json.collect{ |c| c['id'].to_i }.sort).to eq [@course3.id]

      @course3.enrollments.each do |e|
        e.type = 'ObserverEnrollment'
        e.role_id = observer_role.id
        e.save!
      end
      json = api_call(:get, "/api/v1/courses.json",
                      { :controller => 'courses', :action => 'index', :format => 'json' },
                      { :state => ['unpublished'] })
      expect(json.collect{ |c| c['id'].to_i }).to eq []
    end

    it "should return courses with active StudentEnrollment or ObserverEnrollment when state[]=unpublished" do
      @course3.enrollments.each do |e|
        e.type = 'ObserverEnrollment'
        e.role_id = observer_role.id
        e.workflow_state = "active"
        e.save!
      end
      @course4.enrollments.each do |e|
        e.type = 'StudentEnrollment'
        e.role_id = student_role.id
        e.workflow_state = "active"
        e.save!
      end
      json = api_call(:get, "/api/v1/courses.json",
                      { :controller => 'courses', :action => 'index', :format => 'json' },
                      { :state => ['unpublished'] })
      expect(json.collect{ |c| c['id'].to_i }.sort).to eq [@course3.id, @course4.id]
    end
  end

  context "course list + sharding" do
    specs_require_sharding

    before :once do
      @shard1.activate { @student = User.create!(name: 'outofshard') }
      enrollment = @course1.enroll_student(@student)
    end

    it "returns courses for out-of-shard users" do
      @user = @student
      json = api_call(:get, "/api/v1/courses.json",
        { :controller => 'courses', :action => 'index', :format => 'json' },
        { :state => ['available'] })

      expect(json.size).to eq(1)
      expect(json.first['id']).to eq(@course1.id)
    end

    it "returns courses relative to root account shard when looking at other users" do
      account_admin_user(:active_all => true)
      json = api_call(:get, "/api/v1/users/#{@student.id}/courses",
        { :controller => 'courses', :action => 'user_index', :user_id => @student.id.to_s, :format => 'json' })

      expect(json.size).to eq(1)
      expect(json.first['id']).to eq(@course1.id)
    end
  end

  describe "root account filter" do
    before :once do
      @course1 = course_with_student(account: Account.default, active_all: true).course
      @course2 = course_with_student(account: account_model(name: 'other root account'), user: @student, active_all: true).course
    end

    it "should not filter by default" do
      json = api_call(:get, "/api/v1/courses.json",
                      { :controller => 'courses', :action => 'index', :format => 'json' })
      expect(json.map { |c| c['id'] }).to match_array [@course1.id, @course2.id]
    end

    it "should accept current_domain_only=true" do
      json = api_call(:get, "/api/v1/courses.json?current_domain_only=true",
                      { :controller => 'courses', :action => 'index', :format => 'json',
                        :current_domain_only => 'true' })
      expect(json.map { |c| c['id'] }).to eql [@course1.id]
    end

    it "should accept root_account_id=self" do
      json = api_call(:get, "/api/v1/courses.json?root_account_id=self",
                      { :controller => 'courses', :action => 'index', :format => 'json',
                        :root_account_id => 'self' })
      expect(json.map { |c| c['id'] }).to eql [@course1.id]
    end

    it "should accept root_account_id=id" do
      json = api_call(:get, "/api/v1/courses.json?root_account_id=#{@course2.root_account.id}",
                      { :controller => 'courses', :action => 'index', :format => 'json',
                        :root_account_id => @course2.root_account.to_param })
      expect(json.map { |c| c['id'] }).to eql [@course2.id]
    end

    it "should return an empty result if the given root account does not exist" do
      json = api_call(:get, "/api/v1/courses.json?root_account_id=0",
                      { :controller => 'courses', :action => 'index', :format => 'json',
                        :root_account_id => '0' })
      expect(json).to eql([])
    end
  end

  describe "/students" do
    it "should return the list of students for the course" do
      first_user = @user
      new_user = User.create!(:name => 'Zombo')
      @course2.enroll_student(new_user).accept!
      RoleOverride.create!(:context => Account.default, :permission => 'read_sis', :role => teacher_role, :enabled => false)

      json = api_call(:get, "/api/v1/courses/#{@course2.id}/students.json",
                      { :controller => 'courses', :action => 'students', :course_id => @course2.id.to_s, :format => 'json' })
      expect(json.sort_by{|x| x["id"]}).to eq api_json_response([first_user, new_user],
                                                            :only => user_api_fields).sort_by{|x| x["id"]}
    end

    it "should not include user sis id or login id for non-admins" do
      first_user = @user
      new_user = User.create!(:name => 'Zombo')
      @course2.enroll_student(new_user).accept!
      RoleOverride.create!(:context => Account.default, :permission => 'read_sis', :role => teacher_role, :enabled => false)

      @user = @me
      json = api_call(:get, "/api/v1/courses/#{@course2.id}/students.json",
                      { :controller => 'courses', :action => 'students', :course_id => @course2.id.to_s, :format => 'json' })
      %w{sis_user_id unique_id}.each do |attribute|
        expect(json.map { |u| u[attribute] }).to eq [nil, nil]
      end
    end

    it "should include user sis id and login id if account admin" do
      @course2.account.account_users.create!(user: @me)
      first_user = @user
      new_user = user_with_pseudonym(:name => 'Zombo', :username => 'nobody2@example.com')
      @course2.enroll_student(new_user).accept!
      new_user.pseudonym.update_attribute(:sis_user_id, 'user2')

      @user = @me
      json = api_call(:get, "/api/v1/courses/#{@course2.id}/students.json",
                      { :controller => 'courses', :action => 'students', :course_id => @course2.id.to_s, :format => 'json' })
      expect(json.map { |u| u['sis_user_id'] }.sort).to eq ['user1', 'user2'].sort
      expect(json.map { |u| u['login_id'] }.sort).to eq ["nobody@example.com", "nobody2@example.com"].sort
    end

    it "should include user sis id and login id if can manage_students in the course" do
      expect(@course1.grants_right?(@me, :manage_students)).to be_truthy
      first_student = user_with_pseudonym(:name => 'Zombo', :username => 'nobody2@example.com')
      @course1.enroll_student(first_student).accept!
      first_student.pseudonym.update_attribute(:sis_user_id, 'user2')
      second_student = user_with_pseudonym(:name => 'second student', :username => 'nobody3@example.com')
      @course1.enroll_student(second_student).accept!
      second_student.pseudonym.update_attribute(:sis_user_id, 'user3')

      @user = @me
      json = api_call(:get, "/api/v1/courses/#{@course1.id}/students.json",
                      { :controller => 'courses', :action => 'students', :course_id => @course1.to_param, :format => 'json' })
      expect(json.map { |u| u['sis_user_id'] }.sort).to eq ['user2', 'user3'].sort
      expect(json.map { |u| u['login_id'] }.sort).to eq ['nobody2@example.com', 'nobody3@example.com'].sort
    end

    it "should include user sis id and login id if site admin" do
      Account.site_admin.account_users.create!(user: @me)
      first_user = @user
      new_user = user_with_pseudonym(:name => 'Zombo', :username => 'nobody2@example.com')
      @course2.enroll_student(new_user).accept!
      new_user.pseudonym.update_attribute(:sis_user_id, 'user2')

      @user = @me
      json = api_call(:get, "/api/v1/courses/#{@course2.id}/students.json",
                      { :controller => 'courses', :action => 'students', :course_id => @course2.id.to_s, :format => 'json' })
      expect(json.map { |u| u['sis_user_id'] }.sort).to eq ['user1', 'user2'].sort
      expect(json.map { |u| u['login_id'] }.sort).to eq ["nobody@example.com", "nobody2@example.com"].sort
    end

    it "should allow specifying course sis id" do
      first_user = @user
      new_user = User.create!(:name => 'Zombo')
      @course2.update_attribute(:sis_source_id, 'TEST-SIS-ONE.2011')
      @course2.enroll_student(new_user).accept!
      ro = RoleOverride.create!(:context => Account.default, :permission => 'read_sis', :role => teacher_role, :enabled => false)

      json = api_call(:get, "/api/v1/courses/sis_course_id:TEST-SIS-ONE.2011/students.json",
                      { :controller => 'courses', :action => 'students', :course_id => 'sis_course_id:TEST-SIS-ONE.2011', :format => 'json' })
      expect(json.sort_by{|x| x["id"]}).to eq api_json_response([first_user, new_user],
                                                            :only => user_api_fields).sort_by{|x| x["id"]}

      @course2.enroll_teacher(@user).accept!
      ro.destroy
      json = api_call(:get, "/api/v1/courses/sis_course_id:TEST-SIS-ONE.2011.json",
                      { :controller => 'courses', :action => 'show', :id => 'sis_course_id:TEST-SIS-ONE.2011', :format => 'json' })
      expect(json['id']).to eq @course2.id
      expect(json['sis_course_id']).to eq 'TEST-SIS-ONE.2011'
    end

    it "should not be paginated (for legacy reasons)" do
      controller = double()
      allow(controller).to receive(:params).and_return({})
      course_with_teacher(:active_all => true)
      num = Api.per_page_for(controller) + 1 # get the default api per page value
      create_users_in_course(@course, num)
      json = api_call(:get, "/api/v1/courses/#{@course.id}/students.json",
                      { :controller => 'courses', :action => 'students', :course_id => @course.id.to_s, :format => 'json' })
      expect(json.count).to eq num
    end
  end

  describe "users" do
    before :once do
      @section1 = @course1.default_section
      @section2 = @course1.course_sections.create!(:name => 'Section B')
      @ta = user_factory(:name => 'TAPerson')
      @ta.communication_channels.create!(:path => 'ta@ta.com') { |cc| cc.workflow_state = 'confirmed' }
      @ta_enroll1 = @course1.enroll_user(@ta, 'TaEnrollment', :section => @section1)
      @ta_enroll2 = @course1.enroll_user(@ta, 'TaEnrollment', :section => @section2, :allow_multiple_enrollments => true)

      @student1 = user_factory(:name => 'SSS1')
      @student2 = user_factory(:name => 'SSS2')
      @student1_enroll = @course1.enroll_user(@student1, 'StudentEnrollment', :section => @section1)
      @student2_enroll = @course1.enroll_user(@student2, 'StudentEnrollment', :section => @section2)

      @test_student = @course1.student_view_student
    end

    describe "search users" do
      let(:api_url) { "/api/v1/courses/#{@course1.id}/users.json" }
      let(:api_route) do
        {
          :controller => 'courses',
          :action => 'users',
          :course_id => @course1.id.to_s,
          :format => 'json'
        }
      end

      it "returns an error when search_term is fewer than 3 characters" do
        json = api_call(:get, api_url, api_route, {:search_term => 'ab'}, {}, :expected_status => 400)
        error = json["errors"].first
        verify_json_error(error, "search_term", "invalid", "3 or more characters is required")
      end

      it "returns a list of users" do
        json = api_call(:get, api_url, api_route, :search_term => "TAP")

        sorted_users = json.sort_by{ |x| x["id"] }
        expected_users =
          api_json_response(
            @course1.users.select{ |u| u.name == 'TAPerson' },
            :only => user_api_fields)

        expect(sorted_users).to eq expected_users

        # this endpoint doesn't exist, but we maintain the route for backwards compat
        json = api_call(:get, "/api/v1/courses/#{@course1.id}/search_users",
                        { controller: 'courses', action: 'users', course_id: @course1.to_param, format: 'json' },
                        :search_term => "TAP")
        sorted_users = json.sort_by{ |x| x["id"] }
        expect(sorted_users).to eq expected_users
      end

      it "returns concluded enrollments if ?enrollment_state[]=concluded" do
        @ta.enrollments.each(&:conclude)

        json = api_call(:get, api_url, api_route, :enrollment_state => ["invited","active"], :search_term => "TAP")
        ta_users = json.select{ |u| u["name"] == "TAPerson" }
        expect(ta_users).to be_empty

        json = api_call(:get, api_url, api_route, :enrollment_state => ["invited","active","completed"], :search_term => "TAP")
        ta_users = json.select{ |u| u["name"] == "TAPerson" }
        expect(ta_users).not_to be_empty
      end

      it "returns enrollments when filtering by enrollment_state" do
        @ta.enrollments.each(&:conclude)

        json = api_call(:get, api_url, api_route, :enrollment_state => ["completed"], :include => ["enrollments"], :search_term => "TAP")
        ta_users = json.select{ |u| u["name"] == "TAPerson" }
        expect(ta_users).not_to be_empty
        expect(ta_users.first['enrollments']).to be_present
      end

      it "returns active and invited enrollments if no enrollment state is given" do
        json = api_call(:get, api_url, api_route, :search_term => "TAP")
        ta_users = json.select{ |u| u["name"] == "TAPerson" }
        expect(ta_users).not_to be_empty

        @ta.enrollments.each(&:conclude)

        json = api_call(:get, api_url, api_route, :search_term => "TAP")
        ta_users = json.select{ |u| u["name"] == "TAPerson" }
        expect(ta_users).to be_empty
      end

      it "accepts a list of enrollment_types" do
        ta2 = user_factory(:name => 'SSS Helper')
        ta2_enroll1 = @course1.enroll_user(ta2, 'TaEnrollment', :section => @section1)

        student3 = user_factory(:name => 'T1')
        student3_enroll = @course1.enroll_user(student3, 'StudentEnrollment', :section => @section2)

        json = api_call(:get, api_url, api_route, :search_term => "SSS", :enrollment_type => ["student","ta"])

        sorted_users = json.sort_by{ |x| x["id"] }
        expected_users =
          api_json_response(
            @course1.users.select{ |u| ['SSS Helper', 'SSS1', 'SSS2'].include? u.name },
            :only => user_api_fields)

        expect(sorted_users).to eq expected_users.sort_by{ |x| x["id"] }
      end

      it "respects limit option (as pagination)" do
        json = api_call(:get, api_url, api_route, :search_term => "SSS", :limit => 1)
        expect(json.length).to eq 1
        link_header = response.headers['Link'].split(',')
        expect(link_header[0]).to match /page=1&per_page=1/ # current page
        expect(link_header[1]).to match /page=2&per_page=1/ # next page
        expect(link_header[2]).to match /page=1&per_page=1/ # first page
      end

      it "should respect includes" do
        @user = @course1.teachers.first
        @ta.profile.bio = 'hey'
        @ta.save!
        @ta_enroll1.accept!
        @course1.root_account.settings[:enable_profiles] = true
        @course1.root_account.save!

        json = api_call(:get, api_url, api_route, :search_term => "TAPerson", :include => ['email', 'bio'])

        expect(json).to eq [
          {
            'id' => @ta.id,
            'name' => 'TAPerson',
            'sortable_name' => 'TAPerson',
            'short_name' => 'TAPerson',
            'sis_user_id' =>nil,
            'integration_id' =>nil,
            'email' => 'ta@ta.com',
            'bio' => 'hey'
          }
        ]
      end

      context "avatar_url" do
        before(:once) do
          @course1.root_account.set_service_availability(:avatars, true)
          @course1.root_account.save!
          @ta.avatar_image = { 'type' => 'gravatar', 'url' => 'http://www.gravatar.com/ta.jpg' }
          @ta.save!
        end

        it "includes avatar_url if requested" do
          json = api_call(:get, api_url, api_route, :include => ['avatar_url'])
          expect(json.detect { |item| item['id'] == @ta.id }['avatar_url']).to eq 'http://www.gravatar.com/ta.jpg'
          expect(json.detect { |item| item['id'] == @student.id }['avatar_url']).to eq 'http://www.example.com/images/messages/avatar-50.png'
        end

        it "omits fallbacks if requested" do
          json = api_call(:get, api_url, api_route, :include => ['avatar_url'], :no_avatar_fallback => '1')
          expect(json.detect { |item| item['id'] == @ta.id }['avatar_url']).to eq 'http://www.gravatar.com/ta.jpg'
          expect(json.detect { |item| item['id'] == @student.id }['avatar_url']).to be_nil
        end
      end

      context "sharding" do
        specs_require_sharding

        it "should load the user's enrollment for an out-of-shard user" do
          @shard1.activate { @user = User.create!(name: 'outofshard') }
          enrollment = @course1.enroll_student(@user)
          @course1.root_account.pseudonyms.create!(user: @user, unique_id: 'outofshard')

          json = api_call(:get, api_url, api_route, search_term: 'outofshard', include: ['enrollments'])

          expect(json.length).to eq 1
          expect(json.first['id']).to eq @user.id
          expect(json.first['enrollments']).to be_present
          expect(json.first['enrollments'].length).to eq 1
          expect(json.first['enrollments'].first['id']).to eq enrollment.id
        end
      end
    end

    describe "/users" do
      let(:api_url) {"/api/v1/courses/#{@course1.id}/users.json"}
      let(:api_route) do
        {
          controller: 'courses',
          action: 'users',
          course_id: @course1.id.to_s,
          format: 'json'
        }
      end

      it "returns an empty array for a page past the end" do
        json = api_call(:get, "/api/v1/courses/#{@course1.id}/users.json?page=5",
                        controller: 'courses',
                        action: 'users',
                        course_id: @course1.id.to_s,
                        page: '5',
                        format: 'json')
        expect(json).to eq []
      end

      it "returns a 404 for an otherwise invalid page" do
        raw_api_call(:get, "/api/v1/courses/#{@course1.id}/users.json?page=invalid",
                     controller: 'courses',
                     action: 'users',
                     course_id: @course1.id.to_s,
                     page: 'invalid',
                     format: 'json')
        assert_status(404)
      end

      it "returns a list of users" do
        json = api_call(:get, api_url, api_route)
        expected_users = @course1.users.to_a.uniq - [@test_student]
        expect(json.sort_by {|x| x["id"]}).to eq api_json_response(expected_users,
                                                                   only: user_api_fields).sort_by {|x| x["id"]}
      end

      it "returns a list of users filtered by id if user_ids is given" do
        expected_users = [@student1, @student2]
        json = api_call(:get, api_url, {
          controller: 'courses',
          action: 'users',
          course_id: @course1.id.to_s,
          user_ids: expected_users.map(&:id),
          format: 'json'
        })
        expect(json.sort_by {|x| x["id"]}).to eq api_json_response(
                                                   expected_users,
                                                   only: user_api_fields
                                                 ).sort_by {|x| x["id"]}
      end

      it "excludes the test student by default" do
        @course1.student_view_student
        json = api_call(:get, "/api/v1/courses/#{@course1.id}/users.json",
                        {controller: 'courses', action: 'users', course_id: @course1.id.to_s, format: 'json'})
        expect(json.map {|s| s["name"]}).not_to include("Test Student")
      end

      context "inactive enrollments" do
        before do
          @inactive_user = user_with_pseudonym(:name => "Inactive User")
          student_in_course(:course => @course1, :user => @inactive_user)
          @inactive_enroll = @inactive_user.enrollments.first
          @inactive_enroll.deactivate
        end

        it "excludes users with inactive enrollments for students" do
          student_in_course(course: @course1, active_all: true, user: user_with_pseudonym)
          json = api_call(:get, api_url, api_route)
          expect(json.map{ |s| s["id"] }).not_to include(@inactive_user.id)
        end

        it "includes users with inactive enrollments for teachers" do
          @user = @course1.teachers.first
          json = api_call(:get, api_url, api_route, include: ['enrollments'], include_inactive: true)
          expect(json.map{ |s| s["id"] }).to include(@inactive_user.id)
          user_json = json.detect{ |s| s["id"] == @inactive_user.id}
          expect(user_json['enrollments'].map{|e| e['id']}).to eq [@inactive_enroll.id]
          expect(user_json['enrollments'].first['enrollment_state']).to eq 'inactive'
        end

        it 'does not include inactive enrollments by default' do
          @admin = account_admin_user(user: user_with_pseudonym, account: @course.account, active_all: true)
          json = api_call(:get, api_url, api_route)
          expect(json.count).to eq 5
          json = api_call(:get, api_url, api_route, include_inactive: true)
          expect(json.count).to eq 6
        end
      end

      it "includes the test student if told to do so" do
        @course1.student_view_student
        json = api_call(:get, "/api/v1/courses/#{@course1.id}/users.json",
          { :controller => 'courses', :action => 'users', :course_id => @course1.id.to_s, :format => 'json'},
          :include => ['test_student'] )
        expect(json.map{ |s| s["name"] }).to include("Test Student")
      end

      it "returns a list of users with emails (unless unconfirmed)" do
        secretstudent = user_with_pseudonym(:username => 'secretuser@example.com', :active_all => true)
        @course1.enroll_student(secretstudent) #don't accept
        @user = @course1.teachers.first
        json1 = api_call(:get, "/api/v1/courses/#{@course1.id}/users.json",
                        { :controller => 'courses', :action => 'users', :course_id => @course1.id.to_s, :format => 'json' },
                        :include => ['email'])

        json2 = api_call(:get, "/api/v1/courses/#{@course1.id}/users.json",
          { :controller => 'courses', :action => 'users', :course_id => @course1.id.to_s, :format => 'json' },
          :include => ['email', 'enrollments']) # should work either way

        [json1, json2].each do |json|
          normal = json.detect{|h| h['id'] == @user.id}
          expect(normal['email']).to eq @user.email
          expect(normal['login_id']).to eq @user.pseudonym.unique_id

          secret = json.detect{|h| h['id'] == secretstudent.id}
          expect(secret.keys & %w{email login_id}).to be_empty
        end
      end

      it "returns a list of users and enrollments with enrollments option" do
        json = api_call(:get, "/api/v1/courses/#{@course1.id}/users.json",
                        { :controller => 'courses', :action => 'users', :course_id => @course1.id.to_s, :format => 'json' },
                        :include => ['enrollments'])
        # helper
        check_json = lambda { |user, *enrollments|
          j = json.find { |x| x['id'] == user.id }
          expect(j.delete('enrollments').map { |e| e['id'] }.sort).
            to eq enrollments.map(&:id)
          expect(j).to eq api_json_response(user, :only => user_api_fields)
        }
        # expect
        check_json.call(@ta, @ta_enroll1, @ta_enroll2)
        check_json.call(@student1, @student1_enroll)
        check_json.call(@student2, @student2_enroll)
      end

      it "doesn't return enrollments from another course" do
        other_enroll = @course2.enroll_user(@student1, 'StudentEnrollment')
        json = api_call(:get, "/api/v1/courses/#{@course1.id}/users.json",
                        { :controller => 'courses', :action => 'users', :course_id => @course1.id.to_s, :format => 'json' },
                        :include => ['enrollments'])
        enroll_ids = json.find { |x| x['id'] == @student1.id }['enrollments'].map { |e| e['id'] }.sort
        expect(enroll_ids).to eq [@student1_enroll.id]
      end

      it "optionally filters users by enrollment_type" do
        json = api_call(:get, "/api/v1/courses/#{@course1.id}/users.json",
                        { :controller => 'courses', :action => 'users', :course_id => @course1.id.to_s, :format => 'json' },
                        :enrollment_type => 'student')
        expect(json.map {|x| x["id"]}.sort).to eq api_json_response([@student1, @student2],
                                                                :only => user_api_fields).map {|x| x["id"]}.sort
      end

      it "should accept an array of enrollment_types" do
        json = api_call(:get, "/api/v1/courses/#{@course1.id}/users",
                        {:controller => 'courses', :action => 'users', :course_id => @course1.to_param, :format => 'json' },
                        :enrollment_type => ['student', 'student_view', 'teacher'], :include => ['enrollments'])

        expect(json.map { |u| u['enrollments'].map { |e| e['type'] } }.flatten.uniq.sort).to eq %w{StudentEnrollment StudentViewEnrollment TeacherEnrollment}
      end

      describe "enrollment_role" do
        before :once do
          role = Account.default.roles.build :name => 'EliteStudent'
          role.base_role_type = 'StudentEnrollment'
          role.save!
          @student3 = user_factory(:name => 'S3')
          @student3_enroll = @course1.enroll_user(@student3, 'StudentEnrollment', { :role => role })
        end

        it "should return all student types with ?enrollment_type=student" do
          json = api_call(:get, "/api/v1/courses/#{@course1.id}/users.json",
                          { :controller => 'courses', :action => 'users', :course_id => @course1.id.to_s, :format => 'json' },
                          :enrollment_type => 'student')

          expect(json.map {|x| x["id"].to_i}.sort).to eq [@student1, @student2, @student3].map(&:id).sort
        end

        it "should return only base student types with ?enrollment_role=StudentEnrollment" do
          json = api_call(:get, "/api/v1/courses/#{@course1.id}/users.json",
                          { :controller => 'courses', :action => 'users', :course_id => @course1.id.to_s, :format => 'json' },
                          :enrollment_role => 'StudentEnrollment')

          expect(json.map {|x| x["id"].to_i}.sort).to eq [@student1, @student2].map(&:id).sort
        end

        it "should return users with a custom role type" do
          json = api_call(:get, "/api/v1/courses/#{@course1.id}/users.json",
                          { :controller => 'courses', :action => 'users', :course_id => @course1.id.to_s, :format => 'json' },
                          :enrollment_role => 'EliteStudent')

          expect(json.map {|x| x["id"].to_i}).to eq [@student3.id]
        end

        it "should accept an array of enrollment roles" do
          json = api_call(:get, "/api/v1/courses/#{@course1.id}/users.json",
                          { :controller => 'courses', :action => 'users', :course_id => @course1.id.to_s, :format => 'json' },
                          :enrollment_role => %w{StudentEnrollment EliteStudent})

          expect(json.map {|x| x["id"].to_i}.sort).to eq [@student1, @student2, @student3].map(&:id).sort
        end
      end

      describe "enrollment_role_id" do
        before :once do
          @role = Account.default.roles.build :name => 'EliteStudent'
          @role.base_role_type = 'StudentEnrollment'
          @role.save!
          @student3 = user_factory(:name => 'S3')
          @student3_enroll = @course1.enroll_user(@student3, 'StudentEnrollment', { :role => @role })
        end

        it "should return only base student types with ?enrollment_role_id=(built_in_role id)" do
          json = api_call(:get, "/api/v1/courses/#{@course1.id}/users.json",
                          { :controller => 'courses', :action => 'users', :course_id => @course1.id.to_s, :format => 'json' },
                          :enrollment_role_id => student_role.id)

          expect(json.map {|x| x["id"].to_i}.sort).to eq [@student1, @student2].map(&:id).sort
        end

        it "should return users with a custom role type" do
          json = api_call(:get, "/api/v1/courses/#{@course1.id}/users.json",
                          { :controller => 'courses', :action => 'users', :course_id => @course1.id.to_s, :format => 'json' },
                          :enrollment_role_id => @role.id)

          expect(json.map {|x| x["id"].to_i}).to eq [@student3.id]
        end

        it "should accept an array of enrollment roles" do
          json = api_call(:get, "/api/v1/courses/#{@course1.id}/users.json",
                          { :controller => 'courses', :action => 'users', :course_id => @course1.id.to_s, :format => 'json' },
                          :enrollment_role_id => [student_role.id, @role.id])

          expect(json.map {|x| x["id"].to_i}.sort).to eq [@student1, @student2, @student3].map(&:id).sort
        end
      end

      it "maintains query parameters in link headers" do
        json = api_call(
          :get,
          "/api/v1/courses/#{@course1.id}/users.json",
          { :controller => 'courses', :action => 'users', :course_id => @course1.id.to_s, :format => 'json' },
          { :enrollment_type => 'student', :maintain_params => '1', :per_page => 1 })
        links = response['Link'].split(",")
        expect(links).not_to be_empty
        expect(links.all?{ |l| l =~ /enrollment_type=student/ }).to be_truthy
        expect(links.first.scan(/per_page/).length).to eq 1
      end

      it "should not include sis user id or login id for non-admins" do
        RoleOverride.create!(:context => Account.default, :permission => 'read_sis', :role => teacher_role, :enabled => false)
        student_in_course(:course => @course2, :active_all => true, :name => 'Zombo')

        @user = @me # @me is a student in course 2
        json = api_call(:get, "/api/v1/courses/#{@course2.id}/users.json",
                        { :controller => 'courses', :action => 'users', :course_id => @course2.id.to_s, :format => 'json' },
                        :enrollment_type => 'student')
        expect(json.length).to eq 2
        %w{sis_user_id unique_id}.each do |attribute|
          expect(json.map { |u| u[attribute] }).to eq [nil, nil]
        end
      end

      it "should include user sis id and login id if account admin" do
        @course2.account.account_users.create!(user: @me)
        first_user = @user
        new_user = user_with_pseudonym(:name => 'Zombo', :username => 'nobody2@example.com')
        @course2.enroll_student(new_user).accept!
        new_user.pseudonym.update_attribute(:sis_user_id, 'user2')

        @user = @me
        json = api_call(:get, "/api/v1/courses/#{@course2.id}/users.json",
                        { :controller => 'courses', :action => 'users', :course_id => @course2.id.to_s, :format => 'json' },
                        :enrollment_type => 'student')
        expect(json.map { |u| u['sis_user_id'] }.sort).to eq ['user1', 'user2'].sort
        expect(json.map { |u| u['login_id'] }.sort).to eq ["nobody@example.com", "nobody2@example.com"].sort
      end

      it "should include user sis id and login id if can manage_students in the course" do
        expect(@course1.grants_right?(@me, :manage_students)).to be_truthy
        first_student = user_with_pseudonym(:name => 'Zombo', :username => 'nobody2@example.com')
        @course1.enroll_student(first_student).accept!
        first_student.pseudonym.update_attribute(:sis_user_id, 'user2')
        second_student = user_with_pseudonym(:name => 'second student', :username => 'nobody3@example.com')
        @course1.enroll_student(second_student).accept!
        second_student.pseudonym.update_attribute(:sis_user_id, 'user3')

        @user = @me
        json = api_call(:get, "/api/v1/courses/#{@course1.id}/users.json",
                        { :controller => 'courses', :action => 'users', :course_id => @course1.to_param, :format => 'json' },
                        :enrollment_type => 'student')
        expect(json.map { |u| u['sis_user_id'] }.compact.sort).to eq ['user2', 'user3'].sort
        expect(json.map { |u| u['login_id'] }.compact.sort).to eq ['nobody2@example.com', 'nobody3@example.com'].sort
      end

      it "should include user sis id and login id if site admin" do
        Account.site_admin.account_users.create!(user: @me)
        first_user = @user
        new_user = user_with_pseudonym(:name => 'Zombo', :username => 'nobody2@example.com')
        @course2.enroll_student(new_user).accept!
        new_user.pseudonym.update_attribute(:sis_user_id, 'user2')

        @user = @me
        json = api_call(:get, "/api/v1/courses/#{@course2.id}/users.json",
                        { :controller => 'courses', :action => 'users', :course_id => @course2.id.to_s, :format => 'json' },
                        :enrollment_type => 'student')
        expect(json.map { |u| u['sis_user_id'] }.sort).to eq ['user1', 'user2'].sort
        expect(json.map { |u| u['login_id'] }.sort).to eq ["nobody@example.com", "nobody2@example.com"].sort
      end

      describe "localized sorting" do
        before do
          skip("require pg_collkey") unless ActiveRecord::Base.connection.extension_installed?(:pg_collkey)
        end

        it "should use course-level locale setting for sorting" do
          n1 = "bee"
          @student1.update_attribute(:sortable_name, n1)
          n2 = "æee"
          @student2.update_attribute(:sortable_name, n2)
          json = api_call(:get, "/api/v1/courses/#{@course1.id}/users.json", { :controller => 'courses', :action => 'users', :course_id => @course1.id.to_s, :format => 'json' })
          names = json.map{|s| s["sortable_name"]}
          expect(names.index(n1) > names.index(n2)).to be_truthy

          @course1.update_attribute(:locale, "is")
          json = api_call(:get, "/api/v1/courses/#{@course1.id}/users.json", { :controller => 'courses', :action => 'users', :course_id => @course1.id.to_s, :format => 'json' })
          names = json.map{|s| s["sortable_name"]}
          expect(names.index(n2) > names.index(n1)).to be_truthy
        end
      end

      describe "as a student" do
        before :once do
          @other_user = user_with_pseudonym(:name => 'Waldo', :username => 'dontfindme@example.com')
          @other_user.pseudonym.update_attribute(:sis_user_id, 'mysis_8675309')
          @course1.enroll_student(@other_user).accept!

          @user = user_factory
          @course1.enroll_student(@user).accept!
        end

        it "should not return email addresses" do
          json = api_call(:get, "/api/v1/courses/#{@course1.to_param}/users",
                          { :controller => 'courses', :action => 'users',
                          :course_id => @course1.to_param, :format => 'json' },
                          { :include => %w{email} })
          json.each do |u|
            if u['id'] == @user.id
              expect(u['email']).to eq @user.email
            else
              expect(u.keys).not_to include(:email)
            end
          end
        end

        it "should search by name" do
          json = api_call(:get, "/api/v1/courses/#{@course1.to_param}/users",
                          { :controller => 'courses', :action => 'users',
                            :course_id => @course1.to_param, :format => 'json' },
                          { :search_term => 'wal' })
          expect(json.count).to eq 1
          expect(json.first['id']).to eq @other_user.id
        end

        it "should not search by email address" do
          json = api_call(:get, "/api/v1/courses/#{@course1.to_param}/users",
                          { :controller => 'courses', :action => 'users',
                            :course_id => @course1.to_param, :format => 'json' },
                          { :search_term => 'dont' })
          expect(json).to be_empty
        end

        it "should not search by sis id" do
          json = api_call(:get, "/api/v1/courses/#{@course1.to_param}/users",
                          { :controller => 'courses', :action => 'users',
                            :course_id => @course1.to_param, :format => 'json' },
                          { :search_term => 'mysis' })
          expect(json).to be_empty
        end
      end

      it "should allow specifying course sis id" do
        @user = @me
        first_user = @user
        new_user = User.create!(:name => 'Zombo')
        @course2.update_attribute(:sis_source_id, 'TEST-SIS-ONE.2011')
        @course2.enroll_student(new_user).accept!
        ro = RoleOverride.create!(:context => Account.default, :permission => 'read_sis', :role => teacher_role, :enabled => false)

        json = api_call(:get, "/api/v1/courses/sis_course_id:TEST-SIS-ONE.2011/users.json",
                        { :controller => 'courses', :action => 'users', :course_id => 'sis_course_id:TEST-SIS-ONE.2011', :format => 'json' },
                        :enrollment_type => 'student')
        expect(json.sort_by{|x| x["id"]}).to eq api_json_response([first_user, new_user],
                                                              :only => user_api_fields).sort_by{|x| x["id"]}

        @course2.enroll_teacher(@user).accept!
        ro.destroy
        json = api_call(:get, "/api/v1/courses/sis_course_id:TEST-SIS-ONE.2011.json",
                        { :controller => 'courses', :action => 'show', :id => 'sis_course_id:TEST-SIS-ONE.2011', :format => 'json' },
                        :enrollment_type => 'student')
        expect(json['id']).to eq @course2.id
        expect(json['sis_course_id']).to eq 'TEST-SIS-ONE.2011'
      end

      it "should paginate unique users correctly" do
        students = [@student1, @student2]
        section2 = @course1.course_sections.create!(:name => 'Section B')

        user_ids = create_users_in_course(@course1, 8)
        create_enrollments(@course1, user_ids, section_id: section2.id)

        json = api_call(:get, "/api/v1/courses/#{@course1.id}/users.json",
                        { :controller => 'courses', :action => 'users', :course_id => @course1.id.to_s, :format => 'json' },
                        { :enrollment_type => 'student', :page => 1, :per_page => 5 })
        expect(json.map{|x| x['id']}.uniq.length).to eq 5

        link_header = response.headers['Link'].split(',')
        expect(link_header[0]).to match /page=1&per_page=5/ # current page
        expect(link_header[1]).to match /page=2&per_page=5/ # next page
        expect(link_header[2]).to match /page=1&per_page=5/ # first page
        expect(link_header[3]).to match /page=2&per_page=5/ # last page
      end

      it "should allow jumping to a user's page based on id" do
        @other_section = @course1.course_sections.create!
        students = create_users(5.times.map{ |i| {name: "User #{i+1}", sortable_name: "#{i+1}, User"} }, return_type: :record)
        create_enrollments(@course1, students)
        create_enrollments(@course1, students, section_id: @other_section.id)
        @target = students[4]
        json = api_call(:get, "/api/v1/courses/#{@course1.id}/users.json",
                        { :controller => 'courses', :action => 'users', :course_id => @course1.id.to_s, :format => 'json' },
                        { :enrollment_type => 'student', :user_id => @target.id, :page => 1, :per_page => 1 })
        expect(json.map{|x| x['id']}.length).to eq 1
        expect(json.map{|x| x['id']}).to eq [@target.id]
      end

      it "includes custom links if requested" do
        json = api_call(:get, "/api/v1/courses/#{@course1.id}/users.json?include[]=custom_links",
                        { :controller => 'courses', :action => 'users', :course_id => @course1.id.to_s,
                          :format => 'json', :include => %w(custom_links) })
        expect(json.first).to have_key 'custom_links'
      end
    end

    it "should include observed users in the enrollments if requested" do
      @student1.name = "student 1"
      @student2.save!
      @student2.name = "student 2"
      @student2.save!

      observer1 = user_factory
      observer2 = user_factory

      @course1.enroll_user(observer1, "ObserverEnrollment", :associated_user_id => @student1.id)
      @course1.enroll_user(observer2, "ObserverEnrollment", :associated_user_id => @student2.id)
      @course1.enroll_user(observer1, "ObserverEnrollment", :allow_multiple_enrollments => true, :associated_user_id => @student2.id)

      @user = @me
      json = api_call(:get, "/api/v1/courses/#{@course1.id}/users.json",
          { :controller => 'courses', :action => 'users', :course_id => @course1.id.to_s, :format => 'json' },
          :include => ['email', 'enrollments', 'observed_users'])

      enrollments1 = json.find{|u| u['id'] == observer1.id}['enrollments']
      expect(enrollments1.map{|e| e['observed_user']['id']}.sort).to eq [@student1.id, @student2.id]

      enrollments2 = json.find{|u| u['id'] == observer2.id}['enrollments']
      expect(enrollments2.map{|e| e['observed_user']['id']}.sort).to eq [@student2.id]

      expect(enrollments2.first['observed_user']['enrollments'].map{|e| e['id']}).to eq [@student2.enrollments.first.id]
    end
  end

  describe "user" do
    it "should allow searching for user by sis id" do
      student = student_in_course(course: @course1, name: "student").user
      pseudonym = pseudonym(student)
      pseudonym.sis_user_id = "sis_1"
      pseudonym.save!

      json = api_call(:get, "/api/v1/courses/#{@course1.id}/users/sis_user_id:#{pseudonym.sis_user_id}.json",
        { controller: 'courses', action: 'user', course_id: @course1.id.to_s, id: "sis_user_id:#{pseudonym.sis_user_id}", :format => 'json' })
      expect(response.code).to eq '200'
    end

    it "shouldn't show other course enrollments to other students" do
      @me = @student
      student2 = student_in_course(course: @course1, name: "student").user
      @course2.enroll_student(student2)
      json = api_call(:get, "/api/v1/courses/#{@course1.id}/users/#{student2.id}.json?include[]=enrollments",
        { controller: 'courses', action: 'user', course_id: @course1.id.to_s, id: student2.id.to_s, include: ['enrollments'], :format => 'json' })
      course_ids = json["enrollments"].map{|e| e["course_id"]}
      expect(course_ids).to eq [@course1.id]
    end
  end

  it "should return the needs_grading_count for all assignments" do
    @group = @course1.assignment_groups.create!({:name => "some group"})
    @assignment = @course1.assignments.create!(:title => "some assignment", :assignment_group => @group, :points_possible => 12)
    student_in_course(:course => @course1, :active_all => true)
    @assignment.submit_homework(@user, :body => 'test!', 'submission_type' => 'online_text_entry')
    @user = @me

    json = api_call(:get, "/api/v1/courses.json?enrollment_type=teacher&include[]=needs_grading_count",
            { :controller => 'courses', :action => 'index', :format => 'json', :enrollment_type => 'teacher', :include=>["needs_grading_count"] })

    expect(json.length).to eq 1
    expect(json[0]).to include(
      'id' => @course1.id,
      'needs_grading_count' => 1,
    )
  end

  it "should return the course syllabus" do
    should_translate_user_content(@course1) do |content|
      @course1.syllabus_body = content
      @course1.save!
      json = api_call(:get, "/api/v1/courses.json?enrollment_type=teacher&include[]=syllabus_body",
            { :controller => 'courses', :action => 'index', :format => 'json', :enrollment_type => 'teacher', :include=>["syllabus_body"] })
      json[0]['syllabus_body']
    end
  end

  describe "#show" do
    it "should get individual course data" do
      @course1.root_account.update_attributes(:default_time_zone => 'America/Los_Angeles')
      json = api_call(:get, "/api/v1/courses/#{@course1.id}.json",
              { :controller => 'courses', :action => 'show', :id => @course1.to_param, :format => 'json' })

      expect(json).to eq({
        'id' => @course1.id,
        'name' => @course1.name,
        'account_id' => @course1.account_id,
        'root_account_id' => @course1.root_account_id,
        'course_code' => @course1.course_code,
        'enrollments' => [{'type' => 'teacher', 'role' => 'TeacherEnrollment', 'role_id' => teacher_role.id, 'user_id' => @me.id, 'enrollment_state' => 'active'}],
        'grading_standard_id' => nil,
        'sis_course_id' => @course1.sis_course_id,
        'integration_id' => nil,
        'calendar' => { 'ics' => "http://www.example.com/feeds/calendars/course_#{@course1.uuid}.ics" },
        'hide_final_grades' => @course1.hide_final_grades,
        'start_at' => @course1.start_at,
        'end_at' => @course1.end_at,
        'default_view' => @course1.default_view,
        'public_syllabus' => @course1.public_syllabus,
        'public_syllabus_to_auth' => @course1.public_syllabus_to_auth,
        'is_public' => @course1.is_public,
        'is_public_to_auth_users' => @course1.is_public_to_auth_users,
        'workflow_state' => @course1.workflow_state,
        'storage_quota_mb' => @course1.storage_quota_mb,
        'apply_assignment_group_weights' => false,
        'enrollment_term_id' => @course.enrollment_term_id,
        'restrict_enrollments_to_course_dates' => false,
        'time_zone' => 'America/Los_Angeles',
        'uuid' => @course1.uuid
      })
    end

    it "should map 'created' to 'unpublished'" do
      @course1.workflow_state = 'created'
      @course1.save!
      json = api_call(:get, "/api/v1/courses/#{@course1.id}.json",
              { :controller => 'courses', :action => 'show', :id => @course1.to_param, :format => 'json' })
      expect(json['workflow_state']).to eq 'unpublished'
    end

    it "should map 'claimed' to 'unpublished'" do
      @course1.workflow_state = 'claimed'
      @course1.save!
      json = api_call(:get, "/api/v1/courses/#{@course1.id}.json",
              { :controller => 'courses', :action => 'show', :id => @course1.to_param, :format => 'json' })
      expect(json['workflow_state']).to eq 'unpublished'
    end

    it "should allow sis id in hex packed format" do
      sis_id = 'This.Sis/Id\\Has Nasty?Chars'
      # sis_id.unpack('H*').first
      packed_sis_id = '546869732e5369732f49645c486173204e617374793f4368617273'
      @course1.update_attribute(:sis_source_id, sis_id)
      json = api_call(:get, "/api/v1/courses/hex:sis_course_id:#{packed_sis_id}.json",
                      {:controller => 'courses', :action => 'show', :id => "hex:sis_course_id:#{packed_sis_id}", :format => 'json'})
      expect(json['id']).to eq @course1.id
      expect(json['sis_course_id']).to eq sis_id
    end

    it "should not find courses in other root accounts" do
      acct = account_model(:name => 'root')
      acct.account_users.create!(user: @user)
      course_factory(:account => acct)
      @course.update_attribute('sis_source_id', 'OTHER-SIS')
      raw_api_call(:get, "/api/v1/courses/sis_course_id:OTHER-SIS",
                   :controller => "courses", :action => "show", :id => "sis_course_id:OTHER-SIS", :format => "json")
      assert_status(404)
    end

    it 'should include permissions' do
      # Make sure it only returns permissions when asked
      json = api_call(:get, "/api/v1/courses/#{@course1.id}.json", { :controller => 'courses', :action => 'show', :id => @course1.to_param, :format => 'json' })
      expect(json).to_not include "permissions"

      # When its asked to return permissions make sure they are there
      json = api_call(:get, "/api/v1/courses/#{@course1.id}.json?include[]=permissions", { :controller => 'courses', :action => 'show', :id => @course1.to_param, :format => 'json', :include => [ "permissions" ] })
      expect(json).to include "permissions"
    end

    it 'should include permission create_discussion_topic' do
      json = api_call(:get, "/api/v1/courses/#{@course1.id}.json?include[]=permissions", { :controller => 'courses', :action => 'show', :id => @course1.to_param, :format => 'json', :include => [ "permissions" ] })
      expect(json).to include "permissions"
      expect(json["permissions"]).to include "create_discussion_topic"
    end

    it 'should include permission create_announcement' do
      json = api_call(:get, "/api/v1/courses/#{@course1.id}.json?include[]=permissions", { :controller => 'courses', :action => 'show', :id => @course1.to_param, :format => 'json', :include => [ "permissions" ] })
      expect(json).to include "permissions"
      expect(json["permissions"]).to include "create_announcement"
      expect(json["permissions"]["create_announcement"]).to be_truthy # The setup makes this user a teacher of the course too
    end

    it 'should include grading_standard_id' do
      standard = grading_standard_for @course1
      @course1.update_attribute(:grading_standard_id, standard.id)
      json = api_call(:get, "/api/v1/courses/#{@course1.id}.json", { :controller => 'courses', :action => 'show',
                                                                     :id => @course1.to_param, :format => 'json' })
      expect(json['grading_standard_id']).to eq(standard.id)
    end

    it 'includes tabs if requested' do
      json = api_call(:get, "/api/v1/courses/#{@course1.id}.json?include[]=tabs",
        { :controller => 'courses', :action => 'show', :id => @course1.to_param, :format => 'json', :include => ['tabs'] })
      expect(json).to have_key 'tabs'
      expected_tabs = [
        "home", "announcements", "assignments", "discussions", "grades", "people",
        "pages", "files", "syllabus", "outcomes", "quizzes", "modules", "settings"
      ]
      expect(json['tabs'].map{ |tab| tab['id'] }).to match_array(expected_tabs)
    end

    context "when scoped to account" do
      before :once do
        @admin = account_admin_user(:account => @course.account, :active_all => true)
        user_with_pseudonym(:user => @admin)
      end

      it "should 401 for unauthorized users" do
        other_account = Account.create!
        other_course = other_account.courses.create!
        json = api_call(:get, "/api/v1/accounts/#{other_account.id}/courses/#{other_course.id}.json",
                          {:controller => 'courses', :action => 'show', :id => other_course.to_param, :format => 'json', :account_id => other_account.id.to_param},
                          {}, {}, :expected_status => 401)
      end

      it "should 404 for bad account id" do
        json = api_call(:get, "/api/v1/accounts/0/courses/#{@course.id}.json",
                          {:controller => 'courses', :action => 'show', :id => @course.id.to_param, :format => 'json', :account_id => '0'},
                          {}, {}, :expected_status => 404)
      end

      context "when course is active" do

        it "should find the course" do
          json = api_call(:get, "/api/v1/accounts/#{@course.account.id}/courses/#{@course.id}.json",
              { :controller => 'courses', :action => 'show', :id => @course.to_param, :format => 'json', :account_id => @course.account.id.to_param })

          expect(json['id']).to eq @course.id
        end

        it "should scope to specified account" do
          other_account = Account.create!
          c2 = other_account.courses.create!
          json = api_call(:get, "/api/v1/accounts/#{@course.account.id}/courses/#{c2.id}.json",
                          {:controller => 'courses', :action => 'show', :id => c2.to_param, :format => 'json', :account_id => @course.account.id.to_param},
                          {}, {}, :expected_status => 404)
        end

        it "should find courses in sub accounts" do
          sub_account = @course.account.sub_accounts.create!
          c2 = sub_account.courses.create!
          json = api_call(:get, "/api/v1/accounts/#{sub_account.id}/courses/#{c2.id}.json",
                          {:controller => 'courses', :action => 'show', :id => c2.to_param, :format => 'json', :account_id => sub_account.id.to_param})
          expect(json['id']).to eq c2.id
        end

        it "should not find courses in sibling accounts" do
          sub = @course.account.sub_accounts.create!
          c2 = sub.courses.create!
          sub2 = @course.account.sub_accounts.create!
          json = api_call(:get, "/api/v1/accounts/#{sub2.id}/courses/#{c2.id}.json",
                          {:controller => 'courses', :action => 'show', :id => c2.to_param, :format => 'json', :account_id => sub2.id.to_param},
                          {}, {}, :expected_status => 404)
        end
      end

      context "when course is deleted" do
        before :once do
          @course.destroy
        end

        it "should return 404" do
          json = api_call(:get, "/api/v1/accounts/#{@course.account.id}/courses/#{@course.id}.json",
              { :controller => 'courses', :action => 'show', :id => @course.to_param, :format => 'json', :account_id => @course.account.id.to_param },
                          {}, {}, :expected_status => 404)
        end

        it "should find a course if include all specified" do
          json = api_call(:get, "/api/v1/accounts/#{@course.account.id}/courses/#{@course.id}.json?include[]=all_courses",
              { :controller => 'courses', :action => 'show', :id => @course.to_param, :format => 'json', :account_id => @course.account.id.to_param, :include=>["all_courses"] })

          expect(json['id']).to eq @course.id
          expect(json['workflow_state']).to eq 'deleted'
        end
      end
    end
  end

  context "course files" do
    include_examples "file uploads api with folders"
    include_examples "file uploads api with quotas"

    before :each do
      @context = @course
    end

    def preflight(preflight_params, opts = {})
      @user = @teacher
      api_call(:post, "/api/v1/courses/#{@course.id}/files",
        { :controller => "courses", :action => "create_file", :format => "json", :course_id => @course.to_param, },
        preflight_params,
        {},
        opts)
    end

    def has_query_exemption?
      false
    end

    def context
      @course
    end

    it "should require the correct permission to upload" do
      @user = student_in_course(:course => @course).user
      api_call(:post, "/api/v1/courses/#{@course.id}/files",
        { :controller => "courses", :action => "create_file", :format => "json", :course_id => @course.to_param, },
        { :name => 'failboat.txt' }, {}, :expected_status => 401)
    end

    it "should create the file in unlocked state if :usage_rights_required is disabled" do
      @course.disable_feature! 'usage_rights_required'
      preflight({ :name => 'test' })
      attachment = Attachment.order(:id).last
      expect(attachment.locked).to be_falsy
    end

    it "should create the file in locked state if :usage_rights_required is enabled" do
      @course.enable_feature! 'usage_rights_required'
      preflight({ :name => 'test' })
      attachment = Attachment.order(:id).last
      expect(attachment.locked).to be_truthy
    end
  end

  describe "/settings" do
    before :once do
      course_with_teacher(:active_all => true)
    end

    it "should render settings json" do
      json = api_call(:get, "/api/v1/courses/#{@course.id}/settings", {
        :controller => 'courses',
        :action => 'settings',
        :course_id => @course.to_param,
        :format => 'json'
      })
      expect(json).to eq({
        'allow_student_discussion_topics' => true,
        'allow_student_forum_attachments' => false,
        'allow_student_discussion_editing' => true,
        'grading_standard_enabled' => false,
        'grading_standard_id' => nil,
        'allow_student_organized_groups' => true,
        'hide_distribution_graphs' => false,
        'hide_final_grades' => false,
        'lock_all_announcements' => false,
        'restrict_student_past_view' => false,
        'restrict_student_future_view' => false,
        'show_announcements_on_home_page' => false,
        'home_page_announcement_limit' => nil,
        'image_url' => nil,
        'image_id' => nil,
        'image' => nil
      })
    end

    it "should update settings" do
      expect(Auditors::Course).to receive(:record_updated).
        with(anything, anything, anything, source: :api)

      json = api_call(:put, "/api/v1/courses/#{@course.id}/settings", {
        :controller => 'courses',
        :action => 'update_settings',
        :course_id => @course.to_param,
        :format => 'json'
      }, {
        :allow_student_discussion_topics => false,
        :allow_student_forum_attachments => true,
        :allow_student_discussion_editing => false,
        :allow_student_organized_groups => false,
        :hide_distribution_graphs => true,
        :hide_final_grades => true,
        :lock_all_announcements => true,
        :restrict_student_past_view => true,
        :restrict_student_future_view => true,
        :show_announcements_on_home_page => false,
        :home_page_announcement_limit => nil
      })
      expect(json).to eq({
        'allow_student_discussion_topics' => false,
        'allow_student_forum_attachments' => true,
        'allow_student_discussion_editing' => false,
        'grading_standard_enabled' => false,
        'grading_standard_id' => nil,
        'allow_student_organized_groups' => false,
        'hide_distribution_graphs' => true,
        'hide_final_grades' => true,
        'lock_all_announcements' => true,
        'restrict_student_past_view' => true,
        'restrict_student_future_view' => true,
        'show_announcements_on_home_page' => false,
        'home_page_announcement_limit' => nil,
        'image_url' => nil,
        'image_id' => nil,
        'image' => nil
      })
      @course.reload
      expect(@course.allow_student_discussion_topics).to eq false
      expect(@course.allow_student_forum_attachments).to eq true
      expect(@course.allow_student_discussion_editing).to eq false
      expect(@course.allow_student_organized_groups).to eq false
      expect(@course.hide_distribution_graphs).to eq true
      expect(@course.hide_final_grades).to eq true
      expect(@course.lock_all_announcements).to eq true
      expect(@course.show_announcements_on_home_page).to eq false
      expect(@course.home_page_announcement_limit).to be_falsey
    end
  end

  describe "/recent_students" do
    before :once do
      course_with_teacher(:active_all => true)
      @student1 = student_in_course(:active_all => true, :name => "Sheldon Cooper").user
      @student2 = student_in_course(:active_all => true, :name => "Leonard Hofstadter").user
      @student3 = student_in_course(:active_all => true, :name => "Howard Wolowitz").user
      pseudonym(@student1) # no login info
      pseudonym(@student2).tap{|p| p.current_login_at = 1.days.ago; p.save!}
      pseudonym(@student3).tap{|p| p.current_login_at = 2.days.ago; p.save!}
    end

    it "should include the last_login information" do
      @user = @teacher
      json = api_call(:get, "/api/v1/courses/#{@course.id}/recent_students",
                      { :controller => 'courses', :action => 'recent_students', :course_id => @course.to_param, :format => 'json' })
      expect(json.map{ |el| el['last_login'] }.compact).not_to be_empty
    end

    it "should sort by last_login" do
      @user = @teacher
      json = api_call(:get, "/api/v1/courses/#{@course.id}/recent_students",
                      { :controller => 'courses', :action => 'recent_students', :course_id => @course.to_param, :format => 'json' })
      expect(json.map{ |el| el['id'] }).to eq [@student2.id, @student3.id, @student1.id]
    end
  end

  describe "/preview_html" do
    before :once do
      course_with_teacher(:active_all => true)
    end

    it "should sanitize html and process links" do
      @user = @teacher
      attachment_model(:context => @course)
      html = %{<p><a href="/files/#{@attachment.id}/download?verifier=huehuehuehue">Click!</a><script></script></p>}
      json = api_call(:post, "/api/v1/courses/#{@course.id}/preview_html",
                      { :controller => 'courses', :action => 'preview_html', :course_id => @course.to_param, :format => 'json' },
                      { :html => html})

      returned_html = json["html"]
      expect(returned_html).not_to include("<script>")
      expect(returned_html).to include("/courses/#{@course.id}/files/#{@attachment.id}/download?verifier=#{@attachment.uuid}")
    end

    it "should require permission to preview" do
      @user = user_factory
      api_call(:post, "/api/v1/courses/#{@course.id}/preview_html",
                      { :controller => 'courses', :action => 'preview_html', :course_id => @course.to_param, :format => 'json' },
                      { :html => ""}, {}, {:expected_status => 401})

    end
  end

  it "should return the activity stream" do
    discussion_topic_model
    json = api_call(:get, "/api/v1/courses/#{@course.id}/activity_stream.json",
                    { controller: "courses", course_id: @course.id.to_s, action: "activity_stream", format: 'json' })
    expect(json.size).to eq 1
  end

  it "should return the activity stream summary" do
    discussion_topic_model
    json = api_call(:get, "/api/v1/courses/#{@course.id}/activity_stream/summary.json",
                    { controller: "courses", course_id: @course.id.to_s, action: "activity_stream_summary", format: 'json' })
    expect(json).to eq [{"type" => "DiscussionTopic", "count" => 1, "unread_count" => 1, "notification_category" => nil}]
  end

  it "should update activity time" do
    expect(@enrollment.last_activity_at).to be_nil
    api_call(:post, "/api/v1/courses/#{@course.id}/ping",
                    { controller: "courses", course_id: @course.id.to_s, action: "ping", format: 'json' })
    @enrollment.reload
    expect(@enrollment.last_activity_at).not_to be_nil
  end
end

def each_copy_option
  [[:assignments, :assignments], [:external_tools, :context_external_tools], [:files, :attachments],
   [:topics, :discussion_topics], [:calendar_events, :calendar_events], [:quizzes, :quizzes],
   [:modules, :context_modules], [:outcomes, :created_learning_outcomes]].each{|o| yield o}
end

describe ContentImportsController, type: :request do
  before :once do
    course_with_teacher(:active_all => true, :name => 'origin story')
    @copy_from = @course
    @copy_from.sis_source_id = 'from_course'

    # create one of everything that can be copied
    group = @course.assignment_groups.create!(:name => 'group1')
    @course.assignments.create!(:title => 'Assignment 1', :points_possible => 10, :assignment_group => group)
    @copy_from.discussion_topics.create!(:title => "Topic 1", :message => "<p>watup?</p>")
    @copy_from.syllabus_body = "haha"
    @copy_from.wiki_pages.create!(:title => "some page", :body => 'hi')
    @copy_from.context_external_tools.create!(:name => "new tool", :consumer_key => "key", :shared_secret => "secret", :domain => 'example.com')
    Attachment.create!(:filename => 'wut.txt', :display_name => "huh?", :uploaded_data => StringIO.new('uh huh.'), :folder => Folder.unfiled_folder(@copy_from), :context => @copy_from)
    @copy_from.calendar_events.create!(:title => 'event', :description => 'hi', :start_at => 1.day.from_now)
    @copy_from.context_modules.create!(:name => "a module")
    @copy_from.quizzes.create!(:title => 'quiz')
    @copy_from.root_outcome_group.add_outcome(@copy_from.created_learning_outcomes.create!(:short_description => 'oi', :context => @copy_from))
    @copy_from.save!

    course_with_teacher(:active_all => true, :name => 'whatever', :user => @user)
    @copy_to = @course
    @copy_to.sis_source_id = 'to_course'
    @copy_to.save!
  end

  def run_copy(to_id=nil, from_id=nil, options={})
    to_id ||= @copy_to.to_param
    from_id ||= @copy_from.to_param
    data = api_call(:post, "/api/v1/courses/#{to_id}/course_copy",
            { :controller => 'content_imports', :action => 'copy_course_content', :course_id => to_id, :format => 'json' },
    {:source_course => from_id}.merge(options))

    cm = ContentMigration.order(:id).last
    expect(data).to eq({
      'id' => cm.id,
      'progress' => nil,
      'status_url' => "http://www.example.com/api/v1/courses/#{@copy_to.to_param}/course_copy/#{cm.id}",
      'created_at' => cm.created_at.as_json,
      'workflow_state' => 'created',
    })

    status_url = data['status_url']

    api_call(:get, status_url, { :controller => 'content_imports', :action => 'copy_course_status', :course_id => @copy_to.to_param, :id => data['id'].to_param, :format => 'json' })
    (JSON.parse(response.body)).tap do |res|
      expect(res['workflow_state']).to eq 'started'
      expect(res['progress']).to eq 0
    end

    run_jobs
    cm.reload
    expect(cm.old_warnings_format).to eq []
    expect(cm.content_export.error_messages).to eq []

    api_call(:get, status_url, { :controller => 'content_imports', :action => 'copy_course_status', :course_id => @copy_to.to_param, :id => data['id'].to_param, :format => 'json' })
    (JSON.parse(response.body)).tap do |res|
      expect(res['workflow_state']).to eq 'completed'
      expect(res['progress']).to eq 100
    end
  end

  def run_unauthorized(to_id, from_id)
    status = raw_api_call(:post, "/api/v1/courses/#{to_id}/course_copy",
            { :controller => 'content_imports', :action => 'copy_course_content', :course_id => to_id, :format => 'json' },
    {:source_course => from_id})
    expect(status).to eq 401
  end

  def run_not_found(to_id, from_id)
    status = raw_api_call(:post, "/api/v1/courses/#{to_id}/course_copy",
            { :controller => 'content_imports', :action => 'copy_course_content', :course_id => to_id, :format => 'json' },
    {:source_course => from_id})
    assert_status(404)
  end

  def run_only_copy(option)
    run_copy(nil, nil, {:only => [option]})
  end

  def run_except_copy(option)
    run_copy(nil, nil, {:except => [option]})
  end

  def check_counts(expected_count, skip = nil)
    each_copy_option do |option, association|
      next if skip && option == skip
      next if !Qti.qti_enabled? && association == :quizzes
      expect(@copy_to.send(association).count).to eq expected_count
    end
  end

  it "should copy a course with canvas id" do
    run_copy
    check_counts 1
  end

  it "should log copied event to course activity" do
    expect(Auditors::Course).to receive(:record_copied).once
    run_copy
  end

  it "should copy a course using sis ids" do
    run_copy('sis_course_id:to_course', 'sis_course_id:from_course')
    check_counts 1
  end

  it "should not allow copying into an unauthorized course" do
    course_with_teacher_logged_in(:active_all => true, :name => 'origin story')
    run_unauthorized(@copy_to.to_param, @course.to_param)
  end

  it "should not allow copying from an unauthorized course" do
    course_with_teacher_logged_in(:active_all => true, :name => 'origin story')
    run_unauthorized(@course.to_param, @copy_from.to_param)
  end

  it "should return 404 for a source course that isn't found" do
    run_not_found(@copy_to.to_param, "0")
  end

  it "should return 404 for a destination course that isn't found" do
    run_not_found("0", @copy_from.to_param)
  end

  it "should return 404 for an import that isn't found" do
    raw_api_call(:get, "/api/v1/courses/#{@copy_to.id}/course_copy/444",
                 { :controller => 'content_imports', :action => 'copy_course_status', :course_id => @copy_to.to_param, :id => '444', :format => 'json' })
    assert_status(404)
  end

  it "shouldn't allow both only and except options" do
    raw_api_call(:post, "/api/v1/courses/#{@copy_to.id}/course_copy",
            { :controller => 'content_imports', :action => 'copy_course_content', :course_id => @copy_to.to_param, :format => 'json' },
    {:source_course => @copy_from.to_param, :only => [:topics], :except => [:assignments]})
    assert_status(400)
    json = JSON.parse(response.body)
    expect(json['errors']).to eq 'You can not use "only" and "except" options at the same time.'
  end

  it "should only copy course settings" do
    @copy_from.default_view = 'modules'
    @copy_from.save!
    run_only_copy(:course_settings)
    check_counts 0
    @copy_to.reload
    expect(@copy_to.default_view).to eq 'modules'
  end

  it "should only copy wiki pages" do
    run_only_copy(:wiki_pages)
    check_counts 0
    expect(@copy_to.wiki_pages.count).to eq 1
  end

  each_copy_option do |option, association|
    it "should only copy #{option}" do
      skip if !Qti.qti_enabled? && association == :quizzes
      run_only_copy(option)
      expect(@copy_to.send(association).count).to eq 1
      check_counts(0, option)
    end
  end

  it "should skip copy course settings" do
    run_except_copy(:course_settings)
    check_counts 1
    @copy_to.reload
    expect(@copy_to.syllabus_body).to eq nil
  end
  it "should skip copy wiki pages" do
    run_except_copy(:wiki_pages)
    check_counts 1
    expect(@copy_to.wiki_pages.count).to eq 0
  end
  each_copy_option do |option, association|
    it "should skip copy #{option}" do
      run_except_copy(option)
      expect(@copy_to.send(association).count).to eq 0
      check_counts(1, option)
    end
  end

  it "should create and retrieve link validation results" do
    course_with_teacher_logged_in(:active_all => true, :name => 'validayshun')

    # shouldn't have started
    json = api_call(:get, "/api/v1/courses/#{@course.id}/link_validation",
      { :controller => 'courses', :action => 'link_validation', :format => 'json', :course_id => @course.id.to_param })
    expect(json).to be_empty

    # start
    json = api_call(:post, "/api/v1/courses/#{@course.id}/link_validation",
      { :controller => 'courses', :action => 'start_link_validation', :format => 'json', :course_id => @course.id.to_param })
    expect(json).to eq({'success' => true})

    # check queued state
    json = api_call(:get, "/api/v1/courses/#{@course.id}/link_validation",
      { :controller => 'courses', :action => 'link_validation', :format => 'json', :course_id => @course.id.to_param })
    expect(json['workflow_state']).to eq('queued')
    expect(json).not_to have_key('results')

    allow_any_instance_of(CourseLinkValidator).to receive(:check_course)
    allow_any_instance_of(CourseLinkValidator).to receive(:issues).and_return(['mock_issue'])
    run_jobs

    # check results
    json = api_call(:get, "/api/v1/courses/#{@course.id}/link_validation",
                    { :controller => 'courses', :action => 'link_validation', :format => 'json', :course_id => @course.id.to_param })
    expect(json['workflow_state']).to eq('completed')
    expect(json['results']['issues']).to eq(['mock_issue'])
  end
end

describe CoursesController, type: :request do
  before(:once) do
    @now = Time.zone.now
    @test_course = Course.create!
    @teacher = course_with_teacher(course: @test_course, active_all: true).user
    @test_student = student_in_course(course: @test_course, active_all: true).user
    @assignment1 = @test_course.assignments.create!(due_at: 5.days.ago(@now))
    @assignment2 = @test_course.assignments.create!(due_at: 10.days.from_now(@now))
    @effective_due_dates_path = "/api/v1/courses/#{@test_course.id}/effective_due_dates"
    @options = { controller: "courses", action: "effective_due_dates", format: "json", course_id: @test_course.id }
    # api_call sets up session based on @user; i'd rather set it here explicitly than make our
    # course_with_teacher and student_in_course calls order-dependent
    @user = @teacher
  end

  describe "#effective_due_dates" do
    context "permissions" do
      it "allows teachers to access the information" do
        api_call(:get, @effective_due_dates_path, @options, {}, {}, expected_status: 200)
      end

      it "does not allow teachers to from other courses to access the information" do
        new_course = Course.create!
        @user = course_with_teacher(course: new_course, active_all: true).user
        api_call(:get, @effective_due_dates_path, @options, {}, {}, expected_status: 401)
      end

      it "allows TAs to access the information" do
        @user = ta_in_course(course: @test_course, active_all: true).user
        api_call(:get, @effective_due_dates_path, @options, {}, {}, expected_status: 200)
      end

      it "allows admins to access the information" do
        @user = @test_course.root_account.users.create!
        api_call(:get, @effective_due_dates_path, @options, {}, {}, expected_status: 200)
      end

      it "does not allow students to access the information" do
        @user = @test_student
        api_call(:get, @effective_due_dates_path, @options, {}, {}, expected_status: 401)
      end
    end

    it "returns a key for each assignment in the course" do
      json = api_call(:get, @effective_due_dates_path, @options)
      expect(json.keys).to contain_exactly(@assignment1.id.to_s, @assignment2.id.to_s)
    end

    it "returns a subset of assignments if specific assignment ids are requested" do
      json = api_call(:get, @effective_due_dates_path, @options.merge(assignment_ids: [@assignment2.id]))
      expect(json.keys).to contain_exactly(@assignment2.id.to_s)
    end

    it "returns all assignments if the assignment_ids param is not an array" do
      json = api_call(:get, @effective_due_dates_path, @options.merge(assignment_ids: @assignment2.id))
      expect(json.keys).to contain_exactly(@assignment1.id.to_s, @assignment2.id.to_s)
    end

    it "each assignment only contains keys for students that are assigned to it" do
      @new_student = student_in_course(course: @test_course, active_all: true).user
      override = @assignment1.assignment_overrides.create!(
        due_at: 10.days.from_now(@now),
        due_at_overridden: true
      )
      override.assignment_override_students.create!(user: @new_student)
      @assignment1.due_at = nil
      @assignment1.only_visible_to_overrides = true
      @assignment1.save!
      @user = @teacher

      json = api_call(:get, @effective_due_dates_path, @options)
      student_ids = json[@assignment1.id.to_s].keys
      expect(student_ids).to contain_exactly(@new_student.id.to_s)
    end

    it "returns the effective due at along with grading period information" do
      json = api_call(:get, @effective_due_dates_path, @options)
      due_date_info = json[@assignment1.id.to_s][@student.id.to_s]
      expected_attributes = ["due_at", "grading_period_id", "in_closed_grading_period"]
      expect(due_date_info.keys).to match_array(expected_attributes)
    end
  end
end

describe CoursesController, type: :request do
  describe "course#user(s)" do
    let_once(:account) { Account.default }
    let_once(:test_course) { account.courses.create! }
    let_once(:grading_period) do
      group = account.grading_period_groups.create!(title: "Score Test Group")
      group.enrollment_terms << test_course.enrollment_term
      Factories::GradingPeriodHelper.new.create_presets_for_group(group, :current)
      group.grading_periods.first
    end
    let_once(:student) { student_in_course(course: test_course, active_all: true) }
    let_once(:teacher) { teacher_in_course(course: test_course, active_all: true) }

    before(:once) do
      student.scores.create!(grading_period_id: grading_period.id,
                             current_score: 100, final_score: 50,
                             unposted_current_score: 70, unposted_final_score: 60)
      student.scores.create!(current_score: 80, final_score: 74,
                             unposted_current_score: 75, unposted_final_score: 86)
    end

    context "users endpoint with mgp" do
      let(:users_path) {"/api/v1/courses/#{test_course.id}/users?include[]=enrollments" }
      let(:users_options) do
        {
          controller: "courses",
          action: "users",
          format: "json",
          course_id: test_course.id,
          include: ['enrollments']
        }
      end

      it "uses the total score by default" do
        json = api_call_as_user(teacher.user, :get, users_path, users_options)
        grades = json.find { |j| j['id'] == student.user.id }.dig('enrollments', 0, 'grades')

        expect(grades).to include({
          "current_score" => 80.0,
          "final_score" => 74.0,
          "unposted_current_score" => 75.0,
          "unposted_final_score" => 86.0
        })
      end

      it "uses the current grading period score if requested" do
        path = "#{users_path}&include[]=current_grading_period_scores"
        users_options[:include] << 'current_grading_period_scores'

        json = api_call_as_user(teacher.user, :get, path, users_options)
        grades = json.find { |j| j['id'] == student.user.id }.dig('enrollments', 0, 'grades')

        expect(grades).to include({
          "current_score" => 100.0,
          "final_score" => 50.0,
          "unposted_current_score" => 70.0,
          "unposted_final_score" => 60.0,
          "grading_period_id" => grading_period.id
        })
      end
    end

    context "user endpoint with mgp" do
      let(:user_path) do
        "/api/v1/courses/#{test_course.id}/users/#{student.user.id}?include[]=enrollments"
      end
      let(:user_options) do
        {
          controller: "courses",
          action: "user",
          format: "json",
          course_id: test_course.id,
          id: student.user.id,
          include: ['enrollments']
        }
      end

      it "uses the total score by default" do
        json = api_call_as_user(teacher.user, :get, user_path, user_options)
        grades = json.dig('enrollments', 0, 'grades')

        expect(grades).to include({
          "current_score" => 80.0,
          "final_score" => 74.0,
          "unposted_current_score" => 75.0,
          "unposted_final_score" => 86.0
        })
      end

      it "uses the current grading period score if requested" do
        path = "#{user_path}&include[]=current_grading_period_scores"
        user_options[:include] << 'current_grading_period_scores'

        json = api_call_as_user(teacher.user, :get, path, user_options)
        grades = json.dig('enrollments', 0, 'grades')

        expect(grades).to include({
          "current_score" => 100.0,
          "final_score" => 50.0,
          "unposted_current_score" => 70.0,
          "unposted_final_score" => 60.0,
          "grading_period_id" => grading_period.id
        })
      end
    end
  end
end
