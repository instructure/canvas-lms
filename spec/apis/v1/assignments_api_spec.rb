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
require File.expand_path(File.dirname(__FILE__) + '/../locked_spec')
require File.expand_path(File.dirname(__FILE__) + '/../../sharding_spec_helper')

describe AssignmentsApiController, :include_lti_spec_helpers, type: :request do
  include Api
  include Api::V1::Assignment
  include Api::V1::Submission

  context 'locked api item' do
    include_examples 'a locked api item'

    let(:item_type) { 'assignment' }

    let_once(:locked_item) do
      @course.assignments.create!(:title => 'Locked Assignment')
    end

    def api_get_json
      api_get_assignment_in_course(locked_item, @course)
    end
  end

  def create_submitted_assignment_with_user(user=@user)
    now = Time.zone.now
    assignment = @course.assignments.create!(
      :title => "dawg you gotta submit this",
      :submission_types => "online_url")
    submission = bare_submission_model assignment,
                                       user,
                                       score: '99',
                                       grade: '99',
                                       submitted_at: now,
                                       grade_matches_current_submission: true
    return assignment,submission
  end

  def create_override_for_assignment(assignment=@assignment)
      override = @assignment.assignment_overrides.build
      @assignment.any_instantiation.unstub(:overridden_for)
      override.title = "I am overridden and being returned in the API!"
      override.set = @section
      override.set_type = 'CourseSection'
      override.due_at = Time.zone.now + 2.days
      override.unlock_at = Time.zone.now + 1.days
      override.lock_at = Time.zone.now + 3.days
      override.due_at_overridden = true
      override.lock_at_overridden = true
      override.unlock_at_overridden = true
      override.save!
      override
  end

  describe "GET /courses/:course_id/assignments (#index)" do
    before :once do
      course_with_teacher(:active_all => true)
    end

    it "returns unauthorized for users who cannot :read the course" do
      # unpublished course with invited student
      course_with_student
      expect(@course.grants_right?(@student, :read)).to be_falsey

      api_call(:get,
        "/api/v1/courses/#{@course.id}/assignments",
        {
          :controller => 'assignments_api',
          :action => 'index',
          :format => 'json',
          :course_id => @course.id.to_s
        },
        {},
        {},
        {:expected_status => 401}
      )
    end

    it "includes has_due_date_in_closed_grading_period in returned json" do
      @course.assignments.create!(title: "Example Assignment")
      json = api_get_assignments_index_from_course(@course)
      expect(json.first).to have_key('has_due_date_in_closed_grading_period')
    end

    it "sorts the returned list of assignments" do
      # the API returns the assignments sorted by
      # [assignment_groups.position, assignments.position]
      group1 = @course.assignment_groups.create!(:name => 'group1')
      group1.update_attribute(:position, 10)
      group2 = @course.assignment_groups.create!(:name => 'group2')
      group2.update_attribute(:position, 7)
      group3 = @course.assignment_groups.create!(:name => 'group3')
      group3.update_attribute(:position, 12)
      @course.assignments.create!(:title => 'assignment1',
                                  :assignment_group => group2).
                                  update_attribute(:position, 2)
      @course.assignments.create!(:title => 'assignment2',
                                  :assignment_group => group2).
                                  update_attribute(:position, 1)
      @course.assignments.create!(:title => 'assignment3',
                                  :assignment_group => group1).
                                  update_attribute(:position, 1)
      @course.assignments.create!(:title => 'assignment4',
                                  :assignment_group => group3).
                                  update_attribute(:position, 3)
      @course.assignments.create!(:title => 'assignment5',
                                  :assignment_group => group1).
                                  update_attribute(:position, 2)
      @course.assignments.create!(:title => 'assignment6',
                                  :assignment_group => group2).
                                  update_attribute(:position, 3)
      @course.assignments.create!(:title => 'assignment7',
                                  :assignment_group => group3).
                                  update_attribute(:position, 2)
      @course.assignments.create!(:title => 'assignment8',
                                  :assignment_group => group3).
                                  update_attribute(:position, 1)
      json = api_get_assignments_index_from_course(@course)
      order = json.map { |a| a['name'] }
      expect(order).to eq %w(assignment2
                          assignment1
                          assignment6
                          assignment3
                          assignment5
                          assignment8
                          assignment7
                          assignment4)
    end

    it "should search for assignments by title" do
      2.times {|i| @course.assignments.create!(:title => "First_#{i}") }
      ids = @course.assignments.map(&:id)
      2.times {|i| @course.assignments.create!(:title => "second_#{i}") }

      json = api_call(:get,
                      "/api/v1/courses/#{@course.id}/assignments.json?search_term=fir",
                      {
                          :controller => 'assignments_api',
                          :action => 'index',
                          :format => 'json',
                          :course_id => @course.id.to_s,
                          :search_term => 'fir'
                      })
      expect(json.map{|h| h['id']}.sort).to eq ids.sort
    end

    it "should allow filtering based on assignment_ids[] parameter" do
      13.times { |i| @course.assignments.create!(title: "a_#{i}") }
      all_ids = @course.assignments.pluck(:id).map(&:to_s)
      some_ids = all_ids.slice(1, 4)
      query_string = some_ids.map { |id| "assignment_ids[]=#{id}" }.join('&')

      json = api_call(:get,
                      "/api/v1/courses/#{@course.id}/assignments.json?#{query_string}",
                      {
                          :controller => 'assignments_api',
                          :action => 'index',
                          :format => 'json',
                          :course_id => @course.id.to_s,
                          :assignment_ids => some_ids
                      })

      expect(json.length).to eq 4
      expect(json.map{|h| h['id']}.map(&:to_s).sort).to eq some_ids.sort
    end

    it "should fail if given an assignment_id that does not exist" do
      good_assignment = @course.assignments.create!(title: "assignment")
      bad_assignment = @course.assignments.create!(title: "assignment")
      bad_assignment.destroy!
      bad_id = bad_assignment.id
      json = api_call(:get,
                      "/api/v1/courses/#{@course.id}/assignments.json?assignment_ids[]=#{good_assignment.id}&assignment_ids[]=#{bad_id}",
                      {
                        :controller => 'assignments_api',
                        :action => 'index',
                        :format => 'json',
                        :course_id => @course.id.to_s,
                        :assignment_ids => [ good_assignment.id.to_s, bad_id.to_s ]
                      }, {}, {}, {
                        expected_status: 400
                      })
    end

    it "should fail when given an assignment_id without permissions" do
      student_in_course
      bad_assignment = @course.assignments.create!(title: "assignment") # not published
      bad_assignment.workflow_state = :unpublished
      bad_assignment.save!
      json = api_call_as_user(@student, :get,
                      "/api/v1/courses/#{@course.id}/assignments.json?assignment_ids[]=#{bad_assignment.id}",
                      {
                        :controller => 'assignments_api',
                        :action => 'index',
                        :format => 'json',
                        :course_id => @course.id.to_s,
                        :assignment_ids => [ bad_assignment.id.to_s ]
                      }, {}, {}, {
                        expected_status: 400
                      })
    end

    it "should fail if given too many assignment_ids" do
      all_ids = (1...(Api.max_per_page + 10)).map(&:to_s)
      query_string = all_ids.map { |id| "assignment_ids[]=#{id}" }.join('&')
      json = api_call(:get,
                      "/api/v1/courses/#{@course.id}/assignments.json?#{query_string}",
                      {
                          :controller => 'assignments_api',
                          :action => 'index',
                          :format => 'json',
                          :course_id => @course.id.to_s,
                          :assignment_ids => all_ids
                      }, {}, {}, {
                        expected_status: 400
                      })
    end

    it "should return the assignments list with API-formatted Rubric data" do
      # the API changes the structure of the data quite a bit, to hide
      # implementation details and ease API use.
      @group = @course.assignment_groups.create!({:name => "some group"})
      @assignment = @course.assignments.create!(:title => "some assignment",
                                                :assignment_group => @group,
                                                :points_possible => 12)
      @assignment.update_attribute(:submission_types,
                 "online_upload,online_text_entry,online_url,media_recording")
      @rubric = rubric_model(:user => @user,
                             :context => @course,
                             :data => larger_rubric_data,
                             :title => 'some rubric',
                             :points_possible => 12,
                              :free_form_criterion_comments => true)

      @assignment.build_rubric_association(:rubric => @rubric,
                                           :purpose => 'grading',
                                           :use_for_grading => true,
                                           :context => @course)
      @assignment.rubric_association.save!
      json = api_get_assignments_index_from_course(@course)
      expect(json.first['rubric_settings']).to eq({
        'id' => @rubric.id,
        'title' => 'some rubric',
        'points_possible' => 12,
        'free_form_criterion_comments' => true
      })
      expect(json.first['rubric']).to eq [
        {
          'id' => 'crit1',
          'points' => 10,
          'description' => 'Crit1',
          'ratings' => [
            {'id' => 'rat1', 'points' => 10, 'description' => 'A'},
            {'id' => 'rat2', 'points' => 7, 'description' => 'B'},
            {'id' => 'rat3', 'points' => 0, 'description' => 'F'}
          ]
        },
        {
          'id' => 'crit2',
          'points' => 2,
          'description' => 'Crit2',
          'ratings' => [
            {'id' => 'rat1', 'points' => 2, 'description' => 'Pass'},
            {'id' => 'rat2', 'points' => 0, 'description' => 'Fail'},
          ]
        }
      ]
    end

    it "should return learning outcome info with rubric criterions if available" do
      @group = @course.assignment_groups.create!({:name => "some group"})
      @assignment = @course.assignments.create!(:title => "some assignment",
                                                :assignment_group => @group,
                                                :points_possible => 12)
      @assignment.update_attribute(:submission_types,
                                   "online_upload,online_text_entry,online_url,media_recording")

      criterion = valid_rubric_attributes[:data].first
      @outcome = @course.created_learning_outcomes.build(
          :title => "My Outcome",
          :description => "Description of my outcome",
          :vendor_guid => "vendorguid9000"
      )
      @outcome.rubric_criterion = criterion
      @outcome.save!

      rubric_data = [criterion.merge({:learning_outcome_id => @outcome.id})]

      @rubric = rubric_model(:user => @user,
                             :context => @course,
                             :data => rubric_data,
                             :points_possible => 12,
                             :free_form_criterion_comments => true)

      @assignment.build_rubric_association(:rubric => @rubric,
                                           :purpose => 'grading',
                                           :use_for_grading => true,
                                           :context => @course)
      @assignment.rubric_association.save!
      json = api_get_assignments_index_from_course(@course)

      expect(json.first['rubric'].first["outcome_id"]).to eq @outcome.id
      expect(json.first['rubric'].first["vendor_guid"]).to eq "vendorguid9000"
    end

    it "should exclude deleted assignments in the list return" do
      @context = @course
      @assignment = factory_with_protected_attributes(
        @course.assignments,
        {
          :title => 'assignment1',
          :submission_types => 'discussion_topic',
          :discussion_topic => discussion_topic_model
        })
      @assignment.reload
      @assignment.destroy
      json = api_get_assignments_index_from_course(@course)
      expect(json.size).to eq 0
    end

    describe "assignment bucketing" do
      before :once do
        course_with_student_logged_in(:active_all => true)
        @student1 = @user
        @section = @course.course_sections.create!(name: "test section")
        student_in_section(@section, user: @student1)

        @student2 = create_users(1, return_type: :record).first
        @course.enroll_student(@student2, :enrollment_state => 'active')
        @section2 = @course.course_sections.create!(name: "second test section")
        student_in_section(@section2, user: @student2)

        # names based on student 1's due dates
        @past_assignment = @course.assignments.create!(title: "past", only_visible_to_overrides: true, due_at: (Time.now - 10.days))
        create_section_override_for_assignment(@past_assignment, {course_section: @section, due_at: (Time.now - 10.days)})

        @overdue_assignment = @course.assignments.create!(title: "overdue", only_visible_to_overrides: true, submission_types: "online")
        create_section_override_for_assignment(@overdue_assignment, {course_section: @section, due_at: (Time.now - 10.days)})

        @far_future_assignment = @course.assignments.create!(title: "far future", only_visible_to_overrides: true)
        create_section_override_for_assignment(@far_future_assignment, {course_section: @section, due_at: (Time.now + 30.days)})

        @upcoming_assignment = @course.assignments.create!(title: "upcoming", only_visible_to_overrides: true)
        create_section_override_for_assignment(@upcoming_assignment, {course_section: @section, due_at: (Time.now + 1.days)})

        @undated_assignment = @course.assignments.create!(title: "undated", only_visible_to_overrides: true)
        override = create_section_override_for_assignment(@undated_assignment, {course_section: @section, due_at: nil})
        override.due_at = nil
        override.save

        # student2 overrides
        create_section_override_for_assignment(@past_assignment, {course_section: @section2, due_at: (Time.now - 10.days)})
        create_section_override_for_assignment(@far_future_assignment, {course_section: @section2, due_at: (Time.now - 10.days)})
      end

      it "returns an error with an invalid bucket" do
        raw_api_call(:get, "/api/v1/courses/#{@course.id}/assignments.json",
          { :controller => 'assignments_api',
            :action => 'index',
            :format => 'json',
            :course_id => @course.id.to_s,
            :bucket => "invalid bucket name"
          }
        )

        expect(response).not_to be_success
        json = JSON.parse response.body
        expect(json["errors"]["bucket"].first["message"]).to eq "bucket name must be one of the following: past, overdue, undated, ungraded, unsubmitted, upcoming, future"
      end

      def assignment_index_bucketed_api_call(bucket)
        api_call(:get, "/api/v1/courses/#{@course.id}/assignments.json",
          { :controller => 'assignments_api',
            :action => 'index',
            :format => 'json',
            :course_id => @course.id.to_s,
            :bucket => bucket
          }
        )
      end

      def assert_call_gets_assignments(bucket, assignments)
        assignments_json = assignment_index_bucketed_api_call(bucket)
        expect(assignments_json.map{|a| a["id"]}.sort).to eq assignments.map(&:id).sort
        if assignments_json.any?
          expect(assignments_json.first["bucket"]).to eq bucket
        end
      end

      def assert_calls_get_assignments(expectations)
        expectations.each do |bucket, assignments|
          assert_call_gets_assignments(bucket.to_s, assignments)
        end
      end

      context "as a student" do
        it "should bucket assignments properly" do
          assert_calls_get_assignments(
            future: [@upcoming_assignment, @far_future_assignment, @undated_assignment],
            upcoming: [@upcoming_assignment],
            past: [@past_assignment, @overdue_assignment],
            undated: [@undated_assignment],
            overdue: [@overdue_assignment]
          )
        end

        it "should apply overrides properly to different students" do
          # as student1
          assert_call_gets_assignments("past", [@past_assignment, @overdue_assignment])

          user_session(@student2)
          @user = @student2

          assert_call_gets_assignments("past", [@past_assignment, @far_future_assignment])
        end
      end

      context "as a teacher" do
        it "should use default assignment dates" do
          teacher = @course.teachers.first
          user_session(teacher)
          @user = teacher

          assert_calls_get_assignments(
            past: [@past_assignment],
            undated: [@upcoming_assignment, @undated_assignment, @overdue_assignment, @far_future_assignment]
          )
        end
      end

      context "as an observer" do
        before :once do
          @observer = User.create
          user_session(@observer)
          @user = @observer
        end
        it "should get the same results as a student when only observing one student" do
          @observer_enrollment = @course.enroll_user(@observer, 'ObserverEnrollment', :section => @section2, :enrollment_state => 'active')
          @observer_enrollment.update_attribute(:associated_user_id, @student1.id)

          assert_calls_get_assignments(
            future: [@upcoming_assignment, @far_future_assignment, @undated_assignment],
            upcoming: [@upcoming_assignment],
            past: [@past_assignment, @overdue_assignment],
            undated: [@undated_assignment],
            overdue: [@overdue_assignment]
          )
        end

        it "should treat multi-student observers like course observers" do
          @observer_enrollment = @course.enroll_user(@observer, 'ObserverEnrollment', :section => @section, :enrollment_state => 'active', :allow_multiple_enrollments => true)
          @observer_enrollment.update_attribute(:associated_user_id, @student1.id)
          @observer_enrollment = @course.enroll_user(@observer, 'ObserverEnrollment', :section => @section, :enrollment_state => 'active', :allow_multiple_enrollments => true)
          @observer_enrollment.update_attribute(:associated_user_id, @student2.id)

          assert_calls_get_assignments(
            future: [@upcoming_assignment, @far_future_assignment, @undated_assignment],
            upcoming: [@upcoming_assignment],
            past: [@past_assignment, @overdue_assignment],
            undated: [@undated_assignment],
            overdue: []
          )
        end

        it "should use sections dates when observing a whole course" do
          @observer_enrollment = @course.enroll_user(@observer, 'ObserverEnrollment', :section => @section, :enrollment_state => 'active')

          assert_calls_get_assignments(
            future: [@upcoming_assignment, @far_future_assignment, @undated_assignment],
            upcoming: [@upcoming_assignment],
            past: [@past_assignment, @overdue_assignment],
            undated: [@undated_assignment],
            overdue: []
          )
        end
      end
    end

    describe "enable draft" do
      before :once do
        course_with_teacher(:active_all => true)
        @assignment = @course.assignments.create :name => 'some assignment'
        @assignment.workflow_state = 'unpublished'
        @assignment.save!
      end

      it "should include published flag for accounts that do have enabled_draft" do
        @json = api_get_assignment_in_course(@assignment, @course)

        expect(@json.has_key?('published')).to be_truthy
        expect(@json['published']).to be_falsey
      end

      it "includes has_due_date_in_closed_grading_period in returned json" do
        @course.assignments.create!(title: "Example Assignment")
        json = api_get_assignment_in_course(@assignment, @course)
        expect(json).to have_key('has_due_date_in_closed_grading_period')
      end
    end

    describe "differentiated assignments" do

      def setup_DA
        @course_section = @course.course_sections.create
        @student1, @student2, @student3 = create_users(3, return_type: :record)
        @assignment = @course.assignments.create!(title: "title", only_visible_to_overrides: true)
        @course.enroll_student(@student2, :enrollment_state => 'active')
        @section = @course.course_sections.create!(name: "test section")
        @section2 = @course.course_sections.create!(name: "second test section")
        student_in_section(@section, user: @student1)
        create_section_override_for_assignment(@assignment, {course_section: @section})
        @assignment2 = @course.assignments.create!(title: "title2", only_visible_to_overrides: true)
        create_section_override_for_assignment(@assignment2, {course_section: @section2})
        @course.reload
      end

      before :once do
        course_with_teacher_logged_in(active_all: true)
        @assignment = @course.assignments.create(name: 'differentiated assignment')
        section = @course.course_sections.create!(name: "second test section")
        create_section_override_for_assignment(@assignment, {course_section: section})
        assignment_override_model(assignment: @assignment, set_type: 'Noop', title: 'Just a Tag')
      end

      it "should include overrides if overrides flag is included in the params" do
        ConditionalRelease::Service.stubs(:enabled_in_context?).returns(true)
        assignments_json = api_call(:get, "/api/v1/courses/#{@course.id}/assignments",
          {
            controller: 'assignments_api',
            action: 'index',
            format: 'json',
            course_id: @course.id.to_s,
          },
            include: ['overrides']
          )
        expect(assignments_json[0].keys).to include("overrides")
        expect(assignments_json[0]["overrides"].length).to eq 2
      end

      it "should include the only_visible_to_overrides flag if differentiated assignments is on" do
        @json = api_get_assignment_in_course(@assignment, @course)
        expect(@json.has_key?('only_visible_to_overrides')).to be_truthy
        expect(@json['only_visible_to_overrides']).to be_falsey
      end

      it "should include visibility data if included" do
        json =  api_call(:get,
            "/api/v1/courses/#{@course.id}/assignments.json",
            {
              :controller => 'assignments_api', :action => 'index',
              :format => 'json', :course_id => @course.id.to_s
            },
            :include => ['assignment_visibility']
          )
        json.each do |a|
          expect(a.has_key?("assignment_visibility")).to eq true
        end
      end

      it "should show all assignments" do
        setup_DA
        count = @course.assignments.reload.length
        json = api_get_assignments_index_from_course(@course)
        expect(json.length).to eq count
      end

      context "as a student" do
        before :once do
          course(:active_all => true)
          setup_DA
        end

        it "should show visible assignments" do
          user_session @student1
          @user = @student1
          json = api_get_assignments_index_from_course(@course)
          expect(json.length).to eq 1
          expect(json.first["id"]).to eq @assignment.id
        end

        it "should not show non-visible assignments" do
          user_session @student2
          @user = @student2
          json = api_get_assignments_index_from_course(@course)
          expect(json).to eq []
        end
      end

      context "as an observer" do
        before :once do
          course(:active_all => true)
          setup_DA
          @observer = User.create
          @observer_enrollment = @course.enroll_user(@observer, 'ObserverEnrollment', :section => @course.course_sections.first, :enrollment_state => 'active', :allow_multiple_enrollments => true)
        end

        it "should show assignments visible to observed student" do
          @observer_enrollment.update_attribute(:associated_user_id, @student1.id)
          user_session @observer
          @user = @student1
          json = api_get_assignments_index_from_course(@course)
          expect(json.length).to eq 1
          expect(json.first["id"]).to eq @assignment.id
        end

        it "should not show assignments not visible to observed student" do
          @observer_enrollment.update_attribute(:associated_user_id, @student2.id)
          user_session @observer
          @user = @student2
          json = api_get_assignments_index_from_course(@course)
          expect(json).to eq []
        end

        it "should show assignments visible to any of the observed students" do
          @observer_enrollment.update_attribute(:associated_user_id, @student2.id)
          @course.enroll_user(@observer, "ObserverEnrollment", {:allow_multiple_enrollments => true, :associated_user_id => @student1.id})
          user_session @observer
          @user = @student1
          json = api_get_assignments_index_from_course(@course)
          expect(json.length).to eq 1
          expect(json.first["id"]).to eq @assignment.id
        end
      end
    end

    it "includes submission info with include flag" do
      course_with_student_logged_in(:active_all => true)
      assignment,submission = create_submitted_assignment_with_user(@user)
      json = api_call(:get,
            "/api/v1/courses/#{@course.id}/assignments.json",
            {
              :controller => 'assignments_api',
              :action => 'index',
              :format => 'json',
              :course_id => @course.id.to_s
            },
            :include => ['submission']
             )
      assign = json.first
      expect(assign['submission']).to eq(
        json_parse(controller.submission_json(submission,assignment,@user,session).to_json)
      )
    end

    it "includes all_dates with include flag" do
      course_with_student_logged_in(:active_all => true)
      @course.assignments.create!(:title => "all_date_test", :submission_types => "online_url")
      json = api_call(:get,
            "/api/v1/courses/#{@course.id}/assignments.json",
            {
              :controller => 'assignments_api',
              :action => 'index',
              :format => 'json',
              :course_id => @course.id.to_s
            },
            :include => ['all_dates']
             )
      assign = json.first
      expect(assign['all_dates']).not_to be_nil
    end

    it "doesn't include all_dates if there are too many" do
      course_with_teacher_logged_in(:active_all => true)
      s1 = student_in_course(:course => @course, :active_all => true).user
      s2 = student_in_course(:course => @course, :active_all => true).user

      a = @course.assignments.create!(:title => "all_date_test", :submission_types => "online_url", :only_visible_to_overrides => true)
      o1 = assignment_override_model(:assignment => a)
      os1 = o1.assignment_override_students.create!(:user => s1)

      Setting.set('assignment_all_dates_too_many_threshold', '2')

      @user = @teacher
      json = api_call(:get,
        "/api/v1/courses/#{@course.id}/assignments.json",
        { :controller => 'assignments_api', :action => 'index', :format => 'json', :course_id => @course.id.to_s},
        :include => ['all_dates'])
      expect(json.first['all_dates'].count).to eq 1

      o2 = assignment_override_model(:assignment => a)
      os2 = o2.assignment_override_students.create!(:user => s2)

      json = api_call(:get,
        "/api/v1/courses/#{@course.id}/assignments.json",
        { :controller => 'assignments_api', :action => 'index', :format => 'json', :course_id => @course.id.to_s},
        :include => ['all_dates'])
      expect(json.first['all_dates']).to be_nil
      expect(json.first['all_dates_count']).to eq 2
    end


    it "returns due dates as they apply to the user" do
      course_with_student(active_all: true)
      @user = @student
      @student.enrollments.map(&:destroy_permanently!)
      @assignment = @course.assignments.create!(title: "Test Assignment", description: "public stuff")
      @section = @course.course_sections.create!(name: "afternoon delight")
      @course.enroll_user(@student, "StudentEnrollment", section: @section, enrollment_state: :active)
      override = create_override_for_assignment
      json = api_get_assignments_index_from_course(@course).first
      expect(json['due_at']).to eq override.due_at.iso8601.to_s
      expect(json['unlock_at']).to eq override.unlock_at.iso8601.to_s
      expect(json['lock_at']).to eq override.lock_at.iso8601.to_s
    end

    it "returns original assignment due dates" do
      course_with_student(:active_all => true)
      @user = @teacher
      @student.enrollments.map(&:destroy_permanently!)
      @assignment = @course.assignments.create!(
        :title => "Test Assignment",
        :description => "public stuff",
        :due_at => Time.zone.now + 1.days,
        :unlock_at => Time.zone.now,
        :lock_at => Time.zone.now + 2.days
      )
      @section = @course.course_sections.create! :name => "afternoon delight"
      @course.enroll_user(@student,'StudentEnrollment',
                          :section => @section,
                          :enrollment_state => :active)
      create_override_for_assignment
      json = api_call(:get,
                      "/api/v1/courses/#{@course.id}/assignments.json",
                      {
                        :controller => 'assignments_api',
                        :action => 'index',
                        :format => 'json',
                        :course_id => @course.id.to_s
                      },
                      :override_assignment_dates => 'false'
      ).first
      expect(json['due_at']).to eq @assignment.due_at.iso8601.to_s
      expect(json['unlock_at']).to eq @assignment.unlock_at.iso8601.to_s
      expect(json['lock_at']).to eq @assignment.lock_at.iso8601.to_s
    end

    describe "draft state" do

      before :once do
        course_with_student(:active_all => true)
        @published = @course.assignments.create!({:name => "published assignment"})
        @published.workflow_state = 'published'
        @published.save!

        @unpublished = @course.assignments.create!({:name => "unpublished assignment"})
        @unpublished.workflow_state = 'unpublished'
        @unpublished.save!
      end

      it "only shows published assignments to students" do
        json = api_get_assignments_index_from_course(@course)
        expect(json.length).to eq 1
        expect(json[0]['id']).to eq @published.id
      end

      it "shows unpublished assignments to teachers" do
        user
        @enrollment = @course.enroll_user(@user, 'TeacherEnrollment')
        @enrollment.course = @course # set the reverse association

        json = api_get_assignments_index_from_course(@course)
        expect(json.length).to eq 2
        expect(json[0]['id']).to eq @published.id
        expect(json[1]['id']).to eq @unpublished.id
      end
    end

    it 'returns the url attribute for external tools' do
      course_with_student(:active_all => true)
      assignment = @course.assignments.create!
      @tool_tag = ContentTag.new({:url => 'http://www.example.com', :new_tab=>false})
      @tool_tag.context = assignment
      @tool_tag.save!
      assignment.submission_types = 'external_tool'
      assignment.save!
      expect(assignment.external_tool_tag).not_to be_nil
      @json = api_get_assignments_index_from_course(@course)

      expect(@json[0]).to include('url')
      uri = URI(@json[0]['url'])
      expect(uri.path).to eq "/api/v1/courses/#{@course.id}/external_tools/sessionless_launch"
      expect(uri.query).to include('assignment_id=')
    end
  end

  describe "GET /users/:user_id/courses/:course_id/assignments (#user_index)" do
    before :once do
      course_with_teacher(:active_all => true)
    end

    it "returns data for user calling on self" do
      course_with_student_submissions(:active_all => true)
      json = api_get_assignments_user_index(@student, @course)
      expect(json[0]['course_id']).to eq @course.id
    end

    it "returns assignments for authorized observer" do
      course_with_student_submissions(:active_all => true)
      parent = User.create
      parent.user_observees.create! do |uo|
        uo.user_id = @student.id
      end
      parent.save!
      json = api_get_assignments_user_index(@student, @course, parent)
      expect(json[0]['course_id']).to eq @course.id
    end

    it "returns unauthorized for users who cannot :read the course" do
      # unpublished course with invited student
      course_with_student
      expect(@course.grants_right?(@student, :read)).to be_falsey
      api_call(:get,
               "/api/v1/users/#{@student.id}/courses/#{@course.id}/assignments",
               {
                   :controller => 'assignments_api',
                   :action => 'user_index',
                   :format => 'json',
                   :course_id=> @course.id,
                   :user_id=> @student.id.to_s
               },
               {},
               {},
               {:expected_status => 401}
              )
    end

    it "returns data for for teacher who can read target student data" do
      course_with_student_submissions(active_all: true)

      json = api_get_assignments_user_index(@student, @course, @teacher)
      expect(json[0]['course_id']).to eq @course.id
    end

    it "returns data for ta who can read target student data" do
      course_with_teacher(active_all: true)
      section = add_section('section')
      student = student_in_section(section)
      ta = ta_in_section(section)

      json = api_get_assignments_user_index(student, @course, ta)
      expect(response).to be_success
    end

    it "returns unauthorized for ta who cannot read target student data" do
      course_with_teacher(active_all: true)
      s1 = add_section('for student')
      s2 = add_section('for ta')
      student = student_in_section(s1)
      ta = ta_in_section(s2)

      api_call_as_user(ta, :get,
               "/api/v1/users/#{student.id}/courses/#{@course.id}/assignments",
               {
                   :controller => 'assignments_api',
                   :action => 'user_index',
                   :format => 'json',
                   :course_id=> @course.id,
                   :user_id=> student.id.to_s
               },
               {},
               {},
               {:expected_status => 401}
              )
    end
  end

  describe "POST /courses/:course_id/assignments (#create)" do

    def create_assignment_json(group, group_category)
      { 'name' => 'some assignment',
        'position' => '1',
        'points_possible' => '12',
        'due_at' => '2011-01-01T00:00:00Z',
        'lock_at' => '2011-01-03T00:00:00Z',
        'unlock_at' => '2011-12-31T00:00:00Z',
        'description' => 'assignment description',
        'assignment_group_id' => group.id,
        'submission_types' => [
          'online_upload'
        ],
        'notify_of_update' => true,
        'allowed_extensions' => [
          'docx','ppt'
        ],
        'grade_group_students_individually' => true,
        'automatic_peer_reviews' => true,
        'peer_reviews' => true,
        'peer_reviews_assign_at' => '2011-01-02T00:00:00Z',
        'peer_review_count' => 2,
        'group_category_id' => group_category.id,
        'turnitin_enabled' => true,
        'vericite_enabled' => true,
        'grading_type' => 'points',
        'muted' => 'true'
      }
    end

    before :once do
      course_with_teacher(:active_all => true)
    end

    it 'should respect post_to_sis default' do
      a = @course.account
      a.settings[:sis_default_grade_export] = {locked: false, value: true}
      a.save!
      group = @course.assignment_groups.create!({name: "first group"})
      group_category = @course.group_categories.create!(name: "foo")
      json = api_create_assignment_in_course(@course, create_assignment_json(group, group_category))
      expect(json['post_to_sis']).to eq true
      a.settings[:sis_default_grade_export] = {locked: false, value: false}
      a.save!
      json = api_create_assignment_in_course(@course, create_assignment_json(group, group_category))
      expect(json['post_to_sis']).to eq false
    end

    it "should not overwrite post_to_sis with default if missing in update params" do
      a = @course.account
      a.settings[:sis_default_grade_export] = {locked: false, value: true}
      a.save!
      json = api_create_assignment_in_course(@course, {'name' => 'some assignment'})
      @assignment = Assignment.find(json['id'])
      expect(@assignment.post_to_sis).to eq true
      a.settings[:sis_default_grade_export] = {locked: false, value: false}
      a.save!

      json = api_call(:put,
        "/api/v1/courses/#{@course.id}/assignments/#{@assignment.id}",
        {
          :controller => 'assignments_api',
          :action => 'update',
          :format => 'json',
          :course_id => @course.id.to_s,
          :id => @assignment.to_param
        },
        {:assignment => {:points_possible => 10}})
      @assignment.reload
      expect(@assignment.post_to_sis).to eq true
    end

    it "returns unauthorized for users who do not have permission" do
      student_in_course(:active_all => true)
      @group = @course.assignment_groups.create!({:name => "some group"})
      @group_category = @course.group_categories.create!(name: "foo")

      @user = @student
      api_call(:post,
        "/api/v1/courses/#{@course.id}/assignments",
        {
          :controller => 'assignments_api',
          :action => 'create',
          :format => 'json',
          :course_id => @course.id.to_s
        },
        create_assignment_json(@group, @group_category),
        {},
        {:expected_status => 401}
      )
    end

    it "allows authenticated users to create assignments" do
      @course.assignment_groups.create!({:name => "first group"})
      @group = @course.assignment_groups.create!({:name => "some group"})
      @course.assignment_groups.create!({:name => "last group",
        :position => 2})
      @group_category = @course.group_categories.create!(name: "foo")
      @course.any_instantiation.expects(:turnitin_enabled?).
        at_least_once.returns true
      @course.any_instantiation.expects(:vericite_enabled?).
        at_least_once.returns true
      @json = api_create_assignment_in_course(@course,
        create_assignment_json(@group, @group_category)
       )
      @group_category.reload
      @assignment = Assignment.find @json['id']
      @assignment.reload
      expect(@json['id']).to eq @assignment.id
      expect(@json['assignment_group_id']).to eq @group.id
      expect(@json['name']).to eq 'some assignment'
      expect(@json['course_id']).to eq @course.id
      expect(@json['description']).to eq 'assignment description'
      expect(@json['muted']).to eq true
      expect(@json['lock_at']).to eq @assignment.lock_at.iso8601
      expect(@json['unlock_at']).to eq @assignment.unlock_at.iso8601
      expect(@json['automatic_peer_reviews']).to eq true
      expect(@json['peer_reviews']).to eq true
      expect(@json['peer_review_count']).to eq 2
      expect(@json['peer_reviews_assign_at']).to eq(
        @assignment.peer_reviews_assign_at.iso8601
      )
      expect(@json['position']).to eq 1
      expect(@json['group_category_id']).to eq @group_category.id
      expect(@json['turnitin_enabled']).to eq true
      expect(@json['vericite_enabled']).to eq true
      expect(@json['turnitin_settings']).to eq({
        'originality_report_visibility' => 'immediate',
        's_paper_check' => true,
        'submit_papers_to' => true,
        'internet_check' => true,
        'journal_check' => true,
        'exclude_biblio' => true,
        'exclude_quoted' => true,
        'exclude_small_matches_type' => nil,
        'exclude_small_matches_value' => nil
      })
      expect(@json['allowed_extensions']).to match_array [
        'docx','ppt'
      ]
      expect(@json['points_possible']).to eq 12
      expect(@json['grading_type']).to eq 'points'
      expect(@json['due_at']).to eq @assignment.due_at.iso8601
      expect(@json['html_url']).to eq course_assignment_url(@course,@assignment)
      expect(@json['needs_grading_count']).to eq 0

      expect(Assignment.count).to eq 1
    end

    it "should not allow assignment titles longer than 255 characters" do
      name_too_long = "a" * 256

      expect{
        raw_api_call(:post,
          "/api/v1/courses/#{@course.id}/assignments.json",
          {
               :controller => 'assignments_api',
               :action => 'create',
               :format => 'json',
               :course_id => @course.id.to_s
          },
          {:assignment => { 'name' => name_too_long} }
        )
        assert_status(400)
      }.not_to change(Assignment, :count)
    end

    it "does not allow modifying turnitin_enabled when not enabled on the context" do
      Course.any_instance.expects(:turnitin_enabled?).at_least_once.returns false
      response = api_create_assignment_in_course(@course,
            { 'name' => 'some assignment',
              'turnitin_enabled' => false
            }
       )

      expect(response.keys).not_to include 'turnitin_enabled'
      expect(Assignment.last.turnitin_enabled).to be_falsey
    end

    it "does not allow modifying vericite_enabled when not enabled on the context" do
      Course.any_instance.expects(:vericite_enabled?).at_least_once.returns false
      response = api_create_assignment_in_course(@course,
            { 'name' => 'some assignment',
              'vericite_enabled' => false
            }
       )

      expect(response.keys).not_to include 'vericite_enabled'
      expect(Assignment.last.vericite_enabled).to be_falsey
    end

    it "should process html content in description on create" do
      should_process_incoming_user_content(@course) do |content|
        api_create_assignment_in_course(@course, { 'description' => content })

        a = Assignment.last
        a.reload
        a.description
      end
    end

    it "sets the lti_context_id if provided" do
      lti_assignment_id = SecureRandom.uuid
      jwt = Canvas::Security.create_jwt(lti_assignment_id: lti_assignment_id)

      api_create_assignment_in_course(@course, { 'description' => 'description',
        'secure_params' => jwt
      })

      a = Assignment.last
      expect(a.lti_context_id).to eq(lti_assignment_id)
    end

    it "should allow valid submission types as an array" do
      raw_api_call(:post, "/api/v1/courses/#{@course.id}/assignments",
        { :controller => 'assignments_api',
          :action => 'create',
          :format => 'json',
          :course_id => @course.id.to_s },
        { :assignment => {
            'name' => 'some assignment',
            'submission_types' => [
              'online_upload',
              'online_url'
            ]}
      })
      expect(response).to be_success
    end

    it "should allow valid submission types as a string (quick add dialog)" do
      raw_api_call(:post, "/api/v1/courses/#{@course.id}/assignments",
        { :controller => 'assignments_api',
          :action => 'create',
          :format => 'json',
          :course_id => @course.id.to_s },
        { :assignment => {
            'name' => 'some assignment',
            'submission_types' => 'not_graded'}
      })
      expect(response).to be_success
    end

    it "should not allow unpermitted submission types" do
      raw_api_call(:post, "/api/v1/courses/#{@course.id}/assignments",
        { :controller => 'assignments_api',
          :action => 'create',
          :format => 'json',
          :course_id => @course.id.to_s },
        { :assignment => {
            'name' => 'some assignment',
            'submission_types' => [
              'on_papers'
            ]}
      })
      expect(response.code).to eql '400'
    end

    it "allows creating an assignment with overrides via the API" do
      student_in_course(:course => @course, :active_enrollment => true)

      @adhoc_due_at = 5.days.from_now
      @section_due_at = 7.days.from_now

      @user = @teacher

      assignment_params = {
        :assignment => {
          'name' => 'some assignment',
          'assignment_overrides' => {
            '0' => {
              'student_ids' => [@student.id],
              'due_at' => @adhoc_due_at.iso8601
            },
            '1' => {
                'course_section_id' => @course.default_section.id,
                'due_at' => @section_due_at.iso8601
            },
            '2' => {
                'title' => 'Helpful Tag',
                'noop_id' => 999
            }
          }
        }
      }

      controller_params = {
        :controller => 'assignments_api',
        :action => 'create',
        :format => 'json',
        :course_id => @course.id.to_s
      }

      @json = api_call(
        :post,
        "/api/v1/courses/#{@course.id}/assignments.json",
        controller_params,
        assignment_params
      )

      @assignment = Assignment.find @json['id']
      expect(@assignment.assignment_overrides.count).to eq 3

      @adhoc_override = @assignment.assignment_overrides.where(set_type: 'ADHOC').first
      expect(@adhoc_override).not_to be_nil
      expect(@adhoc_override.set).to eq [@student]
      expect(@adhoc_override.due_at_overridden).to be_truthy
      expect(@adhoc_override.due_at.to_i).to eq @adhoc_due_at.to_i
      expect(@adhoc_override.title).to eq "1 student"

      @section_override = @assignment.assignment_overrides.where(set_type: 'CourseSection').first
      expect(@section_override).not_to be_nil
      expect(@section_override.set).to eq @course.default_section
      expect(@section_override.due_at_overridden).to be_truthy
      expect(@section_override.due_at.to_i).to eq @section_due_at.to_i

      @noop_override = @assignment.assignment_overrides.where(set_type: 'Noop').first
      expect(@noop_override).not_to be_nil
      expect(@noop_override.set).to be_nil
      expect(@noop_override.set_type).to eq 'Noop'
      expect(@noop_override.set_id).to eq 999
      expect(@noop_override.title).to eq 'Helpful Tag'
      expect(@noop_override.due_at_overridden).to be_falsey
    end

    it 'accepts configuration argument to split needs grading by section' do
      student_in_course(:course => @course, :active_enrollment => true)
      @user = @teacher

      json = api_call(:post, "/api/v1/courses/#{@course.id}/assignments.json",
        { :controller => 'assignments_api',
          :action => 'create',
          :format => 'json',
          :course_id => @course.id.to_s },
        { :assignment => {
            'name' => 'some assignment',
            'assignment_overrides' => {
              '0' => {
                'student_ids' => [@student.id],
                'title' => 'some title'
              },
              '1' => {
                  'course_section_id' => @course.default_section.id
                }
            }
          }
        })

      assignments_json = api_call(:get, "/api/v1/courses/#{@course.id}/assignments.json",
        { controller: 'assignments_api',
          action: 'index',
          format: 'json',
          course_id: @course.id.to_s }, {needs_grading_count_by_section: 'true'})
      expect(assignments_json[0].keys).to include("needs_grading_count_by_section")

      assignment_id = assignments_json[0]['id']
      show_json = api_call(:get, "/api/v1/courses/#{@course.id}/assignments/#{assignment_id}.json",
        { controller: 'assignments_api',
          action: 'show',
          format:'json',
          course_id: @course.id.to_s,
          id: assignment_id.to_s
        }, {needs_grading_count_by_section: 'true'})
      expect(show_json.keys).to include("needs_grading_count_by_section")
    end

    context "adhoc overrides" do
      def adhoc_override_api_call(rest_method, endpoint, action, opts={})
        overrides = [{
                      'student_ids' => opts[:student_ids] || [],
                      'title' => opts[:title] || 'adhoc override',
                      'due_at' => opts[:adhoc_due_at] || (5.days.from_now).iso8601
                    }]

        overrides.concat(opts[:additional_overrides]) if opts[:additional_overrides]
        overrides_hash = Hash[(0...overrides.size).zip overrides]

        api_params = {
            :controller => 'assignments_api',
            :action => action,
            :format => 'json',
            :course_id => @course.id.to_s
          }
        api_params.merge!(opts[:additional_api_params]) if opts[:additional_api_params]

        api_call(rest_method, "/api/v1/courses/#{@course.id}/#{endpoint}",
          api_params,
          {
            :assignment => {
              'name' => 'some assignment',
              'assignment_overrides' => overrides_hash,
            }
          }
        )
      end

      def api_call_to_create_adhoc_override(opts={})
        adhoc_override_api_call(:post, 'assignments.json', 'create', opts)
      end

      def api_call_to_update_adhoc_override(opts={})
        opts[:additional_api_params] = {id: @assignment.id.to_s}
        adhoc_override_api_call(:put, "assignments/#{@assignment.id}", 'update', opts)
      end

      it 'allows the update of an adhoc override with one more student' do
        student_in_course(:course => @course, :active_enrollment => true)
        @first_student = @student
        student_in_course(:course => @course, :active_enrollment => true)

        @user = @teacher
        json = api_call_to_create_adhoc_override(student_ids: [@student.id])

        @assignment = Assignment.find json['id']
        adhoc_override = @assignment.assignment_overrides.active.where(set_type: 'ADHOC').first

        expect(@assignment.assignment_overrides.count).to eq 1

        api_call_to_update_adhoc_override(student_ids: [@student.id, @first_student.id])

        ao = @assignment.assignment_overrides.active.where(set_type: 'ADHOC').first
        expect(ao.set).to  match_array([@student, @first_student])
      end

      it 'allows the update of an adhoc override with one less student' do
        student_in_course(:course => @course, :active_enrollment => true)
        @first_student = @student
        student_in_course(:course => @course, :active_enrollment => true)

        @user = @teacher
        json = api_call_to_create_adhoc_override(student_ids: [@student.id, @first_student.id])
        @assignment = Assignment.find json['id']

        api_call_to_update_adhoc_override(student_ids: [@student.id])

        ao = @assignment.assignment_overrides.where(set_type: 'ADHOC').first
        expect(AssignmentOverrideStudent.count ==1)
      end

      it 'allows the update of an adhoc override with different student' do
        student_in_course(:course => @course, :active_enrollment => true)
        @first_student = @student
        student_in_course(:course => @course, :active_enrollment => true)

        @user = @teacher
        json = api_call_to_create_adhoc_override(student_ids: [@student.id])
        @assignment = Assignment.find json['id']

        expect(@assignment.assignment_overrides.count).to eq 1

        adhoc_override = @assignment.assignment_overrides.active.where(set_type: 'ADHOC').first
        expect(adhoc_override.set).to eq [@student]

        api_call_to_update_adhoc_override(student_ids: [@first_student.id])

        ao = @assignment.assignment_overrides.active.where(set_type: 'ADHOC').first
        expect(ao.set).to eq [@first_student]
      end
    end

    context "notifications" do
      before :once do
        student_in_course(:course => @course, :active_enrollment => true)
        course_with_ta(:course => @course, :active_enrollment => true)
        @course.course_sections.create!

        @notification = Notification.create! :name => "Assignment Created"

        @student.register!
        @student.communication_channels.create(:path => "student@instructure.com").confirm!
        @student.email_channel.notification_policies.create!(notification: @notification,
          frequency: 'immediately')
      end

      it "takes overrides into account in the assignment-created notification " +
        "for assignments created with overrides" do
        @ta.register!
        @ta.communication_channels.create(:path => "ta@instructure.com").confirm!
        @ta.email_channel.notification_policies.create!(notification: @notification,
                                                        frequency: 'immediately')

        @override_due_at = Time.parse('2002 Jun 22 12:00:00')

        @user = @teacher
        json = api_call(:post,
                 "/api/v1/courses/#{@course.id}/assignments.json",
                 {
                   :controller => 'assignments_api',
                   :action => 'create', :format => 'json',
                   :course_id => @course.id.to_s },
                 { :assignment => {
                     'name' => 'some assignment',
                     'assignment_overrides' => {
                         '0' => {
                           'course_section_id' => @student.enrollments.first.course_section.id,
                           'due_at' => @override_due_at.iso8601
                         }
                     }
                   }
                   })
        assignment = Assignment.find(json['id'])
        assignment.publish if assignment.unpublished?

        expect(@student.messages.detect{|m| m.notification_id == @notification.id}.body).
          to be_include 'Jun 22'
        expect(@ta.messages.detect{|m| m.notification_id == @notification.id}.body).
          to be_include 'Multiple Dates'
      end

      it "should send notification of creation on save and publish" do
        assignment = @course.assignments.new(:name => "blah")
        assignment.workflow_state = 'unpublished'
        assignment.save!

        @user = @teacher
        json = api_call(:put,
          "/api/v1/courses/#{@course.id}/assignments/#{assignment.id}",
          {
            :controller => 'assignments_api',
            :action => 'update', :format => 'json',
            :course_id => @course.id.to_s,
            :id => assignment.to_param
          },
          { :assignment => {
            'published' => true,
            'assignment_overrides' => {
              '0' => {
                'course_section_id' => @student.enrollments.first.course_section.id,
                'due_at' => 1.day.from_now.iso8601
              }
            }
          }
          })
        expect(@student.messages.detect{|m| m.notification_id == @notification.id}).to be_present
      end
    end

    it "should not allow an assignment_group_id that is not a number" do
      student_in_course(:course => @course, :active_enrollment => true)
      @user = @teacher

      raw_api_call(:post, "/api/v1/courses/#{@course.id}/assignments",
        { :controller => 'assignments_api',
          :action => 'create',
          :format => 'json',
          :course_id => @course.id.to_s },
        { :assignment => {
            'name' => 'some assignment',
            'assignment_group_id' => 'foo'
          }
        })

      expect(response).not_to be_success
      json = JSON.parse response.body
      expect(json['errors']['assignment[assignment_group_id]'].first['message']).
        to eq "must be a positive number"
    end

    context "discussion topic assignments" do
      it "should prevent creating assignments with group category IDs and discussions" do
        course_with_teacher(:active_all => true)
        group_category = @course.group_categories.create!(name: "foo")
        raw_api_call(:post, "/api/v1/courses/#{@course.id}/assignments",
          { :controller => 'assignments_api',
            :action => 'create',
            :format => 'json',
            :course_id => @course.id.to_s },
          { :assignment => {
              'name' => 'some assignment',
              'group_category_id' => group_category.id,
              'submission_types' => [
                 'discussion_topic'
              ],
              'discussion_topic' => {
                'title' => 'some assignment'
              }
            }
          })
        expect(response.code).to eql '400'
      end
    end
  end

  describe "PUT /courses/:course_id/assignments/:id (#update)" do
    before :once do
      course_with_teacher(:active_all => true)
    end

    it "returns unauthorized for users who do not have permission" do
      course_with_student(:active_all => true)
      @assignment = @course.assignments.create!({
        :name => "some assignment",
        :points_possible => 15
      })

      api_call(:put,
        "/api/v1/courses/#{@course.id}/assignments/#{@assignment.id}",
        {
          :controller => 'assignments_api',
          :action => 'update',
          :format => 'json',
          :course_id => @course.id.to_s,
          :id => @assignment.to_param
        },
        { 'points_possible' => 10 },
        {},
        {:expected_status => 401}
      )
    end

    it "should update published/unpublished" do
      @assignment = @course.assignments.create({
        :name => "some assignment",
        :points_possible => 15
      })
      @assignment.workflow_state = 'unpublished'
      @assignment.save!

      #change it to published
      api_update_assignment_call(@course, @assignment, {'published' => true})
      @assignment.reload
      expect(@assignment.workflow_state).to eq 'published'

      #change it back to unpublished
      api_update_assignment_call(@course, @assignment, {'published' => false})
      @assignment.reload
      expect(@assignment.workflow_state).to eq 'unpublished'

      course_with_student(:active_all => true, :course => @course)
      @assignment.submit_homework(@student, :submission_type => "online_text_entry")
      @assignment.publish
      @user = @teacher
      raw_api_call(
        :put,
        "/api/v1/courses/#{@course.id}/assignments/#{@assignment.id}.json",
        {
          :controller => 'assignments_api',
          :action => 'update',
          :format => 'json',
          :course_id => @course.id.to_s,
          :id => @assignment.id.to_s
        },
        { :assignment => { :published => false } }
      )
      expect(response).not_to be_success
      json = JSON.parse response.body
      expect(json['errors']['published'].first['message']).
        to eq "Can't unpublish if there are student submissions"
    end

    it "updates using lti_context_id" do
      @assignment = @course.assignments.create({
                                                 :name => "some assignment",
                                                 :points_possible => 15
                                               })
      raw_api_call(:put,
                   "/api/v1/courses/#{@course.id}/assignments/lti_context_id:#{@assignment.lti_context_id}.json",
                   {:controller => 'assignments_api', :action => 'update',
                    :format => 'json',
                    :course_id => @course.id.to_s,
                    :id => "lti_context_id:#{@assignment.lti_context_id}"},
                   {
                     assignment: {:published => false}
                   })
      expect(JSON.parse(response.body)['id']).to eq @assignment.id
    end


    it "should 400 with invalid date times" do
      the_date = 1.day.ago
      @assignment = @course.assignments.create({
        :name => "some assignment",
        :points_possible => 15
      })
      @assignment.due_at = the_date
      @assignment.lock_at = the_date
      @assignment.unlock_at = the_date
      @assignment.peer_reviews_assign_at = the_date
      @assignment.save!
      raw_api_update_assignment(@course, @assignment,
                                {'peer_reviews_assign_at' => '1/1/2013' })
      expect(response).not_to be_success
      expect(response.code).to eql '400'
      json = JSON.parse response.body
      expect(json['errors']['assignment[peer_reviews_assign_at]'].first['message']).
        to eq 'Invalid datetime for peer_reviews_assign_at'
    end

    it "should allow clearing dates" do
      the_date = 1.day.ago
      @assignment = @course.assignments.create({
        :name => "some assignment",
        :points_possible => 15
      })
      @assignment.due_at = the_date
      @assignment.lock_at = the_date
      @assignment.unlock_at = the_date
      @assignment.peer_reviews_assign_at = the_date
      @assignment.save!

      api_update_assignment_call(@course, @assignment,
                                 {'due_at' => nil,
                                  'lock_at' => '',
                                  'unlock_at' => nil,
                                  'peer_reviews_assign_at' => nil })
      expect(response).to be_success
      @assignment.reload

      expect(@assignment.due_at).to be_nil
      expect(@assignment.lock_at).to be_nil
      expect(@assignment.unlock_at).to be_nil
      expect(@assignment.peer_reviews_assign_at).to be_nil
    end

    it "should not allow updating an assignment title to longer than 255 characters" do
      course_with_teacher(:active_all => true)
      name_too_long = "a" * 256
      #create an assignment
      @json = api_create_assignment_in_course(@course, {'name' => 'some name'})
      @assignment = Assignment.find @json['id']
      @assignment.reload

      #not update an assignment with a name too long
      raw_api_call(
        :put,
        "/api/v1/courses/#{@course.id}/assignments/#{@assignment.id}.json",
        {
          :controller => 'assignments_api',
          :action => 'update',
          :format => 'json',
          :course_id => @course.id.to_s,
          :id => @assignment.id.to_s
        },
        { :assignment => { 'name' => name_too_long} }
      )
      assert_status(400)
      @assignment.reload
      expect(@assignment.name).to eq 'some name'
    end

    it "disallows updating deleted assignments" do
      course_with_teacher(:active_all => true)
      @assignment = @course.assignments.create!({
        :name => "some assignment",
        :points_possible => 15
      })
      @assignment.destroy

      api_call(:put,
        "/api/v1/courses/#{@course.id}/assignments/#{@assignment.id}",
        {
          :controller => 'assignments_api',
          :action => 'update',
          :format => 'json',
          :course_id => @course.id.to_s,
          :id => @assignment.to_param
        },
        { 'points_possible' => 10 },
        {},
        {:expected_status => 404}
      )
    end

    context "without overrides or frozen attributes" do
      before :once do
        @start_group = @course.assignment_groups.create!({:name => "start group"})
        @group = @course.assignment_groups.create!({:name => "new group"})
        @assignment = @course.assignments.create!(:title => "some assignment",
                                                  :points_possible => 15,
                                                  :description => "blah",
                                                  :position => 2,
                                                  :peer_review_count => 2,
                                                  :peer_reviews => true,
                                                  :peer_reviews_due_at => Time.now,
                                                  :grading_type => 'percent',
                                                  :due_at => nil)
        @assignment.update_attribute(:muted, false)
        @assignment.assignment_group = @start_group
        @assignment.group_category = @assignment.context.group_categories.create!(name: "foo")
        @assignment.save!

        @new_grading_standard = grading_standard_for(@course)
      end

      before :each do
        @json = api_update_assignment_call(@course,@assignment,{
          'name' => 'some assignment',
          'points_possible' => '12',
          'assignment_group_id' => @group.id,
          'peer_reviews' => false,
          'grading_standard_id' => @new_grading_standard.id,
          'group_category_id' => nil,
          'description' => 'assignment description',
          'grading_type' => 'letter_grade',
          'due_at' => '2011-01-01T00:00:00Z',
          'position' => 1,
          'muted' => true
        })
        @assignment.reload
      end

      it "returns, but does not update, the assignment's id" do
        expect(@json['id']).to eq @assignment.id
      end

      it "updates the assignment's assignment group id" do
        expect(@assignment.assignment_group_id).to eq @group.id
        expect(@json['assignment_group_id']).to eq @group.id
      end

      it "updates the title/name of the assignment" do
        expect(@assignment.title).to eq 'some assignment'
        expect(@json['name']).to eq 'some assignment'
      end

      it "returns, but doesn't update, the assignment's course_id" do
        expect(@assignment.context_id).to eq @course.id
        expect(@json['course_id']).to eq @course.id
      end

      it "updates the assignment's description" do
        expect(@assignment.description).to eq 'assignment description'
        expect(@json['description']).to eq 'assignment description'
      end

      it "updates the assignment's muted property" do
        expect(@assignment.muted?).to eq true
        expect(@json['muted']).to eq true
      end

      it "updates the assignment's position" do
        expect(@assignment.position).to eq 1
        expect(@json['position']).to eq @assignment.position
      end

      it "updates the assignment's points possible" do
        expect(@assignment.points_possible).to eq 12
        expect(@json['points_possible']).to eq @assignment.points_possible
      end

      it "updates the assignment's grading_type" do
        expect(@assignment.grading_type).to eq 'letter_grade'
        expect(@json['grading_type']).to eq @assignment.grading_type
      end

      it "updates the assignments grading_type when outcome not provided" do
        @json = api_update_assignment_call(@course,@assignment,{
            'grading_type' => 'points'
        })
        @assignment.reload
        expect(@assignment.grading_type).to eq 'points'
        expect(@json['grading_type']).to eq @assignment.grading_type
      end

      it "returns, but does not change, the needs_grading_count" do
        expect(@assignment.needs_grading_count).to eq 0
        expect(@json['needs_grading_count']).to eq 0
      end

      it "updates the assignment's due_at" do
        # fancy midnight
        expect(@json['due_at']).to eq "2011-01-01T23:59:59Z"
      end

      it "updates the assignment's submission types" do
        expect(@assignment.submission_types).to eq 'none'
        expect(@json['submission_types']).to eq ['none']
      end

      it "updates the group_category_id" do
        expect(@json['group_category_id']).to eq nil
      end

      it "returns the html_url, which is a URL to the assignment" do
        expect(@json['html_url']).to eq course_assignment_url(@course,@assignment)
      end

      it "updates the peer reviews info" do
        expect(@assignment.peer_reviews).to eq false
        expect(@json.has_key?( 'peer_review_count' )).to eq false
        expect(@json.has_key?( 'peer_reviews_assign_at' )).to eq false
      end

      it "updates the grading standard" do
        expect(@assignment.grading_standard_id).to eq @new_grading_standard.id
        expect(@json['grading_standard_id']).to eq @new_grading_standard.id
      end
    end

    it "should process html content in description on update" do
      @assignment = @course.assignments.create!

      should_process_incoming_user_content(@course) do |content|
        api_update_assignment_call(@course, @assignment, {
            'description' => content
        })

        @assignment.reload
        @assignment.description
      end
    end

    context "with assignment overrides on the assignment" do
      describe 'updating assignment overrides' do
        before :once do
          student_in_course(:course => @course, :active_enrollment => true)
          @assignment = @course.assignments.create!
          @adhoc_due_at = 5.days.from_now
          @section_due_at = 7.days.from_now
          @user = @teacher
        end

        before :each do
          api_update_assignment_call(@course,@assignment,{
            'name' => 'Assignment With Overrides',
            'assignment_overrides' => {
              '0' => {
                'student_ids' => [@student.id],
                'title' => 'adhoc override',
                'due_at' => @adhoc_due_at.iso8601
              },
              '1' => {
                'course_section_id' => @course.default_section.id,
                'due_at' => @section_due_at.iso8601
              },
              '2' => {
                'title' => 'Helpful Tag',
                'noop_id' => 999
              }
            }
          })
          @assignment.reload
        end

        it "updates any ADHOC overrides" do
          expect(@assignment.assignment_overrides.count).to eq 3
          @adhoc_override = @assignment.assignment_overrides.where(set_type: 'ADHOC').first
          expect(@adhoc_override).not_to be_nil
          expect(@adhoc_override.set).to eq [@student]
          expect(@adhoc_override.due_at_overridden).to be_truthy
          expect(@adhoc_override.due_at.to_i).to eq @adhoc_due_at.to_i
        end

        it "updates any CourseSection overrides" do
          @section_override = @assignment.assignment_overrides.where(set_type: 'CourseSection').first
          expect(@section_override).not_to be_nil
          expect(@section_override.set).to eq @course.default_section
          expect(@section_override.due_at_overridden).to be_truthy
          expect(@section_override.due_at.to_i).to eq @section_due_at.to_i
        end

        it "updates any Noop overrides" do
          @noop_override = @assignment.assignment_overrides.where(set_type: 'Noop').first
          expect(@noop_override).not_to be_nil
          expect(@noop_override.set).to be_nil
          expect(@noop_override.set_type).to eq 'Noop'
          expect(@noop_override.set_id).to eq 999
          expect(@noop_override.title).to eq 'Helpful Tag'
          expect(@noop_override.due_at_overridden).to be_falsey
        end
      end

      describe "deleting all CourseSection overrides from assignment" do
        it "works when :assignment_overrides key is nil" do
          student_in_course(:course => @course, :active_all => true)
          @assignment = @course.assignments.create!
          Assignment.where(:id => @assignment).update_all(:created_at => Time.zone.now - 1.day)
          @section_due_at = 7.days.from_now
          @params = {
            'name' => 'Assignment With Overrides',
            'assignment_overrides' => {}
          }
          @user = @teacher

          expect(@params.has_key?('assignment_overrides')).to be_truthy

          api_update_assignment_call(@course, @assignment, @params)
          expect(@assignment.assignment_overrides.active.count).to eq 0
        end
      end
    end

    context "broadcasting while updating overrides" do
      before :once do
        @notification = Notification.create! :name => "Assignment Changed"
        student_in_course(:course => @course, :active_all => true)
        @student.communication_channels.create(:path => "student@instructure.com").confirm!
        @student.email_channel.notification_policies.create!(notification: @notification,
                                                             frequency: 'immediately')
        @assignment = @course.assignments.create!
        Assignment.where(:id => @assignment).update_all(:created_at => Time.zone.now - 1.day)
        @adhoc_due_at = 5.days.from_now
        @section_due_at = 7.days.from_now
        @params = {
          'name' => 'Assignment With Overrides',
          'assignment_overrides' => {
            '0' => {
              'student_ids' => [@student.id],
              'title' => 'adhoc override',
              'due_at' => @adhoc_due_at.iso8601
            },
            '1' => {
              'course_section_id' => @course.default_section.id,
              'due_at' => @section_due_at.iso8601
            }
          }
        }
      end

      it "should not send assignment_changed if notify_of_update is not set" do
        @user = @teacher
        api_update_assignment_call(@course,@assignment,@params)
        expect(@student.messages.detect{|m| m.notification_id == @notification.id}).to be_nil
      end

      it "should send assignment_changed if notify_of_update is set" do
        @user = @teacher
        api_update_assignment_call(@course,@assignment,@params.merge({:notify_of_update => true}))
        expect(@student.messages.detect{|m| m.notification_id == @notification.id}).to be_present
      end
    end

    context "when turnitin is enabled on the context" do
      before :once do
        @assignment = @course.assignments.create!
        acct = @course.account
        acct.turnitin_account_id = 0
        acct.turnitin_shared_secret = "blah"
        acct.save!
      end

      it "should allow setting turnitin_enabled" do
        expect(@assignment).not_to be_turnitin_enabled
        api_update_assignment_call(@course,@assignment,{
          'turnitin_enabled' => '1',
        })
        expect(@assignment.reload).to be_turnitin_enabled
        api_update_assignment_call(@course,@assignment,{
          'turnitin_enabled' => '0',
        })
        expect(@assignment.reload).not_to be_turnitin_enabled
      end

      it "should allow setting valid turnitin_settings" do
        update_settings = {
          :originality_report_visibility => 'after_grading',
          :s_paper_check => '0',
          :internet_check => false,
          :journal_check => '1',
          :exclude_biblio => true,
          :exclude_quoted => '0',
          :submit_papers_to => '1',
          :exclude_small_matches_type => 'percent',
          :exclude_small_matches_value => 50
        }

        json = api_update_assignment_call(@course, @assignment, {
          :turnitin_settings => update_settings
        })
        expect(json["turnitin_settings"]).to eq({
          'originality_report_visibility' => 'after_grading',
          's_paper_check' => false,
          'internet_check' => false,
          'journal_check' => true,
          'exclude_biblio' => true,
          'exclude_quoted' => false,
          'submit_papers_to' => true,
          'exclude_small_matches_type' => 'percent',
          'exclude_small_matches_value' => 50
        })

        expect(@assignment.reload.turnitin_settings).to eq({
          'originality_report_visibility' => 'after_grading',
          's_paper_check' => '0',
          'internet_check' => '0',
          'journal_check' => '1',
          'exclude_biblio' => '1',
          'exclude_quoted' => '0',
          'submit_papers_to' => '1',
          'exclude_type' => '2',
          'exclude_value' => '50',
          's_view_report' => '1'
        })
      end

      it "should not allow setting invalid turnitin_settings" do
        update_settings = {
          :blah => '1'
        }.with_indifferent_access

        api_update_assignment_call(@course, @assignment, {
          :turnitin_settings => update_settings
        })
        expect(@assignment.reload.turnitin_settings["blah"]).to be_nil
      end
    end

    context "when a non-admin tries to update a frozen assignment" do
      before :once do
        @assignment = create_frozen_assignment_in_course(@course)
      end

      before :each do
        PluginSetting.stubs(:settings_for_plugin).returns({"title" => "yes"}).at_least_once
      end

      it "doesn't allow the non-admin to update a frozen attribute" do
        title_before_update = @assignment.title
        raw_api_update_assignment(@course,@assignment,{
          :name => "should not change!"
        })
        expect(response.code).to eql '400'
        expect(@assignment.reload.title).to eq title_before_update
      end

      it "does allow editing a non-frozen attribute" do
        raw_api_update_assignment(@course, @assignment, {
          :points_possible => 15
        })
        expect(response.code).to eql '201'
        expect(@assignment.reload.points_possible).to eq 15
      end
    end

    context "when an admin tries to update a completely frozen assignment" do
      it "allows the admin to update the frozen assignment" do
        @user = account_admin_user
        course_with_teacher(:active_all => true, :user => @user)
        PluginSetting.expects(:settings_for_plugin).
          returns(fully_frozen_settings).at_least_once
        @assignment = create_frozen_assignment_in_course(@course)
        raw_api_update_assignment(@course,@assignment,{
          'name' => "This changes!"
        })
        expect(@assignment.title).to eq "This changes!"
        expect(response.code.to_i).to eql 201
      end
    end

    context "differentiated assignments" do
      before :once do
        @assignment = @course.assignments.create(:name => 'test', :only_visible_to_overrides => false)
        @flag_before = @assignment.only_visible_to_overrides
      end

      it "should update the only_visible_to_overrides flag if differentiated assignments is on" do
        raw_api_update_assignment(@course,@assignment,{
          :only_visible_to_overrides => !@flag_before
        })
        expect(@assignment.reload.only_visible_to_overrides).to eq !@flag_before
      end
    end

    context "when an admin tried to update a grading_standard" do
      before(:once) do
        account_admin_user(user: @user)
        @assignment = @course.assignments.create({:name => "some assignment"})
        @assignment.save!
        @account_standard = @course.account.grading_standards.create!(:title => "account standard", :standard_data => {:a => {:name => 'A', :value => '95'}, :b => {:name => 'B', :value => '80'}, :f => {:name => 'F', :value => ''}})
        @course_standard = @course.grading_standards.create!(:title => "course standard", :standard_data => {:a => {:name => 'A', :value => '95'}, :b => {:name => 'B', :value => '80'}, :f => {:name => 'F', :value => ''}})
      end

      it "allows setting an account grading standard" do
        raw_api_call(
            :put,
            "/api/v1/courses/#{@course.id}/assignments/#{@assignment.id}.json",
            {
                :controller => 'assignments_api',
                :action => 'update',
                :format => 'json',
                :course_id => @course.id.to_s,
                :id => @assignment.id.to_s
            },
            { :assignment => { :grading_standard_id => @account_standard.id } }
        )
        @assignment.reload
        expect(@assignment.grading_standard).to eq @account_standard
      end

      it "allows setting a course level grading standard" do
        raw_api_call(
            :put,
            "/api/v1/courses/#{@course.id}/assignments/#{@assignment.id}.json",
            {
                :controller => 'assignments_api',
                :action => 'update',
                :format => 'json',
                :course_id => @course.id.to_s,
                :id => @assignment.id.to_s
            },
            { :assignment => { :grading_standard_id => @course_standard.id } }
        )
        @assignment.reload
        expect(@assignment.grading_standard).to eq @course_standard
      end

      it "should update a sub account level grading standard" do
        sub_account = @course.account.sub_accounts.create!
        c2 = sub_account.courses.create!
        assignment2 = c2.assignments.create({:name => "some assignment"})
        assignment2.save!
        sub_account_standard = sub_account.grading_standards.create!(:title => "sub account standard", :standard_data => {:a => {:name => 'A', :value => '95'}, :b => {:name => 'B', :value => '80'}, :f => {:name => 'F', :value => ''}})
        raw_api_call(
            :put,
            "/api/v1/courses/#{c2.id}/assignments/#{assignment2.id}.json",
            {
                :controller => 'assignments_api',
                :action => 'update',
                :format => 'json',
                :course_id => c2.id.to_s,
                :id => assignment2.id.to_s
            },
            { :assignment => { :grading_standard_id => sub_account_standard.id } }
        )
        assignment2.reload
        expect(assignment2.grading_standard).to eq sub_account_standard
      end

      it "should not update grading standard from sub account not on account chain" do
        sub_account = @course.account.sub_accounts.create!
        sub_account2 = @course.account.sub_accounts.create!
        c2 = sub_account.courses.create!
        assignment2 = c2.assignments.create({:name => "some assignment"})
        assignment2.save!
        sub_account_standard = sub_account2.grading_standards.create!(:title => "sub account standard", :standard_data => {:a => {:name => 'A', :value => '95'}, :b => {:name => 'B', :value => '80'}, :f => {:name => 'F', :value => ''}})
        raw_api_call(
            :put,
            "/api/v1/courses/#{c2.id}/assignments/#{assignment2.id}.json",
            {
                :controller => 'assignments_api',
                :action => 'update',
                :format => 'json',
                :course_id => c2.id.to_s,
                :id => assignment2.id.to_s
            },
            { :assignment => { :grading_standard_id => sub_account_standard.id } }
        )
        assignment2.reload
        expect(assignment2.grading_standard).to eq nil
      end

      it "should not delete grading standard if invalid standard provided" do
        @assignment.grading_standard = @account_standard
        @assignment.save!
        sub_account = @course.account.sub_accounts.create!
        sub_account_standard = sub_account.grading_standards.create!(:title => "sub account standard", :standard_data => {:a => {:name => 'A', :value => '95'}, :b => {:name => 'B', :value => '80'}, :f => {:name => 'F', :value => ''}})
        raw_api_call(
            :put,
            "/api/v1/courses/#{@course.id}/assignments/#{@assignment.id}.json",
            {
                :controller => 'assignments_api',
                :action => 'update',
                :format => 'json',
                :course_id => @course.id.to_s,
                :id => @assignment.id.to_s
            },
            { :assignment => { :grading_standard_id => sub_account_standard.id } }
        )
        @assignment.reload
        expect(@assignment.grading_standard).to eq @account_standard
      end

      it "should remove a standard if empty value passed" do
        @assignment.grading_standard = @account_standard
        @assignment.save!
        sub_account = @course.account.sub_accounts.create!
        sub_account_standard = sub_account.grading_standards.create!(:title => "sub account standard", :standard_data => {:a => {:name => 'A', :value => '95'}, :b => {:name => 'B', :value => '80'}, :f => {:name => 'F', :value => ''}})
        raw_api_call(
            :put,
            "/api/v1/courses/#{@course.id}/assignments/#{@assignment.id}.json",
            {
                :controller => 'assignments_api',
                :action => 'update',
                :format => 'json',
                :course_id => @course.id.to_s,
                :id => @assignment.id.to_s
            },
            { :assignment => { :grading_standard_id => nil } }
        )
        @assignment.reload
        expect(@assignment.grading_standard).to eq nil
      end
    end

    context "discussion topic assignments" do
      it "should prevent setting group category ID on assignments with discussions" do
        course_with_teacher(:active_all => true)
        group_category = @course.group_categories.create!(name: "foo")
        @assignment = factory_with_protected_attributes(
          @course.assignments,
          {
            :title => 'assignment1',
          })
        @topic = @course.discussion_topics.build(assignment: @assignment, title: 'asdf')
        @topic.save
        raw_api_update_assignment(@course, @assignment, {
          :group_category_id => group_category.id
        })
        @assignment.reload
        expect(@assignment.group_category).to be_nil
        expect(response.code).to eql '400'
      end
    end
  end

  describe "DELETE /courses/:course_id/assignments/:id (#delete)" do
    before :once do
      course_with_student(:active_all => true)
      @assignment = @course.assignments.create!(
        :title => "Test Assignment",
        :description => "public stuff"
      )
    end
    context "user does not have the permission to delete the assignment" do
      it "does not delete the assignment" do
        json = api_call(:delete,
              "/api/v1/courses/#{@course.id}/assignments/#{@assignment.id}",
              {
                :controller => 'assignments',
                :action => 'destroy',
                :format => 'json',
                :course_id => @course.id.to_s,
                :id => @assignment.to_param
              },
              {},
              {},
              {:expected_status => 401})
        expect(@assignment.reload).not_to be_deleted
      end
    end
    context "when user requesting the deletion has permission to delete" do
      it "deletes the assignment " do
        teacher_in_course(:course => @course, :active_all => true)
        json = api_call(:delete,
              "/api/v1/courses/#{@course.id}/assignments/#{@assignment.id}",
              {
                :controller => 'assignments',
                :action => 'destroy',
                :format => 'json',
                :course_id => @course.id.to_s,
                :id => @assignment.to_param
              },
              {},
              {},
              {:expected_status => 200})
        expect(@assignment.reload).to be_deleted
      end

      it "deletes by lti_context_id" do
        teacher_in_course(:course => @course, :active_all => true)
        api_call(:delete,
                 "/api/v1/courses/#{@course.id}/assignments/lti_context_id:#{@assignment.lti_context_id}",
                 {
                   :controller => 'assignments',
                   :action => 'destroy',
                   :format => 'json',
                   :course_id => @course.id.to_s,
                   :id => "lti_context_id:#{@assignment.lti_context_id}"
                 },
                 {},
                 {},
                 {:expected_status => 200})
        expect(@assignment.reload).to be_deleted
      end

    end

  end

  describe "GET /courses/:course_id/assignments/:id (#show)" do

    before :once do
      course_with_student(:active_all => true)
    end

    describe 'with a normal assignment' do

      before :once do
        @assignment = @course.assignments.create!(
          :title => "Locked Assignment",
          :description => "secret stuff"
        )
      end

      before :each do
        @assignment.any_instantiation.stubs(:overridden_for).
          returns @assignment
        @assignment.any_instantiation.stubs(:locked_for?).returns(
          {:asset_string => '', :unlock_at => 1.hour.from_now }
        )
      end

      it "looks up an assignment by lti_context_id" do
        json = api_call(:get,
                        "/api/v1/courses/#{@course.id}/assignments/lti_context_id:#{@assignment.lti_context_id}.json",
                        {:controller => "assignments_api", :action => "show",
                         :format => "json", :course_id => @course.id.to_s,
                         :id => "lti_context_id:#{@assignment.lti_context_id}"})
        expect(json["id"]).to eq @assignment.id
      end

      it "does not return the assignment's description if locked for user" do
        @json = api_get_assignment_in_course(@assignment,@course)
        expect(@json['description']).to be_nil
      end

      it "returns the mute status of the assignment" do
        @json = api_get_assignment_in_course(@assignment,@course)
        expect(@json["muted"]).to eql false
      end

      it "translates assignment descriptions" do
        course_with_teacher(:active_all => true)
        should_translate_user_content(@course) do |content|
          assignment = @course.assignments.create!(:description => content)
          json = api_get_assignment_in_course(assignment,@course)
          json['description']
        end
      end

      it "returns the discussion topic url" do
        @user = @teacher
        @context = @course
        @assignment = factory_with_protected_attributes(
          @course.assignments,
          {
            :title => 'assignment1',
            :submission_types => 'discussion_topic',
            :discussion_topic => discussion_topic_model}
        )
        json = api_get_assignment_in_course(@assignment,@course)
        expect(json['discussion_topic']).to eq({
          'author' => {},
          'id' => @topic.id,
          'title' => 'assignment1',
          'message' => nil,
          'posted_at' => @topic.posted_at.as_json,
          'last_reply_at' => @topic.last_reply_at.as_json,
          'require_initial_post' => nil,
          'discussion_subentry_count' => 0,
          'assignment_id' => @assignment.id,
          'delayed_post_at' => nil,
          'lock_at' => nil,
          'user_name' => @topic.user_name,
          'pinned' => !!@topic.pinned,
          'position' => @topic.position,
          'topic_children' => [],
          'locked' => false,
          'can_lock' => true,
          'locked_for_user' => false,
          'root_topic_id' => @topic.root_topic_id,
          'podcast_url' => nil,
          'podcast_has_student_posts' => nil,
          'read_state' => 'unread',
          'unread_count' => 0,
          'user_can_see_posts' => @topic.user_can_see_posts?(@user),
          'subscribed' => @topic.subscribed?(@user),
          'published' => @topic.published?,
          'can_unpublish' => @topic.can_unpublish?,
          'url' =>
            "http://www.example.com/courses/#{@course.id}/discussion_topics/#{@topic.id}",
          'html_url' =>
            "http://www.example.com/courses/#{@course.id}/discussion_topics/#{@topic.id}",
          'attachments' => [],
          'permissions' => {'delete' => true, 'attach' => true, 'update' => true, 'reply' => true},
          'discussion_type' => 'side_comment',
          'group_category_id' => nil,
          'can_group' => true,
          'allow_rating' => nil,
          'only_graders_can_rate' => nil,
          'sort_by_rating' => nil,
        })
      end

      it "fulfills module progression requirements" do
        @assignment = @course.assignments.create!(
          :title => "Test Assignment",
          :description => "public stuff"
        )
        mod = @course.context_modules.create!(:name => "some module")
        tag = mod.add_item(:id => @assignment.id, :type => 'assignment')
        mod.completion_requirements = { tag.id => {:type => 'must_view'} }
        mod.save!

        # index should not affect anything
        api_call(:get,
                 "/api/v1/courses/#{@course.id}/assignments.json",
                 {
                   :controller => 'assignments_api',
                   :action => 'index',
                   :format => 'json',
                   :course_id => @course.id.to_s
                 })
        expect(mod.evaluate_for(@user)).to be_unlocked

        # show should count as a view
        json = api_get_assignment_in_course(@assignment,@course)
        expect(json['description']).not_to be_nil
        expect(mod.evaluate_for(@user)).to be_completed
      end

      it "returns the dates for assignment as they apply to the user" do
        @student.enrollments.map(&:destroy_permanently!)
        @assignment = @course.assignments.create!(
          :title => "Test Assignment",
          :description => "public stuff"
        )
        @section = @course.course_sections.create! :name => "afternoon delight"
        @course.enroll_user(@student,'StudentEnrollment',
                            :section => @section,
                            :enrollment_state => :active)
        override = create_override_for_assignment
        json = api_get_assignment_in_course(@assignment,@course)
        expect(json['due_at']).to eq override.due_at.iso8601.to_s
        expect(json['unlock_at']).to eq override.unlock_at.iso8601.to_s
        expect(json['lock_at']).to eq override.lock_at.iso8601.to_s
      end

      it "returns original assignment due dates" do
        @student.enrollments.map(&:destroy_permanently!)
        @assignment = @course.assignments.create!(
          :title => "Test Assignment",
          :description => "public stuff",
          :due_at => Time.zone.now + 1.days,
          :unlock_at => Time.zone.now,
          :lock_at => Time.zone.now + 2.days
        )
        @section = @course.course_sections.create! :name => "afternoon delight"
        @course.enroll_user(@student,'StudentEnrollment',
                            :section => @section,
                            :enrollment_state => :active)
        create_override_for_assignment
        json = api_call(:get,
                        "/api/v1/courses/#{@course.id}/assignments/#{@assignment.id}.json",
                        { :controller => "assignments_api", :action => "show",
                          :format => "json", :course_id => @course.id.to_s,
                          :id => @assignment.id.to_s},
                        {:override_assignment_dates => 'false'})
        expect(json['due_at']).to eq @assignment.due_at.iso8601.to_s
        expect(json['unlock_at']).to eq @assignment.unlock_at.iso8601.to_s
        expect(json['lock_at']).to eq @assignment.lock_at.iso8601.to_s
      end

      it "returns has_overrides correctly" do
        @user = @teacher
        @assignment = @course.assignments.create!(:title => "Test Assignment",:description => "foo")
        json = api_get_assignment_in_course(@assignment, @course)
        expect(json['has_overrides']).to eq false

        @section = @course.course_sections.create! :name => "afternoon delight"
        create_override_for_assignment
        json = api_get_assignment_in_course(@assignment, @course)
        expect(json['has_overrides']).to eq true

        @user = @student # don't show has_overrides to students
        json = api_get_assignment_in_course(@assignment, @course)
        expect(json['has_overrides']).to be_nil
      end

      it "returns all_dates when requested" do
        @assignment = @course.assignments.create!(:title => "Test Assignment",:description => "foo")
        json = api_call(:get,
                        "/api/v1/courses/#{@course.id}/assignments/#{@assignment.id}.json",
                        { :controller => "assignments_api", :action => "show",
                          :format => "json", :course_id => @course.id.to_s,
                          :id => @assignment.id.to_s,
                          :all_dates => true},
                        {:override_assignment_dates => 'false'})
        expect(json['all_dates']).not_to be_nil
      end

      it "does not fulfill requirements when description isn't returned" do
        @assignment = @course.assignments.create!(
          :title => "Locked Assignment",
          :description => "locked!"
        )
        @assignment.any_instantiation.expects(:overridden_for)
          .returns @assignment
        @assignment.any_instantiation.expects(:locked_for?).returns({
          :asset_string => '',
          :unlock_at => 1.hour.from_now
        }).at_least(1)

        mod = @course.context_modules.create!(:name => "some module")
        tag = mod.add_item(:id => @assignment.id, :type => 'assignment')
        mod.completion_requirements = { tag.id => {:type => 'must_view'} }
        mod.save!
        json = api_get_assignment_in_course(@assignment,@course)
        expect(json['description']).to be_nil
        expect(mod.evaluate_for(@user)).to be_unlocked
      end

      it "still includes a description when a locked assignment is viewable" do
        @assignment = @course.assignments.create!(
          :title => "Locked but Viewable Assignment",
          :description => "locked but viewable!"
        )
        @assignment.any_instantiation.expects(:overridden_for)
          .returns @assignment
        @assignment.any_instantiation.expects(:locked_for?).returns({
          :asset_string => '',
          :unlock_at => 1.hour.ago,
          :can_view => true
        }).at_least(1)

        mod = @course.context_modules.create!(:name => "some module")
        tag = mod.add_item(:id => @assignment.id, :type => 'assignment')
        mod.completion_requirements = { tag.id => {:type => 'must_view'} }
        mod.save!
        json = api_get_assignment_in_course(@assignment,@course)
        expect(json['description']).not_to be_nil
        expect(mod.evaluate_for(@user)).to be_completed
      end

      it "includes submission info when requested with include flag" do
        assignment,submission = create_submitted_assignment_with_user(@user)
        json = api_call(:get,
          "/api/v1/courses/#{@course.id}/assignments/#{assignment.id}.json",
          { :controller => "assignments_api", :action => "show",
          :format => "json", :course_id => @course.id.to_s,
          :id => assignment.id.to_s},
          {:include => ['submission']})
        expect(json['submission']).to eq(
          json_parse(controller.submission_json(submission,assignment,@user,session).to_json)
        )
      end

      context "AssignmentFreezer plugin disabled" do

        before do
          @user = @teacher
          @assignment = create_frozen_assignment_in_course(@course)
          PluginSetting.stubs(:settings_for_plugin).returns {}
          @json = api_get_assignment_in_course(@assignment,@course)
        end

        it "excludes frozen and frozen_attributes fields" do
          expect(@json.has_key?('frozen')).to eq false
          expect(@json.has_key?('frozen_attributes')).to eq false
        end

      end

      context "AssignmentFreezer plugin enabled" do

        context "assignment frozen" do
          before :once do
            @user = @teacher
            @assignment = create_frozen_assignment_in_course(@course)
          end

          before :each do
            PluginSetting.stubs(:settings_for_plugin).returns({"title" => "yes"})
            @json = api_get_assignment_in_course(@assignment,@course)
          end

          it "tells the consumer that the assignment is frozen" do
            expect(@json['frozen']).to eq true
          end

          it "returns an list of frozen attributes" do
            expect(@json['frozen_attributes']).to eq ["title"]
          end

          it "tells the consumer that the assignment will be frozen when copied" do
            expect(@json['freeze_on_copy']).to be_truthy
          end

          it "returns an empty list when no frozen attributes" do
            PluginSetting.stubs(:settings_for_plugin).returns({})
            json = api_get_assignment_in_course(@assignment,@course)
            expect(json['frozen_attributes']).to eq []
          end
        end

        context "assignment not frozen" do
          before :once do
            @user = @teacher
            @assignment = @course.assignments.create!({
              :title => "Frozen",
              :description => "frozen!"
            })
          end

          before :each do
            PluginSetting.stubs(:settings_for_plugin).returns({"title" => "yes"}) #enable plugin
            @assignment.any_instantiation.expects(:overridden_for).returns @assignment
            @assignment.any_instantiation.expects(:frozen?).at_least_once.returns false
            @json = api_get_assignment_in_course(@assignment,@course)
          end

          it "tells the consumer that the assignment is not frozen" do
            expect(@json['frozen']).to eq false
          end

          it "gives the consumer an empty list for frozen attributes" do
            expect(@json['frozen_attributes']).to eq []
          end

          it "tells the consumer that the assignment will not be frozen when copied" do
            expect(@json['freeze_on_copy']).to eq false
          end
        end

        context "assignment with quiz" do
          before do
            @user = @teacher
            @quiz = Quizzes::Quiz.create!(:title => 'Quiz Name', :context => @course)
            @quiz.did_edit!
            @quiz.offer!
            assignment = @quiz.assignment
            @json = api_get_assignment_in_course(assignment, @course)
          end

          it "should have quiz information" do
            expect(@json['quiz_id']).to eq @quiz.id
            expect(@json['anonymous_submissions']).to eq false
            expect(@json['name']).to eq @quiz.title
            expect(@json['submission_types']).to include 'online_quiz'
          end
        end
      end

      context "external tool assignment" do

        before :once do
          @assignment = @course.assignments.create!
          @tool_tag = ContentTag.new({:url => 'http://www.example.com', :new_tab=>false})
          @tool_tag.context = @assignment
          @tool_tag.save!
          @assignment.submission_types = 'external_tool'
          @assignment.save!
          expect(@assignment.external_tool_tag).not_to be_nil
        end

        before :each do
          @json = api_get_assignment_in_course(@assignment, @course)
        end

        it 'has the external tool submission type' do
          expect(@json['submission_types']).to eq ['external_tool']
        end

        it 'includes the external tool attributes' do
          expect(@json['external_tool_tag_attributes']).to eq({
            'url' => 'http://www.example.com',
            'new_tab' => false,
            'resource_link_id' => ContextExternalTool.opaque_identifier_for(@tool_tag, @tool_tag.context.shard)
          })
        end

        it 'includes the assignment_id attribute' do
          expect(@json).to include('url')
          uri = URI(@json['url'])
          expect(uri.path).to eq "/api/v1/courses/#{@course.id}/external_tools/sessionless_launch"
          expect(uri.query).to include('assignment_id=')
        end
      end
    end

    context "draft state" do

      before :once do
        @assignment = @course.assignments.create!({
          :name => "unpublished assignment",
          :points_possible => 15
        })
        @assignment.workflow_state = 'unpublished'
        @assignment.save!
      end

      it "returns an authorization error to students if an assignment is unpublished" do

        raw_api_call(:get,
          "/api/v1/courses/#{@course.id}/assignments/#{@assignment.id}",
          {
            :controller => 'assignments_api',
            :action => 'show',
            :format => 'json',
            :course_id => @course.id.to_s,
            :id => @assignment.id.to_s
          }
        )

        #should be authorization error
        expect(response.code).to eq '401'
      end

      it "shows an unpublished assignment to teachers" do
        course_with_teacher_logged_in(:course => @course, :active_all => true)

        json = api_get_assignment_in_course(@assignment, @course)
        expect(response).to be_success
        expect(json['id']).to eq @assignment.id
        expect(json['unpublishable']).to eq true

        # Returns "unpublishable => false" when student submissions
        student_in_course(:active_all => true, :course => @course)
        @assignment.submit_homework(@student, :submission_type => "online_text_entry")
        @user = @teacher
        json = api_get_assignment_in_course(@assignment, @course)
        expect(response).to be_success
        expect(json['unpublishable']).to eq false
      end
    end

    context "differentiated assignments" do
      before :once do
        @user = @teacher
        @assignment1 = @course.assignments.create! :only_visible_to_overrides => true
        @assignment2 = @course.assignments.create! :only_visible_to_overrides => true
        section1 = @course.course_sections.create!
        section2 = @course.course_sections.create!
        @student1 = User.create!(name: "Test Student")
        @student2 = User.create!(name: "Test Student2")
        @student3 = User.create!(name: "Test Student3")
        student_in_section(section1, user: @student1)
        student_in_section(section2, user: @student2)
        student_in_section(section2, user: @student3)
        create_section_override_for_assignment(@assignment1, {course_section: section1})
        create_section_override_for_assignment(@assignment2, {course_section: section2})
        assignment_override_model(assignment: @assignment1, set_type: 'Noop', title: 'Just a Tag')
      end

      def visibility_api_request(assignment)
        api_call(:get,
          "/api/v1/courses/#{@course.id}/assignments/#{assignment.id}.json",
          {
            :controller => 'assignments_api', :action => 'show',
            :format => 'json', :course_id => @course.id.to_s,
            :id => assignment.id.to_s
          },
          :include => ['assignment_visibility']
        )
      end

      it "should include overrides if overrides flag is included in the params" do
        ConditionalRelease::Service.stubs(:enabled_in_context?).returns(true)
        assignments_json = api_call(:get, "/api/v1/courses/#{@course.id}/assignments/#{@assignment1.id}.json",
          {
            controller: 'assignments_api',
            action: 'show',
            format: 'json',
            course_id: @course.id.to_s,
            id: @assignment1.id.to_s
          },
          :include => ['overrides']
        )
        expect(assignments_json.keys).to include("overrides")
        expect(assignments_json["overrides"].length).to eq 2
      end


      it "returns any assignment" do
        json1 = api_get_assignment_in_course @assignment1, @course
        expect(json1["id"]).to eq @assignment1.id
        json2 = api_get_assignment_in_course @assignment2, @course
        expect(json2["id"]).to eq @assignment2.id
      end

      it "includes assignment_visibility" do
        json = visibility_api_request @assignment1
        expect(json.has_key?("assignment_visibility")).to eq true
      end

      it "assignment_visibility includes the correct user_ids" do
        json = visibility_api_request @assignment1
        expect(json["assignment_visibility"].include?("#{@student1.id}")).to eq true
        json = visibility_api_request @assignment2
        expect(json["assignment_visibility"].include?("#{@student2.id}")).to eq true
        expect(json["assignment_visibility"].include?("#{@student3.id}")).to eq true
      end

      context "as a student" do
        it "should return a visible assignment" do
          user_session @student1
          @user = @student1
          json = api_get_assignment_in_course @assignment1, @course
          expect(json["id"]).to eq @assignment1.id
        end

        it "should return an error for a non-visible assignment" do
          user_session @student2
          @user = @student2
          json = api_call(:get,
            "/api/v1/courses/#{@course.id}/assignments/#{@assignment1.id}.json",
            { :controller => "assignments_api", :action => "show",
            :format => "json", :course_id => @course.id.to_s,
            :id => @assignment1.id.to_s }, {}, {}, {:expected_status => 401})
        end

        it "should not include assignment_visibility data when requested" do
          user_session @student1
          @user = @student1
          json = visibility_api_request @assignment1
          expect(json.has_key?("assignment_visibility")).to eq false
        end
      end
    end
  end

  describe "assignment_json" do
    let(:result) { assignment_json(@assignment, @user, {}) }

    before :once do
      course_with_teacher(:active_all => true)
      @assignment = @course.assignments.create!(:title => "some assignment")
    end

    context "when turnitin_enabled is true on the context" do
      before {
        @course.account.update_attributes! turnitin_account_id: 1234,
                                                turnitin_shared_secret: 'foo',
                                                turnitin_host: 'example.com'
        @assignment.reload
      }

      it "contains a turnitin_enabled key" do
        expect(result.has_key?('turnitin_enabled')).to eq true
      end
    end

    context "when turnitin_enabled is false on the context" do
      it "does not contain a turnitin_enabled key" do
        expect(result.has_key?('turnitin_enabled')).to eq false
      end
    end
  end

  context "update_from_params" do
    before :once do
      course_with_teacher(:active_all => true)
      student_in_course(active_all: true)
      @assignment = @course.assignments.create!(:title => "some assignment")
    end

    def strong_anything
      ArbitraryStrongishParams::ANYTHING
    end

    it 'updates the external tool content_id' do
      mh = create_message_handler(create_resource_handler(create_tool_proxy))
      tool_tag = ContentTag.new(url: 'http://www.example.com', new_tab: false, tag_type: 'context_module')
      tool_tag.context = @assignment
      tool_tag.save!
      params = ActionController::Parameters.new({
        "submission_types" => ["external_tool"],
        "external_tool_tag_attributes" => {
          "url" => "https://testvmserver.test.com/canvas/test/",
          "content_type" => "lti/message_handler",
          "content_id" => mh.id,
          "new_tab" => "0"
        }
      })
      assignment = update_from_params(@assignment, params, @user)
      tag = assignment.external_tool_tag
      expect(tag.content_id).to eq mh.id
      expect(tag.content_type).to eq "Lti::MessageHandler"
    end

    it 'sets the context external tool type' do
      tool = ContextExternalTool.new( name: 'test tool', consumer_key:'test',
        shared_secret: 'shh', url: 'http://www.example.com')
      tool.context = @course
      tool.save!
      tool_tag = ContentTag.new(url: 'http://www.example.com', new_tab: false, tag_type: 'context_module')
      tool_tag.context = @assignment
      tool_tag.save!
      params = ActionController::Parameters.new({
        "submission_types" => ["external_tool"],
        "external_tool_tag_attributes" => {
          "url" => "https://testvmserver.test.com/canvas/test/",
          "content_type" => "context_external_tool",
          "content_id" => tool.id,
          "new_tab" => "0"
        }
      })
      assignment = update_from_params(@assignment, params, @user)
      tag = assignment.external_tool_tag
      expect(tag.content_id).to eq tool.id
      expect(tag.content_type).to eq "ContextExternalTool"
    end

    it "does not update integration_data when lacking permission" do
      json = %{{"key": "value"}}
      params = ActionController::Parameters.new({"integration_data" => json})

      update_from_params(@assignment, params, @user)
      expect(@assignment.integration_data).to eq({})
    end

    it "updates integration_data with permission" do
      json = %{{"key": "value"}}
      params = ActionController::Parameters.new({"integration_data" => json})
      account_admin_user_with_role_changes(
        :role_changes => {:manage_sis => true})
      update_from_params(@assignment, params, @admin)
      expect(@assignment.integration_data).to eq({"key" => "value"})
    end

    it "unmuting publishes hidden comments" do
      @assignment.mute!
      @assignment.update_submission @student, comment: "blah blah blah", author: @teacher
      sub = @assignment.submission_for_student(@student)
      comment = sub.submission_comments.first
      expect(comment.hidden?).to eql true

      params = ActionController::Parameters.new({"muted" => "false"})
      update_from_params(@assignment, params, @teacher)
      expect(comment.reload.hidden?).to eql false
    end
  end

  context "as an observer viewing assignments" do
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

      @assignment, @submission = create_submitted_assignment_with_user(@observed_student)
    end

    it "should include submissions for observed users when requested with all assignments" do
      json = api_call_as_user(@observer, :get,
                              "/api/v1/courses/#{@observer_course.id}/assignments?include[]=observed_users&include[]=submission",
                              { :controller => 'assignments_api',
                                :action => 'index', :format => 'json',
                                :course_id => @observer_course.id,
                                :include => [ "observed_users", "submission" ]})

      expect(json.first['submission']).to eq [{
         "assignment_id" => @assignment.id,
         "attempt" => nil,
         "body" => nil,
         "excused" => nil,
         "grade" => "99",
         "grade_matches_current_submission" => true,
         "graded_at" => nil,
         "grader_id" => nil,
         "id" => @submission.id,
         "score" => 99,
         "submission_type" => nil,
         "submitted_at" => nil,
         "url" => nil,
         "user_id" => @observed_student.id,
         "workflow_state" => "submitted",
         "late" => false,
         "preview_url" =>
         "http://www.example.com/courses/#{@observer_course.id}/assignments/#{@assignment.id}/submissions/#{@observed_student.id}?preview=1&version=0"
       }]
    end

    it "should insoclude submissions for observed users when requested with a single assignment" do
      json = api_call_as_user(@observer, :get,
                              "/api/v1/courses/#{@observer_course.id}/assignments/#{@assignment.id}?include[]=observed_users&include[]=submission",
                              { :controller => 'assignments_api',
                                :action => 'show', :format => 'json',
                                :id => @assignment.id,
                                :course_id => @observer_course.id,
                                :include => [ "observed_users", "submission" ]})
      expect(json['submission']).to eq [{
         "assignment_id" => @assignment.id,
         "attempt" => nil,
         "body" => nil,
         "excused" => nil,
         "grade" => "99",
         "grade_matches_current_submission" => true,
         "graded_at" => nil,
         "grader_id" => nil,
         "id" => @submission.id,
         "score" => 99,
         "submission_type" => nil,
         "submitted_at" => nil,
         "url" => nil,
         "user_id" => @observed_student.id,
         "workflow_state" => "submitted",
         "late" => false,
         "preview_url" =>
         "http://www.example.com/courses/#{@observer_course.id}/assignments/#{@assignment.id}/submissions/#{@observed_student.id}?preview=1&version=0"
       }]
    end
  end

  context "assignment override preloading" do
    before :once do
      course_with_teacher(:active_all => true)

      student_in_course(:course => @course, :active_all => true)
      @override = assignment_override_model(:course => @course)
      @override_student = @override.assignment_override_students.build
      @override_student.user = @student
      @override_student.save!

      @assignment.only_visible_to_overrides = true
      @assignment.save!
    end

    it "should preload student_ids when including adhoc overrides" do
      @override.any_instantiation.expects(:assignment_override_students).never

      json = api_call_as_user(@teacher, :get,
        "/api/v1/courses/#{@course.id}/assignments?include[]=overrides",
        { :controller => 'assignments_api',
          :action => 'index', :format => 'json',
          :course_id => @course.id,
          :include => [ "overrides" ]})
      expect(json.first["overrides"].first["student_ids"]).to eq [@student.id]
    end

    it "should preload student_ids when including adhoc overrides on assignment groups api as well" do
      # yeah i know this is a separate api; sue me

      @override.any_instantiation.expects(:assignment_override_students).never

      json = api_call_as_user(@teacher, :get,
        "/api/v1/courses/#{@course.id}/assignment_groups?include[]=assignments&include[]=overrides",
        { :controller => 'assignment_groups',
          :action => 'index', :format => 'json',
          :course_id => @course.id,
          :include => [ "assignments", "overrides" ]})
      expect(json.first["assignments"].first["overrides"].first["student_ids"]).to eq [@student.id]
    end
  end
