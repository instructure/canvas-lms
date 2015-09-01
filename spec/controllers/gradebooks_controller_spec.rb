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
      a1.grade_student(@student, grade: 10)
      a2.grade_student(@student, grade: 5)
      get 'grade_summary', course_id: @course.id, id: @student.id
      expected =
      expect(assigns[:js_env][:submissions].sort_by { |s|
        s['assignment_id']
      }).to eq [
        {'score' => nil, 'assignment_id' => a1.id},
        {'score' => 5, 'assignment_id' => a2.id}
      ]
    end

    it "sorts assignments by due date (null last), then title" do
      user_session(@teacher)
      assignment1 = @course.assignments.create(:title => "Assignment 1")
      assignment2 = @course.assignments.create(:title => "Assignment 2", :due_at => 3.days.from_now)
      assignment3 = @course.assignments.create(:title => "Assignment 3", :due_at => 2.days.from_now)

      get 'grade_summary', :course_id => @course.id, :id => @student.id
      assignment_ids = assigns[:presenter].assignments.select{|a| a.class == Assignment}.map(&:id)
      expect(assignment_ids).to eq [assignment3, assignment2, assignment1].map(&:id)
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
            { user: @teacher, include_priors: false, include_sis_id: true }
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
    end

    it "renders the unauthorized page without gradebook authorization" do
      get "show", :course_id => @course.id
      assert_unauthorized
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

    it "creates a provisional grade" do
      user_session(@teacher)
      @assignment = @course.assignments.create!(:title => "some assignment")
      @student = @course.enroll_student(User.create!(:name => "some user"), :enrollment_state => :active).user
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
      expect(submission.provisional_grade(@teacher).submission_comments.first.comment).to eq 'provisional!'

      # confirm the response JSON shows provisional information
      json = JSON.parse response.body
      expect(json[0]['submission']['score']).to eq 100
      expect(json[0]['submission']['grade_matches_current_submission']).to eq true
      expect(json[0]['submission']['submission_comments'].first['submission_comment']['comment']).to eq 'provisional!'
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

  describe '#light_weight_ags_json' do
    it 'returns the necessary JSON for GradeCalculator' do
      ag = @course.assignment_groups.create! group_weight: 100
      a  = ag.assignments.create! :submission_types => 'online_upload',
                                  :points_possible  => 10,
                                  :context  => @course
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
          }
        ],
      },
    ]
    end
  end
end
