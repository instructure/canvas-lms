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
      expect(@test_api.course_json(@course1, @me, {}, [], []).has_key?("html_url")).to be_falsey
    end

    it 'should only include needs_grading_count if requested' do
      expect(@test_api.course_json(@course1, @me, {}, [], [teacher_enrollment]).has_key?("needs_grading_count")).to be_falsey
    end

    it 'should honor needs_grading_count for teachers' do
      expect(@test_api.course_json(@course1, @me, {}, ['needs_grading_count'], [teacher_enrollment]).has_key?("needs_grading_count")).to be_truthy
    end

    it 'should not honor needs_grading_count for designers' do
      @designer_enrollment = @course1.enroll_designer(@me)
      @designer_enrollment.accept!
      expect(@test_api.course_json(@course1, @me, {}, ['needs_grading_count'], [@designer_enrollment]).has_key?("needs_grading_count")).to be_falsey
    end

    it 'should include apply_assignment_group_weights' do
      expect(@test_api.course_json(@course1, @me, {}, [], []).has_key?("apply_assignment_group_weights")).to be_truthy
    end

    it "should include course progress" do
      mod = @course2.context_modules.create!(:name => "some module", :require_sequential_progress => true)
      assignment = @course2.assignments.create!(:title => "some assignment")
      tag = mod.add_item({:id => assignment.id, :type => 'assignment'})
      mod.completion_requirements = {tag.id => {:type => 'must_submit'}}
      mod.require_sequential_progress = true
      mod.publish
      mod.save!

      class CourseProgress
        def course_context_modules_item_redirect_url(opts = {})
          "course_context_modules_item_redirect_url(:course_id => #{opts[:course_id]}, :id => #{opts[:id]}, :host => HostUrl.context_host(Course.find(#{opts[:course_id]}))"
        end
      end

      json = @test_api.course_json(@course2, @me, {}, ['course_progress'], [])
      expect(json).to include('course_progress')
      expect(json['course_progress']).to eq({
        'requirement_count' => 1,
        'requirement_completed_count' => 0,
        'next_requirement_url' => "course_context_modules_item_redirect_url(:course_id => #{@course2.id}, :id => #{tag.id}, :host => HostUrl.context_host(Course.find(#{@course2.id}))",
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

    context "total_scores" do
      before do
        @enrollment.computed_current_score = 95.0;
        @enrollment.computed_final_score = 85.0;
        def @course.grading_standard_enabled?; true; end
      end

      let(:json) { @test_api.course_json(@course1, @me, {}, ['total_scores'], [@enrollment]) }

      it "should include computed scores" do
        expect(json['enrollments']).to eq [{
          "type" => "student",
          "role" => student_role.name,
          "role_id" => student_role.id,
          "enrollment_state" => "active",
          "computed_current_score" => 95,
          "computed_final_score" => 85,
          "computed_current_grade" => "A",
          "computed_final_grade" => "B"
        }]
      end
    end
  end

  describe '#add_helper_dependant_entries' do
    let(:hash) { Hash.new }
    let(:course) { stub_everything( :feed_code => 573, :id => 42, :syllabus_body => 'syllabus text' ) }
    let(:course_json) { stub_everything() }
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
      let(:course_json){ stub( :include_syllabus => false, :include_url => false ) }

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
      let(:course_json){ stub( :include_syllabus => true, :include_url => true ) }

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
  USER_API_FIELDS = %w(id name sortable_name short_name)

  before :once do
    course_with_teacher(:active_all => true, :user => user_with_pseudonym(:name => 'UWP'))
    @me = @user
    @course1 = @course
    course_with_student(:user => @user, :active_all => true)
    @course2 = @course
    @course2.update_attribute(:sis_source_id, 'TEST-SIS-ONE.2011')
    @course2.update_attribute(:default_view, 'wiki')
    @user.pseudonym.update_attribute(:sis_user_id, 'user1')
  end

  before :each do
    Course.any_instance.stubs(:start_at).returns nil
    Course.any_instance.stubs(:end_at).returns nil
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

    courses = json.select { |c| c.has_key?("permissions") }
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

      before :each do
        Course.any_instance.unstub(:start_at, :end_at)
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
          }
        }
        course_response = post_params['course'].merge({
          'account_id' => @account.id,
          'root_account_id' => @account.id,
          'enrollment_term_id' => term.id,
          'integration_id' => nil,
          'start_at' => '2011-01-01T07:00:00Z',
          'end_at' => '2011-05-01T07:00:00Z',
          'workflow_state' => 'available',
          'default_view' => 'feed',
          'storage_quota_mb' => @account.default_storage_quota_mb
        })
        Auditors::Course.expects(:record_created).once
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
        course_response.merge!(
          'id' => new_course.id,
          'calendar' => { 'ics' => "http://www.example.com/feeds/calendars/course_#{new_course.uuid}.ics" }
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
            'public_description'                   => 'Nature is lethal but it doesn\'t hold a candle to man.',
          }
        }
        course_response = post_params['course'].merge({
          'account_id' => @account.id,
          'root_account_id' => @account.id,
          'enrollment_term_id' => term.id,
          'integration_id' => nil,
          'start_at' => '2011-01-01T07:00:00Z',
          'end_at' => '2011-05-01T07:00:00Z',
          'workflow_state' => 'available',
          'default_view' => 'feed',
          'storage_quota_mb' => @account.default_storage_quota_mb
        })
        json = api_call(:post, @resource_path, @resource_params, post_params)
        new_course = Course.find(json['id'])
        expect(new_course.enrollment_term_id).to eql term.id
        course_response.merge!(
          'id' => new_course.id,
          'calendar' => { 'ics' => "http://www.example.com/feeds/calendars/course_#{new_course.uuid}.ics" }
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
        Auditors::Course.expects(:record_published).once
        json = api_call(:post, @resource_path,
          @resource_params,
          { :account_id => @account.id, :offer => true, :course => { :name => 'Test Course' } }
        )
        new_course = Course.find(json['id'])
        expect(new_course).to be_available
      end

      it "should allow setting sis_course_id without offering the course" do
        Auditors::Course.expects(:record_created).once
        Auditors::Course.expects(:record_published).never
        json = api_call(:post, @resource_path,
          @resource_params,
          { :account_id => @account.id, :course => { :name => 'Test Course', :sis_course_id => '9999' } }
        )
        new_course = Course.find(json['id'])
        expect(new_course.sis_source_id).to eq '9999'
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
          user
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
        'default_view' => 'new default view',
        'course_format' => 'on_campus'
      }, 'offer' => true }
    end

    before :each do
      Course.any_instance.unstub(:start_at, :end_at)
    end

    context "an account admin" do
      it "should be able to update a course" do
        @course.root_account.allow_self_enrollment!
        Auditors::Course.expects(:record_updated).once

        json = api_call(:put, @path, @params, @new_values)
        @course.reload

        expect(json['name']).to eql @new_values['course']['name']
        expect(json['course_code']).to eql @new_values['course']['course_code']
        expect(json['start_at']).to eql @new_values['course']['start_at']
        expect(json['end_at']).to eql @new_values['course']['end_at']
        expect(json['sis_course_id']).to eql @new_values['course']['sis_course_id']
        expect(json['default_view']).to eql @new_values['course']['default_view']

        expect(@course.name).to eql @new_values['course']['name']
        expect(@course.course_code).to eql @new_values['course']['course_code']
        expect(@course.start_at.strftime('%Y-%m-%dT%H:%M:%SZ')).to eql @new_values['course']['start_at']
        expect(@course.end_at.strftime('%Y-%m-%dT%H:%M:%SZ')).to eql @new_values['course']['end_at']
        expect(@course.sis_course_id).to eql @new_values['course']['sis_course_id']
        expect(@course.enrollment_term_id).to eq @term.id
        expect(@course.license).to eq 'public_domain'
        expect(@course.is_public).to be_truthy
        expect(@course.public_syllabus).to be_truthy
        expect(@course.public_description).to eq 'new description'
        expect(@course.allow_wiki_comments).to be_truthy
        expect(@course.allow_student_forum_attachments).to be_truthy
        expect(@course.open_enrollment).to be_truthy
        expect(@course.self_enrollment).to be_truthy
        expect(@course.restrict_enrollments_to_course_dates).to be_truthy
        expect(@course.workflow_state).to eq 'available'
        expect(@course.apply_group_weights?).to eq true
        expect(@course.default_view).to eq 'new default view'
        expect(@course.course_format).to eq 'on_campus'
      end

      it "should not change dates that aren't given" do
        @course.update_attribute(:conclude_at, '2012-01-01T23:59:59Z')
        @new_values['course'].delete('end_at')
        api_call(:put, @path, @params, @new_values)
        @course.reload
        expect(@course.end_at.strftime('%Y-%m-%dT%T%z')).to eq '2012-01-01T23:59:59+0000'
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
    end

    context "a teacher" do
      before :once do
        user
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
    end

    context "an unauthorized user" do
      before { user }

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
        Auditors::Course.expects(:record_deleted).once
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
        Auditors::Course.expects(:record_concluded).once
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
        Auditors::Course.expects(:record_deleted).times(course_ids.length)
        api_call(:put, @path, @params, { :event => 'delete', :course_ids => course_ids })
        run_jobs
        [@course1, @course2, @course3].each { |c| expect(c.reload).to be_deleted }
      end

      it "should conclude multiple courses" do
        Auditors::Course.expects(:record_concluded).times(course_ids.length)
        api_call(:put, @path, @params, { :event => 'conclude', :course_ids => course_ids })
        run_jobs
        [@course1, @course2, @course3].each { |c| expect(c.reload).to be_completed }
      end

      it "should publish multiple courses" do
        Auditors::Course.expects(:record_published).times(course_ids.length)
        api_call(:put, @path, @params, { :event => 'offer', :course_ids => course_ids })
        run_jobs
        [@course1, @course2, @course3].each { |c| expect(c.reload).to be_available }
      end

      it "should accept sis ids" do
        course_ids = ['sis_course_id:course1', 'sis_course_id:course2', 'sis_course_id:course3']
        Auditors::Course.expects(:record_published).times(course_ids.length)
        api_call(:put, @path, @params, { :event => 'offer', :course_ids => course_ids })
        run_jobs
        [@course1, @course2, @course3].each { |c| expect(c.reload).to be_available }
      end

      it 'should undelete courses' do
        [@course1, @course2].each { |c| c.destroy }
        Auditors::Course.expects(:record_restored).twice
        api_call(:put, @path, @params, { :event => 'undelete', :course_ids => [@course1.id, 'sis_course_id:course2'] })
        run_jobs
        [@course1, @course2].each { |c| expect(c.reload).to be_claimed }
      end

      it "should not conclude deleted courses" do
        @course1.destroy
        Auditors::Course.expects(:record_concluded).once
        api_call(:put, @path, @params, { :event => 'conclude', :course_ids => [@course1.id, @course2.id] })
        run_jobs
        expect(@course1.reload).to be_deleted
        expect(@course2.reload).to be_completed
      end

      it "should not publish deleted courses" do
        @course1.destroy
        Auditors::Course.expects(:record_published).once
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
        @course2.enrollments.scoped.delete_all
        @course2.course_account_associations.scoped.delete_all
        @course2.course_sections.scoped.delete_all
        @course2.destroy!
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
        Auditors::Course.expects(:record_published).twice
        json = api_call(:put, @path, @params, { :event => 'offer', :course_ids => course_ids })
        run_jobs
        progress = Progress.find(json['id'])
        expect(progress.message).to be_include "3 courses processed"
        [@course1, @course2, @course3].each { |c| expect(c.reload).to be_available }
      end

      it "should succeed when concluding already concluded courses" do
        @course1.complete!
        @course2.complete!
        Auditors::Course.expects(:record_concluded).once
        json = api_call(:put, @path, @params, { :event => 'conclude', :course_ids => course_ids })
        run_jobs
        progress = Progress.find(json['id'])
        expect(progress.message).to be_include "3 courses processed"
        [@course1, @course2, @course3].each { |c| expect(c.reload).to be_completed }
      end

      it "should be able to unconclude courses" do
        @course1.complete!
        @course2.complete!
        Auditors::Course.expects(:record_unconcluded).twice
        json = api_call(:put, @path, @params, { :event => 'offer', :course_ids => course_ids })
        run_jobs
        progress = Progress.find(json['id'])
        expect(progress.message).to be_include "3 courses processed"
        [@course1, @course2, @course3].each { |c| expect(c.reload).to be_available }
      end

      it "should report a failure if no updates succeeded" do
        @course2.enrollments.scoped.delete_all
        @course2.course_account_associations.scoped.delete_all
        @course2.course_sections.scoped.delete_all
        @course2.destroy!
        json = api_call(:put, @path + "?event=offer&course_ids[]=#{@course2.id}",
                        @params.merge(:event => 'offer', :course_ids => [@course2.id.to_s]))
        run_jobs
        progress = Progress.find(json['id'])
        expect(progress).to be_failed
        expect(progress.message).to be_include "0 courses processed"
        expect(progress.message).to be_include "The course was not found: #{@course2.id}"
      end

      it "should report a failure if an exception is raised outside course update" do
        Progress.any_instance.stubs(:complete!).raises "crazy exception"
        json = api_call(:put, @path + "?event=offer&course_ids[]=#{@course2.id}",
                        @params.merge(:event => 'offer', :course_ids => [@course2.id.to_s]))
        run_jobs
        progress = Progress.find(json['id'])
        expect(progress).to be_failed
        expect(progress.message).to be_include "crazy exception"
        Progress.any_instance.unstub(:complete!)
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

  it "should include term name in course list if requested" do
    [@course1.enrollment_term, @course2.enrollment_term].each do |term|
      term.start_at = 1.day.from_now
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
      'sis_term_id' => nil,
      'workflow_state' => 'active',
    )

    # course2
    courses = json.select { |c| c['id'] == @course2.id }
    expect(courses.length).to eq 1
    expect(courses[0]).to include('term')
    expect(courses[0]['term']).to include(
      'id' => @course2.enrollment_term_id,
      'name' => @course2.enrollment_term.name,
      'sis_term_id' => nil,
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

  it "should include scores in course list if requested" do
    @course2.grading_standard_enabled = true
    @course2.save
    expected_current_score = 80
    expected_final_score = 70
    expected_final_grade = @course2.score_to_grade(expected_final_score)
    @course2.all_student_enrollments.update_all(
      :computed_current_score => expected_current_score,
      :computed_final_score => expected_final_score)

    json = api_call(:get, "/api/v1/courses.json",
            { :controller => 'courses', :action => 'index', :format => 'json' },
            { :include => ['total_scores'] })

    # course2 (only care about student)
    courses = json.select { |c| c['id'] == @course2.id }
    expect(courses.length).to eq 1
    expect(courses[0]).to include('enrollments')
    expect(courses[0]['enrollments'].length).to eq 1
    expect(courses[0]['enrollments'][0]).to include(
      'type' => 'student',
      'computed_current_score' => expected_current_score,
      'computed_final_score' => expected_final_score,
      'computed_final_grade' => expected_final_grade,
    )
  end

  it "should not include scores in course list, even if requested, if final grades are hidden" do
    @course2.grading_standard_enabled = true
    @course2.hide_final_grades = true
    @course2.save
    @course2.all_student_enrollments.update_all(:computed_current_score => 80, :computed_final_score => 70)

    json = api_call(:get, "/api/v1/courses.json",
            { :controller => 'courses', :action => 'index', :format => 'json' },
            { :include => ['total_scores'] })

    # course2 (only care about student)
    courses = json.select { |c| c['id'] == @course2.id }
    expect(courses.length).to eq 1
    expect(courses[0]).to include('enrollments')
    expect(courses[0]['enrollments'].length).to eq 1
    expect(courses[0]['enrollments'][0]).to include(
      'type' => 'student',
    )
    expect(courses[0]['enrollments'][0]).not_to include(
      'computed_current_score',
      'computed_final_score',
      'computed_final_grade',
    )
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
      @course3 = course
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
      expect(json[0]['enrollments']).to eq [{ 'type' => 'teacher', 'role' => 'SuperTeacher', 'role_id' => @role.id, 'enrollment_state' => 'invited' }]
    end
  end

  describe "course state" do
    before :once do
      @role = Account.default.roles.build :name => 'SuperTeacher'
      @role.base_role_type = 'TeacherEnrollment'
      @role.save!
      @course3 = course
      @course3.enroll_user(@me, 'TeacherEnrollment', { :role => @role, :active_all => true })
      @course4 = course
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
      expect(json[0]['enrollments']).to eq [{ 'type' => 'teacher', 'role' => 'SuperTeacher', 'role_id' => @role.id, 'enrollment_state' => 'invited' }]
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
                                                            :only => USER_API_FIELDS).sort_by{|x| x["id"]}
    end

    it "should not include user sis id or login id for non-admins" do
      first_user = @user
      new_user = User.create!(:name => 'Zombo')
      @course2.enroll_student(new_user).accept!
      RoleOverride.create!(:context => Account.default, :permission => 'read_sis', :role => teacher_role, :enabled => false)

      @user = @me
      json = api_call(:get, "/api/v1/courses/#{@course2.id}/students.json",
                      { :controller => 'courses', :action => 'students', :course_id => @course2.id.to_s, :format => 'json' })
      %w{sis_user_id sis_login_id unique_id}.each do |attribute|
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
      expect(json.map { |u| u['sis_login_id'] }.sort).to eq ["nobody@example.com", "nobody2@example.com"].sort
      expect(json.map { |u| u['login_id'] }.sort).to eq ["nobody@example.com", "nobody2@example.com"].sort
    end

    it "should include user sis id and login id if can manage_sis in the account" do
      account_admin_user(user: @me)
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
      expect(json.map { |u| u['sis_login_id'] }.sort).to eq ['nobody2@example.com', 'nobody3@example.com'].sort
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
      expect(json.map { |u| u['sis_login_id'] }.sort).to eq ["nobody@example.com", "nobody2@example.com"].sort
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
                                                            :only => USER_API_FIELDS).sort_by{|x| x["id"]}

      ro.destroy
      json = api_call(:get, "/api/v1/courses/sis_course_id:TEST-SIS-ONE.2011.json",
                      { :controller => 'courses', :action => 'show', :id => 'sis_course_id:TEST-SIS-ONE.2011', :format => 'json' })
      expect(json['id']).to eq @course2.id
      expect(json['sis_course_id']).to eq 'TEST-SIS-ONE.2011'
    end

    it "should not be paginated (for legacy reasons)" do
      controller = mock()
      controller.stubs(:params).returns({})
      course_with_teacher(:active_all => true)
      students = []
      num = Api.per_page_for(controller) + 1 # get the default api per page value
      num.times { students << student_in_course(:course => @course).user }
      first_user = @user
      json = api_call(:get, "/api/v1/courses/#{@course.id}/students.json",
                      { :controller => 'courses', :action => 'students', :course_id => @course.id.to_s, :format => 'json' })
      expect(json.count).to eq num
    end
  end

  describe "users" do
    before :once do
      @section1 = @course1.default_section
      @section2 = @course1.course_sections.create!(:name => 'Section B')
      @ta = user(:name => 'TAPerson')
      @ta.communication_channels.create!(:path => 'ta@ta.com') { |cc| cc.workflow_state = 'confirmed' }
      @ta_enroll1 = @course1.enroll_user(@ta, 'TaEnrollment', :section => @section1)
      @ta_enroll2 = @course1.enroll_user(@ta, 'TaEnrollment', :section => @section2, :allow_multiple_enrollments => true)

      @student1 = user(:name => 'SSS1')
      @student2 = user(:name => 'SSS2')
      @student1_enroll = @course1.enroll_user(@student1, 'StudentEnrollment', :section => @section1)
      @student2_enroll = @course1.enroll_user(@student2, 'StudentEnrollment', :section => @section2)
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
            :only => USER_API_FIELDS)

        expect(sorted_users).to eq expected_users

        # this endpoint doesn't exist, but we maintain the route for backwards compat
        json = api_call(:get, "/api/v1/courses/#{@course1.id}/search_users",
                        { controller: 'courses', action: 'users', course_id: @course1.to_param, format: 'json' },
                        :search_term => "TAP")
        sorted_users = json.sort_by{ |x| x["id"] }
        expect(sorted_users).to eq expected_users
      end

      it "accepts a list of enrollment_types" do
        ta2 = user(:name => 'SSS Helper')
        ta2_enroll1 = @course1.enroll_user(ta2, 'TaEnrollment', :section => @section1)

        student3 = user(:name => 'T1')
        student3_enroll = @course1.enroll_user(student3, 'StudentEnrollment', :section => @section2)

        json = api_call(:get, api_url, api_route, :search_term => "SSS", :enrollment_type => ["student","ta"])

        sorted_users = json.sort_by{ |x| x["id"] }
        expected_users =
          api_json_response(
            @course1.users.select{ |u| ['SSS Helper', 'SSS1', 'SSS2'].include? u.name },
            :only => USER_API_FIELDS)

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
        json = api_call(:get, api_url, api_route, :search_term => "TAPerson", :include => ['email'])

        expect(json).to eq [
          {
            'id' => @ta.id,
            'name' => 'TAPerson',
            'sortable_name' => 'TAPerson',
            'short_name' => 'TAPerson',
            'email' => 'ta@ta.com'
          }
        ]
      end

      context "sharding" do
        specs_require_sharding

        it "should load the user's enrollment for an out-of-shard user" do
          pend_with_bullet
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
        json = api_call(:get, "/api/v1/courses/#{@course1.id}/users.json",
                        { :controller => 'courses', :action => 'users', :course_id => @course1.id.to_s, :format => 'json' })
        expect(json.sort_by{|x| x["id"]}).to eq api_json_response(@course1.users.uniq,
                                                              :only => USER_API_FIELDS).sort_by{|x| x["id"]}
      end

      it "excludes the test student by default" do
        test_student = @course1.student_view_student
        json = api_call(:get, "/api/v1/courses/#{@course1.id}/users.json",
                        { :controller => 'courses', :action => 'users', :course_id => @course1.id.to_s, :format => 'json' })
        expect(json.map{ |s| s["name"] }).not_to include("Test Student")
      end

      it "includes the test student if told to do so" do
        test_student = @course1.student_view_student
        json = api_call(:get, "/api/v1/courses/#{@course1.id}/users.json",
                        { :controller => 'courses', :action => 'users', :course_id => @course1.id.to_s, :format => 'json'},
                          :include => ['test_student'] )
        expect(json.map{ |s| s["name"] }).to include("Test Student")
      end

      it "returns a list of users with emails" do
        @user = @course1.teachers.first
        json = api_call(:get, "/api/v1/courses/#{@course1.id}/users.json",
                        { :controller => 'courses', :action => 'users', :course_id => @course1.id.to_s, :format => 'json' },
                        :include => ['email'])
        json.each { |u| expect(u.keys).to include('email') }
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
          expect(j).to eq api_json_response(user, :only => USER_API_FIELDS)
        }
        # expect
        check_json.call(@ta, @ta_enroll1, @ta_enroll2)
        check_json.call(@student1, @student1_enroll)
        check_json.call(@student2, @student2_enroll)
      end

      it "doesn't return enrollments from another course" do
        pend_with_bullet
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
                                                                :only => USER_API_FIELDS).map {|x| x["id"]}.sort
      end

      it "should accept an array of enrollment_types" do
        json = api_call(:get, "/api/v1/courses/#{@course1.id}/users",
                        {:controller => 'courses', :action => 'users', :course_id => @course1.to_param, :format => 'json' },
                        :enrollment_type => ['student', 'teacher'], :include => ['enrollments'])

        expect(json.map { |u| u['enrollments'].map { |e| e['type'] } }.flatten.uniq.sort).to eq %w{StudentEnrollment TeacherEnrollment}
      end

      describe "enrollment_role" do
        before :once do
          role = Account.default.roles.build :name => 'EliteStudent'
          role.base_role_type = 'StudentEnrollment'
          role.save!
          @student3 = user(:name => 'S3')
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
          @student3 = user(:name => 'S3')
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
        %w{sis_user_id sis_login_id unique_id}.each do |attribute|
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
        expect(json.map { |u| u['sis_login_id'] }.sort).to eq ["nobody@example.com", "nobody2@example.com"].sort
        expect(json.map { |u| u['login_id'] }.sort).to eq ["nobody@example.com", "nobody2@example.com"].sort
      end

      it "should include user sis id and login id if can manage_sis in the account" do
        account_admin_user(user: @me)
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
        expect(json.map { |u| u['sis_login_id'] }.compact.sort).to eq ['nobody2@example.com', 'nobody3@example.com'].sort
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
        expect(json.map { |u| u['sis_login_id'] }.sort).to eq ["nobody@example.com", "nobody2@example.com"].sort
        expect(json.map { |u| u['login_id'] }.sort).to eq ["nobody@example.com", "nobody2@example.com"].sort
      end

      describe "as a student" do
        before :once do
          @other_user = user_with_pseudonym(:name => 'Waldo', :username => 'dontfindme@example.com')
          @other_user.pseudonym.update_attribute(:sis_user_id, 'mysis_8675309')
          @course1.enroll_student(@other_user).accept!

          @user = user
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
                                                              :only => USER_API_FIELDS).sort_by{|x| x["id"]}

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
    end

    it "should include observed users in the enrollments if requested" do
      @student1.name = "student 1"
      @student2.save!
      @student2.name = "student 2"
      @student2.save!

      observer1 = user
      observer2 = user

      @course1.enroll_user(observer1, "ObserverEnrollment", :associated_user_id => @student1.id).accept!
      @course1.enroll_user(observer2, "ObserverEnrollment", :associated_user_id => @student2.id).accept!
      @course1.enroll_user(observer1, "ObserverEnrollment", :allow_multiple_enrollments => true, :associated_user_id => @student2.id).accept!

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
      json = api_call(:get, "/api/v1/courses/#{@course1.id}.json",
              { :controller => 'courses', :action => 'show', :id => @course1.to_param, :format => 'json' })

      expect(json).to eq({
        'id' => @course1.id,
        'name' => @course1.name,
        'account_id' => @course1.account_id,
        'course_code' => @course1.course_code,
        'enrollments' => [{'type' => 'teacher', 'role' => 'TeacherEnrollment', 'role_id' => teacher_role.id, 'enrollment_state' => 'active'}],
        'sis_course_id' => @course1.sis_course_id,
        'integration_id' => nil,
        'calendar' => { 'ics' => "http://www.example.com/feeds/calendars/course_#{@course1.uuid}.ics" },
        'hide_final_grades' => @course1.hide_final_grades,
        'start_at' => @course1.start_at,
        'end_at' => @course1.end_at,
        'default_view' => @course1.default_view,
        'public_syllabus' => @course1.public_syllabus,
        'workflow_state' => @course1.workflow_state,
        'storage_quota_mb' => @course1.storage_quota_mb,
        'apply_assignment_group_weights' => false,
        'enrollment_term_id' => @course.enrollment_term_id
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
      course(:account => acct)
      @course.update_attribute('sis_source_id', 'OTHER-SIS')
      raw_api_call(:get, "/api/v1/courses/sis_course_id:OTHER-SIS",
                   :controller => "courses", :action => "show", :id => "sis_course_id:OTHER-SIS", :format => "json")
      assert_status(404)
    end

    it 'should include permissions' do
      # Make sure it only returns permissions when asked
      json = api_call(:get, "/api/v1/courses/#{@course1.id}.json", { :controller => 'courses', :action => 'show', :id => @course1.to_param, :format => 'json' })
      expect(json.has_key?("permissions")).to be_falsey

      # When its asked to return permissions make sure they are there
      json = api_call(:get, "/api/v1/courses/#{@course1.id}.json?include[]=permissions", { :controller => 'courses', :action => 'show', :id => @course1.to_param, :format => 'json', :include => [ "permissions" ] })
      expect(json.has_key?("permissions")).to be_truthy
    end

    it 'should include permission create_discussion_topic' do
      json = api_call(:get, "/api/v1/courses/#{@course1.id}.json?include[]=permissions", { :controller => 'courses', :action => 'show', :id => @course1.to_param, :format => 'json', :include => [ "permissions" ] })
      expect(json.has_key?("permissions")).to be_truthy
      expect(json["permissions"].has_key?("create_discussion_topic")).to be_truthy
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
        'grading_standard_id' => nil
      })
    end

    it "should update settings" do
      Auditors::Course.expects(:record_updated).with(anything, anything, anything, source: :api)

      json = api_call(:put, "/api/v1/courses/#{@course.id}/settings", {
        :controller => 'courses',
        :action => 'update_settings',
        :course_id => @course.to_param,
        :format => 'json'
      }, {
        :allow_student_discussion_topics => false,
        :allow_student_forum_attachments => true,
        :allow_student_discussion_editing => false
      })
      expect(json).to eq({
        'allow_student_discussion_topics' => false,
        'allow_student_forum_attachments' => true,
        'allow_student_discussion_editing' => false,
        'grading_standard_enabled' => false,
        'grading_standard_id' => nil
      })
      @course.reload
      expect(@course.allow_student_discussion_topics).to eq false
      expect(@course.allow_student_forum_attachments).to eq true
      expect(@course.allow_student_discussion_editing).to eq false
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
      @user = user
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
    @copy_from.wiki.wiki_pages.create!(:title => "some page", :body => 'hi')
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
    Auditors::Course.expects(:record_copied).once
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
    expect(@copy_to.wiki.wiki_pages.count).to eq 1
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
    expect(@copy_to.wiki.wiki_pages.count).to eq 0
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
    expect(json).to eq({'state' => 'queued'})

    CourseLinkValidator.any_instance.stubs(:check_course)
    CourseLinkValidator.any_instance.stubs(:issues).returns(['mock_issue'])
    run_jobs

    # check results
    json = api_call(:get, "/api/v1/courses/#{@course.id}/link_validation",
                    { :controller => 'courses', :action => 'link_validation', :format => 'json', :course_id => @course.id.to_param })
    expect(json['state']).to eq('completed')
    expect(json['issues']).to eq(['mock_issue'])
  end

end