end

def api_get_assignments_index_from_course(course)
    api_call(:get,
          "/api/v1/courses/#{course.id}/assignments.json",
          {
            :controller => 'assignments_api',
            :action => 'index',
            :format => 'json',
            :course_id => course.id.to_s
          })
end

def api_get_assignments_user_index(user, course, api_user = @user)
  api_call_as_user(api_user, :get,
           "/api/v1/users/#{user.id}/courses/#{course.id}/assignments.json",
           {
               :controller => 'assignments_api',
               :action => 'user_index',
               :format => 'json',
               :course_id => course.id.to_s,
               :user_id => user.id.to_s
           })
end

def create_frozen_assignment_in_course(_course)
    assignment = @course.assignments.create!({
      :title => "some assignment",
      :freeze_on_copy => true
    })
    assignment.copied = true
    assignment.save!
    assignment
end

def raw_api_update_assignment(course,assignment,assignment_params)
  raw_api_call(:put,
        "/api/v1/courses/#{course.id}/assignments/#{assignment.id}.json",
        { :controller => 'assignments_api', :action => 'update',
          :format => 'json',
          :course_id => course.id.to_s,
          :id => assignment.id.to_s },
          {
            'assignment' => assignment_params
          }
        )
  course.reload
  assignment.reload
end

