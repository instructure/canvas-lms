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

describe QuizzesController do
  def course_quiz(active=false)
    @quiz = @course.quizzes.create
    @quiz.workflow_state = "available" if active
    @quiz.save!
    @quiz
  end

  def quiz_question
    @quiz.quiz_questions.create
  end

  def quiz_group
    @quiz.quiz_groups.create
  end

  describe "GET 'index'" do
    it "should require authorization" do
      course_with_teacher(:active_all => true)
      get 'index', :course_id => @course.id
      assert_unauthorized
    end

    it "should redirect 'disabled', if disabled by the teacher" do
      course_with_student_logged_in(:active_all => true)
      @course.update_attribute(:tab_configuration, [{'id'=>4,'hidden'=>true}])
      get 'index', :course_id => @course.id
      response.should be_redirect
      flash[:notice].should match(/That page has been disabled/)
    end

    it "should assign variables" do
      course_with_teacher_logged_in(:active_all => true)
      get 'index', :course_id => @course.id
      assigns[:quizzes].should_not be_nil
      assigns[:unpublished_quizzes].should_not be_nil
      assigns[:submissions_hash].should_not be_nil
    end

    it "should retrieve quizzes" do
      course_with_teacher_logged_in(:active_all => true)
      course_quiz(!!:active)

      get 'index', :course_id => @course.id
      assigns[:quizzes].should_not be_nil
      assigns[:quizzes].should_not be_empty
      assigns[:quizzes][0].should eql(@quiz)
    end
  end

  describe "GET 'new'" do
    it "should require authorization" do
      course_with_teacher(:active_all => true)
      get 'new', :course_id => @course.id
      assert_unauthorized
    end

    it "should assign variables" do
      course_with_teacher_logged_in(:active_all => true)
      get 'new', :course_id => @course.id
      assigns[:quiz].should_not be_nil
      q = assigns[:quiz]
    end

    it "subsequent requests should return the same quiz unless ?fresh=1" do
      course_with_teacher_logged_in(:active_all => true)
      get 'new', :course_id => @course.id
      assigns[:quiz].should_not be_nil
      q = assigns[:quiz]

      get 'new', :course_id => @course.id
      assigns[:quiz].should_not be_nil
      assigns[:quiz].should_not eql(q)

      get 'new', :course_id => @course.id, :fresh => 1
      # Quiz.find_by_id(q.id).should be_deleted
      assigns[:quiz].should_not be_nil
      assigns[:quiz].should_not eql(q)
    end
  end

  describe "GET 'edit'" do
    it "should require authorization" do
      course_with_teacher(:active_all => true)
      course_quiz
      get 'edit', :course_id => @course.id, :id => @quiz.id
      assert_unauthorized
      assigns[:quiz].should_not be_nil
    end

    it "should assign variables" do
      course_with_teacher_logged_in(:active_all => true)
      course_quiz
      get 'edit', :course_id => @course.id, :id => @quiz.id
      assigns[:quiz].should_not be_nil
      assigns[:quiz].should eql(@quiz)
      response.should render_template("new")
    end
  end

  describe "GET 'show'" do
    it "should require authorization" do
      course_with_teacher(:active_all => true)
      course_quiz
      get 'show', :course_id => @course.id, :id => @quiz.id
      assert_unauthorized
      assigns[:quiz].should_not be_nil
      assigns[:quiz].should eql(@quiz)
    end

    it "should assign variables" do
      course_with_teacher_logged_in(:active_all => true)
      course_quiz
      get 'show', :course_id => @course.id, :id => @quiz.id
      assigns[:quiz].should_not be_nil
      assigns[:quiz].should eql(@quiz)
      assigns[:question_count].should eql(@quiz.question_count)
      assigns[:just_graded].should eql(false)
      assigns[:stored_params].should_not be_nil
    end

    it "should set the submission count variables" do
      course(:active_all => 1)
      @section = @course.course_sections.create!(:name => 'section 2')
      @user2 = user_with_pseudonym(:active_all => true, :name => 'Student2', :username => 'student2@instructure.com')
      @section.enroll_user(@user2, 'StudentEnrollment', 'active')
      @user1 = user_with_pseudonym(:active_all => true, :name => 'Student1', :username => 'student1@instructure.com')
      @course.enroll_student(@user1)
      @ta1 = user_with_pseudonym(:active_all => true, :name => 'TA1', :username => 'ta1@instructure.com')
      @course.enroll_ta(@ta1).update_attribute(:limit_privileges_to_course_section, true)
      course_quiz
      @sub1 = @quiz.generate_submission(@user1)
      @sub2 = @quiz.generate_submission(@user2)
      @sub2.start_grading
      @sub2.update_attribute(:workflow_state, 'pending_review')

      user_session @teacher
      get 'show', :course_id => @course.id, :id => @quiz.id
      assigns[:submitted_student_count].should == 2
      assigns[:any_submissions_pending_review].should == true

      controller.js_env.clear

      user_session @ta1
      get 'show', :course_id => @course.id, :id => @quiz.id
      assigns[:submitted_student_count].should == 1
      assigns[:any_submissions_pending_review].should == false
    end

    it "should allow forcing authentication on public quiz pages" do
      course_with_student :active_all => 1
      @course.update_attribute :is_public, true
      course_quiz !!:active
      get 'show', :course_id => @course.id, :id => @quiz.id, :force_user => 1
      response.should be_redirect
      response.location.should match /login/
    end

    it "should set session[headless_quiz] if persist_headless param is sent" do
      course_with_student_logged_in :active_all => 1
      course_quiz !!:active
      get 'show', :course_id => @course.id, :id => @quiz.id, :persist_headless => 1
      controller.session[:headless_quiz].should be_true
      assigns[:headers].should be_false
    end

    it "should not render headers if session[:headless_quiz] is set" do
      course_with_student_logged_in :active_all => 1
      course_quiz !!:active
      controller.session[:headless_quiz] = true
      get 'show', :course_id => @course.id, :id => @quiz.id
      assigns[:headers].should be_false
    end
  end

  describe "GET 'managed_quiz_data'" do
    it "should respect section privilege limitations" do
      course(:active_all => 1)
      @section = @course.course_sections.create!(:name => 'section 2')
      @user2 = user_with_pseudonym(:active_all => true, :name => 'Student2', :username => 'student2@instructure.com')
      @section.enroll_user(@user2, 'StudentEnrollment', 'active')
      @user1 = user_with_pseudonym(:active_all => true, :name => 'Student1', :username => 'student1@instructure.com')
      @course.enroll_student(@user1)
      @ta1 = user_with_pseudonym(:active_all => true, :name => 'TA1', :username => 'ta1@instructure.com')
      @course.enroll_ta(@ta1).update_attribute(:limit_privileges_to_course_section, true)
      course_quiz
      @sub1 = @quiz.generate_submission(@user1)
      @sub2 = @quiz.generate_submission(@user2)

      user_session @teacher
      get 'managed_quiz_data', :course_id => @course.id, :quiz_id => @quiz.id
      assigns[:submissions][@sub1.user_id].should == @sub1
      assigns[:submissions][@sub2.user_id].should == @sub2
      assigns[:submitted_students].sort_by(&:id).should == [@user1, @user2].sort_by(&:id)

      user_session @ta1
      get 'managed_quiz_data', :course_id => @course.id, :quiz_id => @quiz.id
      assigns[:submissions][@sub1.user_id].should == @sub1
      assigns[:submitted_students].should == [@user1]
    end
  end

  describe "GET 'moderate'" do
    it "should require authorization" do
      course_with_teacher(:active_all => true)
      course_quiz
      get 'moderate', :course_id => @course.id, :quiz_id => @quiz.id
      assert_unauthorized
    end

    it "should assign variables" do
      @student = course_with_student(:active_all => true).user
      course_with_teacher_logged_in(:course => @course, :active_all => true)
      course_quiz
      @sub = @quiz.generate_submission(@student)
      get 'moderate', :course_id => @course.id, :quiz_id => @quiz.id
      assigns[:quiz].should == @quiz
      assigns[:students].should == [@student]
      assigns[:submissions].should == [@sub]
    end

    it "should respect section privilege limitations" do
      course_with_teacher(:active_all => 1)
      @section = @course.course_sections.create!(:name => 'section 2')
      @user2 = user_with_pseudonym(:active_all => true, :name => 'Student2', :username => 'student2@instructure.com')
      @section.enroll_user(@user2, 'StudentEnrollment', 'active')
      @user1 = user_with_pseudonym(:active_all => true, :name => 'Student1', :username => 'student1@instructure.com')
      @course.enroll_student(@user1)
      @ta1 = user_with_pseudonym(:active_all => true, :name => 'TA1', :username => 'ta1@instructure.com')
      @course.enroll_ta(@ta1).update_attribute(:limit_privileges_to_course_section, true)
      course_quiz
      @sub1 = @quiz.generate_submission(@user1)
      @sub2 = @quiz.generate_submission(@user2)

      user_session @teacher
      get 'moderate', :course_id => @course.id, :quiz_id => @quiz.id
      assigns[:students].sort_by(&:id).should == [@user1, @user2].sort_by(&:id)
      assigns[:submissions].sort_by(&:id).should == [@sub1, @sub2].sort_by(&:id)

      user_session @ta1
      get 'moderate', :course_id => @course.id, :quiz_id => @quiz.id
      assigns[:students].should == [@user1]
      assigns[:submissions].should == [@sub1]
    end
  end

  describe "POST 'reorder'" do
    it "should require authorization" do
      course_with_teacher(:active_all => true)
      course_quiz
      post 'reorder', :course_id => @course.id, :quiz_id => @quiz.id, :order => ""
      assert_unauthorized
    end

    it "should require authorization" do
      course_with_student_logged_in(:active_all => true)
      course_quiz
      post 'reorder', :course_id => @course.id, :quiz_id => @quiz.id, :order => ""
      assert_unauthorized
    end

    it "should reorder questions" do
      course_with_teacher_logged_in(:active_all => true)
      course_quiz
      q1 = quiz_question
      q2 = quiz_question
      q3 = quiz_question
      q1.position.should eql(1)
      q2.position.should eql(2)
      q3.position.should eql(3)
      post 'reorder', :course_id => @course.id, :quiz_id => @quiz.id, :order => "question_#{q3.id},question_#{q1.id},question_#{q2.id}"
      assigns[:quiz].should eql(@quiz)
      q1.reload
      q2.reload
      q3.reload
      q1.position.should eql(2)
      q2.position.should eql(3)
      q3.position.should eql(1)
      response.should be_success
    end

    it "should reorder questions AND groups" do
      course_with_teacher_logged_in(:active_all => true)
      course_quiz
      q1 = quiz_question
      q1.save!
      q2 = quiz_question
      g3 = quiz_group
      q1.position.should eql(1)
      q2.position.should eql(2)
      g3.position.should eql(3)
      post 'reorder', :course_id => @course.id, :quiz_id => @quiz.id, :order => "group_#{g3.id},question_#{q1.id},question_#{q2.id}"
      assigns[:quiz].should eql(@quiz)
      q1.reload
      q2.reload
      g3.reload
      q1.position.should eql(2)
      q1.quiz_group_id.should be_nil
      q2.position.should eql(3)
      g3.position.should eql(1)
      response.should be_success
    end
  end

  describe "POST 'take'" do
    it "should require authorization" do
      course_with_student(:active_all => true)
      course_quiz(true)
      post 'show', :course_id => @course, :quiz_id => @quiz.id, :take => '1'
      assert_unauthorized
    end

    it "should allow taking the quiz" do
      course_with_student_logged_in(:active_all => true)
      course_quiz(true)
      post 'show', :course_id => @course, :quiz_id => @quiz.id, :take => '1'
      response.should redirect_to("/courses/#{@course.id}/quizzes/#{@quiz.id}/take")
    end

    context 'verification' do
      before do
        course_with_student_logged_in(:active_all => true)
        course_quiz(true)
        @quiz.access_code = 'bacon'
        @quiz.save!
      end

      it "should render verification page if password required" do
        post 'show', :course_id => @course, :quiz_id => @quiz.id, :take => '1'
        response.should render_template('access_code')
      end

      it "shouldn't let you in on a bad access code" do
        post 'show', :course_id => @course, :quiz_id => @quiz.id, :take => '1', :access_code => 'wrongpass'
        response.should_not be_redirect
        response.should render_template('access_code')
      end

      it "should send you to take with the right access code" do
        post 'show', :course_id => @course, :quiz_id => @quiz.id, :take => '1', :access_code => 'bacon'
        response.should redirect_to("/courses/#{@course.id}/quizzes/#{@quiz.id}/take")
      end


      it "should not ask for the access code again if you reload the quiz" do
        get 'show', :course_id => @course, :quiz_id => @quiz.id, :take => '1', :access_code => 'bacon'
        response.should_not be_redirect
        response.should_not render_template('access_code')

        controller.js_env.clear

        get 'show', :course_id => @course, :quiz_id => @quiz.id, :take => '1'
        response.should_not render_template('access_code')
      end
    end

    it "should not let them take the quiz if it's locked" do
      course_with_student_logged_in(:active_all => true)
      course_quiz(true)
      @quiz.locked = true
      @quiz.save!
      post 'show', :course_id => @course, :quiz_id => @quiz.id, :take => '1'
      response.should render_template('show')
      assigns[:locked].should_not be_nil
    end

    it "should let them take the quiz if it's locked but unlocked by an override" do
      course_with_student_logged_in(:active_all => true)
      course_quiz(true)
      @quiz.lock_at = Time.now
      @quiz.save!
      override = AssignmentOverride.new
      override.title = "ADHOC quiz override"
      override.quiz = @quiz
      override.lock_at = Time.now + 1.day
      override.lock_at_overridden = true
      override.save!
      override_student = override.assignment_override_students.build
      override_student.user = @user
      override_student.save!
      post 'show', :course_id => @course, :quiz_id => @quiz.id, :take => '1'
      response.should redirect_to("/courses/#{@course.id}/quizzes/#{@quiz.id}/take")
    end

    it "should let them take the quiz if it's locked but they've been explicitly unlocked" do
      course_with_student_logged_in(:active_all => true)
      course_quiz(true)
      @quiz.locked = true
      @quiz.save!
      @sub = @quiz.find_or_create_submission(@user, nil, 'settings_only')
      @sub.manually_unlocked = true
      @sub.save!
      post 'show', :course_id => @course, :quiz_id => @quiz.id, :take => '1'
      response.should redirect_to("/courses/#{@course.id}/quizzes/#{@quiz.id}/take")
    end

    it "should use default duration if no extensions specified" do
      course_with_student_logged_in(:active_all => true)
      course_quiz(true)
      @quiz.time_limit = 60
      @quiz.save!
      post 'show', :course_id => @course, :quiz_id => @quiz.id, :take => '1'
      response.should redirect_to("/courses/#{@course.id}/quizzes/#{@quiz.id}/take")
      assigns[:submission].should_not be_nil
      assigns[:submission].user.should eql(@user)
      (assigns[:submission].end_at - assigns[:submission].started_at).to_i.should eql(60.minutes.to_i)
    end

    it "should give user more time if specified" do
      course_with_student_logged_in(:active_all => true)
      course_quiz(true)
      @quiz.time_limit = 60
      @quiz.save!
      @sub = @quiz.find_or_create_submission(@user, nil, 'settings_only')
      @sub.extra_time = 30
      @sub.save!
      post 'show', :course_id => @course, :quiz_id => @quiz.id, :take => '1'
      response.should redirect_to("/courses/#{@course.id}/quizzes/#{@quiz.id}/take")
      assigns[:submission].should_not be_nil
      assigns[:submission].user.should eql(@user)
      (assigns[:submission].end_at - assigns[:submission].started_at).to_i.should eql(90.minutes.to_i)
    end

    it "should render ip_filter page if ip_filter doesn't match" do
      course_with_student_logged_in(:active_all => true)
      course_quiz(true)
      @quiz.ip_filter = '123.123.123.123'
      @quiz.save!
      post 'show', :course_id => @course, :quiz_id => @quiz.id, :take => '1'
      response.should render_template('invalid_ip')
    end

    it "should let the user take the quiz if the ip_filter matches" do
      course_with_student_logged_in(:active_all => true)
      course_quiz(true)
      @quiz.ip_filter = '123.123.123.123'
      @quiz.save!
      request.env['REMOTE_ADDR'] = '123.123.123.123'
      post 'show', :course_id => @course, :quiz_id => @quiz.id, :take => '1'
      response.should redirect_to("/courses/#{@course.id}/quizzes/#{@quiz.id}/take")
    end

    it "should work without a user for non-graded quizzes in public courses" do
      course_with_student :active_all => true
      @course.update_attribute :is_public, true
      course_quiz :active
      @quiz.update_attribute :quiz_type, 'practice_quiz'
      post 'show', :course_id => @course, :quiz_id => @quiz.id, :take => '1'
      response.should redirect_to("/courses/#{@course.id}/quizzes/#{@quiz.id}/take")
    end
  end

  describe "GET 'take'" do
    it "should require authorization" do
      course_with_student(:active_all => true)
      course_quiz(true)
      get 'show', :course_id => @course, :quiz_id => @quiz.id, :take => '1'
      assert_unauthorized
    end

    it "should render the quiz page if the user hasn't started the quiz" do
      course_with_student_logged_in(:active_all => true)
      course_quiz(true)
      get 'show', :course_id => @course, :quiz_id => @quiz.id, :take => '1'
      response.should render_template('show')
    end

    it "should render ip_filter page if the ip_filter stops matching" do
      course_with_student_logged_in(:active_all => true)
      course_quiz(true)
      @quiz.ip_filter = '123.123.123.123'
      @quiz.save!
      @quiz.generate_submission(@user)

      get 'show', :course_id => @course, :quiz_id => @quiz.id, :take => '1'
      response.should render_template('invalid_ip')
    end

    it "should allow taking the quiz" do
      course_with_student_logged_in(:active_all => true)
      course_quiz(true)
      @quiz.generate_submission(@user)

      get 'show', :course_id => @course, :quiz_id => @quiz.id, :take => '1'
      response.should render_template('take_quiz')
      assigns[:submission].should_not be_nil
      assigns[:submission].user.should eql(@user)
    end

    context "when the ID of a question is passed in" do
      before do
        course_with_student_logged_in(:active_all => true)
        course_quiz(true)
        @quiz.generate_submission(@user)
      end
      
      context "a valid question" do
        it "renders take_quiz" do
          QuizzesController.any_instance.stubs(:valid_question?).returns(true)
          get 'show', :course_id => @course, :quiz_id => @quiz.id, :question_id => '1', :take => '1'
          response.should render_template('take_quiz')
        end
      end

      context "a question not in this quiz" do
        it "redirects to the main quiz page" do
          QuizzesController.any_instance.stubs(:valid_question?).returns(false)
          get 'show', :course_id => @course, :quiz_id => @quiz.id, :question_id => '1', :take => '1'
          response.should redirect_to course_quiz_url(@course, @quiz)
        end
      end
    end

    describe "valid_question?" do
      let(:submission) { mock }

      context "when the passed in question ID is in the submission" do
        it "returns true" do
          submission.stubs(:has_question?).with(1).returns(true)
          controller.send(:valid_question?, submission, 1).should be_true
        end
      end

      context "when the question ID isn't part of the submission" do
        it "returns false" do
          submission.stubs(:has_question?).with(1).returns(false)
          controller.send(:valid_question?, submission, 1).should be_false
        end
      end
    end
  end

  describe "GET 'history'" do
    it "should require authorization" do
      course_with_teacher(:active_all => true)
      course_quiz
      get 'history', :course_id => @course.id, :quiz_id => @quiz.id
      assert_unauthorized
    end

    it "should redirect if there are no submissions for the user" do
      course_with_student_logged_in(:active_all => true)
      course_quiz
      get 'history', :course_id => @course.id, :quiz_id => @quiz.id
      response.should be_redirect
      response.should redirect_to("/courses/#{@course.id}/quizzes/#{@quiz.id}")
    end

    it "should assign variables" do
      course_with_student_logged_in(:active_all => true)
      course_quiz
      @submission = @quiz.generate_submission(@user)
      get 'history', :course_id => @course.id, :quiz_id => @quiz.id

      response.should be_success
      assigns[:user].should_not be_nil
      assigns[:user].should eql(@user)
      assigns[:quiz].should_not be_nil
      assigns[:quiz].should eql(@quiz)
      assigns[:submission].should_not be_nil
      assigns[:submission].should eql(@submission)
    end

    it "should find the observed submissions" do
      course_with_student(:active_all => true)
      course_quiz
      @submission = @quiz.generate_submission(@student)
      @observer = user
      @enrollment = @course.enroll_user(@observer, 'ObserverEnrollment', :enrollment_state => 'active')
      @enrollment.update_attribute(:associated_user, @student)
      user_session(@observer)
      get 'history', :course_id => @course.id, :quiz_id => @quiz.id, :user_id => @student.id

      response.should be_success
      assigns[:user].should_not be_nil
      assigns[:user].should eql(@student)
      assigns[:quiz].should_not be_nil
      assigns[:quiz].should eql(@quiz)
      assigns[:submission].should_not be_nil
      assigns[:submission].should eql(@submission)
    end

    it "should not allow viewing other submissions if not a teacher" do
      u = user(:active_all => true)
      course_with_student_logged_in(:active_all => true)
      course_quiz
      s = @quiz.generate_submission(u)
      @submission = @quiz.generate_submission(@user)
      get 'history', :course_id => @course.id, :quiz_id => @quiz.id, :user_id => u.id
      response.should_not be_success
    end

    it "should allow viewing other submissions if a teacher" do
      u = user(:active_all => true)
      course_with_teacher_logged_in(:active_all => true)
      @course.enroll_student(u)
      course_quiz
      s = @quiz.generate_submission(u)
      @submission = @quiz.generate_submission(@user)
      get 'history', :course_id => @course.id, :quiz_id => @quiz.id, :user_id => u.id

      response.should be_success
      assigns[:user].should_not be_nil
      assigns[:user].should eql(u)
      assigns[:quiz].should_not be_nil
      assigns[:quiz].should eql(@quiz)
      assigns[:submission].should_not be_nil
      assigns[:submission].should eql(s)
    end

    it "should not allow student viewing if the assignment is muted" do
      u = user(:active_all => true)
      course_with_student_logged_in(:active_all => true)
      course_quiz
      @quiz.generate_quiz_data
      @quiz.workflow_state = 'available'
      @quiz.published_at = Time.now
      @quiz.save
      
      @quiz.assignment.should_not be_nil
      @quiz.assignment.mute!
      s = @quiz.generate_submission(u)
      @submission = @quiz.generate_submission(@user)
      get 'history', :course_id => @course.id, :quiz_id => @quiz.id, :user_id => u.id

      response.should be_redirect
      response.should redirect_to("/courses/#{@course.id}/quizzes/#{@quiz.id}")
      flash[:notice].should match(/You cannot view the quiz history while the quiz is muted/)
    end

    it "should allow teacher viewing if the assignment is muted" do
      u = user(:active_all => true)
      course_with_teacher_logged_in(:active_all => true)
      @course.enroll_student(u)

      course_quiz
      @quiz.generate_quiz_data
      @quiz.workflow_state = 'available'
      @quiz.published_at = Time.now
      @quiz.save

      @quiz.assignment.should_not be_nil
      @quiz.assignment.mute!
      s = @quiz.generate_submission(u)
      @submission = @quiz.generate_submission(@user)
      get 'history', :course_id => @course.id, :quiz_id => @quiz.id, :user_id => u.id

      response.should be_success
    end
  end

  describe "POST 'create'" do
    it "should require authorization" do
      course_with_teacher(:active_all => true)
      post 'create', :course_id => @course.id
      assert_unauthorized
    end

    it "should not allow students to create quizzes" do
      course_with_student_logged_in(:active_all => true)
      post 'create', :course_id => @course.id, :quiz => {:title => "some quiz"}
      assert_unauthorized
    end

    it "should create quiz" do
      course_with_teacher_logged_in(:active_all => true)
      post 'create', :course_id => @course.id, :quiz => {:title => "some quiz"}
      assigns[:quiz].should_not be_nil
      assigns[:quiz].title.should eql("some quiz")
      response.should be_success
    end

    it "creates quizzes with overrides" do
      course_with_teacher_logged_in(:active_all => true)
      section = @course.course_sections.create!
      course_due_date = 3.days.from_now.iso8601
      section_due_date = 5.days.from_now.iso8601
      post 'create', :course_id => @course.id,
        :quiz => {
          :title => "overridden quiz",
          :due_at => course_due_date,
          :assignment_overrides => [{
            :course_section_id => section.id,
            :due_at => section_due_date,
          }]
        }
      response.should be_success
      quiz = assigns[:quiz].overridden_for(@user)
      overrides = quiz.overrides_visible_to(@user)
      overrides.length.should == 1
      overrides.first[:due_at].iso8601.should == section_due_date
    end
  end

  describe "PUT 'update'" do
    it "should require authorization" do
      course_with_teacher(:active_all => true)
      course_quiz
      put 'update', :course_id => @course.id, :id => @quiz.id, :quiz => {:title => "test"}
      assert_unauthorized
    end

    it "should not allow students to update quizzes" do
      course_with_student_logged_in(:active_all => true)
      course_quiz
      post 'update', :course_id => @course.id, :id => @quiz.id, :quiz => {:title => "some quiz"}
      assert_unauthorized
    end

    it "should update quizzes" do
      course_with_teacher_logged_in(:active_all => true)
      course_quiz
      post 'update', :course_id => @course.id, :id => @quiz.id, :quiz => {:title => "some quiz"}
      assigns[:quiz].should_not be_nil
      assigns[:quiz].should eql(@quiz)
      assigns[:quiz].title.should eql("some quiz")
    end

    it "should lock and unlock without removing assignment" do
      course_with_teacher_logged_in(:active_all => true)
      a = @course.assignments.create!(:title => "some assignment", :points_possible => 5)
      a.points_possible.should eql(5.0)
      a.submission_types.should_not eql("online_quiz")
      @quiz = @course.quizzes.build(:assignment_id => a.id, :title => "some quiz", :points_possible => 10)
      @quiz.workflow_state = 'available'
      @quiz.save
      post 'update', :course_id => @course.id, :id => @quiz.id, :quiz => {"locked" => "true"}
      @quiz.reload
      @quiz.assignment.should_not be_nil
      post 'update', :course_id => @course.id, :id => @quiz.id, :quiz => {"locked" => "false"}
      @quiz.reload
      @quiz.assignment.should_not be_nil
    end

    it "updates overrides for a quiz" do
      course_with_teacher_logged_in(:active_all => true)
      quiz = @course.quizzes.build( :title => "Update Overrides Quiz")
      quiz.save!
      section = @course.course_sections.build
      section.save!
      course_due_date = 3.days.from_now.iso8601
      section_due_date = 5.days.from_now.iso8601
      quiz.save!
      post 'update', :course_id => @course.id,
        :id => quiz.id,
        :quiz => {
          :title => "overridden quiz",
          :due_at => course_due_date,
          :assignment_overrides => [{
            :course_section_id => section.id,
            :due_at => section_due_date,
            :due_at_overridden => true
          }]
        }
      quiz = quiz.reload.overridden_for(@user)
      overrides = quiz.overrides_visible_to(@user)
      overrides.length.should == 1
    end

    it "deletes overrides for a quiz if assignment_overrides params is 'false'" do
      course_with_teacher_logged_in(:active_all => true)
      quiz = @course.quizzes.build(:title => "Delete overrides!")
      quiz.save!
      section = @course.course_sections.create!(:name => "VDD Course Section")
      override = AssignmentOverride.new
      override.set_type = 'CourseSection'
      override.set = section
      override.due_at = Time.zone.now
      override.quiz = quiz
      override.save!
      course_due_date = 3.days.from_now.iso8601
      post 'update', :course_id => @course.id,
        :id => quiz.id,
        :quiz => {
          :title => "overridden quiz",
          :due_at => course_due_date,
          :assignment_overrides => "false"
        }
      quiz.reload.assignment_overrides.active.should be_empty
    end

    it 'updates the quiz with the correct times for fancy midnight' do
      time = Time.local(2013,3,13,0,0).in_time_zone
      course_with_teacher_logged_in(:active_all => true)
      quiz = @course.quizzes.build(:title => "Test that fancy midnight, baby!")
      quiz.save!
      post :update, :course_id => @course.id,
        :id => quiz.id,
        :quiz => {
          :due_at => time,
          :lock_at => time,
          :unlock_at => time
        }
      quiz.reload
      quiz.due_at.to_i.should == CanvasTime.fancy_midnight(time).to_i
      quiz.lock_at.to_i.should == CanvasTime.fancy_midnight(time).to_i
      quiz.unlock_at.to_i.should == time.to_i
    end

    context 'notifications' do
      before do
        @notification = Notification.create(:name => 'Assignment Due Date Changed')

        course_with_teacher_logged_in(:active_all => true)
        @section = @course.course_sections.create!

        student_in_course(:active_all => true)
        @student.communication_channels.create(:path => "student@instructure.com").confirm!
        @student.email_channel.notification_policies.
          find_or_create_by_notification_id(@notification.id).
          update_attribute(:frequency, 'immediately')

        course_quiz
        @quiz.generate_quiz_data
        @quiz.workflow_state = 'available'
        @quiz.published_at = Time.now
        @quiz.save!

        @quiz.update_attribute(:created_at, 1.day.ago)
        @quiz.assignment.update_attribute(:created_at, 1.day.ago)

      end

      it "should send due date changed if notify_of_update is set" do
        course_due_date = 2.days.from_now
        section_due_date = 3.days.from_now
        post 'update', :course_id => @course.id,
          :id => @quiz.id,
          :quiz => {
            :title => "overridden quiz",
            :due_at => course_due_date.iso8601,
            :assignment_overrides => [{
              :course_section_id => @section.id,
              :due_at => section_due_date.iso8601,
              :due_at_overridden => true
            }],
            :notify_of_update => true
          }

        @student.messages.detect{|m| m.notification_id == @notification.id}.should_not be_nil
      end

      it "should send due date changed if notify_of_update is not set" do
        course_due_date = 2.days.from_now
        section_due_date = 3.days.from_now
        post 'update', :course_id => @course.id,
          :id => @quiz.id,
          :quiz => {
            :title => "overridden quiz",
            :due_at => course_due_date.iso8601,
            :assignment_overrides => [{
              :course_section_id => @section.id,
              :due_at => section_due_date.iso8601,
              :due_at_overridden => true
            }]
          }

        @student.messages.detect{ |m| m.notification_id == @notification.id }.should_not be_nil
      end
    end
  end

  describe "GET 'statistics'" do
    it "should allow concluded teachers to see a quiz's statistics" do
      course_with_teacher_logged_in(:active_all => true)
      course_quiz
      get 'statistics', :course_id => @course.id, :quiz_id => @quiz.id
      response.should be_success
      response.should render_template('statistics')

      @enrollment.conclude
      get 'statistics', :course_id => @course.id, :quiz_id => @quiz.id
      response.should be_success
      response.should render_template('statistics')
    end

    it "should redirect to the quiz show page if the course is a MOOC" do
      course_with_teacher_logged_in(:active_all => true)
      @course.large_roster = true
      @course.save!
      course_quiz
      get 'statistics', :course_id => @course.id, :quiz_id => @quiz.id
      flash[:notice].should == "That page has been disabled for this course"
      response.should redirect_to course_quiz_url(@course.id, @quiz.id)
    end
  end

  describe "GET 'statistics.csv'" do
    it "redirects to the attachment url" do
      course_with_teacher_logged_in
      course_quiz
      get 'statistics', :course_id => @course.id, :quiz_id => @quiz.id,
        :format => 'csv'
      @quiz.quiz_statistics.size.should == 1
      stats = @quiz.quiz_statistics.first
      response.should redirect_to stats.csv_attachment.cacheable_s3_download_url
    end
  end

  describe "GET 'read_only'" do
    it "should allow concluded teachers to see a read-only view of a quiz" do
      course_with_teacher_logged_in(:active_all => true)
      course_quiz
      get 'read_only', :course_id => @course.id, :quiz_id => @quiz.id
      response.should be_success
      response.should render_template('read_only')

      @enrollment.conclude
      get 'read_only', :course_id => @course.id, :quiz_id => @quiz.id
      response.should be_success
      response.should render_template('read_only')
    end

    it "should not allow students to see a read-only view of a quiz" do
      course_with_student_logged_in(:active_all => true)
      course_quiz
      get 'read_only', :course_id => @course.id, :quiz_id => @quiz.id
      assert_unauthorized

      @enrollment.conclude
      get 'read_only', :course_id => @course.id, :quiz_id => @quiz.id
      assert_unauthorized
    end
  end

  describe "DELETE 'destroy'" do
    it "should require authorization" do
      course_with_teacher(:active_all => true)
      course_quiz
      delete 'destroy', :course_id => @course.id, :id => @quiz.id
      assert_unauthorized
    end

    it "should not allow students to delete quizzes" do
      course_with_student_logged_in(:active_all => true)
      course_quiz
      delete 'destroy', :course_id => @course.id, :id => @quiz.id
      assert_unauthorized
    end

    it "should delete quizzes" do
      course_with_teacher_logged_in(:active_all => true)
      course_quiz
      delete 'destroy', :course_id => @course.id, :id => @quiz.id
      assigns[:quiz].should_not be_nil
      assigns[:quiz].should eql(@quiz)
      assigns[:quiz].should be_deleted
    end
  end
end

