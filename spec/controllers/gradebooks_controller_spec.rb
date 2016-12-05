# encoding: utf-8
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

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe GradebooksController do
  before :once do
    course_with_teacher active_all: true
    @teacher_enrollment = @enrollment
    student_in_course active_all: true
    @student_enrollment = @enrollment

    user(:active_all => true)
    @observer = @user
    @oe = @course.enroll_user(@user, 'ObserverEnrollment')
    @oe.accept
    @oe.update_attribute(:associated_user_id, @student.id)
  end

  it "uses GradebooksController" do
    expect(controller).to be_an_instance_of(GradebooksController)
  end

  describe "GET 'index'" do
    before(:each) do
      Course.expects(:find).returns(['a course'])
    end
  end

  describe "GET 'grade_summary'" do
    it "redirects to the login page if the user is logged out" do
      get 'grade_summary', :course_id => @course.id, :id => @student.id
      expect(response).to redirect_to(login_url)
      expect(flash[:warning]).to be_present
    end

    it "redirects teacher to gradebook" do
      user_session(@teacher)
      get 'grade_summary', :course_id => @course.id, :id => nil
      expect(response).to redirect_to(:action => 'show')
    end

    it "renders for current user" do
      user_session(@student)
      get 'grade_summary', :course_id => @course.id, :id => nil
      expect(response).to render_template('grade_summary')
    end

    it "does not allow access for inactive enrollment" do
      user_session(@student)
      @student_enrollment.deactivate
      get 'grade_summary', :course_id => @course.id, :id => nil
      assert_unauthorized
    end

    it "renders with specified user_id" do
      user_session(@student)
      get 'grade_summary', :course_id => @course.id, :id => @student.id
      expect(response).to render_template('grade_summary')
      expect(assigns[:presenter].courses_with_grades).not_to be_nil
    end

    it "does not allow access for wrong user" do
      user(:active_all => true)
      user_session(@user)
      get 'grade_summary', :course_id => @course.id, :id => nil
      assert_unauthorized
      get 'grade_summary', :course_id => @course.id, :id => @student.id
      assert_unauthorized
    end

    it "allows access for a linked observer" do
      user_session(@observer)
      get 'grade_summary', :course_id => @course.id, :id => @student.id
      expect(response).to render_template('grade_summary')
      expect(assigns[:courses_with_grades]).to be_nil
    end

    it "does not allow access for a linked student" do
      user(:active_all => true)
      user_session(@user)
      @se = @course.enroll_student(@user)
      @se.accept
      @se.update_attribute(:associated_user_id, @student.id)
      @user.reload
      get 'grade_summary', :course_id => @course.id, :id => @student.id
      assert_unauthorized
    end

    it "does not allow access for an observer linked in a different course" do
      @course1 = @course
      course(:active_all => true)
      @course2 = @course

      user_session(@observer)

      get 'grade_summary', :course_id => @course2.id, :id => @student.id
      assert_unauthorized
    end

    it "allows concluded teachers to see a student grades pages" do
      user_session(@teacher)
      @teacher_enrollment.conclude
      get 'grade_summary', :course_id => @course.id, :id => @student.id
      expect(response).to be_success
      expect(response).to render_template('grade_summary')
      expect(assigns[:courses_with_grades]).to be_nil
    end

    it "allows concluded students to see their grades pages" do
      user_session(@student)
      @student_enrollment.conclude
      get 'grade_summary', :course_id => @course.id, :id => @student.id
      expect(response).to render_template('grade_summary')
    end

    it "gives a student the option to switch between courses" do
      pseudonym(@teacher, :username => 'teacher@example.com')
      pseudonym(@student, :username => 'student@example.com')
      course_with_teacher(:user => @teacher, :active_all => 1)
      student_in_course :user => @student, :active_all => 1
      user_session(@student)
      get 'grade_summary', :course_id => @course.id, :id => @student.id
      expect(response).to be_success
      expect(assigns[:presenter].courses_with_grades).not_to be_nil
      expect(assigns[:presenter].courses_with_grades.length).to eq 2
    end

    it "does not give a teacher the option to switch between courses when viewing a student's grades" do
      pseudonym(@teacher, :username => 'teacher@example.com')
      pseudonym(@student, :username => 'student@example.com')
      course_with_teacher(:user => @teacher, :active_all => 1)
      student_in_course :user => @student, :active_all => 1
      user_session(@teacher)
      get 'grade_summary', :course_id => @course.id, :id => @student.id
      expect(response).to be_success
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
      get 'grade_summary', :course_id => course1.id, :id => @student.id
      expect(response).to be_success
      expect(assigns[:courses_with_grades]).to be_nil
    end

    it "assigns values for grade calculator to ENV" do
      user_session(@teacher)
      get 'grade_summary', :course_id => @course.id, :id => @student.id
      expect(assigns[:js_env][:submissions]).not_to be_nil
      expect(assigns[:js_env][:assignment_groups]).not_to be_nil
    end

    it "does not include assignment discussion information in grade calculator ENV data" do
      user_session(@teacher)
      assignment1 = @course.assignments.create(:title => "Assignment 1")
      assignment1.submission_types = "discussion_topic"
      assignment1.save!

      get 'grade_summary', :course_id => @course.id, :id => @student.id
      expect(assigns[:js_env][:assignment_groups].first[:assignments].first["discussion_topic"]).to be_nil
    end

    it "does not leak muted scores" do
      user_session(@student)
      a1, a2 = 2.times.map { |i|
        @course.assignments.create! name: "blah#{i}", points_possible: 10
      }
      a1.mute!
      a1.grade_student(@student, grade: 10, grader: @teacher)
      a2.grade_student(@student, grade: 5, grader: @teacher)
      get 'grade_summary', course_id: @course.id, id: @student.id
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
      get('grade_summary', course_id: @course.id, id: @student.id)
      submission = assigns[:js_env][:submissions].first
      expect(submission).to include :excused
      expect(submission).to include :workflow_state
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
        get 'grade_summary', course_id: @course.id, id: @student.id
        expect(assignment_ids).to eq [assignment3, assignment2, assignment1].map(&:id)
      end

      it "sort order of 'due_at' sorts by due date (null last), then title" do
        @teacher.preferences[:course_grades_assignment_order] = { @course.id => :due_at }
        @teacher.save!
        get 'grade_summary', course_id: @course.id, id: @student.id
        expect(assignment_ids).to eq [assignment3, assignment2, assignment1].map(&:id)
      end

      context "sort by: title" do
        let!(:teacher_setup) do
          @teacher.preferences[:course_grades_assignment_order] = { @course.id => :title }
          @teacher.save!
        end

        it "sorts assignments by title" do
          get 'grade_summary', course_id: @course.id, id: @student.id
          expect(assignment_ids).to eq [assignment2, assignment1, assignment3].map(&:id)
        end

        it "ingores case" do
          assignment1.title = 'banana'
          assignment1.save!
          get 'grade_summary', course_id: @course.id, id: @student.id
          expect(assignment_ids).to eq [assignment2, assignment1, assignment3].map(&:id)
        end
      end

      it "sort order of 'assignment_group' sorts by assignment group position, then assignment position" do
        @teacher.preferences[:course_grades_assignment_order] = { @course.id => :assignment_group }
        @teacher.save!
        get 'grade_summary', course_id: @course.id, id: @student.id
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
          get 'grade_summary', course_id: @course.id, id: @student.id
          expect(assignment_ids).to eq [assignment3, assignment2, assignment1].map(&:id)
        end

        it "sorts by module position, then context module tag position, " \
        "with those not belonging to a module sorted last" do
          assignment3.context_module_tags.first.destroy!
          get 'grade_summary', course_id: @course.id, id: @student.id
          expect(assignment_ids).to eq [assignment2, assignment1, assignment3].map(&:id)
        end
      end
    end

    context "Multiple Grading Periods" do
      before :once do
        @course.root_account.enable_feature!(:multiple_grading_periods)
      end

      it "does not display totals if 'All Grading Periods' is selected" do
        user_session(@student)
        all_grading_periods_id = 0
        get 'grade_summary', :course_id => @course.id, :id => @student.id, grading_period_id: all_grading_periods_id
        expect(assigns[:exclude_total]).to eq true
      end

      it "displays totals if any grading period other than 'All Grading Periods' is selected" do
        user_session(@student)
        get 'grade_summary', :course_id => @course.id, :id => @student.id, grading_period_id: 1
        expect(assigns[:exclude_total]).to eq false
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
          get 'grade_summary', :course_id => @course.id, :id => @student.id
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

        get 'grade_summary', :course_id => @course.id, :id => @fake_student.id
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
        get 'grade_summary', :course_id => @course.id, :id => "lqw"
      end
    end
  end

  describe "GET 'show'" do
    describe "csv" do
      before :once do
        assignment1 = @course.assignments.create(:title => "Assignment 1")
        assignment2 = @course.assignments.create(:title => "Assignment 2")
      end

      before :each do
        user_session(@teacher)
      end

      shared_examples_for "working download" do
        it "does not recompute enrollment grades" do
          Enrollment.expects(:recompute_final_score).never
          get 'show', :course_id => @course.id, :init => 1, :assignments => 1, :format => 'csv'
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
        get "show", :course_id => @course.id
        expect(response).to render_template("gradebook2")
      end

      it "redirects to Individual View with a friendly URL" do
        @teacher.preferences[:gradebook_version] = "srgb"
        get "show", :course_id => @course.id
        expect(response).to render_template("screenreader")
      end

      it "requests groups without wiki_page assignments" do
        get "show", :course_id => @course.id
        url = controller.js_env[:GRADEBOOK_OPTIONS][:assignment_groups_url]
        expect(URI.unescape(url)).to include 'exclude_assignment_submission_types[]=wiki_page'
      end
    end

    it "renders the unauthorized page without gradebook authorization" do
      get "show", :course_id => @course.id
      assert_unauthorized
    end

    context "includes student context card info in ENV" do
      before { user_session(@teacher) }

      it "includes context_id" do
        get :show, course_id: @course.id
        context_id = assigns[:js_env][:GRADEBOOK_OPTIONS][:context_id]
        expect(context_id).to eq @course.id.to_param
      end

      it "doesn't enable context cards when feature is off" do
        get :show, course_id: @course.id
        expect(assigns[:js_env][:STUDENT_CONTEXT_CARDS_ENABLED]).to eq false
      end

      it "enables context cards when feature is on" do
        @course.root_account.enable_feature! :student_context_cards
        get :show, course_id: @course.id
        expect(assigns[:js_env][:STUDENT_CONTEXT_CARDS_ENABLED]).to eq true
      end
    end
  end

  describe "GET 'change_gradebook_version'" do
    it 'switches to gradebook2 if clicked' do
      user_session(@teacher)
      get 'grade_summary', :course_id => @course.id, :id => nil

      expect(response).to redirect_to(:action => 'show')

      # tell it to use gradebook 2
      get 'change_gradebook_version', :course_id => @course.id, :version => 2
      expect(response).to redirect_to(:action => 'show')
    end
  end

  describe "POST 'submissions_zip_upload'" do
    it "requires authentication" do
      course
      assignment_model
      post 'submissions_zip_upload', :course_id => @course.id, :assignment_id => @assignment.id, :submissions_zip => 'dummy'
      assert_unauthorized
    end
  end

  describe "POST 'update_submission'" do
    it "allows adding comments for submission" do
      user_session(@teacher)
      @assignment = @course.assignments.create!(:title => "some assignment")
      @student = @course.enroll_user(User.create!(:name => "some user"))
      post 'update_submission', :course_id => @course.id, :submission =>
        {:comment => "some comment",:assignment_id => @assignment.id, :user_id => @student.user_id}
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
      data = fixture_file_upload("scribd_docs/doc.doc", "application/msword", true)
      post 'update_submission',
        :course_id => @course.id,
        :attachments => { "0" => { :uploaded_data => data } },
        :submission => { :comment => "some comment",
                         :assignment_id => @assignment.id,
                         :user_id => @student.user_id }
      expect(response).to be_redirect
      expect(assigns[:assignment]).to eql(@assignment)
      expect(assigns[:submissions]).not_to be_nil
      expect(assigns[:submissions].length).to eql(1)
      expect(assigns[:submissions][0].submission_comments).not_to be_nil
      expect(assigns[:submissions][0].submission_comments[0].comment).to eql("some comment")
      expect(assigns[:submissions][0].submission_comments[0].attachments.length).to eql(1)
      expect(assigns[:submissions][0].submission_comments[0].attachments[0].display_name).to eql("doc.doc")
    end

    it "does not allow updating submissions for concluded courses" do
      user_session(@teacher)
      @teacher_enrollment.complete
      @assignment = @course.assignments.create!(:title => "some assignment")
      @student = @course.enroll_user(User.create!(:name => "some user"))
      post 'update_submission',
        :course_id => @course.id,
        :submission => { :comment => "some comment",
                         :assignment_id => @assignment.id,
                         :user_id => @student.user_id }
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
        :course_id => @course.id,
        :submission => { :comment => "some comment",
                         :assignment_id => @assignment.id,
                         :user_id => s1.user_id }
      expect(response).to be_redirect

      # attempt to grade another section throws not found
      post 'update_submission',
        :course_id => @course.id,
        :submission => { :comment => "some comment",
                         :assignment_id => @assignment.id,
                         :user_id => s2.user_id }
      expect(flash[:error]).to eql 'Submission was unsuccessful: Submission Failed'
    end

    context "moderated grading" do
      before :once do
        @assignment = @course.assignments.create!(:title => "some assignment", :moderated_grading => true)
        @student = @course.enroll_student(User.create!(:name => "some user"), :enrollment_state => :active).user
      end

      before :each do
        user_session(@teacher)
      end

      it "creates a provisional grade" do
        submission = @assignment.submit_homework(@student, :body => "hello")
        post 'update_submission',
          :format => :json,
          :course_id => @course.id,
          :submission => { :score => 100,
                           :comment => "provisional!",
                           :assignment_id => @assignment.id,
                           :user_id => @student.id,
                           :provisional => true }

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

      it "includes the graded anonymously flag in the provisional grade object" do
        submission = @assignment.submit_homework(@student, body: "hello")
        post 'update_submission',
          format: :json,
          course_id: @course.id,
          submission: { score: 100,
                           comment: "provisional!",
                           assignment_id: @assignment.id,
                           user_id: @student.id,
                           provisional: true,
                           graded_anonymously: true }

        submission.reload
        pg = submission.provisional_grade(@teacher)
        expect(pg.graded_anonymously).to eq true

        submission = @assignment.submit_homework(@student, body: "hello")
        post 'update_submission',
          format: :json,
          course_id: @course.id,
          submission: { score: 100,
                           comment: "provisional!",
                           assignment_id: @assignment.id,
                           user_id: @student.id,
                           provisional: true,
                           graded_anonymously: false }

        submission.reload
        pg = submission.provisional_grade(@teacher)
        expect(pg.graded_anonymously).to eq false
      end

      it "doesn't create a provisional grade when the student has one already (and isn't in the moderation set)" do
        submission = @assignment.submit_homework(@student, :body => "hello")
        other_teacher = teacher_in_course(:course => @course, :active_all => true).user
        submission.find_or_create_provisional_grade!(other_teacher)

        post 'update_submission', :format => :json, :course_id => @course.id,
          :submission => { :score => 100, :comment => "provisional!", :assignment_id => @assignment.id,
            :user_id => @student.id, :provisional => true }
        expect(response).to_not be_success
        expect(response.body).to include("Student already has the maximum number of provisional grades")
     end

      it "should create a provisional grade even if the student has one but is in the moderation set" do
        submission = @assignment.submit_homework(@student, :body => "hello")
        other_teacher = teacher_in_course(:course => @course, :active_all => true).user
        submission.find_or_create_provisional_grade!(other_teacher)

        @assignment.moderated_grading_selections.create!(:student => @student)

        post 'update_submission', :format => :json, :course_id => @course.id,
          :submission => { :score => 100, :comment => "provisional!", :assignment_id => @assignment.id,
            :user_id => @student.id, :provisional => true }
        expect(response).to be_success
      end

      it "creates a final provisional grade" do
        submission = @assignment.submit_homework(@student, :body => "hello")
        other_teacher = teacher_in_course(:course => @course, :active_all => true).user
        submission.find_or_create_provisional_grade!(other_teacher) # create one so we can make a final

        post 'update_submission',
          :format => :json,
          :course_id => @course.id,
          :submission => { :score => 100,
            :comment => "provisional!",
            :assignment_id => @assignment.id,
            :user_id => @student.id,
            :provisional => true,
            :final => true
          }
        expect(response).to be_success

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
    end
  end

  describe "GET 'speed_grader'" do
    it "redirects the user if course's large_roster? setting is true" do
      user_session(@teacher)
      assignment = @course.assignments.create!(:title => 'some assignment')

      Course.any_instance.stubs(:large_roster?).returns(true)

      get 'speed_grader', :course_id => @course.id, :assignment_id => assignment.id
      expect(response).to be_redirect
      expect(flash[:notice]).to eq 'SpeedGrader is disabled for this course'
    end

    context "assignment published status" do
      before :once do
        @assign = @course.assignments.create!(title: 'Totally')
        @assign.unpublish
      end

      before :each do
        user_session(@teacher)
      end

      it "redirects if the assignment is unpublished" do
        get 'speed_grader', course_id: @course, assignment_id: @assign.id
        expect(response).to be_redirect
        expect(flash[:notice]).to eq I18n.t(
          :speedgrader_enabled_only_for_published_content,
                           'SpeedGrader is enabled only for published content.')
      end

      it "does not redirect if the assignment is published" do
        @assign.publish
        get 'speed_grader', course_id: @course, assignment_id: @assign.id
        expect(response).not_to be_redirect
      end
    end

    it 'includes the lti_retrieve_url in the js_env' do
      user_session(@teacher)
      @assignment = @course.assignments.create!(title: "A Title", submission_types: 'online_url,online_file')

      get 'speed_grader', course_id: @course, assignment_id: @assignment.id
      expect(assigns[:js_env][:lti_retrieve_url]).not_to be_nil
    end
  end

  describe "POST 'speed_grader_settings'" do
    it "lets you set your :enable_speedgrader_grade_by_question preference" do
      user_session(@teacher)
      expect(@teacher.preferences[:enable_speedgrader_grade_by_question]).not_to be_truthy

      post 'speed_grader_settings', course_id: @course.id,
        enable_speedgrader_grade_by_question: "1"
      expect(@teacher.reload.preferences[:enable_speedgrader_grade_by_question]).to be_truthy

      post 'speed_grader_settings', course_id: @course.id,
        enable_speedgrader_grade_by_question: "0"
      expect(@teacher.reload.preferences[:enable_speedgrader_grade_by_question]).not_to be_truthy
    end
  end

  describe "POST 'save_assignment_order'" do
    it "saves the sort order in the user's preferences" do
      user_session(@teacher)
      post 'save_assignment_order', course_id: @course.id, assignment_order: 'due_at'
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
              omit_from_final_grade: true
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
            omit_from_final_grade: false
          }
        ],
      },
    ]
    end
  end
end