def api_get_assignment_in_course(assignment,course)
  json = api_call(:get,
    "/api/v1/courses/#{course.id}/assignments/#{assignment.id}.json",
    { :controller => "assignments_api", :action => "show",
    :format => "json", :course_id => course.id.to_s,
    :id => assignment.id.to_s })
  assignment.reload
  course.reload
  json
end

def api_update_assignment_call(course,assignment,assignment_params)
  json = api_call(
    :put,
    "/api/v1/courses/#{course.id}/assignments/#{assignment.id}.json",
    {
      :controller => 'assignments_api',
      :action => 'update',
      :format => 'json',
      :course_id => course.id.to_s,
      :id => assignment.id.to_s
    },
    { :assignment => assignment_params }
  )
  assignment.reload
  course.reload
  json
end

def fully_frozen_settings
  {
    "title" => "true",
    "description" => "true",
    "lock_at" => "true",
    "points_possible" => "true",
    "grading_type" => "true",
    "submission_types" => "true",
    "assignment_group_id" => "true",
    "allowed_extensions" => "true",
    "group_category_id" => "true",
    "notify_of_update" => "true",
    "peer_reviews" => "true",
    "workflow_state" => "true"
  }
end

def api_create_assignment_in_course(course,assignment_params)
  api_call(:post,
           "/api/v1/courses/#{course.id}/assignments.json",
           {
             :controller => 'assignments_api',
             :action => 'create',
             :format => 'json',
             :course_id => course.id.to_s
           }, {:assignment => assignment_params })
end
