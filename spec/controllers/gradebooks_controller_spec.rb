#
# Copyright (C) 2011 - present Instructure, Inc.
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

require_relative '../sharding_spec_helper'

describe GradebooksController do
  before :once do
    course_with_teacher active_all: true
    @teacher_enrollment = @enrollment
    student_in_course active_all: true
    @student_enrollment = @enrollment

    user_factory(active_all: true)
    @observer = @user
    @oe = @course.enroll_user(@user, 'ObserverEnrollment')
    @oe.accept
    @oe.update_attribute(:associated_user_id, @student.id)
  end

  it "uses GradebooksController" do
    expect(controller).to be_an_instance_of(GradebooksController)
  end

  describe "GET 'grade_summary'" do
    it "redirects to the login page if the user is logged out" do
      get 'grade_summary', params: {:course_id => @course.id, :id => @student.id}
      expect(response).to redirect_to(login_url)
      expect(flash[:warning]).to be_present
    end

    it "redirects teacher to gradebook" do
      user_session(@teacher)
      get 'grade_summary', params: {:course_id => @course.id, :id => nil}
      expect(response).to redirect_to(:action => 'show')
    end

    it "renders for current user" do
      user_session(@student)
      get 'grade_summary', params: {:course_id => @course.id, :id => nil}
      expect(response).to render_template('grade_summary')
    end

    it "does not allow access for inactive enrollment" do
      user_session(@student)
      @student_enrollment.deactivate
      get 'grade_summary', params: {:course_id => @course.id, :id => nil}
      assert_unauthorized
    end

    it "renders with specified user_id" do
      user_session(@student)
      get 'grade_summary', params: {:course_id => @course.id, :id => @student.id}
      expect(response).to render_template('grade_summary')
      expect(assigns[:presenter].courses_with_grades).not_to be_nil
    end

    it "does not allow access for wrong user" do
      user_factory(active_all: true)
      user_session(@user)
      get 'grade_summary', params: {:course_id => @course.id, :id => nil}
      assert_unauthorized
      get 'grade_summary', params: {:course_id => @course.id, :id => @student.id}
      assert_unauthorized
    end

    it "allows access for a linked observer" do
      user_session(@observer)
      get 'grade_summary', params: {:course_id => @course.id, :id => @student.id}
      expect(response).to render_template('grade_summary')
      expect(assigns[:courses_with_grades]).to be_nil
    end

    it "does not allow access for a linked student" do
      user_factory(active_all: true)
      user_session(@user)
      @se = @course.enroll_student(@user)
      @se.accept
      @se.update_attribute(:associated_user_id, @student.id)
      @user.reload
      get 'grade_summary', params: {:course_id => @course.id, :id => @student.id}
      assert_unauthorized
    end

    it "does not allow access for an observer linked in a different course" do
      @course1 = @course
      course_factory(active_all: true)
      @course2 = @course

      user_session(@observer)

      get 'grade_summary', params: {:course_id => @course2.id, :id => @student.id}
      assert_unauthorized
    end

    it "allows concluded teachers to see a student grades pages" do
      user_session(@teacher)
      @teacher_enrollment.conclude
      get 'grade_summary', params: {:course_id => @course.id, :id => @student.id}
      expect(response).to be_successful
      expect(response).to render_template('grade_summary')
      expect(assigns[:courses_with_grades]).to be_nil
    end

    it "allows concluded students to see their grades pages" do
      user_session(@student)
      @student_enrollment.conclude
      get 'grade_summary', params: {:course_id => @course.id, :id => @student.id}
      expect(response).to render_template('grade_summary')
    end

    it "gives a student the option to switch between courses" do
      pseudonym(@teacher, :username => 'teacher@example.com')
      pseudonym(@student, :username => 'student@example.com')
      course_with_teacher(:user => @teacher, :active_all => 1)
      student_in_course :user => @student, :active_all => 1
      user_session(@student)
      get 'grade_summary', params: {:course_id => @course.id, :id => @student.id}
      expect(response).to be_successful
      expect(assigns[:presenter].courses_with_grades).not_to be_nil
      expect(assigns[:presenter].courses_with_grades.length).to eq 2
    end

    it "does not give a teacher the option to switch between courses when viewing a student's grades" do
      pseudonym(@teacher, :username => 'teacher@example.com')
      pseudonym(@student, :username => 'student@example.com')
      course_with_teacher(:user => @teacher, :active_all => 1)
      student_in_course :user => @student, :active_all => 1
      user_session(@teacher)
      get 'grade_summary', params: {:course_id => @course.id, :id => @student.id}
      expect(response).to be_successful
      expect(assigns[:courses_with_grades]).to be_nil
    end

    it "does not give a linked observer the option to switch between courses when viewing a student's grades" do
      pseudonym(@teacher, :username => 'teacher@example.com')
      pseudonym(@student, :username => 'student@example.com')
      user_with_pseudonym(:username => 'parent@example.com', :active_all => 1)

      course1 = @course
      course2 = course_with_teacher(:user => @teacher, :active_all => 1).course
      student_in_course :user => @student, :active_all => 1
      oe = course2.enroll_user(@observer, 'ObserverEnrollment')
      oe.associated_user = @student
      oe.save!
      oe.accept

      user_session(@observer)
      get 'grade_summary', params: {:course_id => course1.id, :id => @student.id}
      expect(response).to be_successful
      expect(assigns[:courses_with_grades]).to be_nil
    end

    it "assigns assignment group values for grade calculator to ENV" do
      user_session(@teacher)
      get 'grade_summary', params: {:course_id => @course.id, :id => @student.id}
      expect(assigns[:js_env][:submissions]).not_to be_nil
      expect(assigns[:js_env][:assignment_groups]).not_to be_nil
    end

    it "does not include assignment discussion information in grade calculator ENV data" do
      user_session(@teacher)
      assignment1 = @course.assignments.create(:title => "Assignment 1")
      assignment1.submission_types = "discussion_topic"
      assignment1.save!

      get 'grade_summary', params: {:course_id => @course.id, :id => @student.id}
      expect(assigns[:js_env][:assignment_groups].first[:assignments].first["discussion_topic"]).to be_nil
    end

    it "includes assignment sort options in the ENV" do
      user_session(@teacher)
      get :grade_summary, params: { course_id: @course.id, id: @student.id }
      expect(assigns[:js_env][:assignment_sort_options]).to match_array [["Due Date", "due_at"], ["Title", "title"]]
    end

    it "includes the current assignment sort order in the ENV" do
      user_session(@teacher)
      get :grade_summary, params: { course_id: @course.id, id: @student.id }
      order = assigns[:js_env][:current_assignment_sort_order]
      expect(order).to eq :due_at
    end

    it "includes the post_policies_enabled in the ENV" do
      user_session(@teacher)
      get :grade_summary, params: { course_id: @course.id, id: @student.id }
      expect(assigns[:js_env][:post_policies_enabled]).to be true
    end

    it "includes the current grading period id in the ENV" do
      group = @course.root_account.grading_period_groups.create!
      period = group.grading_periods.create!(title: "GP", start_date: 3.months.ago, end_date: 3.months.from_now)
      group.enrollment_terms << @course.enrollment_term
      user_session(@teacher)
      get :grade_summary, params: { course_id: @course.id, id: @student.id }
      expect(assigns[:js_env][:current_grading_period_id]).to eq period.id
    end

    it "includes courses_with_grades, with each course having an id, nickname, and URL" do
      user_session(@teacher)
      get :grade_summary, params: { course_id: @course.id, id: @student.id }
      courses = assigns[:js_env][:courses_with_grades]
      expect(courses).to all include("id", "nickname", "url")
    end

    it "includes the URL to save the assignment order in the ENV" do
      user_session(@teacher)
      get :grade_summary, params: { course_id: @course.id, id: @student.id }
      expect(assigns[:js_env]).to have_key :save_assignment_order_url
    end

    it "includes the students for the grade summary page in the ENV" do
      user_session(@teacher)
      get :grade_summary, params: { course_id: @course.id, id: @student.id }
      expect(assigns[:js_env][:students]).to match_array [@student].as_json(include_root: false)
    end

    context "final grade override" do
      before(:once) do
        @course.update!(grading_standard_enabled: true)
        @course.enable_feature!(:final_grades_override)
        @course.assignments.create!(title: "an assignment")
        @student_enrollment.scores.find_by(course_score: true).update!(override_score: 99)
      end

      it "includes the effective final score in the ENV" do
        user_session(@teacher)
        get :grade_summary, params: { course_id: @course.id, id: @student.id }
          expect(assigns[:js_env][:effective_final_score]).to eq 99
      end

      it "does not include the effective final score in the ENV if the feature is disabled" do
        @course.disable_feature!(:final_grades_override)
        user_session(@teacher)
        get :grade_summary, params: { course_id: @course.id, id: @student.id }
          expect(assigns[:js_env].key?(:effective_final_score)).to be false
      end

      it "does not include the effective final score in the ENV if there is no override score" do
        @student_enrollment.scores.find_by(course_score: true).update!(override_score: nil)
        user_session(@teacher)
        get :grade_summary, params: { course_id: @course.id, id: @student.id }
          expect(assigns[:js_env].key?(:effective_final_score)).to be false
      end

      it "does not include the effective final score in the ENV if there is no score" do
        invited_student = @course.enroll_user(User.create!, "StudentEnrollment", enrollment_state: "invited").user
        user_session(@teacher)
        get :grade_summary, params: { course_id: @course.id, id: invited_student.id }
          expect(assigns[:js_env].key?(:effective_final_score)).to be false
      end

      it "takes the effective final score for the grading period, if present" do
        grading_period_group = @course.grading_period_groups.create!
        grading_period = grading_period_group.grading_periods.create!(
          title: "a grading period",
          start_date: 1.day.ago,
          end_date: 1.day.from_now
        )
        @student_enrollment.scores.find_by(grading_period: grading_period).update!(override_score: 84)
        user_session(@teacher)
        get :grade_summary, params: { course_id: @course.id, id: @student.id }
          expect(assigns[:js_env][:effective_final_score]).to eq 84
      end

      it "takes the effective final score for the course score, if viewing all grading periods" do
        user_session(@teacher)
        get :grade_summary, params: { course_id: @course.id, id: @student.id, grading_period_id: 0 }
          expect(assigns[:js_env][:effective_final_score]).to eq 99
      end
    end

    it "includes muted assignments" do
      user_session(@student)
      assignment = @course.assignments.create!(title: "Example Assignment")
      assignment.ensure_post_policy(post_manually: true)
      get 'grade_summary', params: {course_id: @course.id, id: @student.id}
      expect(assigns[:js_env][:assignment_groups].first[:assignments].size).to eq 1
      expect(assigns[:js_env][:assignment_groups].first[:assignments].first[:muted]).to eq true
    end

    it "does not include scores of unposted submissions" do
      user_session(@student)
      assignment = @course.assignments.create!
      assignment.ensure_post_policy(post_manually: true)
      assignment.grade_student(@student, grade: 10, grader: @teacher)
      get 'grade_summary', params: {course_id: @course.id, id: @student.id}
      submission = assigns[:js_env][:submissions].find { |s| s[:assignment_id] == assignment.id }
      expect(submission).not_to have_key(:score)
    end

    it "does not include excused of unposted submissions" do
      user_session(@student)
      assignment = @course.assignments.create!
      assignment.ensure_post_policy(post_manually: true)
      assignment.grade_student(@student, grade: 10, grader: @teacher)
      get 'grade_summary', params: {course_id: @course.id, id: @student.id}
      submission = assigns[:js_env][:submissions].find { |s| s[:assignment_id] == assignment.id }
      expect(submission).not_to have_key(:excused)
    end

    it "does not include workflow_state of unposted submissions" do
      user_session(@student)
      assignment = @course.assignments.create!
      assignment.ensure_post_policy(post_manually: true)
      assignment.grade_student(@student, grade: 10, grader: @teacher)
      get 'grade_summary', params: {course_id: @course.id, id: @student.id}
      submission = assigns[:js_env][:submissions].find { |s| s[:assignment_id] == assignment.id }
      expect(submission).not_to have_key(:workflow_state)
    end

    it "includes scores of posted submissions" do
      user_session(@student)
      assignment = @course.assignments.create!
      assignment.grade_student(@student, grade: 10, grader: @teacher)
      get 'grade_summary', params: {course_id: @course.id, id: @student.id}
      submission = assigns[:js_env][:submissions].find { |s| s[:assignment_id] == assignment.id }
      expect(submission[:score]).to be 10.0
    end

    it "includes excused of posted submissions" do
      user_session(@student)
      assignment = @course.assignments.create!
      assignment.grade_student(@student, grade: 10, grader: @teacher)
      get 'grade_summary', params: {course_id: @course.id, id: @student.id}
      submission = assigns[:js_env][:submissions].find { |s| s[:assignment_id] == assignment.id }
      expect(submission[:excused]).to be false
    end

    it "includes workflow_state of posted submissions" do
      user_session(@student)
      assignment = @course.assignments.create!
      assignment.grade_student(@student, grade: 10, grader: @teacher)
      get 'grade_summary', params: {course_id: @course.id, id: @student.id}
      submission = assigns[:js_env][:submissions].find { |s| s[:assignment_id] == assignment.id }
      expect(submission[:workflow_state]).to eq "graded"
    end

    it 'returns submissions of even inactive students' do
      user_session(@teacher)
      assignment = @course.assignments.create!(points_possible: 10)
      assignment.grade_student(@student, grade: 6.6, grader: @teacher)
      enrollment = @course.enrollments.find_by(user: @student)
      enrollment.deactivate
      get :grade_summary, params: { course_id: @course.id, id: @student.id }
      expect(assigns.fetch(:js_env).fetch(:submissions).first.fetch(:score)).to be 6.6
    end

    context "assignment sorting" do
      let!(:teacher_session) { user_session(@teacher) }
      let!(:assignment1) { @course.assignments.create(title: "Banana", position: 2) }
      let!(:assignment2) { @course.assignments.create(title: "Apple", due_at: 3.days.from_now, position: 3) }
      let!(:assignment3) do
        assignment_group = @course.assignment_groups.create!(position: 2)
        @course.assignments.create!(
          assignment_group: assignment_group, title: "Carrot", due_at: 2.days.from_now, position: 1
        )
      end
      let(:assignment_ids) { assigns[:presenter].assignments.select{ |a| a.class == Assignment }.map(&:id) }

      it "sorts assignments by due date (null last), then title if there is no saved order preference" do
        get 'grade_summary', params: {course_id: @course.id, id: @student.id}
          expect(assignment_ids).to eq [assignment3, assignment2, assignment1].map(&:id)
      end

      it "sort order of 'due_at' sorts by due date (null last), then title" do
        @teacher.set_preference(:course_grades_assignment_order, @course.id, :due_at)
        get 'grade_summary', params: {course_id: @course.id, id: @student.id}
          expect(assignment_ids).to eq [assignment3, assignment2, assignment1].map(&:id)
      end

      context "sort by: title" do
        let!(:teacher_setup) do
          @teacher.set_preference(:course_grades_assignment_order, @course.id, :title)
        end

        it "sorts assignments by title" do
          get 'grade_summary', params: {course_id: @course.id, id: @student.id}
              expect(assignment_ids).to eq [assignment2, assignment1, assignment3].map(&:id)
        end

        it "ingores case" do
          assignment1.title = 'banana'
          assignment1.save!
          get 'grade_summary', params: {course_id: @course.id, id: @student.id}
              expect(assignment_ids).to eq [assignment2, assignment1, assignment3].map(&:id)
        end
      end

      it "sort order of 'assignment_group' sorts by assignment group position, then assignment position" do
        @teacher.preferences[:course_grades_assignment_order] = { @course.id => :assignment_group }
        get 'grade_summary', params: {course_id: @course.id, id: @student.id}
          expect(assignment_ids).to eq [assignment1, assignment2, assignment3].map(&:id)
      end

      context "sort by: module" do
        let!(:first_context_module) { @course.context_modules.create! }
        let!(:second_context_module) { @course.context_modules.create! }
        let!(:assignment1_tag) do
          a1_tag = assignment1.context_module_tags.new(context: @course, position: 1, tag_type: 'context_module')
          a1_tag.context_module = second_context_module
          a1_tag.save!
        end

        let!(:assignment2_tag) do
          a2_tag = assignment2.context_module_tags.new(context: @course, position: 3, tag_type: 'context_module')
          a2_tag.context_module = first_context_module
          a2_tag.save!
        end

        let!(:assignment3_tag) do
          a3_tag = assignment3.context_module_tags.new(context: @course, position: 2, tag_type: 'context_module')
          a3_tag.context_module = first_context_module
          a3_tag.save!
        end

        let!(:teacher_setup) do
          @teacher.set_preference(:course_grades_assignment_order, @course.id, :module)
        end

        it "sorts by module position, then context module tag position" do
          get 'grade_summary', params: {course_id: @course.id, id: @student.id}
              expect(assignment_ids).to eq [assignment3, assignment2, assignment1].map(&:id)
        end

        it "sorts by module position, then context module tag position, " \
        "with those not belonging to a module sorted last" do
          assignment3.context_module_tags.first.destroy!
          get 'grade_summary', params: {course_id: @course.id, id: @student.id}
              expect(assignment_ids).to eq [assignment2, assignment1, assignment3].map(&:id)
        end
      end
    end

    context "with grading periods" do
      let(:group_helper)  { Factories::GradingPeriodGroupHelper.new }
      let(:period_helper) { Factories::GradingPeriodHelper.new }

      before :once do
        @grading_period_group = group_helper.create_for_account(@course.root_account, weighted: true)
        term = @course.enrollment_term
        term.grading_period_group = @grading_period_group
        term.save!
        @grading_periods = period_helper.create_presets_for_group(@grading_period_group, :past, :current, :future)
      end

      it "does not display totals if 'All Grading Periods' is selected" do
        user_session(@student)
        all_grading_periods_id = 0
        get 'grade_summary', params: {:course_id => @course.id, :id => @student.id, grading_period_id: all_grading_periods_id}
          expect(assigns[:exclude_total]).to eq true
      end

      it "assigns grading period values for grade calculator to ENV" do
        user_session(@teacher)
        all_grading_periods_id = 0
        get 'grade_summary', params: {:course_id => @course.id, :id => @student.id, grading_period_id: all_grading_periods_id}
          expect(assigns[:js_env][:submissions]).not_to be_nil
        expect(assigns[:js_env][:grading_periods]).not_to be_nil
      end

      it "displays totals if any grading period other than 'All Grading Periods' is selected" do
        user_session(@student)
        get 'grade_summary', params: {:course_id => @course.id, :id => @student.id, grading_period_id: @grading_periods.first.id}
          expect(assigns[:exclude_total]).to eq false
      end

      it "includes the grading period group (as 'set') in the ENV" do
        user_session(@teacher)
        get :grade_summary, params: { course_id: @course.id, id: @student.id }
          grading_period_set = assigns[:js_env][:grading_period_set]
        expect(grading_period_set[:id]).to eq @grading_period_group.id
      end

      it "includes grading periods within the group" do
        user_session(@teacher)
        get :grade_summary, params: { course_id: @course.id, id: @student.id }
          grading_period_set = assigns[:js_env][:grading_period_set]
        expect(grading_period_set[:grading_periods].count).to eq 3
        period = grading_period_set[:grading_periods][0]
        expect(period).to have_key(:is_closed)
        expect(period).to have_key(:is_last)
      end

      it "includes necessary keys with each grading period" do
        user_session(@teacher)
        get :grade_summary, params: { course_id: @course.id, id: @student.id }
          periods = assigns[:js_env][:grading_period_set][:grading_periods]
        expect(periods).to all include(:id, :start_date, :end_date, :close_date, :is_closed, :is_last)
      end

      it 'is ordered by start_date' do
        @grading_periods.sort_by!(&:id)
        grading_period_ids = @grading_periods.map(&:id)
        @grading_periods.last.update!(
          start_date: @grading_periods.first.start_date - 1.week,
          end_date: @grading_periods.first.start_date - 1.second
        )
        user_session(@teacher)
        get :grade_summary, params: { course_id: @course.id, id: @student.id }
          periods = assigns[:js_env][:grading_period_set][:grading_periods]
        expected_ids = [grading_period_ids.last].concat(grading_period_ids[0..-2])
        expect(periods.map{|period| period.fetch('id')}).to eql expected_ids
      end
    end

    context "with assignment due date overrides" do
      before :once do
        @assignment = @course.assignments.create(:title => "Assignment 1")
        @due_at = 4.days.from_now
      end

      def check_grades_page(due_at)
        [@student, @teacher, @observer].each do |u|
          controller.js_env.clear
          user_session(u)
          get 'grade_summary', params: {:course_id => @course.id, :id => @student.id}
              assignment_due_at = assigns[:presenter].assignments.find{|a| a.class == Assignment}.due_at
          expect(assignment_due_at.to_i).to eq due_at.to_i
        end
      end

      it "reflects section overrides" do
        section = @course.default_section
        override = assignment_override_model(:assignment => @assignment)
        override.set = section
        override.override_due_at(@due_at)
        override.save!
        check_grades_page(@due_at)
      end

      it "shows the latest section override in student view" do
        section = @course.default_section
        override = assignment_override_model(:assignment => @assignment)
        override.set = section
        override.override_due_at(@due_at)
        override.save!

        section2 = @course.course_sections.create!
        override2 = assignment_override_model(:assignment => @assignment)
        override2.set = section2
        override2.override_due_at(@due_at - 1.day)
        override2.save!

        user_session(@teacher)
        @fake_student = @course.student_view_student
        session[:become_user_id] = @fake_student.id

        get 'grade_summary', params: {:course_id => @course.id, :id => @fake_student.id}
          assignment_due_at = assigns[:presenter].assignments.find{|a| a.class == Assignment}.due_at
        expect(assignment_due_at.to_i).to eq @due_at.to_i
      end

      it "reflects group overrides when student is a member" do
        @assignment.group_category = group_category
        @assignment.save!
        group = @assignment.group_category.groups.create!(:context => @course)
        group.add_user(@student)

        override = assignment_override_model(:assignment => @assignment)
        override.set = group
        override.override_due_at(@due_at)
        override.save!
        check_grades_page(@due_at)
      end

      it "does not reflect group overrides when student is not a member" do
        @assignment.group_category = group_category
        @assignment.save!
        group = @assignment.group_category.groups.create!(:context => @course)

        override = assignment_override_model(:assignment => @assignment)
        override.set = group
        override.override_due_at(@due_at)
        override.save!
        check_grades_page(nil)
      end

      it "reflects ad-hoc overrides" do
        override = assignment_override_model(:assignment => @assignment)
        override.override_due_at(@due_at)
        override.save!
        override_student = override.assignment_override_students.build
        override_student.user = @student
        override_student.save!
        check_grades_page(@due_at)
      end

      it "uses the latest override" do
        section = @course.default_section
        override = assignment_override_model(:assignment => @assignment)
        override.set = section
        override.override_due_at(@due_at)
        override.save!

        override = assignment_override_model(:assignment => @assignment)
        override.override_due_at(@due_at + 1.day)
        override.save!
        override_student = override.assignment_override_students.build
        override_student.user = @student
        override_student.save!

        check_grades_page(@due_at + 1.day)
      end
    end

    it "raises an exception on a non-integer :id" do
      user_session(@teacher)
      assert_page_not_found do
        get 'grade_summary', params: {:course_id => @course.id, :id => "lqw"}
      end
    end
  end

  describe "GET 'show'" do
    let(:gradebook_options) { controller.js_env.fetch(:GRADEBOOK_OPTIONS) }

    context "as an admin" do
      before :each do
        account_admin_user(account: @course.root_account)
        user_session(@admin)
      end

      it "renders default gradebook when preferred with 'default'" do
        @admin.preferences[:gradebook_version] = "default"
        get "show", params: { course_id: @course.id }
        expect(response).to render_template("gradebooks/gradebook")
      end

      it "renders default gradebook when preferred with '2'" do
        # most users will have this set from before New Gradebook existed
        @admin.preferences[:gradebook_version] = "2"
        get "show", params: { course_id: @course.id }
        expect(response).to render_template("gradebooks/gradebook")
      end

      it "renders screenreader gradebook when preferred with 'individual'" do
        @admin.preferences[:gradebook_version] = "individual"
        get "show", params: { course_id: @course.id }
        expect(response).to render_template("gradebooks/individual")
      end

      it "renders screenreader gradebook when preferred with 'srgb'" do
        # most a11y users will have this set from before New Gradebook existed
        @admin.preferences[:gradebook_version] = "srgb"
        get "show", params: { course_id: @course.id }
        expect(response).to render_template("gradebooks/individual")
      end

      it "renders default gradebook when user has no preference" do
        get "show", params: { course_id: @course.id }
        expect(response).to render_template("gradebooks/gradebook")
      end

      it "ignores the parameter version when not in development" do
        allow(Rails.env).to receive(:development?).and_return(false)
        @admin.preferences[:gradebook_version] = "default"
        get "show", params: { course_id: @course.id, version: "individual" }
        expect(response).to render_template("gradebooks/gradebook")
      end
    end

    context "in development and requested version is 'default'" do
      before :each do
        account_admin_user(account: @course.root_account)
        user_session(@admin)
        @admin.preferences[:gradebook_version] = "individual"
        allow(Rails.env).to receive(:development?).and_return(true)
      end

      it "renders default gradebook" do
        get "show", params: { course_id: @course.id, version: "default" }
        expect(response).to render_template("gradebooks/gradebook")
      end
    end

    context "in development and requested version is 'individual'" do
      before :each do
        account_admin_user(account: @course.root_account)
        user_session(@admin)
        @admin.preferences[:gradebook_version] = "default"
        allow(Rails.env).to receive(:development?).and_return(true)
      end

      it "renders screenreader gradebook" do
        get "show", params: { course_id: @course.id, version: "individual" }
        expect(response).to render_template("gradebooks/individual")
      end
    end

    describe 'js_env' do
      before :each do
        user_session(@teacher)
      end

      describe "course_settings" do
        let(:course_settings) { gradebook_options.fetch(:course_settings) }

        describe "filter_speed_grader_by_student_group" do
          before :once do
            @course.root_account.enable_feature!(:filter_speed_grader_by_student_group)
          end

          it "sets filter_speed_grader_by_student_group to true when filter_speed_grader_by_student_group? is true" do
            @course.update!(filter_speed_grader_by_student_group: true)
            get :show, params: { course_id: @course.id }
            expect(course_settings.fetch(:filter_speed_grader_by_student_group)).to be true
          end

          it "sets filter_speed_grader_by_student_group to false when filter_speed_grader_by_student_group? is false" do
            @course.update!(filter_speed_grader_by_student_group: false)
            get :show, params: { course_id: @course.id }
            expect(course_settings.fetch(:filter_speed_grader_by_student_group)).to be false
          end
        end

        describe "allow_final_grade_override" do
          before :once do
            @course.enable_feature!(:final_grades_override)
            @course.update!(allow_final_grade_override: true)
          end

          let(:allow_final_grade_override) { course_settings.fetch(:allow_final_grade_override) }

          it "sets allow_final_grade_override to true when final grade override is allowed" do
            get :show, params: { course_id: @course.id }
            expect(allow_final_grade_override).to eq true
          end

          it "sets allow_final_grade_override to false when final grade override is not allowed" do
            @course.update!(allow_final_grade_override: false)
            get :show, params: { course_id: @course.id }
            expect(allow_final_grade_override).to eq false
          end

          it "sets allow_final_grade_override to false when 'Final Grade Override' is not enabled" do
            @course.disable_feature!(:final_grades_override)
            get :show, params: { course_id: @course.id }
            expect(allow_final_grade_override).to eq false
          end
        end
      end

      describe "default_grading_standard" do
        it "uses the course's grading standard" do
          grading_standard = grading_standard_for(@course)
          @course.update!(default_grading_standard: grading_standard)
          get :show, params: { course_id: @course.id }
          expect(gradebook_options.fetch(:default_grading_standard)).to eq grading_standard.data
        end

        it "uses the Canvas default grading standard if the course does not have one" do
          get :show, params: { course_id: @course.id }
          expect(gradebook_options.fetch(:default_grading_standard)).to eq GradingStandard.default_grading_standard
        end
      end

      it "includes colors" do
        get :show, params: {course_id: @course.id}
        expect(gradebook_options).to have_key :colors
      end

      it "includes final_grade_override_enabled" do
        get :show, params: {course_id: @course.id}
        expect(gradebook_options).to have_key :final_grade_override_enabled
      end

      it "includes late_policy" do
        get :show, params: { course_id: @course.id }
        expect(gradebook_options).to have_key :late_policy
      end

      it "includes grading_schemes" do
        get :show, params: { course_id: @course.id }
        expect(gradebook_options).to have_key :grading_schemes
      end

      describe "additional_sort_options_enabled" do
        before(:once) { @course.root_account.allow_feature!(:new_gradebook_sort_options) }

        it "is set to true when the new_gradebook_sort_options feature is enabled" do
          @course.enable_feature!(:new_gradebook_sort_options)
          get :show, params: { course_id: @course.id }
          expect(gradebook_options[:additional_sort_options_enabled]).to be true
        end

        it "is set to false when the new_gradebook_sort_options feature is not enabled" do
          get :show, params: { course_id: @course.id }
          expect(gradebook_options[:additional_sort_options_enabled]).to be false
        end
      end

      it "sets post_policies_enabled to true" do
        get :show, params: { course_id: @course.id }
        expect(gradebook_options[:post_policies_enabled]).to be(true)
      end

      it "sets show_similarity_score to true when the New Gradebook Plagiarism Indicator feature flag is enabled" do
        @course.root_account.enable_feature!(:new_gradebook_plagiarism_indicator)
        get :show, params: { course_id: @course.id }
        expect(gradebook_options[:show_similarity_score]).to be(true)
      end

      it "sets show_similarity_score to false when the New Gradebook Plagiarism Indicator feature flag is not enabled" do
        get :show, params: { course_id: @course.id }
        expect(gradebook_options[:show_similarity_score]).to be(false)
      end

      it 'includes api_max_per_page' do
        Setting.set('api_max_per_page', 50)
        get :show, params: {course_id: @course.id}
        api_max_per_page = assigns[:js_env][:GRADEBOOK_OPTIONS][:api_max_per_page]
        expect(api_max_per_page).to eq(50)
      end

      describe "new_post_policy_icons_enabled" do
        it "is set to true when the New Post Policy Icons root account feature flag enabled" do
          @course.root_account.enable_feature!(:new_post_policy_icons)
          get :show, params: {course_id: @course.id}
          expect(gradebook_options[:new_post_policy_icons_enabled]).to be true
        end

        it "is set to false when the New Post Policy Icons root account feature flag is not enabled" do
          get :show, params: {course_id: @course.id}
          expect(gradebook_options[:new_post_policy_icons_enabled]).to be false
        end
      end

      describe "post_manually" do
        it "is set to true when the course is manually-posted" do
          @course.default_post_policy.update!(post_manually: true)
          get :show, params: {course_id: @course.id}
          expect(assigns[:js_env][:GRADEBOOK_OPTIONS][:post_manually]).to be true
        end

        it "is set to false when the course is not manually-posted" do
          get :show, params: {course_id: @course.id}
          expect(assigns[:js_env][:GRADEBOOK_OPTIONS][:post_manually]).to be false
        end
      end

      describe "student_groups" do
        let(:category) { @course.group_categories.create!(name: "category") }
        let(:category2) { @course.group_categories.create!(name: "another category") }

        let(:group_categories_json) { assigns[:js_env][:GRADEBOOK_OPTIONS][:student_groups] }

        before(:each) do
          category.create_groups(2)
          category2.create_groups(2)
        end

        it "includes the student group categories for the course" do
          get :show, params: {course_id: @course.id}
          expect(group_categories_json.pluck("id")).to contain_exactly(category.id, category2.id)
        end

        it "does not include deleted group categories" do
          category2.destroy!

          get :show, params: {course_id: @course.id}
          expect(group_categories_json.pluck("id")).to contain_exactly(category.id)
        end

        it "includes the groups within each category" do
          get :show, params: {course_id: @course.id}

          category2_json = group_categories_json.find { |category_json| category_json["id"] == category2.id }
          expect(category2_json["groups"].pluck("id")).to match_array(category2.groups.pluck(:id))
        end
      end

      context "publish_to_sis_enabled" do
        before(:once) do
          @course.sis_source_id = 'xyz'
          @course.save
        end

        it "is true when the user is able to sync grades to the course SIS" do
          expect_any_instantiation_of(@course).to receive(:allows_grade_publishing_by).with(@teacher).and_return(true)
          get :show, params: { course_id: @course.id }
          expect(gradebook_options[:publish_to_sis_enabled]).to be true
        end

        it "is false when the user is not allowed to publish grades" do
          expect_any_instantiation_of(@course).to receive(:allows_grade_publishing_by).with(@teacher).and_return(false)
          get :show, params: { course_id: @course.id }
          expect(gradebook_options[:publish_to_sis_enabled]).to be false
        end

        it "is false when the user is not allowed to manage grades" do
          allow_any_instantiation_of(@course).to receive(:allows_grade_publishing_by).with(@teacher).and_return(true)
          @course.root_account.role_overrides.create!(
            permission: :manage_grades,
            role: Role.find_by(name: 'TeacherEnrollment'),
            enabled: false
          )
          get :show, params: { course_id: @course.id }
          expect(gradebook_options[:publish_to_sis_enabled]).to be false
        end

        it "is false when the course is not using a SIS" do
          allow_any_instantiation_of(@course).to receive(:allows_grade_publishing_by).with(@teacher).and_return(true)
          @course.sis_source_id = nil
          @course.save
          get :show, params: { course_id: @course.id }
          expect(gradebook_options[:publish_to_sis_enabled]).to be false
        end
      end

      it "includes sis_section_id on the sections even if the teacher doesn't have 'Read SIS Data' permissions" do
        @course.root_account.role_overrides.create!(permission: :read_sis, enabled: false, role: teacher_role)
        get :show, params: { course_id: @course.id }
        section = gradebook_options.fetch(:sections).first
        expect(section).to have_key :sis_section_id
      end

      describe "graded_late_submissions_exist" do
        let(:assignment) do
          @course.assignments.create!(
            due_at: 3.days.ago,
            points_possible: 10,
            submission_types: "online_text_entry"
          )
        end

        let(:graded_late_submissions_exist) do
          gradebook_options.fetch(:graded_late_submissions_exist)
        end

        it "is true if graded late submissions exist" do
          assignment.submit_homework(@student, body: "a body")
          assignment.grade_student(@student, grader: @teacher, grade: 8)
          get :show, params: {course_id: @course.id}
          expect(graded_late_submissions_exist).to be true
        end

        it "is false if late submissions exist, but they are not graded" do
          assignment.submit_homework(@student, body: "a body")
          get :show, params: {course_id: @course.id}
          expect(graded_late_submissions_exist).to be false
        end

        it "is false if there are no late submissions" do
          get :show, params: {course_id: @course.id}
          expect(graded_late_submissions_exist).to be false
        end
      end

      describe "sections" do
        before(:each) do
          @course.course_sections.create!
          Enrollment.limit_privileges_to_course_section!(@course, @teacher, true)
        end

        let(:returned_section_ids) { gradebook_options.fetch(:sections).pluck(:id) }

        it "only includes course sections visible to the user" do
          get :show, params: {course_id: @course.id}
          expect(returned_section_ids).to contain_exactly(@course.default_section.id)
        end
      end

      describe "include_speed_grader_in_assignment_header_menu" do
        it "is set to true when the feature flag of the same name is true" do
          Account.site_admin.enable_feature!(:include_speed_grader_in_assignment_header_menu)
          get :show, params: {course_id: @course.id}
          expect(gradebook_options.fetch(:include_speed_grader_in_assignment_header_menu)).to be true
        end

        it "is set to false when the feature flag of the same name is false" do
          get :show, params: {course_id: @course.id}
          expect(gradebook_options.fetch(:include_speed_grader_in_assignment_header_menu)).to be false
        end
      end
    end

    describe "csv" do
      before :once do
        @course.assignments.create(:title => "Assignment 1")
        @course.assignments.create(:title => "Assignment 2")
      end

      before :each do
        user_session(@teacher)
      end

      shared_examples_for "working download" do
        it "does not recompute enrollment grades" do
          expect(Enrollment).to receive(:recompute_final_score).never
          get 'show', params: {:course_id => @course.id, :init => 1, :assignments => 1}, :format => 'csv'
        end
        it "should get all the expected datas even with multibytes characters" do
          @course.assignments.create(:title => "Déjà vu")
          exporter = GradebookExporter.new(
            @course,
            @teacher,
            { include_sis_id: true }
          )
          raw_csv = exporter.to_csv
          expect(raw_csv).to include("Déjà vu")
        end
      end

      context "with teacher that prefers Grid View" do
        before do
          @user.preferences[:gradebook_version] = "2"
        end
        include_examples "working download"
      end

      context "with teacher that prefers Individual View" do
        before do
          @user.preferences[:gradebook_version] = "srgb"
        end
        include_examples "working download"
      end
    end

    context "Individual View" do
      before do
        user_session(@teacher)
      end

      it "redirects to Grid View with a friendly URL" do
        @teacher.preferences[:gradebook_version] = "2"
        get "show", params: {:course_id => @course.id}
        expect(response).to render_template("gradebook")
      end

      it "redirects to Individual View with a friendly URL" do
        @teacher.preferences[:gradebook_version] = "srgb"
        get "show", params: {:course_id => @course.id}
        expect(response).to render_template("gradebooks/individual")
      end

      it "requests groups without wiki_page assignments" do
        get "show", params: {:course_id => @course.id}
        url = controller.js_env[:GRADEBOOK_OPTIONS][:assignment_groups_url]
        expect(URI.unescape(url)).to include 'exclude_assignment_submission_types[]=wiki_page'
      end
    end

    it "renders the unauthorized page without gradebook authorization" do
      get "show", params: {:course_id => @course.id}
      assert_unauthorized
    end

    context 'includes data needed by the Gradebook Action menu in ENV' do
      let(:create_proficiency) { false }
      let(:enable_non_scoring_rubrics) { false }

      before do
        user_session(@teacher)
        @proficiency = outcome_proficiency_model(@course.account) if create_proficiency
        @course.root_account.enable_feature! :non_scoring_rubrics if enable_non_scoring_rubrics

        get 'show', params: {course_id: @course.id}

        @gradebook_env = assigns[:js_env][:GRADEBOOK_OPTIONS]
      end

      it 'includes the context_allows_gradebook_uploads key in ENV' do
        actual_value = @gradebook_env[:context_allows_gradebook_uploads]
        expected_value = @course.allows_gradebook_uploads?

        expect(actual_value).to eq(expected_value)
      end

      it 'includes the gradebook_import_url key in ENV' do
        actual_value = @gradebook_env[:gradebook_import_url]
        expected_value = new_course_gradebook_upload_path(@course)

        expect(actual_value).to eq(expected_value)
      end

      it "includes the context_modules_url in the ENV" do
        expect(@gradebook_env[:context_modules_url]).to eq(api_v1_course_context_modules_url(@course))
      end

      shared_examples_for 'returns no outcome proficiency' do
        it 'returns nil for outcome proficiency' do
          expect(@gradebook_env[:outcome_proficiency]).to be_nil
        end
      end

      context 'non-scoring rubrics feature flag disabled' do
        context 'no outcome proficiency on account' do
          include_examples 'returns no outcome proficiency'
        end

        skip 'outcome proficiency on account' do
          skip('NSRs are not being disabled properly even with the disable_feature! method')
          let(:create_proficiency) { true }

          include_examples 'returns no outcome proficiency'
        end
      end

      context 'non-scoring rubrics feature flag enabled' do
        let(:enable_non_scoring_rubrics) { true }

        context 'no outcome proficiency on account' do
          include_examples 'returns no outcome proficiency'
        end

        context 'outcome proficiency on account' do
          let(:create_proficiency) { true }

          it 'returns an outcome proficiency' do
            expect(@gradebook_env[:outcome_proficiency]).to eq(@proficiency.as_json)
          end
        end
      end
    end

    context "includes student context card info in ENV" do
      before { user_session(@teacher) }

      it "includes context_id" do
        get :show, params: {course_id: @course.id}
        context_id = assigns[:js_env][:GRADEBOOK_OPTIONS][:context_id]
        expect(context_id).to eq @course.id.to_param
      end

      it "doesn't enable context cards when feature is off" do
        get :show, params: {course_id: @course.id}
        expect(assigns[:js_env][:STUDENT_CONTEXT_CARDS_ENABLED]).to be_falsey
      end

      it "enables context cards when feature is on" do
        @course.root_account.enable_feature! :student_context_cards
        get :show, params: {course_id: @course.id}
        expect(assigns[:js_env][:STUDENT_CONTEXT_CARDS_ENABLED]).to eq true
      end
    end

    context "includes relevant account settings in ENV" do
      before { user_session(@teacher) }
      let(:custom_login_id) { 'FOOBAR' }

      it 'includes login_handle_name' do
        @course.account.update!(login_handle_name: custom_login_id)
        get :show, params: {course_id: @course.id}

        login_handle_name = assigns[:js_env][:GRADEBOOK_OPTIONS][:login_handle_name]

        expect(login_handle_name).to eq(custom_login_id)
      end
    end

    context "with grading periods" do
      let(:group_helper)  { Factories::GradingPeriodGroupHelper.new }
      let(:period_helper) { Factories::GradingPeriodHelper.new }

      before :once do
        @grading_period_group = group_helper.create_for_account(@course.root_account)
        term = @course.enrollment_term
        term.grading_period_group = @grading_period_group
        term.save!
        @grading_periods = period_helper.create_presets_for_group(@grading_period_group, :past, :current, :future)
      end

      before { user_session(@teacher) }

      it "includes the grading period group (as 'set') in the ENV" do
        get :show, params: { course_id: @course.id }
        grading_period_set = assigns[:js_env][:GRADEBOOK_OPTIONS][:grading_period_set]
        expect(grading_period_set[:id]).to eq @grading_period_group.id
      end

      it "includes grading periods within the group" do
        get :show, params: { course_id: @course.id }
        grading_period_set = assigns[:js_env][:GRADEBOOK_OPTIONS][:grading_period_set]
        expect(grading_period_set[:grading_periods].count).to eq 3
        period = grading_period_set[:grading_periods][0]
        expect(period).to have_key(:is_closed)
        expect(period).to have_key(:is_last)
      end

      it "includes necessary keys with each grading period" do
        get :show, params: { course_id: @course.id }
        periods = assigns[:js_env][:GRADEBOOK_OPTIONS][:grading_period_set][:grading_periods]
        expect(periods).to all include(:id, :start_date, :end_date, :close_date, :is_closed, :is_last)
      end
    end

    context "when outcome gradebook is enabled" do
      before :once do
        @course.enable_feature!(:outcome_gradebook)
      end

      before :each do
        user_session(@teacher)
      end

      def preferred_gradebook_view
        gradebook_preferences = @teacher.get_preference(:gradebook_settings, @course.global_id) || {}
        gradebook_preferences["gradebook_view"]
      end

      def update_preferred_gradebook_view!(gradebook_view)
        @teacher.set_preference(:gradebook_settings, @course.global_id, {
          "gradebook_view" => gradebook_view,
        })
      end

      context "when the user has no preferred view" do
        it "renders 'gradebook' when no view is requested" do
          get "show", params: {course_id: @course.id}
          expect(response).to render_template("gradebooks/gradebook")
        end

        it "updates the user's preference when the requested view is 'gradebook'" do
          get "show", params: {course_id: @course.id, view: "gradebook"}
          @teacher.reload
          expect(preferred_gradebook_view).to eql("gradebook")
        end

        it "redirects to the gradebook when the requested view is 'gradebook'" do
          get "show", params: {course_id: @course.id, view: "gradebook"}
          expect(response).to redirect_to(action: "show")
        end

        it "updates the user's preference when the requested view is 'learning_mastery'" do
          get "show", params: {course_id: @course.id, view: "learning_mastery"}
          @teacher.reload
          expect(preferred_gradebook_view).to eql("learning_mastery")
        end

        it "redirects to the gradebook when the requested view is 'learning_mastery'" do
          get "show", params: {course_id: @course.id, view: "learning_mastery"}
          expect(response).to redirect_to(action: "show")
        end
      end

      context "when the user prefers gradebook" do
        before :once do
          update_preferred_gradebook_view!("gradebook")
        end

        it "renders 'gradebook' when no view is requested" do
          get "show", params: {course_id: @course.id}
          expect(response).to render_template("gradebooks/gradebook")
        end

        it "redirects to the gradebook when requesting the preferred view" do
          get "show", params: {course_id: @course.id, view: "gradebook"}
          expect(response).to redirect_to(action: "show")
        end

        it "updates the user's preference when the requested view is 'learning_mastery'" do
          get "show", params: {course_id: @course.id, view: "learning_mastery"}
          @teacher.reload
          expect(preferred_gradebook_view).to eql("learning_mastery")
        end

        it "redirects to the gradebook when changing the requested view" do
          get "show", params: {course_id: @course.id, view: "learning_mastery"}
          expect(response).to redirect_to(action: "show")
        end
      end

      context "when the user prefers learning mastery" do
        before :each do
          update_preferred_gradebook_view!("learning_mastery")
        end

        it "renders 'learning_mastery' when no view is requested" do
          get "show", params: {course_id: @course.id}
          expect(response).to render_template("gradebooks/learning_mastery")
        end

        it "redirects to the gradebook when requesting the preferred view" do
          get "show", params: {course_id: @course.id, view: "learning_mastery"}
          expect(response).to redirect_to(action: "show")
        end

        it "updates the user's preference when the requested view is 'gradebook'" do
          get "show", params: {course_id: @course.id, view: "gradebook"}
          @teacher.reload
          expect(preferred_gradebook_view).to eql("gradebook")
        end

        it "redirects to the gradebook when changing the requested view" do
          get "show", params: {course_id: @course.id, view: "gradebook"}
          expect(response).to redirect_to(action: "show")
        end
      end

      describe "ENV" do
        before do
          user_session(@teacher)
          @proficiency = outcome_proficiency_model(@course.account)
          @course.root_account.enable_feature! :non_scoring_rubrics

          update_preferred_gradebook_view!("learning_mastery")
          get 'show', params: {course_id: @course.id}

          @gradebook_env = assigns[:js_env][:GRADEBOOK_OPTIONS]
        end

        describe ".outcome_proficiency" do
          it "is set to the outcome proficiency on the course" do
            expect(@gradebook_env[:outcome_proficiency]).to eq(@proficiency.as_json)
          end
        end
      end
    end
  end

  describe "GET 'final_grade_overrides'" do
    it "returns unauthorized when there is no current user" do
      get :final_grade_overrides, params: {course_id: @course.id}, format: :json
      assert_status(401)
    end

    it "returns unauthorized when the user is not authorized to manage grades" do
      user_session(@student)
      get :final_grade_overrides, params: {course_id: @course.id}, format: :json
      assert_status(401)
    end

    it "grants authorization to teachers in active courses" do
      user_session(@teacher)
      get :final_grade_overrides, params: {course_id: @course.id}, format: :json
      expect(response).to be_ok
    end

    it "grants authorization to teachers in concluded courses" do
      @course.complete!
      user_session(@teacher)
      get :final_grade_overrides, params: {course_id: @course.id}, format: :json
      expect(response).to be_ok
    end

    it "returns the map of final grade overrides" do
      assignment = assignment_model(course: @course, points_possible: 10)
      assignment.grade_student(@student, grade: '85%', grader: @teacher)
      enrollment = @student.enrollments.find_by!(course: @course)
      enrollment.scores.find_by!(course_score: true).update!(override_score: 89.2)

      user_session(@teacher)
      get :final_grade_overrides, params: {course_id: @course.id}, format: :json
      final_grade_overrides = json_parse(response.body)["final_grade_overrides"]
      expect(final_grade_overrides).to have_key(@student.id.to_s)
    end
  end

  describe "GET 'user_ids'" do
    it "returns unauthorized if there is no current user" do
      get :user_ids, params: {course_id: @course.id}, format: :json
      assert_status(401)
    end

    it "returns unauthorized if the user is not authorized to manage grades" do
      user_session(@student)
      get :user_ids, params: {course_id: @course.id}, format: :json
      assert_status(401)
    end

    it "grants authorization to teachers in active courses" do
      user_session(@teacher)
      get :user_ids, params: {course_id: @course.id}, format: :json
      expect(response).to be_ok
    end

    it "grants authorization to teachers in concluded courses" do
      @course.complete!
      user_session(@teacher)
      get :user_ids, params: {course_id: @course.id}, format: :json
      expect(response).to be_ok
    end

    it "returns an array of user ids sorted according to the user's preferences" do
      student1 = @student
      student1.update!(name: "Jon")
      student2 = student_in_course(active_all: true, name: "Ron").user
      student3 = student_in_course(active_all: true, name: "Don").user
      @teacher.set_preference(:gradebook_settings, @course.global_id, {
        "sort_rows_by_column_id": "student",
        "sort_rows_by_setting_key": "name",
        "sort_rows_by_direction": "descending"
      })

      user_session(@teacher)
      get :user_ids, params: {course_id: @course.id}, format: :json
      user_ids = json_parse(response.body)["user_ids"]
      expect(user_ids).to eq([student2.id, student1.id, student3.id])
    end
  end

  describe "GET 'grading_period_assignments'" do
    before(:once) do
      @group = Factories::GradingPeriodGroupHelper.new.create_for_account(@course.account)
      @group.enrollment_terms << @course.enrollment_term
      @period1, @period2 = Factories::GradingPeriodHelper.new.create_presets_for_group(@group, :past, :current)
      @assignment1_in_gp1 = @course.assignments.create!(due_at: 3.months.ago)
      @assignment2_in_gp2 = @course.assignments.create!(due_at: 1.day.from_now)
    end

    it "returns unauthorized if there is no current user" do
      get :grading_period_assignments, params: { course_id: @course.id }, format: :json
      assert_status(401)
    end

    it "returns unauthorized if the user is not authorized to manage grades" do
      user_session(@student)
      get :grading_period_assignments, params: { course_id: @course.id }, format: :json
      assert_status(401)
    end

    it "grants authorization to teachers in active courses" do
      user_session(@teacher)
      get :grading_period_assignments, params: { course_id: @course.id }, format: :json
      expect(response).to be_ok
    end

    it "grants authorization to teachers in concluded courses" do
      @course.complete!
      user_session(@teacher)
      get :grading_period_assignments, params: { course_id: @course.id }, format: :json
      expect(response).to be_ok
    end

    it "returns an array of user ids sorted according to the user's preferences" do
      user_session(@teacher)
      get :grading_period_assignments, params: { course_id: @course.id }, format: :json
      json = json_parse(response.body)["grading_period_assignments"]
      expect(json).to eq({
        @period1.id.to_s => [@assignment1_in_gp1.id.to_s],
        @period2.id.to_s => [@assignment2_in_gp2.id.to_s]
      })
    end
  end

  describe "GET 'change_gradebook_version'" do
    it 'switches to gradebook if clicked' do
      user_session(@teacher)
      get 'grade_summary', params: {:course_id => @course.id, :id => nil}

      expect(response).to redirect_to(:action => 'show')

      # tell it to use gradebook 2
      get 'change_gradebook_version', params: {:course_id => @course.id, :version => 2}
      expect(response).to redirect_to(:action => 'show')
    end
  end

  describe "GET 'history'" do
    it "grants authorization to teachers in active courses" do
      user_session(@teacher)

      get 'history', params: { course_id: @course.id }
      expect(response).to be_ok
    end

    it "grants authorization to teachers in concluded courses" do
      @course.complete!
      user_session(@teacher)

      get 'history', params: { course_id: @course.id }
      expect(response).to be_ok
    end

    it "returns unauthorized for students" do
      user_session(@student)

      get 'history', params: { course_id: @course.id }
      assert_unauthorized
    end
  end

  describe "POST 'submissions_zip_upload'" do
    it "requires authentication" do
      course_factory
      assignment_model
      post 'submissions_zip_upload', params: {:course_id => @course.id, :assignment_id => @assignment.id, :submissions_zip => 'dummy'}
      assert_unauthorized
    end
  end

  describe "GET 'show_submissions_upload'" do
    before :once do
      course_factory
      assignment_model
    end

    before :each do
      Account.site_admin.enable_feature!(:submissions_reupload_status_page)
      user_session(@teacher)
    end

    it "assigns the @assignment variable for the template" do
      get :show_submissions_upload, params: {course_id: @course.id, assignment_id: @assignment.id}
      expect(assigns[:assignment]).to eql(@assignment)
    end

    it "assigns the @progress variable for the template" do
      progress = Progress.new(context: @assignment, completion: 100)
      allow_any_instance_of(Assignment).to receive(:submission_reupload_progress).and_return(progress)
      get :show_submissions_upload, params: {course_id: @course.id, assignment_id: @assignment.id}
      expect(assigns[:progress]).to eql(progress)
    end

    it "redirects to the assignment page when the course does not allow gradebook uploads" do
      allow_any_instance_of(Course).to receive(:allows_gradebook_uploads?).and_return(false)
      get :show_submissions_upload, params: {course_id: @course.id, assignment_id: @assignment.id}
      expect(response).to redirect_to course_assignment_url(@course, @assignment)
    end

    it "requires authentication" do
      remove_user_session
      get :show_submissions_upload, params: {course_id: @course.id, assignment_id: @assignment.id}
      assert_unauthorized
    end

    it "grants authorization to teachers" do
      get :show_submissions_upload, params: {course_id: @course.id, assignment_id: @assignment.id}
      expect(response).to be_ok
    end

    it "returns unauthorized for students" do
      user_session(@student)
      get :show_submissions_upload, params: {course_id: @course.id, assignment_id: @assignment.id}
      assert_unauthorized
    end

    it "returns not_found when the 'submissions_reupload_status_page' feature is off" do
      Account.site_admin.disable_feature!(:submissions_reupload_status_page)
      assert_page_not_found do
        get :show_submissions_upload, params: {course_id: @course.id, assignment_id: @assignment.id}
      end
    end
  end

  describe "POST 'update_submission'" do
    let(:json) { JSON.parse(response.body) }

    describe "returned JSON" do
      before(:once) do
        @assignment = @course.assignments.create!(title: "Math 1.1")
        @submission = @assignment.submissions.find_by!(user: @student)
      end

      describe 'non-anonymous assignment' do
        before(:each) do
          user_session(@teacher)
          post(
            'update_submission',
            params: {
              course_id: @course.id,
              submission: {
                assignment_id: @assignment.id,
                user_id: @student.id,
                grade: 10
              }
            },
            format: :json
          )
        end

        it "includes assignment_visibility" do
          submissions = json.map {|submission| submission['submission']}
          expect(submissions).to all include('assignment_visible' => true)
        end

        it "includes missing in submission history" do
          submission_history = json.first['submission']['submission_history']
          submissions = submission_history.map {|submission| submission['submission']}
          expect(submissions).to all include('missing' => false)
        end

        it "includes late in submission history" do
          submission_history = json.first['submission']['submission_history']
          submissions = submission_history.map {|submission| submission['submission']}
          expect(submissions).to all include('late' => false)
        end

        it 'includes user_ids' do
          submissions = json.map {|submission| submission['submission']}
          expect(submissions).to all include('user_id')
        end
      end

      describe 'anonymous assignment' do
        before(:once) do
          @assignment.update!(anonymous_grading: true)
        end

        let(:post_params) do
          {
            course_id: @course.id,
            submission: {
              assignment_id: @assignment.id,
              anonymous_id: @submission.anonymous_id,
              grade: 10
            }
          }
        end

        before { user_session(@teacher) }

        it 'works with the absence of user_id and the presence of anonymous_id' do
          post(:update_submission, params: post_params, format: :json)
          submissions = json.map {|submission| submission.fetch('submission').fetch('anonymous_id')}
          expect(submissions).to contain_exactly(@submission.anonymous_id)
        end

        it 'does not include user_ids for muted anonymous assignments' do
          post(:update_submission, params: post_params, format: :json)
          submissions = json.map {|submission| submission['submission'].key?('user_id')}
          expect(submissions).to contain_exactly(false)
        end

        it 'includes user_ids for unmuted anonymous assignments' do
          @assignment.unmute!
          post(:update_submission, params: post_params, format: :json)
          submission = json.first.fetch('submission')
          expect(submission).to have_key('user_id')
        end

        context "given a student comment" do
          before(:once) { @submission.add_comment(comment: 'a student comment', author: @student) }

          it 'includes anonymous_ids on submission_comments' do
            params_with_comment = post_params.deep_merge(submission: {score: 10})
            post(:update_submission, params: params_with_comment, format: :json)
            comments = json.first.fetch('submission').fetch('submission_comments').map { |c| c['submission_comment'] }
            expect(comments).to all have_key('anonymous_id')
          end

          it 'excludes author_name on submission_comments' do
            params_with_comment = post_params.deep_merge(submission: {score: 10})
            post(:update_submission, params: params_with_comment, format: :json)
            comments = json.first.fetch('submission').fetch('submission_comments').map { |c| c['submission_comment'] }
            comments.each do |comment|
              expect(comment).not_to have_key('author_name')
            end
          end
        end
      end
    end

    describe "adding comments" do
      before do
        user_session(@teacher)
        @assignment = @course.assignments.create!(:title => "some assignment")
        @student = @course.enroll_user(User.create!(:name => "some user"))
      end

      it "allows adding comments for submission" do
        post 'update_submission', params: {:course_id => @course.id, :submission =>
          {:comment => "some comment",:assignment_id => @assignment.id, :user_id => @student.user_id}}
        expect(response).to be_redirect
        expect(assigns[:assignment]).to eql(@assignment)
        expect(assigns[:submissions]).not_to be_nil
        expect(assigns[:submissions].length).to eql(1)
        expect(assigns[:submissions][0].submission_comments).not_to be_nil
        expect(assigns[:submissions][0].submission_comments[0].comment).to eql("some comment")
      end

      it "allows attaching files to comments for submission" do
        data = fixture_file_upload("docs/doc.doc", "application/msword", true)
        post 'update_submission',
          params: {:course_id => @course.id,
          :attachments => { "0" => { :uploaded_data => data } },
          :submission => { :comment => "some comment",
                           :assignment_id => @assignment.id,
                           :user_id => @student.user_id }}
        expect(response).to be_redirect
        expect(assigns[:assignment]).to eql(@assignment)
        expect(assigns[:submissions]).not_to be_nil
        expect(assigns[:submissions].length).to eql(1)
        expect(assigns[:submissions][0].submission_comments).not_to be_nil
        expect(assigns[:submissions][0].submission_comments[0].comment).to eql("some comment")
        expect(assigns[:submissions][0].submission_comments[0].attachments.length).to eql(1)
        expect(assigns[:submissions][0].submission_comments[0].attachments[0].display_name).to eql("doc.doc")
      end

      it "sets comment to hidden when assignment posts manually and is unposted" do
        @assignment.ensure_post_policy(post_manually: true)
        @assignment.hide_submissions
        post 'update_submission', params: {
          course_id: @course.id,
          submission: {
            comment: "some comment",
            assignment_id: @assignment.id,
            user_id: @student.user_id
          }
        }
        expect(assigns[:submissions][0].submission_comments[0]).to be_hidden
      end

      it "does not set comment to hidden when assignment posts manually and submission is posted" do
        @assignment.ensure_post_policy(post_manually: true)
        @assignment.post_submissions
        post 'update_submission', params: {
          course_id: @course.id,
          submission: {
            comment: "some comment",
            assignment_id: @assignment.id,
            user_id: @student.user_id
          }
        }
        expect(assigns[:submissions][0].submission_comments[0]).not_to be_hidden
      end

      it "does not set comment to hidden when assignment posts automatically" do
        @assignment.ensure_post_policy(post_manually: false)
        post 'update_submission', params: {
          course_id: @course.id,
          submission: {
            comment: "some comment",
            assignment_id: @assignment.id,
            user_id: @student.user_id
          }
        }
        expect(assigns[:submissions][0].submission_comments[0]).not_to be_hidden
      end

      context 'media comments' do
        before :each do
          post 'update_submission',
            params: {
              course_id: @course.id,
              submission: {
                assignment_id: @assignment.id,
                user_id: @student.user_id,
                media_comment_id: 'asdfqwerty',
                media_comment_type: 'audio'
              }
          }
          @media_comment = assigns[:submissions][0].submission_comments[0]
        end

        it 'allows media comments for submissions' do
          expect(@media_comment).not_to be nil
          expect(@media_comment.media_comment_id).to eql 'asdfqwerty'
        end

        it 'includes the type in the media comment' do
          expect(@media_comment.media_comment_type).to eql 'audio'
        end
      end
    end

    it "stores attached files in instfs if instfs is enabled" do
      allow(InstFS).to receive(:enabled?).and_return(true)
      uuid = "1234-abcd"
      allow(InstFS).to receive(:direct_upload).and_return(uuid)
      user_session(@teacher)
      @assignment = @course.assignments.create!(:title => "some assignment")
      @student = @course.enroll_user(User.create!(:name => "some user"))
      data = fixture_file_upload("docs/doc.doc", "application/msword", true)
      post 'update_submission',
        params: {:course_id => @course.id,
        :attachments => { "0" => { :uploaded_data => data } },
        :submission => { :comment => "some comment",
                         :assignment_id => @assignment.id,
                         :user_id => @student.user_id }}
      expect(assigns[:submissions][0].submission_comments[0].attachments[0].instfs_uuid).to eql(uuid)
    end

    it "does not allow updating submissions for concluded courses" do
      user_session(@teacher)
      @teacher_enrollment.complete
      @assignment = @course.assignments.create!(:title => "some assignment")
      @student = @course.enroll_user(User.create!(:name => "some user"))
      post 'update_submission',
        params: {:course_id => @course.id,
        :submission => { :comment => "some comment",
                         :assignment_id => @assignment.id,
                         :user_id => @student.user_id }}
      assert_unauthorized
    end

    it "does not allow updating submissions in other sections when limited" do
      user_session(@teacher)
      @teacher_enrollment.update_attribute(:limit_privileges_to_course_section, true)
      s1 = submission_model(:course => @course)
      s2 = submission_model(:course => @course,
                            :username => 'otherstudent@example.com',
                            :section => @course.course_sections.create(:name => "another section"),
                            :assignment => @assignment)

      post 'update_submission',
        params: {:course_id => @course.id,
        :submission => { :comment => "some comment",
                         :assignment_id => @assignment.id,
                         :user_id => s1.user_id }}
      expect(response).to be_redirect

      # attempt to grade another section throws not found
      post 'update_submission',
        params: {:course_id => @course.id,
        :submission => { :comment => "some comment",
                         :assignment_id => @assignment.id,
                         :user_id => s2.user_id }}
      expect(flash[:error]).to eql 'Submission was unsuccessful: Submission Failed'
    end

    context "moderated grading" do
      before :once do
        @assignment = @course.assignments.create!(title: "some assignment", moderated_grading: true, grader_count: 1)
        @student = @course.enroll_student(User.create!(:name => "some user"), :enrollment_state => :active).user
      end

      before :each do
        user_session(@teacher)
      end

      it "creates a provisional grade" do
        submission = @assignment.submit_homework(@student, :body => "hello")
        post 'update_submission',
          params: {:course_id => @course.id,
          :submission => { :score => 100,
                           :comment => "provisional!",
                           :assignment_id => @assignment.id,
                           :user_id => @student.id,
                           :provisional => true }},
          :format => :json

        # confirm "real" grades/comments were not written
        submission.reload
        expect(submission.workflow_state).to eq 'submitted'
        expect(submission.score).to be_nil
        expect(submission.grade).to be_nil
        expect(submission.submission_comments.first).to be_nil

        # confirm "provisional" grades/comments were written
        pg = submission.provisional_grade(@teacher)
        expect(pg.score).to eq 100
        expect(pg.submission_comments.first.comment).to eq 'provisional!'

        # confirm the response JSON shows provisional information
        json = JSON.parse response.body
        expect(json.first.fetch('submission').fetch('score')).to eq 100
        expect(json.first.fetch('submission').fetch('grade_matches_current_submission')).to eq true
        expect(json.first.fetch('submission').fetch('submission_comments').first.fetch('submission_comment').fetch('comment')).to eq 'provisional!'
      end

      context 'when submitting a final provisional grade' do
        before(:once) do
          @assignment.update!(final_grader: @teacher)
        end

        let(:provisional_grade_params) do
          {
            course_id: @course.id,
            submission: {
              score: 66,
              comment: "not the end",
              assignment_id: @assignment.id,
              user_id: @student.id,
              provisional: true
            }
          }
        end

        let(:final_provisional_grade_params) do
          {
            course_id: @course.id,
            submission: {
              score: 77,
              comment: "THE END",
              assignment_id: @assignment.id,
              user_id: @student.id,
              final: true,
              provisional: true
            }
          }
        end

        let(:submission_json) do
          response_json = JSON.parse(response.body)
          response_json[0]['submission'].with_indifferent_access
        end

        before do
          post 'update_submission', params: provisional_grade_params, format: :json
          post 'update_submission', params: final_provisional_grade_params, format: :json
        end

        it 'returns the submitted score in the submission JSON' do
          expect(submission_json.fetch('score')).to eq 77
        end

        it 'returns the submitted comments in the submission JSON' do
          all_comments = submission_json.fetch('submission_comments').
            map { |c| c.fetch('submission_comment') }.
            map { |c| c.fetch('comment') }
          expect(all_comments).to contain_exactly('not the end', 'THE END')
        end

        it 'returns the value for grade_matches_current_submission of the submitted grade in the JSON' do
          expect(submission_json['grade_matches_current_submission']).to be true
        end
      end

      it "includes the graded anonymously flag in the provisional grade object" do
        submission = @assignment.submit_homework(@student, body: "hello")
        post 'update_submission',
          params: {course_id: @course.id,
          submission: { score: 100,
                           comment: "provisional!",
                           assignment_id: @assignment.id,
                           user_id: @student.id,
                           provisional: true,
                           graded_anonymously: true }},
          format: :json

        submission.reload
        pg = submission.provisional_grade(@teacher)
        expect(pg.graded_anonymously).to eq true

        submission = @assignment.submit_homework(@student, body: "hello")
        post 'update_submission',
          params: {course_id: @course.id,
          submission: { score: 100,
                           comment: "provisional!",
                           assignment_id: @assignment.id,
                           user_id: @student.id,
                           provisional: true,
                           graded_anonymously: false }},
          format: :json

        submission.reload
        pg = submission.provisional_grade(@teacher)
        expect(pg.graded_anonymously).to eq false
      end

      it "doesn't create a provisional grade when the student has one already" do
        @assignment.submit_homework(@student, :body => "hello")
        other_teacher = teacher_in_course(:course => @course, :active_all => true).user
        @assignment.grade_student(@student, grade: 2, grader: other_teacher, provisional: true)

        post 'update_submission', params: {:course_id => @course.id,
          :submission => { :score => 100, :comment => "provisional!", :assignment_id => @assignment.id,
            :user_id => @student.id, :provisional => true }}, :format => :json
        expect(response).to_not be_successful
        expect(response.body).to include("The maximum number of graders has been reached for this assignment")
     end

      it "should create a provisional grade even if the student has one but is in the moderation set" do
        submission = @assignment.submit_homework(@student, :body => "hello")
        other_teacher = teacher_in_course(:course => @course, :active_all => true).user
        submission.find_or_create_provisional_grade!(other_teacher)

        post 'update_submission', params: {:course_id => @course.id,
          :submission => { :score => 100, :comment => "provisional!", :assignment_id => @assignment.id,
            :user_id => @student.id, :provisional => true }}, :format => :json
        expect(response).to be_successful
      end

      it 'creates a final provisional grade' do
        @assignment.update!(final_grader: @teacher)
        submission = @assignment.submit_homework(@student, :body => "hello")
        other_teacher = teacher_in_course(:course => @course, :active_all => true).user
        submission.find_or_create_provisional_grade!(other_teacher) # create one so we can make a final

        post 'update_submission',
          params: {:course_id => @course.id,
          :submission => { :score => 100,
            :comment => "provisional!",
            :assignment_id => @assignment.id,
            :user_id => @student.id,
            :provisional => true,
            :final => true
          }},
          :format => :json
        expect(response).to be_successful

        # confirm "real" grades/comments were not written
        submission.reload
        expect(submission.workflow_state).to eq 'submitted'
        expect(submission.score).to be_nil
        expect(submission.grade).to be_nil
        expect(submission.submission_comments.first).to be_nil

        # confirm "provisional" grades/comments were written
        pg = submission.provisional_grade(@teacher, final: true)
        expect(pg.score).to eq 100
        expect(pg.final).to eq true
        expect(pg.submission_comments.first.comment).to eq 'provisional!'

        # confirm the response JSON shows provisional information
        json = JSON.parse response.body
        expect(json[0]['submission']['score']).to eq 100
        expect(json[0]['submission']['provisional_grade_id']).to eq pg.id
        expect(json[0]['submission']['grade_matches_current_submission']).to eq true
        expect(json[0]['submission']['submission_comments'].first['submission_comment']['comment']).to eq 'provisional!'
      end

      it 'does not mark the provisional grade as final when the user does not have permission to moderate' do
        submission = @assignment.submit_homework(@student, body: 'hello')
        other_teacher = teacher_in_course(course: @course, active_all: true).user
        submission.find_or_create_provisional_grade!(other_teacher)
        post_params = {
          course_id: @course.id,
          submission: {
            score: 100.to_s,
            comment: 'provisional comment',
            assignment_id: @assignment.id.to_s,
            user_id: @student.id.to_s,
            provisional: true,
            final: true
          }
        }

        post(:update_submission, params: post_params, format: :json)
        submission_json = JSON.parse(response.body).first.fetch('submission')
        provisional_grade = ModeratedGrading::ProvisionalGrade.find(submission_json.fetch('provisional_grade_id'))
        expect(provisional_grade).not_to be_final
      end
    end

    describe 'provisional grade error handling' do
      before(:once) do
        course_with_student(active_all: true)
        teacher_in_course(active_all: true)

        @assignment = @course.assignments.create!(
          title: 'yet another assignment',
          moderated_grading: true,
          grader_count: 1
        )
      end

      let(:submission_params) do
        { provisional: true, assignment_id: @assignment.id, user_id: @student.id, score: 1 }
      end
      let(:request_params) { {course_id: @course.id, submission: submission_params} }

      let(:response_json) { JSON.parse(response.body) }

      it 'returns an error code of MAX_GRADERS_REACHED if a MaxGradersReachedError is raised' do
        @assignment.grade_student(@student, provisional: true, grade: 5, grader: @teacher)
        @previous_teacher = @teacher

        teacher_in_course(active_all: true)
        user_session(@teacher)

        post 'update_submission', params: request_params, format: :json
        expect(response_json.dig('errors', 'error_code')).to eq 'MAX_GRADERS_REACHED'
      end

      it 'returns a generic error if a GradeError is raised' do
        invalid_submission_params = submission_params.merge(excused: true)
        invalid_request_params = request_params.merge(submission: invalid_submission_params)
        user_session(@teacher)

        post 'update_submission', params: invalid_request_params, format: :json
        expect(response_json.dig('errors', 'base')).to be_present
      end

      it 'returns a PROVISIONAL_GRADE_INVALID_SCORE error code if an invalid grade is given' do
        invalid_submission_params = submission_params.merge(grade: 'NaN')
        invalid_request_params = request_params.merge(submission: invalid_submission_params)
        user_session(@teacher)

        post 'update_submission', params: invalid_request_params, format: :json
        expect(response_json.dig('errors', 'error_code')).to eq 'PROVISIONAL_GRADE_INVALID_SCORE'
      end
    end
  end

  describe "GET 'speed_grader'" do
    before :once do
      @assignment = @course.assignments.create!(
        title: 'A Title', submission_types: 'online_url', grading_type: 'percent'
      )
    end

    before :each do
      user_session(@teacher)
    end

    it 'renders speed_grader template with locals' do
      @assignment.publish
      get 'speed_grader', params: {course_id: @course, assignment_id: @assignment.id}
      expect(response).to render_template(:speed_grader, locals: { anonymous_grading: false })
    end

    it "redirects the user if course's large_roster? setting is true" do
      allow_any_instance_of(Course).to receive(:large_roster?).and_return(true)

      get 'speed_grader', params: {:course_id => @course.id, :assignment_id => @assignment.id}
      expect(response).to be_redirect
      expect(flash[:notice]).to eq 'SpeedGrader is disabled for this course'
    end

    it "redirects if the assignment is unpublished" do
      @assignment.unpublish
      get 'speed_grader', params: {course_id: @course, assignment_id: @assignment.id}
      expect(response).to be_redirect
      expect(flash[:notice]).to eq I18n.t(
        :speedgrader_enabled_only_for_published_content, 'SpeedGrader is enabled only for published content.'
      )
    end

    it "does not redirect if the assignment is published" do
      @assignment.publish
      get 'speed_grader', params: {course_id: @course, assignment_id: @assignment.id}
      expect(response).not_to be_redirect
    end

    describe 'js_env' do
      let(:js_env) { assigns[:js_env] }

      it 'includes lti_retrieve_url' do
        get 'speed_grader', params: {course_id: @course, assignment_id: @assignment.id}
        expect(js_env[:lti_retrieve_url]).not_to be_nil
      end

      it 'includes the grading_type' do
        get 'speed_grader', params: {course_id: @course, assignment_id: @assignment.id}
        expect(js_env[:grading_type]).to eq('percent')
      end

      it 'includes anonymous identities keyed by anonymous_id' do
        @assignment.update!(moderated_grading: true, grader_count: 2)
        anonymous_id = @assignment.create_moderation_grader(@teacher, occupy_slot: true).anonymous_id
        get :speed_grader, params: { course_id: @course, assignment_id: @assignment }
        expect(js_env[:anonymous_identities]).to have_key anonymous_id
      end

      it 'sets can_view_audit_trail to true when the current user can view the assignment audit trail' do
        @course.root_account.role_overrides.create!(permission: :view_audit_trail, enabled: true, role: teacher_role)
        @assignment.update!(moderated_grading: true, grader_count: 2, grades_published_at: 2.days.ago)
        @assignment.update!(muted: false) # must be updated separately for some reason
        get :speed_grader, params: { course_id: @course, assignment_id: @assignment }
        expect(js_env[:can_view_audit_trail]).to be true
      end

      it 'sets can_view_audit_trail to false when the current user cannot view the assignment audit trail' do
        @assignment.update!(moderated_grading: true, grader_count: 2, muted: true)
        get :speed_grader, params: { course_id: @course, assignment_id: @assignment }
        expect(js_env[:can_view_audit_trail]).to be false
      end

      it 'includes MANAGE_GRADES' do
        get :speed_grader, params: { course_id: @course, assignment_id: @assignment }
        expect(js_env.fetch(:MANAGE_GRADES)).to be true
      end

      it 'includes READ_AS_ADMIN' do
        get :speed_grader, params: { course_id: @course, assignment_id: @assignment }
        expect(js_env.fetch(:READ_AS_ADMIN)).to be true
      end

      it "includes final_grader_id" do
        @assignment.update!(final_grader: @teacher, grader_count: 2, moderated_grading: true)
        get :speed_grader, params: { course_id: @course, assignment_id: @assignment }
        expect(js_env[:final_grader_id]).to eql @teacher.id
      end

      it "sets filter_speed_grader_by_student_group_feature_enabled to true when enabled" do
        @course.root_account.enable_feature!(:filter_speed_grader_by_student_group)
        get :speed_grader, params: { course_id: @course, assignment_id: @assignment }
        expect(js_env.fetch(:filter_speed_grader_by_student_group_feature_enabled)).to be true
      end

      it "sets filter_speed_grader_by_student_group_feature_enabled to false when disabled" do
        @course.root_account.disable_feature!(:filter_speed_grader_by_student_group)
        get :speed_grader, params: { course_id: @course, assignment_id: @assignment }
        expect(js_env.fetch(:filter_speed_grader_by_student_group_feature_enabled)).to be false
      end

      describe "student group filtering" do
        before(:each) do
          @course.root_account.enable_feature!(:filter_speed_grader_by_student_group)

          group_category.create_groups(2)
          group1.add_user(@student)
        end

        let(:group_category) { @course.group_categories.create!(name: "a group category") }
        let(:group1) { group_category.groups.first }

        context "when the SpeedGrader student group filter is enabled for the course" do
          before(:each) do
            @course.update!(filter_speed_grader_by_student_group: true)
          end

          it "sets filter_speed_grader_by_student_group to true" do
            get :speed_grader, params: {course_id: @course, assignment_id: @assignment}
            expect(js_env[:filter_speed_grader_by_student_group]).to be true
          end

          context "when loading a student causes a new group to be selected" do
            it "updates the viewing user's preferences for the course with the new group" do
              get :speed_grader, params: {course_id: @course, assignment_id: @assignment, student_id: @student}
              @teacher.reload

              saved_group_id = @teacher.get_preference(:gradebook_settings, @course.global_id).dig("filter_rows_by", "student_group_id")
              expect(saved_group_id).to eq group1.id.to_s
            end

            it "sets selected_student_group to the group's JSON representation" do
              get :speed_grader, params: {course_id: @course, assignment_id: @assignment, student_id: @student}
              expect(js_env.dig(:selected_student_group, "id")).to eq group1.id
            end

            it "sets student_group_reason_for_change to the supplied change reason" do
              get :speed_grader, params: {course_id: @course, assignment_id: @assignment, student_id: @student}
              expect(js_env[:student_group_reason_for_change]).to eq :no_group_selected
            end
          end

          context "when the selected group stays the same" do
            before(:each) do
              @teacher.set_preference(:gradebook_settings, @course.global_id, {"filter_rows_by" => {"student_group_id" => group1.id}})
            end

            it "sets selected_student_group to the selected group's JSON representation" do
              get :speed_grader, params: {course_id: @course, assignment_id: @assignment, student_id: @student}
              expect(js_env.dig(:selected_student_group, "id")).to eq group1.id
            end

            it "does not set a value for student_group_reason_for_change" do
              get :speed_grader, params: {course_id: @course, assignment_id: @assignment, student_id: @student}
              expect(js_env).not_to include(:student_group_reason_for_change)
            end
          end

          context "when the selected group is cleared due to loading a student not in any group" do
            let(:groupless_student) { @course.enroll_student(User.create!, enrollment_state: :active).user }

            before(:each) do
              @teacher.set_preference(:gradebook_settings, @course.global_id, {"filter_rows_by" => {"student_group_id" => group1.id}})
            end

            it "clears the selected group from the viewing user's preferences for the course" do
              get :speed_grader, params: {course_id: @course, assignment_id: @assignment, student_id: groupless_student}
              @teacher.reload

              saved_group_id = @teacher.get_preference(:gradebook_settings, @course.global_id).dig("filter_rows_by", "student_group_id")
              expect(saved_group_id).to be nil
            end

            it "does not set selected_student_group" do
              get :speed_grader, params: {course_id: @course, assignment_id: @assignment, student_id: groupless_student}
              expect(js_env).not_to include(:selected_student_group)
            end

            it "sets student_group_reason_for_change to the supplied change reason" do
              get :speed_grader, params: {course_id: @course, assignment_id: @assignment, student_id: groupless_student}
              expect(js_env[:student_group_reason_for_change]).to eq :student_in_no_groups
            end
          end
        end

        context "when the SpeedGrader student group filter is not enabled for the course" do
          it "does not set filter_speed_grader_by_student_group" do
            get :speed_grader, params: {course_id: @course, assignment_id: @assignment}
            expect(js_env).not_to include(:filter_speed_grader_by_student_group)
          end
        end
      end
    end

    describe 'current_anonymous_id' do
      before(:each) do
        user_session(@teacher)
      end

      context 'for a moderated assignment' do
        let(:moderated_assignment) do
          @course.assignments.create!(
            moderated_grading: true,
            grader_count: 1,
            final_grader: @teacher
          )
        end

        it 'is set to the anonymous ID for the viewing grader if grader identities are concealed' do
          moderated_assignment.update!(grader_names_visible_to_final_grader: false)
          moderated_assignment.moderation_graders.create!(user: @teacher, anonymous_id: 'zxcvb')

          get 'speed_grader', params: {course_id: @course, assignment_id: moderated_assignment}
          expect(assigns[:js_env][:current_anonymous_id]).to eq 'zxcvb'
        end

        it 'is not set if grader identities are visible' do
          get 'speed_grader', params: {course_id: @course, assignment_id: moderated_assignment}
          expect(assigns[:js_env]).not_to include(:current_anonymous_id)
        end

        it 'is not set if grader identities are concealed but grades are published' do
          moderated_assignment.update!(
            grader_names_visible_to_final_grader: false,
            grades_published_at: Time.zone.now
          )
          get 'speed_grader', params: {course_id: @course, assignment_id: moderated_assignment}
          expect(assigns[:js_env]).not_to include(:current_anonymous_id)
        end
      end

      it 'is not set if the assignment is not moderated' do
        get 'speed_grader', params: {course_id: @course, assignment_id: @assignment}
        expect(assigns[:js_env]).not_to include(:current_anonymous_id)
      end
    end

    describe "new_gradebook_plagiarism_icons_enabled" do
      it "is set to true if New Gradebook Plagiarism Icons are on" do
        @course.root_account.enable_feature!(:new_gradebook_plagiarism_indicator)
        get "speed_grader", params: {course_id: @course, assignment_id: @assignment}
        expect(assigns[:js_env][:new_gradebook_plagiarism_icons_enabled]).to be true
      end

      it "is not set if the New Gradebook Plagiarism Icons are off" do
        get "speed_grader", params: {course_id: @course, assignment_id: @assignment}
        expect(assigns[:js_env]).not_to include(:new_gradebook_plagiarism_icons_enabled)
      end
    end
  end

  describe "POST 'speed_grader_settings'" do
    it "lets you set your :enable_speedgrader_grade_by_question preference" do
      user_session(@teacher)
      expect(@teacher.preferences[:enable_speedgrader_grade_by_question]).not_to be_truthy

      post 'speed_grader_settings', params: {course_id: @course.id,
        enable_speedgrader_grade_by_question: "1"}
      expect(@teacher.reload.preferences[:enable_speedgrader_grade_by_question]).to be_truthy

      post 'speed_grader_settings', params: {course_id: @course.id,
        enable_speedgrader_grade_by_question: "0"}
      expect(@teacher.reload.preferences[:enable_speedgrader_grade_by_question]).not_to be_truthy
    end

    describe 'selected_section_id preference' do
      let(:course_settings) { @teacher.reload.get_preference(:gradebook_settings, @course.global_id) }

      before(:each) do
        user_session(@teacher)
      end

      it 'sets the selected section for the course to the passed-in value' do
        section_id = @course.course_sections.first.id
        post 'speed_grader_settings', params: {course_id: @course.id, selected_section_id: section_id}

        expect(course_settings.dig('filter_rows_by', 'section_id')).to eq section_id.to_s
      end

      it "ensures that selected_view_options_filters includes 'sections' if a section is selected" do
        section_id = @course.course_sections.first.id
        post 'speed_grader_settings', params: {course_id: @course.id, selected_section_id: section_id}

        expect(course_settings['selected_view_options_filters']).to include('sections')
      end

      context 'when a section has previously been selected' do
        before(:each) do
          @teacher.set_preference(:gradebook_settings, @course.global_id,
            {filter_rows_by: {section_id: @course.course_sections.first.id}})
        end

        it 'clears the selected section for the course if passed the value "all"' do
          post 'speed_grader_settings', params: {course_id: @course.id, selected_section_id: 'all'}

          expect(course_settings.dig('filter_rows_by', 'section_id')).to be nil
        end

        it 'clears the selected section if passed an invalid value' do
          post 'speed_grader_settings', params: {course_id: @course.id, selected_section_id: 'hahahaha'}

          expect(course_settings.dig('filter_rows_by', 'section_id')).to be nil
        end

        it 'clears the selected section if passed a non-active section in the course' do
          deleted_section = @course.course_sections.create!
          deleted_section.destroy!

          post 'speed_grader_settings', params: {course_id: @course.id, selected_section_id: deleted_section.id}

          expect(course_settings.dig('filter_rows_by', 'section_id')).to be nil
        end

        it 'clears the selected section if passed a section ID not in the course' do
          section_in_other_course = Course.create!.course_sections.create!
          post 'speed_grader_settings', params: {course_id: @course.id, selected_section_id: section_in_other_course.id}

          expect(course_settings.dig('filter_rows_by', 'section_id')).to be nil
        end
      end
    end
  end

  describe "POST 'save_assignment_order'" do
    it "saves the sort order in the user's preferences" do
      user_session(@teacher)
      post 'save_assignment_order', params: {course_id: @course.id, assignment_order: 'due_at'}
      saved_order = @teacher.get_preference(:course_grades_assignment_order, @course.id)
      expect(saved_order).to eq(:due_at)
    end
  end

  describe '#light_weight_ags_json' do
    it 'returns the necessary JSON for GradeCalculator' do
      ag = @course.assignment_groups.create! group_weight: 100
      a  = ag.assignments.create! submission_types: 'online_upload',
                                  points_possible: 10,
                                  context: @course,
                                  omit_from_final_grade: true
      AssignmentGroup.add_never_drop_assignment(ag, a)
      @controller.instance_variable_set(:@context, @course)
      @controller.instance_variable_set(:@current_user, @user)
      expect(@controller.light_weight_ags_json([ag])).to eq [
        {
          id: ag.id,
          rules: {
            'never_drop' => [
              a.id.to_s
            ]
          },
          group_weight: 100,
          assignments: [
            {
              due_at: nil,
              id: a.id,
              points_possible: 10,
              submission_types: ['online_upload'],
              omit_from_final_grade: true,
              muted: true
            }
          ],
        },
      ]
    end

    it 'does not return unpublished assignments' do
      course_with_student
      ag = @course.assignment_groups.create! group_weight: 100
      a1 = ag.assignments.create! :submission_types => 'online_upload',
                                  :points_possible  => 10,
                                  :context  => @course
      a2 = ag.assignments.build :submission_types => 'online_upload',
                                :points_possible  => 10,
                                :context  => @course
      a2.workflow_state = 'unpublished'
      a2.save!

    @controller.instance_variable_set(:@context, @course)
    @controller.instance_variable_set(:@current_user, @user)
    expect(@controller.light_weight_ags_json([ag])).to eq [
      {
        id: ag.id,
        rules: {},
        group_weight: 100,
        assignments: [
          {
            id: a1.id,
            due_at: nil,
            points_possible: 10,
            submission_types: ['online_upload'],
            omit_from_final_grade: false,
            muted: true
          }
        ],
      },
    ]
    end
  end

  describe '#external_tool_detail' do
    let(:tool) do
      {
        definition_id: 123,
        name: 'test lti',
        placements: {
          post_grades: {
            canvas_launch_url: 'http://example.com/lti/post_grades',
            launch_width: 100,
            launch_height: 100
          }
        }
      }
    end

    it 'maps a tool to launch details' do
      expect(@controller.external_tool_detail(tool)).to eql(
        id: 123,
        data_url: 'http://example.com/lti/post_grades',
        name: 'test lti',
        type: :lti,
        data_width: 100,
        data_height: 100
      )
    end
  end

  describe '#post_grades_ltis' do
    it 'maps #external_tools with #external_tool_detail' do
      expect(@controller).to receive(:external_tools).and_return([0,1,2,3,4,5,6,7,8,9])
      expect(@controller).to receive(:external_tool_detail).exactly(10).times

      @controller.post_grades_ltis
    end

    it 'memoizes' do
      expect(@controller).to receive(:external_tools).and_return([]).once

      expect(@controller.post_grades_ltis).to eq(@controller.post_grades_ltis)
    end
  end

  describe '#post_grades_tools' do
    it 'returns a tools with a type of post_grades if the post_grades feature option is enabled' do
      @course.enable_feature!(:post_grades)
      @controller.instance_variable_set(:@context, @course)
      expect(@controller.post_grades_tools).to eq([{:type=>:post_grades}])
    end

    it 'does not return a tools with a type of post_grades if the post_grades feature option is enabled' do
      @controller.instance_variable_set(:@context, @course)
      expect(@controller.post_grades_tools).to eq([])
    end
  end

  describe '#post_grades_feature?' do
    it 'returns false when :post_grades feature disabled for context' do
      context = object_double(@course, feature_enabled?: false)
      @controller.instance_variable_set(:@context, context)

      expect(@controller.post_grades_feature?).to eq(false)
    end

    it 'returns false when context does not allow grade publishing by user' do
      context = object_double(@course, feature_enabled?: true, allows_grade_publishing_by: false)
      @controller.instance_variable_set(:@context, context)

      expect(@controller.post_grades_feature?).to eq(false)
    end

    it 'returns false when #can_do is false' do
      context = object_double(@course, feature_enabled?: true, allows_grade_publishing_by: true)
      @controller.instance_variable_set(:@context, context)
      allow(@controller).to receive(:can_do).and_return(false)

      expect(@controller.post_grades_feature?).to eq(false)
    end

    it 'returns true when all conditions are met' do
      context = object_double(@course, feature_enabled?: true, allows_grade_publishing_by: true)
      @controller.instance_variable_set(:@context, context)
      allow(@controller).to receive(:can_do).and_return(true)

      expect(@controller.post_grades_feature?).to eq(true)
    end
  end

  describe "#grading_rubrics" do
    context "sharding" do
      specs_require_sharding

      it "should fetch rubrics from a cross-shard course" do
        user_session(@teacher)
        @shard1.activate do
          a = Account.create!
          @cs_course = Course.create!(:name => 'cs_course', :account => a)
          @rubric = Rubric.create!(context: @cs_course, title: 'testing')
          RubricAssociation.create!(context: @cs_course, rubric: @rubric, purpose: :bookmark, association_object: @cs_course)
          @cs_course.enroll_user(@teacher, "TeacherEnrollment", :enrollment_state => "active")
        end

        get "grading_rubrics", params: {:course_id => @course, :context_code => @cs_course.asset_string}
        json = json_parse(response.body)
        expect(json.first["rubric_association"]["rubric_id"]).to eq @rubric.global_id.to_s
        expect(json.first["rubric_association"]["context_code"]).to eq @cs_course.global_asset_string
      end
    end
  end
end
