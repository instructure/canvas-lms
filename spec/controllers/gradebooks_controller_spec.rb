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

  it "should use GradebooksController" do
    controller.should be_an_instance_of(GradebooksController)
  end

  describe "GET 'index'" do
    before(:each) do
      Course.expects(:find).returns(['a course'])
    end
  end

  describe "GET 'grade_summary'" do
    it "should redirect teacher to gradebook" do
      course_with_teacher_logged_in(:active_all => true)
      get 'grade_summary', :course_id => @course.id, :id => nil
      response.should redirect_to(:action => 'gradebook2')
    end

    it "should render for current user" do
      course_with_student_logged_in(:active_all => true)
      get 'grade_summary', :course_id => @course.id, :id => nil
      response.should render_template('grade_summary')
    end

    it "should render with specified user_id" do
      course_with_student_logged_in(:active_all => true)
      get 'grade_summary', :course_id => @course.id, :id => @user.id
      response.should render_template('grade_summary')
      assigns[:presenter].courses_with_grades.should_not be_nil
    end

    it "should not allow access for wrong user" do
      course_with_student(:active_all => true)
      @student = @user
      user(:active_all => true)
      user_session(@user)
      get 'grade_summary', :course_id => @course.id, :id => nil
      assert_unauthorized
      get 'grade_summary', :course_id => @course.id, :id => @student.id
      assert_unauthorized
    end

    it "should allow access for a linked observer" do
      course_with_student(:active_all => true)
      @student = @user
      user(:active_all => true)
      user_session(@user)
      @oe = @course.enroll_user(@user, 'ObserverEnrollment')
      @oe.accept
      @oe.update_attribute(:associated_user_id, @student.id)
      @user.reload
      get 'grade_summary', :course_id => @course.id, :id => @student.id
      response.should render_template('grade_summary')
      assigns[:courses_with_grades].should be_nil
    end

    it "should not allow access for a linked student" do
      course_with_student(:active_all => true)
      @student = @user
      user(:active_all => true)
      user_session(@user)
      @se = @course.enroll_student(@user)
      @se.accept
      @se.update_attribute(:associated_user_id, @student.id)
      @user.reload
      get 'grade_summary', :course_id => @course.id, :id => @student.id
      assert_unauthorized
    end

    it "should not allow access for an observer linked in a different course" do
      course_with_student(:active_all => true)
      @course1 = @course
      @student = @user
      course(:active_all => true)
      @course2 = @course

      user(:active_all => true)
      user_session(@user)
      @oe = @course1.enroll_user(@user, 'ObserverEnrollment')
      @oe.accept
      @oe.update_attribute(:associated_user_id, @student.id)

      @user.reload
      get 'grade_summary', :course_id => @course2.id, :id => @student.id
      assert_unauthorized
    end

    it "should allow concluded teachers to see a student grades pages" do
      course_with_teacher_logged_in(:active_all => true)
      @enrollment.conclude
      @student = user_model
      @enrollment = @course.enroll_student(@student)
      @enrollment.accept
      get 'grade_summary', :course_id => @course.id, :id => @student.id
      response.should be_success
      response.should render_template('grade_summary')
      assigns[:courses_with_grades].should be_nil
    end

    it "should allow concluded students to see their grades pages" do
      course_with_student_logged_in(:active_all => true)
      @enrollment.conclude
      get 'grade_summary', :course_id => @course.id, :id => @user.id
      response.should render_template('grade_summary')
    end
    
    it "give a student the option to switch between courses" do
      teacher = user_with_pseudonym(:username => 'teacher@example.com', :active_all => 1)
      student = user_with_pseudonym(:username => 'student@example.com', :active_all => 1)
      course1 = course_with_teacher(:user => teacher, :active_all => 1).course
      student_in_course :user => student, :active_all => 1
      course2 = course_with_teacher(:user => teacher, :active_all => 1).course
      student_in_course :user => student, :active_all => 1
      user_session(student)
      get 'grade_summary', :course_id => @course.id, :id => student.id
      response.should be_success
      assigns[:presenter].courses_with_grades.should_not be_nil
      assigns[:presenter].courses_with_grades.length.should == 2
    end
    
    it "should not give a teacher the option to switch between courses when viewing a student's grades" do
      teacher = user_with_pseudonym(:username => 'teacher@example.com', :active_all => 1)
      student = user_with_pseudonym(:username => 'student@example.com', :active_all => 1)
      course1 = course_with_teacher(:user => teacher, :active_all => 1).course
      student_in_course :user => student, :active_all => 1
      course2 = course_with_teacher(:user => teacher, :active_all => 1).course
      student_in_course :user => student, :active_all => 1
      user_session(teacher)
      get 'grade_summary', :course_id => @course.id, :id => student.id
      response.should be_success
      assigns[:courses_with_grades].should be_nil
    end
    
    it "should not give a linked observer the option to switch between courses when viewing a student's grades" do
      teacher = user_with_pseudonym(:username => 'teacher@example.com', :active_all => 1)
      student = user_with_pseudonym(:username => 'student@example.com', :active_all => 1)
      observer = user_with_pseudonym(:username => 'parent@example.com', :active_all => 1)

      course1 = course_with_teacher(:user => teacher, :active_all => 1).course
      student_in_course :user => student, :active_all => 1
      oe = course1.enroll_user(observer, 'ObserverEnrollment')
      oe.associated_user = student
      oe.save!
      oe.accept

      course2 = course_with_teacher(:user => teacher, :active_all => 1).course
      student_in_course :user => student, :active_all => 1
      oe = course2.enroll_user(observer, 'ObserverEnrollment')
      oe.associated_user = student
      oe.save!
      oe.accept

      user_session(observer)
      get 'grade_summary', :course_id => course1.id, :id => student.id
      response.should be_success
      assigns[:courses_with_grades].should be_nil
    end

    it "should assign values for grade calculator to ENV" do
      course_with_teacher_logged_in(:active_all => true)
      student_in_course(:active_all => true)
      get 'grade_summary', :course_id => @course.id, :id => @student.id
      assigns[:js_env][:submissions].should_not be_nil
      assigns[:js_env][:assignment_groups].should_not be_nil
    end

    it "should not include assignment discussion information in grade calculator ENV data" do
      course_with_teacher_logged_in(:active_all => true)
      student_in_course(:active_all => true)
      assignment1 = @course.assignments.create(:title => "Assignment 1")
      assignment1.submission_types = "discussion_topic"
      assignment1.save!

      get 'grade_summary', :course_id => @course.id, :id => @student.id
      assigns[:js_env][:assignment_groups].first[:assignments].first["discussion_topic"].should be_nil
    end

    it "doesn't leak muted scores" do
      course_with_student_logged_in
      a1, a2 = 2.times.map { |i|
        @course.assignments.create! name: "blah#{i}", points_possible: 10
      }
      a1.mute!
      a1.grade_student(@student, grade: 10)
      a2.grade_student(@student, grade: 5)
      get 'grade_summary', course_id: @course.id, id: @student.id
      expected =
      assigns[:js_env][:submissions].sort_by { |s|
        s['assignment_id']
      }.should == [
        {'score' => nil, 'assignment_id' => a1.id},
        {'score' => 5, 'assignment_id' => a2.id}
      ]
    end

    it "should sort assignments by due date (null last), then title" do
      course_with_teacher_logged_in(:active_all => true)
      student_in_course(:active_all => true)
      assignment1 = @course.assignments.create(:title => "Assignment 1")
      assignment2 = @course.assignments.create(:title => "Assignment 2", :due_at => 3.days.from_now)
      assignment3 = @course.assignments.create(:title => "Assignment 3", :due_at => 2.days.from_now)

      get 'grade_summary', :course_id => @course.id, :id => @student.id
      assigns[:presenter].assignments.select{|a| a.class == Assignment}.map(&:id).should == [assignment3, assignment2, assignment1].map(&:id)
    end

    context "with assignment due date overrides" do
      before :each do
        course_with_teacher(:active_all => true)
        student_in_course(:active_all => true)

        user(:active_all => true)
        @observer = @user
        oe = @course.enroll_user(@observer, 'ObserverEnrollment')
        oe.accept
        oe.update_attribute(:associated_user_id, @student.id)

        @assignment = @course.assignments.create(:title => "Assignment 1")
        @due_at = 4.days.from_now
      end

      def check_grades_page(due_at)
        [@student, @teacher, @observer].each do |u|
          controller.js_env.clear
          user_session(u)
          get 'grade_summary', :course_id => @course.id, :id => @student.id
          assigns[:presenter].assignments.find{|a| a.class == Assignment}.due_at.to_i.should == due_at.to_i
        end
      end

      it "should reflect section overrides" do
        section = @course.default_section
        override = assignment_override_model(:assignment => @assignment)
        override.set = section
        override.override_due_at(@due_at)
        override.save!
        check_grades_page(@due_at)
      end

      it "should show the latest section override in student view" do
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
        assigns[:presenter].assignments.find{|a| a.class == Assignment}.due_at.to_i.should == @due_at.to_i
      end

      it "should reflect group overrides when student is a member" do
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

      it "should not reflect group overrides when student is not a member" do
        @assignment.group_category = group_category
        @assignment.save!
        group = @assignment.group_category.groups.create!(:context => @course)

        override = assignment_override_model(:assignment => @assignment)
        override.set = group
        override.override_due_at(@due_at)
        override.save!
        check_grades_page(nil)
      end

      it "should reflect ad-hoc overrides" do
        override = assignment_override_model(:assignment => @assignment)
        override.override_due_at(@due_at)
        override.save!
        override_student = override.assignment_override_students.build
        override_student.user = @student
        override_student.save!
        check_grades_page(@due_at)
      end

      it "should use the latest override" do
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

    it "should raise an exception on a non-integer :id" do
      course_with_teacher_logged_in(:active_all => true)
      assert_page_not_found do
        get 'grade_summary', :course_id => @course.id, :id => "lqw"
      end
    end
  end

  describe "GET 'show'" do
    describe "gradebook_init_json" do
      it "should include group_category in rendered json for assignments" do
        course_with_teacher_logged_in(:active_all => true)
        group_category1 = @course.group_categories.create(:name => 'Category 1')
        group_category2 = @course.group_categories.create(:name => 'Category 2')
        assignment1 = @course.assignments.create(:title => "Assignment 1", :group_category => group_category1)
        assignment2 = @course.assignments.create(:title => "Assignment 2", :group_category => group_category2)
        get 'show', :course_id => @course.id, :init => 1, :assignments => 1, :format => 'json'
        response.should be_success
        data = json_parse
        data.should_not be_nil
        data.size.should == 4 # 2 assignments + an assignment group + a total
        data.first(2).sort_by{ |a| a['assignment']['title'] }.map{ |a| a['assignment']['group_category'] }.
          should == [assignment1, assignment2].map{ |a| a.group_category.name }
      end

      context "draft state" do
        it "should should not return unpublished assignments" do
          course_with_teacher_logged_in(:active_all => true)
          @course.account.enable_feature!(:draft_state)
          ag = @course.assignment_groups.create! group_weight: 100
          a1 = ag.assignments.create! :submission_types => 'online_upload',
                                      :points_possible  => 10,
                                      :context  => @course
          a2 = ag.assignments.build :title => "unpub assign",
                                    :submission_types => 'online_upload',
                                    :points_possible  => 10,
                                    :context  => @course
          a2.workflow_state = 'unpublished'
          a2.save!

          get 'show', :course_id => @course.id, :init => 1, :assignments => 1, :format => 'json'
          response.should be_success
          data = json_parse
          data.should_not be_nil
          data.size.should == 3 # 1 assignment (no unpublished) + an assignment group + a total
          data.map{|a| a['assignment']['title']}.include?(a2.title).should be_false
        end
      end
    end

    describe "csv" do
      before do
        Course.any_instance.stubs(:feature_enabled?).with(:draft_state).returns(true)
        Course.any_instance.stubs(:feature_enabled?).with(:outcome_gradebook).returns(false)
        course_with_teacher_logged_in(:active_all => true)
        student_in_course(:active_all => true)
        assignment1 = @course.assignments.create(:title => "Assignment 1")
        assignment2 = @course.assignments.create(:title => "Assignment 2")
      end

      shared_examples_for "working download" do
        it "should successfully return data" do
          get 'show', :course_id => @course.id, :init => 1, :assignments => 1, :format => 'csv'
          response.should be_success
          response.body.should match(/\AStudent,/)
        end
        it "should not recompute enrollment grades" do
          Enrollment.expects(:recompute_final_score).never
          get 'show', :course_id => @course.id, :init => 1, :assignments => 1, :format => 'csv'
        end
      end

      context "with teacher that prefers gradebook2" do
        before do
          Course.any_instance.stubs(:feature_enabled?).with(:screenreader_gradebook).returns(true)
          @user.preferences[:gradebook_version] = "2"
        end
        include_examples "working download"
      end

      context "with teacher that prefers screenreader gradebook" do
        before do
          Course.any_instance.stubs(:feature_enabled?).with(:screenreader_gradebook).returns(true)
          @user.preferences[:gradebook_version] = "srgb"
        end
        include_examples "working download"
      end

      context "with teacher that prefers the old gradebook" do
        before do
          Course.any_instance.stubs(:feature_enabled?).with(:screenreader_gradebook).returns(false)
          @user.preferences[:use_gradebook2] = false
        end
        include_examples "working download"
      end
    end

    describe "draft state" do
      it "should properly filter unpublished assignments" do
        course_with_teacher_logged_in(:active_all => true)
        @course.account.enable_feature!(:draft_state)
        assignment1 = @course.assignments.build(:title => "Assignment 1")
        assignment1.unpublish
        assignment2 = @course.assignments.create!(:title => "Assignment 2")

        get 'show', :course_id => @course.id
        assign_ids = assigns[:assignments].map(&:id)
        assign_ids.include?(assignment1.id).should be_false
        assign_ids.include?(assignment2.id).should be_true
        assign_ids.include?("group-#{assignment2.assignment_group.id}").should be_true
        assign_ids.include?("final-grade").should be_true

        ag_assign_ids = assigns[:js_env][:assignment_groups].first['assignments'].map{|a| a['id']}
        ag_assign_ids.include?(assignment1.id).should be_false
        ag_assign_ids.include?(assignment2.id).should be_true
      end
    end

    context "with screenreader_gradebook enabled" do
      before do
        course_with_teacher_logged_in(:active_all => true)
        Course.any_instance.stubs(:feature_enabled?).with(:screenreader_gradebook).returns(true)
        Course.any_instance.stubs(:feature_enabled?).with(:draft_state).returns(true)
        Course.any_instance.stubs(:feature_enabled?).with(:outcome_gradebook).returns(false)
      end

      context "teacher that prefers gradebook2" do
        before do
          @user.preferences[:gradebook_version] = "2"
        end
        it "redirects to gradebook2 with a friendly URL" do
          get "show", :course_id => @course.id
          response.should render_template("gradebook2")
        end
      end

      context "teacher that prefers screenreader gradebook" do
        before do
          @user.preferences[:gradebook_version] = "srgb"
        end
        it "redirects to the screenreader gradebook with a friendly URL" do
          get "show", :course_id => @course.id
          response.should render_template("screenreader")
        end
      end
    end

    context "without gradebook authorization" do
      before do
        course_with_student(:active_all => true)
      end

      context "with screenreader feature flag on" do
        before do
          Course.any_instance.stubs(:feature_enabled?).with(:screenreader_gradebook).returns(true)
        end
        it "renders the unauthorized page" do
          get "show", :course_id => @course.id
          response.should render_template("shared/unauthorized")
        end
      end

      context "with screenreader feature flag off" do
        before do
          Course.any_instance.stubs(:feature_enabled?).with(:screenreader_gradebook).returns(false)
        end
        it "renders the unauthorized page" do
          get "show", :course_id => @course.id
          response.should render_template("shared/unauthorized")
        end
      end
    end
  end

  describe "GET 'change_gradebook_version'" do
    it 'should switch to gradebook2 if clicked and back to gradebook1 if clicked with reset=true' do
      course_with_teacher_logged_in(:active_all => true)
      get 'grade_summary', :course_id => @course.id, :id => nil

      response.should redirect_to(:action => 'gradebook2')

      # reset back to showing the old gradebook
      get 'change_gradebook_version', :course_id => @course.id, :version => 1
      response.should redirect_to(:action => 'show')

      # tell it to use gradebook 2
      get 'change_gradebook_version', :course_id => @course.id, :version => 2
      response.should redirect_to(:action => 'gradebook2')
    end

    context "large roster courses" do
      before do
        course_with_teacher_logged_in(:active_all => true)
        @user.preferences[:use_gradebook2] = false
        @user.save!
        @user.preferred_gradebook_version(@course).should == "1"
        @course.large_roster = true
        @course.save!
        @course.reload
        @course.large_roster?.should == true
      end

      it 'should use gradebook2 always for large_roster courses even if user prefers gradebook 1' do
        get 'grade_summary', :course_id => @course.id, :id => nil
        response.should redirect_to(:action => 'gradebook2')
      end

      it 'should not render gb1 json' do
        get 'show', :course_id => @course.id, :format => :json
        assert_status(404)
      end

      it 'should not prevent you from getting gradebook.csv' do
        get 'show', :course_id => @course.id, :format => 'csv'
        response.should be_success
      end
    end
  end

  describe "POST 'update_submission'" do
    # rails 3 checks that a route exists when calling it
    if CANVAS_RAILS2
      it "should have a route for update_submission" do
        params_from(:post, "/courses/20/gradebook/update_submission").should ==
          {:controller => "gradebooks", :action => "update_submission", :course_id => "20"}
      end
    end

    it "should allow adding comments for submission" do
      course_with_teacher_logged_in(:active_all => true)
      @assignment = @course.assignments.create!(:title => "some assignment")
      @student = @course.enroll_user(User.create!(:name => "some user"))
      post 'update_submission', :course_id => @course.id, :submission => {:comment => "some comment", :assignment_id => @assignment.id, :user_id => @student.user_id}
      response.should be_redirect
      assigns[:assignment].should eql(@assignment)
      assigns[:submissions].should_not be_nil
      assigns[:submissions].length.should eql(1)
      assigns[:submissions][0].submission_comments.should_not be_nil
      assigns[:submissions][0].submission_comments[0].comment.should eql("some comment")
    end

    it "should allow attaching files to comments for submission" do
      course_with_teacher_logged_in(:active_all => true)
      @assignment = @course.assignments.create!(:title => "some assignment")
      @student = @course.enroll_user(User.create!(:name => "some user"))
      data = fixture_file_upload("scribd_docs/doc.doc", "application/msword", true)
      post 'update_submission', :course_id => @course.id, :attachments => {"0" => {:uploaded_data => data}}, :submission => {:comment => "some comment", :assignment_id => @assignment.id, :user_id => @student.user_id}
      response.should be_redirect
      assigns[:assignment].should eql(@assignment)
      assigns[:submissions].should_not be_nil
      assigns[:submissions].length.should eql(1)
      assigns[:submissions][0].submission_comments.should_not be_nil
      assigns[:submissions][0].submission_comments[0].comment.should eql("some comment")
      assigns[:submissions][0].submission_comments[0].attachments.length.should eql(1)
      assigns[:submissions][0].submission_comments[0].attachments[0].display_name.should eql("doc.doc")
    end

    it "should not allow updating submissions for concluded courses" do
      course_with_teacher_logged_in(:active_all => true)
      @enrollment.complete
      @assignment = @course.assignments.create!(:title => "some assignment")
      @student = @course.enroll_user(User.create!(:name => "some user"))
      post 'update_submission', :course_id => @course.id, :submission => {:comment => "some comment", :assignment_id => @assignment.id, :user_id => @student.user_id}
      assert_unauthorized
    end

    it "should not allow updating submissions in other sections when limited" do
      course_with_teacher_logged_in(:active_all => true)
      @enrollment.update_attribute(:limit_privileges_to_course_section, true)
      s1 = submission_model(:course => @course)
      s2 = submission_model(:course => @course, :username => 'otherstudent@example.com', :section => @course.course_sections.create(:name => "another section"), :assignment => @assignment)

      post 'update_submission', :course_id => @course.id, :submission => {:comment => "some comment", :assignment_id => @assignment.id, :user_id => s1.user_id}
      response.should be_redirect

      # attempt to grade another section should throw not found
      post 'update_submission', :course_id => @course.id, :submission => {:comment => "some comment", :assignment_id => @assignment.id, :user_id => s2.user_id}
      flash[:error].should eql 'Submission was unsuccessful: Submission Failed'
    end
  end

  describe "GET 'speed_grader'" do
    # rails 3 checks that a route exists when calling it
    if CANVAS_RAILS2
      it "should have a route for speed_grader" do
        params_from(:get, "/courses/20/gradebook/speed_grader").should ==
          {:controller => "gradebooks", :action => "speed_grader", :course_id => "20"}
      end
    end

    it "should redirect user if course's large_roster? setting is true" do
      course_with_teacher_logged_in(:active_all => true)
      assignment = @course.assignments.create!(:title => 'some assignment')

      Course.any_instance.stubs(:large_roster?).returns(true)

      get 'speed_grader', :course_id => @course.id, :assignment_id => assignment.id
      response.should be_redirect
      flash[:notice].should == 'SpeedGrader is disabled for this course'
    end

    context "draft state" do

      before do
        course_with_teacher_logged_in(active_all: true)
        @assign = @course.assignments.create!(title: 'Totally')
        @assign.unpublish
      end

      it "redirects if draft state is enabled and the assignment is unpublished" do

        # Unpublished assignment and draft state enabled
        @course.account.enable_feature!(:draft_state)

        get 'speed_grader', course_id: @course, assignment_id: @assign.id
        response.should be_redirect
        flash[:notice].should == I18n.t(
          :speedgrader_enabled_only_for_published_content,
                           'Speedgrader is enabled only for published content.')

        # Published assignment and draft state enabled
        @assign.publish
        get 'speed_grader', course_id: @course, assignment_id: @assign.id
        response.should_not be_redirect
      end

      it "does not redirect if draft state isn't enabled" do
        get 'speed_grader', course_id: @course, assignment_id: @assign.id
        response.should_not be_redirect
      end

    end
  end

  describe "POST 'speed_grader_settings'" do
    it "lets you set your :enable_speedgrader_grade_by_question preference" do
      course_with_teacher_logged_in(:active_all => true)
      @teacher.preferences[:enable_speedgrader_grade_by_question].should_not be_true

      post 'speed_grader_settings', course_id: @course.id,
        enable_speedgrader_grade_by_question: "1"
      @teacher.reload.preferences[:enable_speedgrader_grade_by_question].should be_true

      post 'speed_grader_settings', course_id: @course.id,
        enable_speedgrader_grade_by_question: "0"
      @teacher.reload.preferences[:enable_speedgrader_grade_by_question].should_not be_true
    end
  end

  describe '#light_weight_ags_json' do
    it 'should return the necessary JSON for GradeCalculator' do
      course_with_student
      ag = @course.assignment_groups.create! group_weight: 100
      a  = ag.assignments.create! :submission_types => 'online_upload',
                                  :points_possible  => 10,
                                  :context  => @course
      AssignmentGroup.add_never_drop_assignment(ag, a)
      @controller.instance_variable_set(:@context, @course)
      @controller.light_weight_ags_json([ag]).should == [
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
              id: a.id,
              points_possible: 10,
              submission_types: ['online_upload'],
            }
          ],
        },
      ]
    end

    context 'draft state' do
      it 'should not return unpublished assignments' do
        course_with_teacher(:active_all => true)
        @course.account.enable_feature!(:draft_state)
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
      @controller.light_weight_ags_json([ag]).should == [
        {
          id: ag.id,
          rules: {},
          group_weight: 100,
          assignments: [
            {
              id: a1.id,
              points_possible: 10,
              submission_types: ['online_upload'],
            }
          ],
        },
      ]
      end
    end
  end
end
