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

require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe Quizzes::QuizzesController do
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

  def temporary_user_code(generate=true)
    if generate
      session[:temporary_user_code] ||= "tmp_#{Digest::MD5.hexdigest("#{Time.now.to_i.to_s}_#{rand.to_s}")}"
    else
      session[:temporary_user_code]
    end
  end

  def logged_out_survey_with_submission(user, questions, &block)
    user_session(@teacher)

    @assignment = @course.assignments.create(:title => "Test Assignment")
    @assignment.workflow_state = "available"
    @assignment.submission_types = "online_quiz"
    @assignment.save
    @quiz = Quizzes::Quiz.find_by_assignment_id(@assignment.id)
    @quiz.anonymous_submissions = false
    @quiz.quiz_type = "survey"

    @questions = questions.map { |q| @quiz.quiz_questions.create!(q) }
    @quiz.generate_quiz_data
    @quiz.save!

    @quiz_submission = @quiz.generate_submission(user)
    @quiz_submission.mark_completed
    @quiz_submission.submission_data = yield if block_given?
    Quizzes::SubmissionGrader.new(@quiz_submission).grade_submission
    @quiz_submission.save!
  end

  def ember_urls
    CanvasEmberUrl::UrlMappings.new(
      :course_quizzes => course_quizzes_url
    )
  end

  before :once do
    course_with_teacher(:active_all => true)
    student_in_course(:active_all => true)
    @student2 = @student
    student_in_course(:active_all => true)
  end

  describe "GET 'index'" do
    it "should require authorization" do
      get 'index', :course_id => @course.id
      assert_unauthorized
    end

    it "should redirect 'disabled', if disabled by the teacher" do
      user_session(@student)
      @course.update_attribute(:tab_configuration, [{'id'=>4,'hidden'=>true}])
      get 'index', :course_id => @course.id
      response.should be_redirect
      flash[:notice].should match(/That page has been disabled/)
    end

    it "should assign variables" do
      user_session(@teacher)
      get 'index', :course_id => @course.id
      assigns[:quizzes].should_not be_nil
      assigns[:unpublished_quizzes].should_not be_nil
      assigns[:submissions_hash].should_not be_nil
    end

    it "should retrieve quizzes" do
      user_session(@teacher)
      course_quiz(!!:active)

      get 'index', :course_id => @course.id
      assigns[:quizzes].should_not be_nil
      assigns[:quizzes].should_not be_empty
      assigns[:quizzes][0].should eql(@quiz)
    end
  end

  describe "GET 'index' with draft state enabled" do
    before :once do
      Account.default.enable_feature! :draft_state
    end

    it "should assign JS variables" do
      user_session(@teacher)
      get 'index', :course_id => @course.id
      controller.js_env[:QUIZZES][:assignment].should_not be_nil
      controller.js_env[:QUIZZES][:open].should_not be_nil
      controller.js_env[:QUIZZES][:surveys].should_not be_nil
      controller.js_env[:QUIZZES][:options].should_not be_nil
    end

    it "should filter out unpublished quizzes for student" do
      user_session(@student)
      course_quiz
      course_quiz(active = true)

      get 'index', :course_id => @course.id

      controller.js_env[:QUIZZES][:assignment].length.should eql 1
      controller.js_env[:QUIZZES][:assignment].map do |quiz|
        quiz[:published].should be_true
      end
    end

    it 'should implicitly grade outstanding submissions for user in course' do
      user_session(@student)
      course_quiz(active = true)

      Quizzes::OutstandingQuizSubmissionManager.expects(:grade_by_course)

      get 'index', :course_id => @course.id
    end
  end

  describe "GET 'index' with quiz stats disabled" do
    before :each do
      a = Account.default
      a.disable_feature! :quiz_stats
      a.save!
    end

    it "should render index page" do
      user_session(@teacher)
      course_quiz(active = true)
      a = Account.default
      a.feature_enabled?(:quiz_stats).should eql false
      get 'index', :course_id => @course.id
      assert_response(:success)
      response.should render_template('index')
    end
  end

  describe "GET 'index' with quiz stats enabled" do
    before :each do
      a = Account.default
      a.enable_feature! :draft_state
      a.enable_feature! :quiz_stats
      a.save!
    end

    it "should render ember quiz index page" do
      user_session(@teacher)
      course_quiz(active = true)
      a = Account.default
      a.feature_enabled?(:quiz_stats).should eql true
      get 'index', :course_id => @course.id
      assert_response(:success)
      response.should render_template('fabulous_quizzes')
    end
  end

  describe "GET 'new'" do
    it "should require authorization" do
      get 'new', :course_id => @course.id
      assert_unauthorized
    end

    it "should assign variables" do
      user_session(@teacher)
      get 'new', :course_id => @course.id
      assigns[:quiz].should_not be_nil
      q = assigns[:quiz]
    end

    it "subsequent requests should return the same quiz unless ?fresh=1" do
      user_session(@teacher)
      get 'new', :course_id => @course.id
      assigns[:quiz].should_not be_nil
      q = assigns[:quiz]

      get 'new', :course_id => @course.id
      assigns[:quiz].should_not be_nil
      assigns[:quiz].should_not eql(q)

      get 'new', :course_id => @course.id, :fresh => 1
      # Quizzes::Quiz.find_by_id(q.id).should be_deleted
      assigns[:quiz].should_not be_nil
      assigns[:quiz].should_not eql(q)
    end
  end

  describe "GET 'edit'" do
    before(:once) { course_quiz }
    it "should require authorization" do
      get 'edit', :course_id => @course.id, :id => @quiz.id
      assert_unauthorized
      assigns[:quiz].should_not be_nil
    end

    it "should assign variables" do
      user_session(@teacher)
      regrade = @quiz.quiz_regrades.create!(:user_id => @teacher.id, quiz_version: @quiz.version_number)
      q = @quiz.quiz_questions.create!
      regrade.quiz_question_regrades.create!(:quiz_question_id => q.id,:regrade_option => 'no_regrade')
      get 'edit', :course_id => @course.id, :id => @quiz.id
      assigns[:quiz].should_not be_nil
      assigns[:quiz].should eql(@quiz)
      assigns[:js_env][:REGRADE_OPTIONS].should == {q.id => 'no_regrade' }
      response.should render_template("new")
    end
  end

  describe "GET 'show'" do
    it "should require authorization" do
      course_quiz
      get 'show', :course_id => @course.id, :id => @quiz.id
      assert_unauthorized
      assigns[:quiz].should_not be_nil
      assigns[:quiz].should eql(@quiz)
    end

    it "should assign variables" do
      user_session(@teacher)
      course_quiz
      get 'show', :course_id => @course.id, :id => @quiz.id
      assigns[:quiz].should_not be_nil
      assigns[:quiz].should eql(@quiz)
      assigns[:question_count].should eql(@quiz.question_count)
      assigns[:just_graded].should eql(false)
      assigns[:stored_params].should_not be_nil
    end

    it "should set the submission count variables" do
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
      @course.update_attribute :is_public, true
      course_quiz !!:active
      get 'show', :course_id => @course.id, :id => @quiz.id, :force_user => 1
      response.should be_redirect
      response.location.should match /login/
    end

    it "should set session[headless_quiz] if persist_headless param is sent" do
      user_session(@student)
      course_quiz !!:active
      get 'show', :course_id => @course.id, :id => @quiz.id, :persist_headless => 1
      controller.session[:headless_quiz].should be_true
      assigns[:headers].should be_false
    end

    it "should not render headers if session[:headless_quiz] is set" do
      user_session(@student)
      course_quiz !!:active
      controller.session[:headless_quiz] = true
      get 'show', :course_id => @course.id, :id => @quiz.id
      assigns[:headers].should be_false
    end

    it "assigns js_env for attachments if submission is present" do
      require 'action_controller_test_process'
      user_session(@student)
      course_quiz !!:active
      submission = @quiz.generate_submission @student
      create_attachment_for_file_upload_submission!(submission)
      get 'show', :course_id => @course.id, :id => @quiz.id
      attachment = submission.attachments.first

      attach = assigns[:js_env][:ATTACHMENTS][attachment.id]
      attach[:id].should == attachment.id
      attach[:display_name].should == attachment.display_name
    end

    it "assigns js_env for versions if submission is present" do
      require 'action_controller_test_process'
      user_session(@student)
      course_quiz !!:active
      submission = @quiz.generate_submission @student
      create_attachment_for_file_upload_submission!(submission)
      get 'show', :course_id => @course.id, :id => @quiz.id

      path = "courses/#{@course.id}/quizzes/#{@quiz.id}/submission_versions"
      assigns[:js_env][:SUBMISSION_VERSIONS_URL].should include(path)
    end

    it "doesn't show unpublished quizzes to students with draft state" do
      user_session(@student)
      course_quiz(active=true)
      Account.default.enable_feature!(:draft_state)
      @quiz.unpublish!
      get 'show', course_id: @course.id, id: @quiz.id
      response.should_not be_success
    end

    it 'logs a single asset access entry with an action level of "view"' do
      Setting.set('enable_page_views', 'db')

      user_session(@teacher)
      course_quiz
      get 'show', :course_id => @course.id, :id => @quiz.id
      assigns[:access].should_not be_nil
      assigns[:accessed_asset].should_not be_nil
      assigns[:accessed_asset][:level].should == 'view'
      assigns[:access].view_score.should == 1
    end

    it "locks results if there is a submission and one_time_results is on" do
      Account.default.disable_feature! :quiz_stats
      user_session(@student)

      course_quiz(true)
      @quiz.one_time_results = true
      @quiz.save!
      @quiz.publish!

      submission = @quiz.generate_submission @student
      submission.mark_completed
      submission.save

      get 'show', course_id: @course.id, id: @quiz.id

      response.should be_success
      submission.reload.has_seen_results.should == true
    end

    it "does not attempt to lock results if there is a settings only submission" do
      Account.default.disable_feature! :quiz_stats
      user_session(@student)

      course_quiz(true)
      @quiz.lock_at = 2.days.ago
      @quiz.one_time_results = true
      @quiz.save!
      @quiz.publish!

      sub_manager = Quizzes::SubmissionManager.new(@quiz)
      submission = sub_manager.find_or_create_submission(@student, nil, 'settings_only')
      submission.manually_unlocked = true
      submission.save!

      get 'show', course_id: @course.id, id: @quiz.id

      response.should be_success
      submission.reload.has_seen_results.should be_nil
    end
  end

  describe "GET 'show' with quiz stats enabled" do
    before :once do
      a = Account.default
      a.enable_feature! :draft_state
      a.enable_feature! :quiz_stats
      a.save!

      course_quiz
    end

    before :each do
      user_session(@teacher)
    end

    it "should redirect to ember quiz stats app" do
      a = Account.default
      a.feature_enabled?(:quiz_stats).should eql true
      get 'show', :course_id => @course.id, :id => @quiz.id
      assert_redirected_to ember_urls.course_quiz_url(@quiz.id)
    end

    it "should redirect to ember quiz stats app with headless if given" do
      a = Account.default
      a.feature_enabled?(:quiz_stats).should eql true
      get 'show', :course_id => @course.id, :id => @quiz.id, :headless => 1
      assert_redirected_to ember_urls.course_quiz_url(@quiz.id, headless: 1)
    end

    it "should redirect to preview ember quiz stats app" do
      a = Account.default
      a.feature_enabled?(:quiz_stats).should eql true
      get 'show', :course_id => @course.id, :id => @quiz.id, :preview => 1
      assert_redirected_to ember_urls.course_quiz_preview_url(@quiz.id)
    end
  end

  describe "GET 'managed_quiz_data'" do
    it "should respect section privilege limitations" do
      @course.student_enrollments.destroy_all
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
      assigns[:submissions_from_users][@sub1.user_id].should == @sub1
      assigns[:submissions_from_users][@sub2.user_id].should == @sub2
      assigns[:submitted_students].sort_by(&:id).should == [@user1, @user2].sort_by(&:id)

      user_session @ta1
      get 'managed_quiz_data', :course_id => @course.id, :quiz_id => @quiz.id
      assigns[:submissions_from_users][@sub1.user_id].should == @sub1
      assigns[:submitted_students].should == [@user1]
    end

    it "should include survey results from logged out users in a public course" do
      #logged out user
      user = temporary_user_code

      #make questions
      questions = [{:question_data => { :name => "test 1" }},
        {:question_data => { :name => "test 2" }},
        {:question_data => { :name => "test 3" }},
        {:question_data => { :name => "test 4" }}]

      logged_out_survey_with_submission user, questions

      get 'managed_quiz_data', :course_id => @course.id, :quiz_id => @quiz.id

      assigns[:submissions_from_logged_out].should == [@quiz_submission]
      assigns[:submissions_from_users].should == {}
    end

    it "should include survey results from a logged-in user in a public course" do
      user_session(@teacher)

      @user1 = user_with_pseudonym(:active_all => true, :name => 'Student1', :username => 'student1@instructure.com')
      @course.enroll_student(@user1)

      questions = [{:question_data => { :name => "test 1" }},
        {:question_data => { :name => "test 2" }},
        {:question_data => { :name => "test 3" }},
        {:question_data => { :name => "test 4" }}]

      @assignment = @course.assignments.create(:title => "Test Assignment")
      @assignment.workflow_state = "available"
      @assignment.submission_types = "online_quiz"
      @assignment.save
      @quiz = Quizzes::Quiz.find_by_assignment_id(@assignment.id)
      @quiz.anonymous_submissions = true
      @quiz.quiz_type = "survey"

      @questions = questions.map { |q| @quiz.quiz_questions.create!(q) }
      @quiz.generate_quiz_data
      @quiz.save!

      @quiz_submission = @quiz.generate_submission(@user1)
      @quiz_submission.mark_completed

      get 'managed_quiz_data', :course_id => @course.id, :quiz_id => @quiz.id

      assigns[:submissions_from_users][@quiz_submission.user_id].should == @quiz_submission
      assigns[:submitted_students].should == [@user1]
    end

    it "should not include teacher previews" do
      user_session(@teacher)

      quiz = quiz_model(course: @course)
      quiz.publish!

      quiz_submission = quiz.generate_submission(@teacher, true)
      quiz_submission.complete!

      get 'managed_quiz_data', :course_id => @course.id, :quiz_id => quiz.id

      assigns[:submissions_from_users].should be_empty
      assigns[:submissions_from_logged_out].should be_empty
      assigns[:submitted_students].should be_empty
    end
  end

  describe "GET 'moderate'" do
    before(:once) { course_quiz }
    it "should require authorization" do
      get 'moderate', :course_id => @course.id, :quiz_id => @quiz.id
      assert_unauthorized
    end

    it "should assign variables" do
      user_session(@teacher)
      @sub = @quiz.generate_submission(@student)
      get 'moderate', :course_id => @course.id, :quiz_id => @quiz.id
      assigns[:quiz].should == @quiz
      assigns[:students].should include @student
      assigns[:submissions].should == [@sub]
    end

    it "should respect section privilege limitations" do
      @course.student_enrollments.destroy_all
      @section = @course.course_sections.create!(:name => 'section 2')
      @user2 = user_with_pseudonym(:active_all => true, :name => 'Student2', :username => 'student2@instructure.com')
      @section.enroll_user(@user2, 'StudentEnrollment', 'active')
      @user1 = user_with_pseudonym(:active_all => true, :name => 'Student1', :username => 'student1@instructure.com')
      @course.enroll_student(@user1)
      @ta1 = user_with_pseudonym(:active_all => true, :name => 'TA1', :username => 'ta1@instructure.com')
      @course.enroll_ta(@ta1).update_attribute(:limit_privileges_to_course_section, true)
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

  describe "GET 'moderate' with quiz stats enabled" do
    before :each do
      a = Account.default
      a.enable_feature! :draft_state
      a.enable_feature! :quiz_stats
      a.save!

      user_session(@teacher)
      course_quiz
    end

    it "should not redirect to ember moderate app" do
      a = Account.default
      a.feature_enabled?(:quiz_stats).should eql true
      get 'moderate', :course_id => @course.id, :quiz_id => @quiz.id
      assert_response :success
    end
  end

  describe "GET 'moderate' with new quiz moderate enabled" do
    before :each do
      a = Account.default
      a.enable_feature! :draft_state
      a.enable_feature! :quiz_stats
      a.enable_feature! :quiz_moderate
      a.save!

      user_session(@teacher)
      course_quiz
    end

    it "should redirect to ember moderate app" do
      a = Account.default
      a.feature_enabled?(:quiz_moderate).should eql true
      get 'moderate', :course_id => @course.id, :quiz_id => @quiz.id
      assert_redirected_to ember_urls.course_quiz_moderate_url(@quiz.id)
    end
  end


  describe "POST 'take'" do
    it "should require authorization" do
      course_quiz(true)
      post 'show', :course_id => @course, :quiz_id => @quiz.id, :take => '1'
      assert_unauthorized
    end

    it "should allow taking the quiz" do
      user_session(@student)
      course_quiz(true)
      post 'show', :course_id => @course, :quiz_id => @quiz.id, :take => '1'
      response.should redirect_to("/courses/#{@course.id}/quizzes/#{@quiz.id}/take")
    end

    context 'asset access logging' do
      before :once do
        Setting.set('enable_page_views', 'db')

        course_quiz
      end

      before :each do
        user_session(@teacher)
      end

      it 'should log a single entry with an action level of "participate"' do
        post 'show', :course_id => @course, :quiz_id => @quiz.id, :take => '1'
        assigns[:access].should_not be_nil
        assigns[:accessed_asset].should_not be_nil
        assigns[:accessed_asset][:level].should == 'participate'
        assigns[:access].participate_score.should == 1
      end

      it 'should not log entries when resuming the quiz' do
        post 'show', :course_id => @course, :quiz_id => @quiz.id, :take => '1'
        assigns[:access].should_not be_nil
        assigns[:accessed_asset].should_not be_nil
        assigns[:accessed_asset][:level].should == 'participate'
        assigns[:access].participate_score.should == 1

        # Since the second request we will make is handled by the same controller
        # instance, @accessed_asset must be reset otherwise
        # ApplicationController#log_page_view will use it to log another entry.
        controller.instance_variable_set('@accessed_asset', nil)
        controller.js_env.clear

        post 'show', :course_id => @course, :quiz_id => @quiz.id, :take => '1'
        assigns[:access].participate_score.should == 1
      end
    end

    context 'verification' do
      before :once do
        course_quiz(true)
        @quiz.access_code = 'bacon'
        @quiz.save!
      end

      before :each do
        user_session(@student)
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
      user_session(@student)
      course_quiz(true)
      @quiz.locked = true
      @quiz.save!
      post 'show', :course_id => @course, :quiz_id => @quiz.id, :take => '1'
      response.should render_template('show')
      assigns[:locked].should_not be_nil
    end

    it "should let them take the quiz if it's locked but unlocked by an override" do
      user_session(@student)
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
      user_session(@student)
      course_quiz(true)
      @quiz.locked = true
      @quiz.save!
      @sub = Quizzes::SubmissionManager.new(@quiz).find_or_create_submission(@user, nil, 'settings_only')
      @sub.manually_unlocked = true
      @sub.save!
      post 'show', :course_id => @course, :quiz_id => @quiz.id, :take => '1'
      response.should redirect_to("/courses/#{@course.id}/quizzes/#{@quiz.id}/take")
    end

    it "should use default duration if no extensions specified" do
      user_session(@student)
      course_quiz(true)
      @quiz.time_limit = 60
      @quiz.save!
      post 'show', :course_id => @course, :quiz_id => @quiz.id, :take => '1'
      response.should redirect_to("/courses/#{@course.id}/quizzes/#{@quiz.id}/take")
      assigns[:submission].should_not be_nil
      assigns[:submission].user.should eql(@student)
      (assigns[:submission].end_at - assigns[:submission].started_at).to_i.should eql(60.minutes.to_i)
    end

    it "should give user more time if specified" do
      user_session(@student)
      course_quiz(true)
      @quiz.time_limit = 60
      @quiz.save!
      @sub = Quizzes::SubmissionManager.new(@quiz).find_or_create_submission(@user, nil, 'settings_only')
      @sub.extra_time = 30
      @sub.save!
      post 'show', :course_id => @course, :quiz_id => @quiz.id, :take => '1'
      response.should redirect_to("/courses/#{@course.id}/quizzes/#{@quiz.id}/take")
      assigns[:submission].should_not be_nil
      assigns[:submission].user.should eql(@student)
      (assigns[:submission].end_at - assigns[:submission].started_at).to_i.should eql(90.minutes.to_i)
    end

    it "should render ip_filter page if ip_filter doesn't match" do
      user_session(@student)
      course_quiz(true)
      @quiz.ip_filter = '123.123.123.123'
      @quiz.save!
      post 'show', :course_id => @course, :quiz_id => @quiz.id, :take => '1'
      response.should render_template('invalid_ip')
    end

    it "should let the user take the quiz if the ip_filter matches" do
      user_session(@student)
      course_quiz(true)
      @quiz.ip_filter = '123.123.123.123'
      @quiz.save!
      request.env['REMOTE_ADDR'] = '123.123.123.123'
      post 'show', :course_id => @course, :quiz_id => @quiz.id, :take => '1'
      response.should redirect_to("/courses/#{@course.id}/quizzes/#{@quiz.id}/take")
    end

    it "should work without a user for non-graded quizzes in public courses" do
      @course.update_attribute :is_public, true
      course_quiz :active
      @quiz.update_attribute :quiz_type, 'practice_quiz'
      post 'show', :course_id => @course, :quiz_id => @quiz.id, :take => '1'
      response.should redirect_to("/courses/#{@course.id}/quizzes/#{@quiz.id}/take")
    end
  end

  describe "GET 'take'" do
    before :once do
      course_quiz(true)
    end

    it "should require authorization" do
      get 'show', :course_id => @course, :quiz_id => @quiz.id, :take => '1'
      assert_unauthorized
    end

    it "should render the quiz page if the user hasn't started the quiz" do
      user_session(@student)
      get 'show', :course_id => @course, :quiz_id => @quiz.id, :take => '1'
      response.should render_template('show')
    end

    it "should render ip_filter page if the ip_filter stops matching" do
      user_session(@student)
      @quiz.ip_filter = '123.123.123.123'
      @quiz.save!
      @quiz.generate_submission(@student)

      get 'show', :course_id => @course, :quiz_id => @quiz.id, :take => '1'
      response.should render_template('invalid_ip')
    end

    it "should allow taking the quiz" do
      user_session(@student)
      @quiz.generate_submission(@student)

      get 'show', :course_id => @course, :quiz_id => @quiz.id, :take => '1'
      response.should render_template('take_quiz')
      assigns[:submission].should_not be_nil
      assigns[:submission].user.should eql(@student)
    end

    context "when the ID of a question is passed in" do
      before :once do
        @quiz.generate_submission(@student)
      end

      before :each do
        user_session(@student)
      end

      context "a valid question" do
        it "renders take_quiz" do
          Quizzes::QuizzesController.any_instance.stubs(:valid_question?).returns(true)
          get 'show', :course_id => @course, :quiz_id => @quiz.id, :question_id => '1', :take => '1'
          response.should render_template('take_quiz')
        end
      end

      context "a question not in this quiz" do
        it "redirects to the main quiz page" do
          Quizzes::QuizzesController.any_instance.stubs(:valid_question?).returns(false)
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
    before :once do
      course_quiz
    end

    it "should require authorization" do
      get 'history', :course_id => @course.id, :quiz_id => @quiz.id
      assert_unauthorized
    end

    it "should redirect if there are no submissions for the user" do
      user_session(@student)
      get 'history', :course_id => @course.id, :quiz_id => @quiz.id
      response.should be_redirect
      response.should redirect_to("/courses/#{@course.id}/quizzes/#{@quiz.id}")
    end

    it "should assign variables" do
      user_session(@student)
      @submission = @quiz.generate_submission(@student)
      get 'history', :course_id => @course.id, :quiz_id => @quiz.id

      response.should be_success
      assigns[:user].should_not be_nil
      assigns[:user].should eql(@student)
      assigns[:quiz].should_not be_nil
      assigns[:quiz].should eql(@quiz)
      assigns[:submission].should_not be_nil
      assigns[:submission].should eql(@submission)
    end

    it "should find the observed submissions" do
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
      user_session(@student)
      s = @quiz.generate_submission(@student2)
      @submission = @quiz.generate_submission(@student)
      get 'history', :course_id => @course.id, :quiz_id => @quiz.id, :user_id => @student2.id
      response.should_not be_success
    end

    it "should allow viewing other submissions if a teacher" do
      user_session(@teacher)
      s = @quiz.generate_submission(@student)
      @submission = @quiz.generate_submission(@teacher)
      get 'history', :course_id => @course.id, :quiz_id => @quiz.id, :user_id => @student.id

      response.should be_success
      assigns[:user].should_not be_nil
      assigns[:user].should eql(@student)
      assigns[:quiz].should_not be_nil
      assigns[:quiz].should eql(@quiz)
      assigns[:submission].should_not be_nil
      assigns[:submission].should eql(s)
    end

    it "should not allow student viewing if the assignment is muted" do
      user_session(@student)
      @quiz.generate_quiz_data
      @quiz.workflow_state = 'available'
      @quiz.published_at = Time.now
      @quiz.save

      @quiz.assignment.should_not be_nil
      @quiz.assignment.mute!
      s = @quiz.generate_submission(@student2)
      @submission = @quiz.generate_submission(@student)
      get 'history', :course_id => @course.id, :quiz_id => @quiz.id, :user_id => @student2.id

      response.should be_redirect
      response.should redirect_to("/courses/#{@course.id}/quizzes/#{@quiz.id}")
      flash[:notice].should match(/You cannot view the quiz history while the quiz is muted/)
    end

    it "should allow teacher viewing if the assignment is muted" do
      user_session(@teacher)

      @quiz.generate_quiz_data
      @quiz.workflow_state = 'available'
      @quiz.published_at = Time.now
      @quiz.save

      @quiz.assignment.should_not be_nil
      @quiz.assignment.mute!
      s = @quiz.generate_submission(@student)
      @submission = @quiz.generate_submission(@teacher)
      get 'history', :course_id => @course.id, :quiz_id => @quiz.id, :user_id => @student.id

      response.should be_success
    end
  end

  describe "POST 'create'" do
    it "should require authorization" do
      post 'create', :course_id => @course.id
      assert_unauthorized
    end

    it "should not allow students to create quizzes" do
      user_session(@student)
      post 'create', :course_id => @course.id, :quiz => {:title => "some quiz"}
      assert_unauthorized
    end

    it "should create quiz" do
      user_session(@teacher)
      post 'create', :course_id => @course.id, :quiz => {:title => "some quiz"}
      assigns[:quiz].should_not be_nil
      assigns[:quiz].title.should eql("some quiz")
      response.should be_success
    end

    it "creates quizzes with overrides" do
      user_session(@teacher)
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
      quiz = assigns[:quiz].overridden_for(@teacher)
      overrides = AssignmentOverrideApplicator.overrides_for_assignment_and_user(quiz, @teacher)
      overrides.length.should == 1
      overrides.first[:due_at].iso8601.should == section_due_date
    end
  end

  describe "PUT 'update'" do
    it "should require authorization" do
      course_quiz
      put 'update', :course_id => @course.id, :id => @quiz.id, :quiz => {:title => "test"}
      assert_unauthorized
    end

    it "should not allow students to update quizzes" do
      user_session(@student)
      course_quiz
      post 'update', :course_id => @course.id, :id => @quiz.id, :quiz => {:title => "some quiz"}
      assert_unauthorized
    end

    it "should update quizzes" do
      user_session(@teacher)
      course_quiz
      post 'update', :course_id => @course.id, :id => @quiz.id, :quiz => {:title => "some quiz"}
      assigns[:quiz].should_not be_nil
      assigns[:quiz].should eql(@quiz)
      assigns[:quiz].title.should eql("some quiz")
    end

    it "should be able to change ungraded survey to quiz without error" do
      # aka should handle the case where the quiz's assignment is nil/not present.
      user_session(@teacher)
      course_quiz
      @quiz.update_attributes(quiz_type: 'ungraded_survey')
      # make sure the assignment doesn't exist
      @quiz.assignment = nil if @quiz.context.feature_enabled?(:draft_state)
      @quiz.assignment.should_not be_present
      post 'update', course_id: @course.id, id: @quiz.id, activate: true,
        quiz: {quiz_type: 'assignment'}
      response.should be_redirect
      @quiz.reload.quiz_type.should == 'assignment'
      @quiz.should be_available
      @quiz.assignment.should be_present
    end

    it "should lock and unlock without removing assignment" do
      user_session(@teacher)
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
      user_session(@teacher)
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
      quiz = quiz.reload.overridden_for(@teacher)
      overrides = AssignmentOverrideApplicator.overrides_for_assignment_and_user(quiz, @teacher)
      overrides.length.should == 1
    end

    it "deletes overrides for a quiz if assignment_overrides params is 'false'" do
      user_session(@teacher)
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
      user_session(@teacher)
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
      before :once do
        @notification = Notification.create(:name => 'Assignment Due Date Changed')

        @section = @course.course_sections.create!

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

      before :each do
        user_session(@teacher)
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
      user_session(@teacher)
      course_quiz
      @enrollment.conclude
      get 'statistics', :course_id => @course.id, :quiz_id => @quiz.id
      response.should be_success
      response.should render_template('statistics')
    end

    context "logged out submissions" do
      integrate_views

      it "should include logged_out users' submissions in a public course" do
        #logged_out user
        user = temporary_user_code

        #make questions
        questions = [{:question_data => { :name => "test 1" }},
          {:question_data => { :name => "test 2" }},
          {:question_data => { :name => "test 3" }},
          {:question_data => { :name => "test 4" }}]

        logged_out_survey_with_submission user, questions

        #non logged_out submissions
        @user1 = user_with_pseudonym(:active_all => true, :name => 'Student1', :username => 'student1@instructure.com')
        @quiz_submission1 = @quiz.generate_submission(@user1)
        Quizzes::SubmissionGrader.new(@quiz_submission1).grade_submission

        @user2 = user_with_pseudonym(:active_all => true, :name => 'Student2', :username => 'student2@instructure.com')
        @quiz_submission2 = @quiz.generate_submission(@user2)
        Quizzes::SubmissionGrader.new(@quiz_submission2).grade_submission

        @course.large_roster = false
        @course.save!


        get 'statistics', :course_id => @course.id, :quiz_id => @quiz.id, :all_versions => '1'
        response.should be_success
        response.body.should match /Logged Out User/
        response.should render_template('statistics')
      end
    end

    it "should show the statistics page if the course is a MOOC" do
      user_session(@teacher)
      @course.large_roster = true
      @course.save!
      course_quiz
      get 'statistics', :course_id => @course.id, :quiz_id => @quiz.id
      response.should be_success
      response.should render_template('statistics')
    end
  end

  describe "GET 'statistics' with new quiz stats enabled" do
    before :each do
      a = Account.default
      a.enable_feature! :draft_state
      a.enable_feature! :quiz_stats
      a.save!

      user_session(@teacher)
      course_quiz
    end

    it "should redirect to ember quiz stats app" do
      a = Account.default
      a.feature_enabled?(:quiz_stats).should eql true
      get 'statistics', :course_id => @course.id, :quiz_id => @quiz.id
      assert_redirected_to ember_urls.course_quiz_statistics_url(@quiz.id)
    end
  end

  describe "GET 'read_only'" do
    before(:once) { course_quiz }

    it "should allow concluded teachers to see a read-only view of a quiz" do
      user_session(@teacher)
      get 'read_only', :course_id => @course.id, :quiz_id => @quiz.id
      response.should be_success
      response.should render_template('read_only')

      @enrollment.conclude
      controller.js_env.clear
      get 'read_only', :course_id => @course.id, :quiz_id => @quiz.id
      response.should be_success
      response.should render_template('read_only')
    end

    it "should not allow students to see a read-only view of a quiz" do
      user_session(@student)
      get 'read_only', :course_id => @course.id, :quiz_id => @quiz.id
      assert_unauthorized

      @enrollment.conclude
      get 'read_only', :course_id => @course.id, :quiz_id => @quiz.id
      assert_unauthorized
    end
  end

  describe "DELETE 'destroy'" do
    before(:once) { course_quiz }

    it "should require authorization" do
      delete 'destroy', :course_id => @course.id, :id => @quiz.id
      assert_unauthorized
    end

    it "should not allow students to delete quizzes" do
      user_session(@student)
      delete 'destroy', :course_id => @course.id, :id => @quiz.id
      assert_unauthorized
    end

    it "should delete quizzes" do
      user_session(@teacher)
      delete 'destroy', :course_id => @course.id, :id => @quiz.id
      assigns[:quiz].should_not be_nil
      assigns[:quiz].should eql(@quiz)
      assigns[:quiz].should be_deleted
    end
  end

  describe "POST 'publish'" do
    it "should require authorization" do
      course_quiz
      post 'publish', :course_id => @course.id, :quizzes => [@quiz.id]
      assert_unauthorized
    end

    it "should publish unpublished quizzes" do
      user_session(@teacher)
      @quiz = @course.quizzes.build(:title => "New quiz!")
      @quiz.save!

      @quiz.published?.should be_false
      post 'publish', :course_id => @course.id, :quizzes => [@quiz.id]

      @quiz.reload.published?.should be_true
    end
  end

  describe "GET 'submission_html'" do
    before(:once) { course_quiz(true) }
    before(:each) { user_session(@teacher) }

    it "renders nothing if there's no submission for current user" do
      get 'submission_html', course_id: @course.id, quiz_id: @quiz.id
      response.should be_success
      response.body.strip.should be_empty
    end

    it "renders submission html if there is a submission" do
      sub = @quiz.generate_submission(@teacher)
      sub.mark_completed
      sub.save!
      get 'submission_html', course_id: @course.id, quiz_id: @quiz.id
      response.should be_success
      response.should render_template("quizzes/submission_html")
    end
  end

  describe "GET 'submission_html' (as a student)" do
    before do
      user_session(@student)
      course_quiz(true)
    end

    it "locks results if there is a submission and one_time_results is on" do
      @quiz.one_time_results = true
      @quiz.save!
      @quiz.publish!

      submission = @quiz.generate_submission(@student)
      submission.mark_completed
      submission.save!

      get 'submission_html', course_id: @course.id, quiz_id: @quiz.id
      response.should be_success

      response.should render_template("quizzes/submission_html")
      submission.reload.has_seen_results.should == true
    end
  end

  describe "POST 'unpublish'" do
    it "should require authorization" do
      course_quiz
      post 'unpublish', :course_id => @course.id, :quizzes => [@quiz.id]
      assert_unauthorized
    end

    it "should unpublish published quizzes" do
      user_session(@teacher)
      @quiz = @course.quizzes.build(:title => "New quiz!")
      @quiz.publish!

      @quiz.published?.should be_true
      post 'unpublish', :course_id => @course.id, :quizzes => [@quiz.id]

      @quiz.reload.published?.should be_false
    end
  end

  describe "GET submission_versions" do
    before(:once) { course_quiz }

    it "requires authorization" do
      get 'submission_versions', :course_id => @course.id, :quiz_id => @quiz.id
      assert_unauthorized
      assigns[:quiz].should_not be_nil
      assigns[:quiz].should eql(@quiz)
    end

    it "assigns variables" do
      user_session(@teacher)
      submission = @quiz.generate_submission @teacher
      create_attachment_for_file_upload_submission!(submission)
      get 'submission_versions', :course_id => @course.id, :quiz_id => @quiz.id
      assigns[:quiz].should_not be_nil
      assigns[:quiz].should eql(@quiz)
      assigns[:submission].should_not be_nil
      assigns[:versions].should_not be_nil
    end

    it "should render nothing if quiz is muted" do
      user_session(@teacher)

      submission = @quiz.generate_submission @teacher

      assignment = @course.assignments.create(:title => "Test Assignment")
      assignment.workflow_state = "available"
      assignment.submission_types = "online_quiz"
      assignment.muted = true
      assignment.save!
      @quiz.assignment = assignment

      get 'submission_versions', :course_id => @course.id, :quiz_id => @quiz.id
      response.should be_success
      response.body.should match(/^\s?$/)
    end
  end

end
