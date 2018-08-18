# encoding: utf-8
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

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

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

    it "includes muted assignments" do
      user_session(@student)
      assignment = @course.assignments.create!(title: "Example Assignment")
      assignment.mute!
      get 'grade_summary', params: {course_id: @course.id, id: @student.id}
      expect(assigns[:js_env][:assignment_groups].first[:assignments].size).to eq 1
      expect(assigns[:js_env][:assignment_groups].first[:assignments].first[:muted]).to eq true
    end

    it "does not leak muted scores" do
      user_session(@student)
      a1, a2 = 2.times.map { |i|
        @course.assignments.create! name: "blah#{i}", points_possible: 10
      }
      a1.mute!
      a1.grade_student(@student, grade: 10, grader: @teacher)
      a2.grade_student(@student, grade: 5, grader: @teacher)
      get 'grade_summary', params: {course_id: @course.id, id: @student.id}
      expected =
      expect(assigns[:js_env][:submissions].sort_by { |s|
        s['assignment_id']
      }).to eq [
        {score: 5, assignment_id: a2.id, excused: false, workflow_state: 'graded'}
      ]
    end

    it "includes necessary attributes on the submissions" do
      user_session(@student)
      assignment = @course.assignments.create!(points_possible: 10)
      assignment.grade_student(@student, grade: 10, grader: @teacher)
      get('grade_summary', params: {course_id: @course.id, id: @student.id})
      submission = assigns[:js_env][:submissions].first
      expect(submission).to include :excused
      expect(submission).to include :workflow_state
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
        @teacher.preferences[:course_grades_assignment_order] = { @course.id => :due_at }
        @teacher.save!
        get 'grade_summary', params: {course_id: @course.id, id: @student.id}
        expect(assignment_ids).to eq [assignment3, assignment2, assignment1].map(&:id)
      end

      context "sort by: title" do
        let!(:teacher_setup) do
          @teacher.preferences[:course_grades_assignment_order] = { @course.id => :title }
          @teacher.save!
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
        @teacher.save!
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
          @teacher.preferences[:course_grades_assignment_order] = { @course.id => :module }
          @teacher.save!
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
        get 'grade_summary', params: {:course_id => @course.id, :id => @student.id, grading_period_id: 1}
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

    context "as an admin with new gradebook disabled" do
      before :each do
        account_admin_user(account: @course.root_account)
        user_session(@admin)
      end

      it "renders default gradebook when preferred with 'default'" do
        @admin.preferences[:gradebook_version] = "default"
        get "show", params: { course_id: @course.id }
        expect(response).to render_template("gradebook")
      end

      it "renders default gradebook when preferred with '2'" do
        # most users will have this set from before New Gradebook existed
        @admin.preferences[:gradebook_version] = "2"
        get "show", params: { course_id: @course.id }
        expect(response).to render_template("gradebook")
      end

      it "renders screenreader gradebook when preferred with 'individual'" do
        @admin.preferences[:gradebook_version] = "individual"
        get "show", params: { course_id: @course.id }
        expect(response).to render_template("screenreader")
      end

      it "renders screenreader gradebook when preferred with 'srgb'" do
        # most users will have this set from before New Gradebook existed
        @admin.preferences[:gradebook_version] = "srgb"
        get "show", params: { course_id: @course.id }
        expect(response).to render_template("screenreader")
      end

      it "renders default gradebook when user has no preference" do
        get "show", params: { course_id: @course.id }
        expect(response).to render_template("gradebook")
      end

      it "ignores the parameter version when not in development" do
        allow(Rails.env).to receive(:development?).and_return(false)
        @admin.preferences[:gradebook_version] = "default"
        get "show", params: { course_id: @course.id, version: "individual" }
        expect(response).to render_template("gradebook")
      end
    end

    context "as an admin with new gradebook enabled" do
      before :each do
        account_admin_user(account: @course.root_account)
        user_session(@admin)
        @course.enable_feature!(:new_gradebook)
      end

      it "renders new default gradebook when preferred with 'default'" do
        @admin.preferences[:gradebook_version] = "default"
        get "show", params: { course_id: @course.id }
        expect(response).to render_template("gradebooks/gradezilla/gradebook")
      end

      it "renders new default gradebook when preferred with '2'" do
        # most users will have this set from before New Gradebook existed
        @admin.preferences[:gradebook_version] = "2"
        get "show", params: { course_id: @course.id }
        expect(response).to render_template("gradebooks/gradezilla/gradebook")
      end

      it "renders new screenreader gradebook when preferred with 'individual'" do
        @admin.preferences[:gradebook_version] = "individual"
        get "show", params: { course_id: @course.id }
        expect(response).to render_template("gradebooks/gradezilla/individual")
      end

      it "renders new screenreader gradebook when preferred with 'srgb'" do
        # most a11y users will have this set from before New Gradebook existed
        @admin.preferences[:gradebook_version] = "srgb"
        get "show", params: { course_id: @course.id }
        expect(response).to render_template("gradebooks/gradezilla/individual")
      end

      it "renders new default gradebook when user has no preference" do
        get "show", params: { course_id: @course.id }
        expect(response).to render_template("gradebooks/gradezilla/gradebook")
      end

      it "ignores the parameter version when not in development" do
        allow(Rails.env).to receive(:development?).and_return(false)
        @admin.preferences[:gradebook_version] = "default"
        get "show", params: { course_id: @course.id, version: "individual" }
        expect(response).to render_template("gradebooks/gradezilla/gradebook")
      end
    end

    context "in development with new gradebook disabled and requested version is 'default'" do
      before :each do
        account_admin_user(account: @course.root_account)
        user_session(@admin)
        @admin.preferences[:gradebook_version] = "individual"
        allow(Rails.env).to receive(:development?).and_return(true)
      end

      it "renders new default gradebook when new_gradebook param is 'true'" do
        get "show", params: { course_id: @course.id, version: "default", new_gradebook: "true" }
        expect(response).to render_template("gradebooks/gradezilla/gradebook")
      end

      it "renders old default gradebook when new_gradebook param is 'false'" do
        get "show", params: { course_id: @course.id, version: "default", new_gradebook: "false" }
        expect(response).to render_template("gradebook")
      end

      it "renders old default gradebook when new_gradebook param is not provided" do
        get "show", params: { course_id: @course.id, version: "default" }
        expect(response).to render_template("gradebook")
      end
    end

    context "in development with new gradebook disabled and requested version is 'individual'" do
      before :each do
        account_admin_user(account: @course.root_account)
        user_session(@admin)
        @admin.preferences[:gradebook_version] = "default"
        allow(Rails.env).to receive(:development?).and_return(true)
      end

      it "renders new screenreader gradebook when new_gradebook param is 'true'" do
        get "show", params: { course_id: @course.id, version: "individual", new_gradebook: "true" }
        expect(response).to render_template("gradebooks/gradezilla/individual")
      end

      it "renders old screenreader gradebook when new_gradebook param is 'false'" do
        get "show", params: { course_id: @course.id, version: "individual", new_gradebook: "false" }
        expect(response).to render_template("screenreader")
      end

      it "renders old screenreader gradebook when new_gradebook param is not provided" do
        get "show", params: { course_id: @course.id, version: "individual" }
        expect(response).to render_template("screenreader")
      end
    end

    context "in development with new gradebook enabled and requested version is 'default'" do
      before :each do
        @course.enable_feature!(:new_gradebook)
        account_admin_user(account: @course.root_account)
        user_session(@admin)
        @admin.preferences[:gradebook_version] = "individual"
        allow(Rails.env).to receive(:development?).and_return(true)
      end

      it "renders new default gradebook when new_gradebook param is 'true'" do
        get "show", params: { course_id: @course.id, version: "default", new_gradebook: "true" }
        expect(response).to render_template("gradebooks/gradezilla/gradebook")
      end

      it "renders old default gradebook when new_gradebook param is 'false'" do
        get "show", params: { course_id: @course.id, version: "default", new_gradebook: "false" }
        expect(response).to render_template("gradebook")
      end

      it "renders new default gradebook when new_gradebook param is not provided" do
        get "show", params: { course_id: @course.id, version: "default" }
        expect(response).to render_template("gradebooks/gradezilla/gradebook")
      end
    end

    context "in development with new gradebook enabled and requested version is 'individual'" do
      before :each do
        @course.enable_feature!(:new_gradebook)
        account_admin_user(account: @course.root_account)
        user_session(@admin)
        @admin.preferences[:gradebook_version] = "default"
        allow(Rails.env).to receive(:development?).and_return(true)
      end

      it "renders new screenreader gradebook when new_gradebook param is 'true'" do
        get "show", params: { course_id: @course.id, version: "individual", new_gradebook: "true" }
        expect(response).to render_template("gradebooks/gradezilla/individual")
      end

      it "renders old screenreader gradebook when new_gradebook param is 'false'" do
        get "show", params: { course_id: @course.id, version: "individual", new_gradebook: "false" }
        expect(response).to render_template("screenreader")
      end

      it "renders new screenreader gradebook when new_gradebook param is not provided" do
        get "show", params: { course_id: @course.id, version: "individual" }
        expect(response).to render_template("gradebooks/gradezilla/individual")
      end
    end

    describe 'js_env' do
      before :each do
        user_session(@teacher)
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

      it "includes colors if New Gradebook is enabled" do
        @course.enable_feature!(:new_gradebook)
        get :show, params: {course_id: @course.id}
        expect(gradebook_options).to have_key :colors
      end

      it "does not include colors if New Gradebook is disabled" do
        get :show, params: {course_id: @course.id}
        expect(gradebook_options).not_to have_key :colors
      end

      it "includes late_policy if New Gradebook is enabled" do
        @course.enable_feature!(:new_gradebook)
        get :show, params: { course_id: @course.id }
        expect(gradebook_options).to have_key :late_policy
      end

      it "does not include late_policy if New Gradebook is disabled" do
        get :show, params: { course_id: @course.id }
        expect(gradebook_options).not_to have_key :late_policy
      end

      it "includes grading_schemes when New Gradebook is enabled" do
        @course.enable_feature!(:new_gradebook)
        get :show, params: { course_id: @course.id }
        expect(gradebook_options).to have_key :grading_schemes
      end

      it "does not include grading_schemes when New Gradebook is disabled" do
        get :show, params: { course_id: @course.id }
        expect(gradebook_options).not_to have_key :grading_schemes
      end

      it 'includes api_max_per_page' do
        Setting.set('api_max_per_page', 50)
        get :show, params: {course_id: @course.id}
        api_max_per_page = assigns[:js_env][:GRADEBOOK_OPTIONS][:api_max_per_page]
        expect(api_max_per_page).to eq(50)
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
        it "is not included if New Gradebook is disabled" do
          get :show, params: {course_id: @course.id}
          expect(gradebook_options).not_to have_key :graded_late_submissions_exist
        end

        context "New Gradebook is enabled" do
          before(:once) do
            @course.enable_feature!(:new_gradebook)
          end

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

          it "is included if New Gradebook is enabled" do
            get :show, params: {course_id: @course.id}
            gradebook_options = controller.js_env.fetch(:GRADEBOOK_OPTIONS)
            expect(gradebook_options).to have_key :graded_late_submissions_exist
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
        it "should get all the expected datas even with multibytes characters", :focus => true do
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
        expect(response).to render_template("screenreader")
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

        context 'outcome proficiency on account' do
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
        expect(assigns[:js_env][:STUDENT_CONTEXT_CARDS_ENABLED]).to eq false
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
      @teacher.preferences[:gradebook_settings] = {}
      @teacher.preferences[:gradebook_settings][@course.id] = {
        "sort_rows_by_column_id": "student",
        "sort_rows_by_setting_key": "name",
        "sort_rows_by_direction": "descending"
      }

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

  describe "POST 'update_submission'" do
    let(:json) { JSON.parse(response.body) }

    describe "returned JSON" do
      before(:once) do
        @assignment = @course.assignments.create!(title: "Math 1.1")
        @student = @course.enroll_user(User.create!(name: "Adam Jones")).user
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

        it 'works with the absence of user_id and the presence of anonymous_id' do
          user_session(@teacher)
          post(:update_submission, params: post_params, format: :json)
          submissions = json.map {|submission| submission.fetch('submission').fetch('anonymous_id')}
          expect(submissions).to contain_exactly(@submission.anonymous_id)
        end

        it 'does not include user_ids for muted anonymous assignments' do
          user_session(@teacher)
          post(:update_submission, params: post_params, format: :json)
          submissions = json.map {|submission| submission['submission'].key?('user_id')}
          expect(submissions).to contain_exactly(false)
        end

        it 'includes user_ids for unmuted anonymous assignments' do
          user_session(@teacher)
          @assignment.unmute!
          post(:update_submission, params: post_params, format: :json)
          submission = json.first.fetch('submission')
          expect(submission).to have_key('user_id')
        end
      end
    end

    it "allows adding comments for submission" do
      user_session(@teacher)
      @assignment = @course.assignments.create!(:title => "some assignment")
      @student = @course.enroll_user(User.create!(:name => "some user"))
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
      expect(response).to be_redirect
      expect(assigns[:assignment]).to eql(@assignment)
      expect(assigns[:submissions]).not_to be_nil
      expect(assigns[:submissions].length).to eql(1)
      expect(assigns[:submissions][0].submission_comments).not_to be_nil
      expect(assigns[:submissions][0].submission_comments[0].comment).to eql("some comment")
      expect(assigns[:submissions][0].submission_comments[0].attachments.length).to eql(1)
      expect(assigns[:submissions][0].submission_comments[0].attachments[0].display_name).to eql("doc.doc")
    end

    context 'media comments' do
      before :each do
        user_session(@teacher)
        @assignment = @course.assignments.create!(title: 'some assignment')
        @student = @course.enroll_user(User.create!(name: 'some user'))
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
        expect(json[0]['submission']['score']).to eq 100
        expect(json[0]['submission']['grade_matches_current_submission']).to eq true
        expect(json[0]['submission']['submission_comments'].first['submission_comment']['comment']).to eq 'provisional!'
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
          response_json[0]['submission']
        end

        it 'returns the submitted score in the submission JSON' do
          post 'update_submission', params: provisional_grade_params, format: :json
          post 'update_submission', params: final_provisional_grade_params, format: :json

          expect(submission_json['score']).to eq 77
        end

        it 'returns the submitted comments in the submission JSON' do
          post 'update_submission', params: provisional_grade_params, format: :json
          post 'update_submission', params: final_provisional_grade_params, format: :json

          all_comments = submission_json['submission_comments']
          expect(all_comments.first['submission_comment']['comment']).to eq 'THE END'
        end

        it 'returns the value for grade_matches_current_submission of the submitted grade in the JSON' do
          post 'update_submission', params: provisional_grade_params, format: :json
          post 'update_submission', params: final_provisional_grade_params, format: :json

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

    it "redirects if the assignment's moderated grader limit is reached" do
      allow_any_instance_of(Assignment).to receive(:moderated_grader_limit_reached?).and_return(true)

      get 'speed_grader', params: {:course_id => @course.id, :assignment_id => @assignment.id}
      expect(response).to be_redirect
      expect(flash[:notice]).to eq 'The maximum number of graders for this assignment has been reached.'
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

    it 'includes the lti_retrieve_url in the js_env' do
      get 'speed_grader', params: {course_id: @course, assignment_id: @assignment.id}
      expect(assigns[:js_env][:lti_retrieve_url]).not_to be_nil
    end

    it 'includes the grading_type in the js_env' do
      get 'speed_grader', params: {course_id: @course, assignment_id: @assignment.id}
      expect(assigns[:js_env][:grading_type]).to eq('percent')
    end

    it 'sets disable_unmute_assignment to false if the assignment is not muted' do
      @assignment.update!(muted: false)
      get 'speed_grader', params: {course_id: @course, assignment_id: @assignment.id}
      expect(assigns[:disable_unmute_assignment]).to eq false
    end

    it 'sets disable_unmute_assignment to false if assignment grades have been published' do
      @assignment.update!(grades_published_at: Time.zone.now)
      get 'speed_grader', params: {course_id: @course, assignment_id: @assignment.id}
      expect(assigns[:disable_unmute_assignment]).to eq false
    end

    it 'sets disable_unmute_assignment to true if assignment muted and grades not published' do
      @assignment.update!(muted: true, grades_published_at: nil, moderated_grading: true, grader_count: 1)
      get 'speed_grader', params: {course_id: @course, assignment_id: @assignment.id}
      expect(assigns[:disable_unmute_assignment]).to eq true
    end

    it 'sets new_gradebook_enabled in ENV to true if new gradebook is enabled' do
      @course.enable_feature!(:new_gradebook)
      get 'speed_grader', params: {course_id: @course, assignment_id: @assignment.id}
      expect(assigns[:js_env][:new_gradebook_enabled]).to eq true
    end

    it 'sets new_gradebook_enabled in ENV to false if new gradebook is not enabled' do
      @course.disable_feature!(:new_gradebook)
      get 'speed_grader', params: {course_id: @course, assignment_id: @assignment.id}
      expect(assigns[:js_env][:new_gradebook_enabled]).to eq false
    end

    it 'includes anonymous identities keyed by anonymous_id in the ENV' do
      @assignment.update!(moderated_grading: true, grader_count: 2)
      anonymous_id = @assignment.create_moderation_grader(@teacher, occupy_slot: true).anonymous_id
      get :speed_grader, params: { course_id: @course, assignment_id: @assignment }
      expect(assigns[:js_env][:anonymous_identities]).to have_key anonymous_id
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
      let(:course_settings) { @teacher.reload.preferences.dig(:gradebook_settings, @course.id) }

      before(:each) do
        @teacher.preferences[:gradebook_settings] = { @course.id => {} }

        user_session(@teacher)
      end

      context 'when new gradebook is enabled' do
        it 'sets the selected section for the course to the passed-in value' do
          section_id = @course.course_sections.first.id
          post 'speed_grader_settings', params: {course_id: @course.id, selected_section_id: section_id}

          expect(course_settings.dig('filter_rows_by', 'section_id')).to eq section_id.to_s
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
      saved_order = @teacher.preferences[:course_grades_assignment_order][@course.id]
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
              muted: false
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
            muted: false
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
end
