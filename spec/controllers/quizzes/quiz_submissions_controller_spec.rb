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

require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe Quizzes::QuizSubmissionsController do

  before :once do
    course_with_teacher(:active_all => true)
    student_in_course(:active_all => true)
    @teacher_enrollment = @enrollment
  end

  describe "POST 'create'" do
    before :once do
      @quiz = @course.quizzes.create!
      @quiz.workflow_state = "available"
      @quiz.quiz_data = [{:correct_comments=>"", :assessment_question_id=>nil, :incorrect_comments=>"", :question_name=>"Question 1", :points_possible=>1, :question_text=>"Which book(s) are required for this course?", :name=>"Question 1", :id=>128, :answers=>[{:weight=>0, :text=>"A", :comments=>"", :id=>1490}, {:weight=>0, :text=>"B", :comments=>"", :id=>1020}, {:weight=>0, :text=>"C", :comments=>"", :id=>7051}], :question_type=>"multiple_choice_question"}]
      @quiz.save!
    end

    it "should allow previewing" do
      user_session(@teacher)
      post 'create', params: {:course_id => @quiz.context_id, :quiz_id => @quiz.id, :preview => 1}
      expect(response).to be_redirect
    end

    it "should allow previewing a quiz with an access code" do
      user_session(@teacher)
      @quiz.access_code = "12345"
      @quiz.save!
      post 'create', params: {:course_id => @quiz.context_id, :quiz_id => @quiz.id, :preview => 1}
      expect(response).to be_redirect
    end

    it "should not break trying to sanitize parameters of an already submitted quiz" do
      user_session(@student)
      @quiz.one_question_at_a_time = true
      @quiz.cant_go_back = true
      @quiz.save!
      @submission = Quizzes::SubmissionManager.new(@quiz).find_or_create_submission(@student)
      Quizzes::SubmissionGrader.new(@submission).grade_submission
      post 'create', params: {:course_id => @quiz.context_id, :quiz_id => @quiz.id, :question_123 => 'hi', :validation_token => @submission.validation_token}
      expect(response).to be_redirect
    end

    it "clears the access code key in user's session" do
      user_session(@student)
      @quiz.access_code = "Testing Testing 123"
      @quiz.save!
      session[:quiz_access_code] = {}
      Hash(session[:quiz_access_code])[@quiz.id] =  @quiz.access_code
      @submission = Quizzes::SubmissionManager.new(@quiz).find_or_create_submission(@student)
      post 'create', params: {:course_id => @quiz.context_id, :quiz_id => @quiz.id, :question_123 => 'hi', :validation_token => @submission.validation_token}
      expect(session[:quiz_access_code]).to be_empty
    end

    it "should reject a submission when the validation token does not match" do
      user_session(@student)
      @submission = Quizzes::SubmissionManager.new(@quiz).find_or_create_submission(@student)
      post 'create', params: {:course_id => @quiz.context_id, :quiz_id => @quiz.id, :question_123 => 'hi', :validation_token => "xxx"}
      expect(response).to be_redirect
      expect(flash[:error]).not_to be_blank
    end

    it "should build a new QuizSubmissionEvent" do
      user_session(@student)
      @submission = Quizzes::SubmissionManager.new(@quiz).find_or_create_submission(@student)
      @submission.submission_data = {}
      @submission.quiz_data = [{:correct_comments=>"", :assessment_question_id=>nil, :incorrect_comments=>"", :question_name=>"Question 1", :points_possible=>1, :question_text=>"Which book(s) are required for this course?", :name=>"Question 1", 'id'=>128, :answers=>[{:weight=>0, :text=>"A", :comments=>"", :id=>1490}, {:weight=>0, :text=>"B", :comments=>"", :id=>1020}, {:weight=>0, :text=>"C", :comments=>"", :id=>7051}], :question_type=>"multiple_choice_question"}]
      @submission.attempt = 1
      @submission.save!

      post 'create', params: {course_id: @quiz.context_id, quiz_id: @quiz.id,
        question_128: "bye", validation_token: @submission.validation_token,
        attempt: 1}
      events = Quizzes::QuizSubmissionEvent.where(quiz_submission_id: @submission.id)
      expect(events.size).to be_equal(1)
    end
  end

  describe "PUT 'update'" do
    before(:once) { quiz_with_submission }
    it "should require authentication" do
      put 'update', params: {:course_id => @quiz.context_id, :quiz_id => @quiz.id, :id => @qsub.id}
      assert_unauthorized
    end

    it "should allow updating scores if the teacher is logged in" do
      user_session(@teacher)
      put 'update', params: {:course_id => @quiz.context_id, :quiz_id => @quiz.id, :id => @qsub.id, "question_score_128" => "2"}
      expect(response).to be_redirect
      expect(assigns[:submission]).not_to be_nil
      expect(assigns[:submission].submission_data[0][:points]).to eq 2
    end

    it "should not allow updating if the course is concluded" do
      @teacher_enrollment.conclude
      put 'update', params: {:course_id => @quiz.context_id, :quiz_id => @quiz.id, :id => @qsub.id}
      assert_unauthorized
    end
  end

  describe "PUT 'backup'" do
    before :once do
      quiz_model(:course => @course)
      @qs = @quiz.generate_submission(@student, false)
    end

    it "should require authentication" do
      Quizzes::QuizSubmission.where(:id => @qs).update_all(:updated_at => 1.hour.ago)

      put 'backup', params: {:quiz_id => @quiz.id, :course_id => @course.id, :a => 'test', :validation_token => @qs.validation_token}
      assert_unauthorized

      expect(@qs.reload.submission_data[:a]).to be_nil
    end

    it "should backup to the user's quiz submission" do
      user_session(@student)
      Quizzes::QuizSubmission.where(:id => @qs).update_all(:updated_at => 1.hour.ago)

      put 'backup', params: {:quiz_id => @quiz.id, :course_id => @course.id, :a => 'test', :validation_token => @qs.validation_token}
      expect(response).to be_successful

      expect(@qs.reload.submission_data[:a]).to eq 'test'
    end

    it "should return the time left to finish a quiz" do
      user_session(@student)
      submission = @qs
      submission.update_attribute(:end_at, Time.now + 1.hour)
      Quizzes::QuizSubmission.where(:id => submission).update_all(:updated_at => 1.hour.ago)

      put 'backup', params: {:quiz_id => @quiz.id, :course_id => @course.id, :a => 'test', :validation_token => submission.validation_token}
      json = JSON.parse(response.body)

      expect(json).to have_key('time_left')
      expect(json['time_left']).to be_within(5.0).of(60 * 60)
    end

    it "should not backup if no submission can be found" do
      user_session(@teacher)
      put 'backup', params: { quiz_id: @quiz.id, course_id: @course.id, a: 'test', preview: 1 }
      json = JSON.parse(response.body)
      expect(json['backup']).to be_falsey
    end
  end

  describe "POST 'record_answer'" do
    before :once do
      @course = nil
      @student = nil
      quiz_with_submission(!:complete_quiz)
      @quiz.update_attribute(:one_question_at_a_time, true)
    end

    it "should require authentication" do
      post 'record_answer', params: {:quiz_id => @quiz.id, :course_id => @course.id, :id => @qsub.id, :a => 'test'}
      assert_unauthorized

      expect(@qsub.reload.submission_data[:a]).to be_nil
    end

    it "should record the user's submission" do
      # TODO: FIXME, this test doesn't appear to match its description
      user_session(@student)

      post 'record_answer', params: {:quiz_id => @quiz.id, :course_id => @course.id, :id => @qsub.id, :a => 'test'}
      assert_status(401)

      expect(@qsub.reload.submission_data[:a]).to be_nil
    end

    it "should redirect back to quiz after login if unauthorized" do
      controller.request.env['HTTP_REFERER'] = 'http://test.host/'
      post 'record_answer', params: {:quiz_id => @quiz.id, :course_id => @course.id, :id => @qsub.id, :a => 'test'}
      assert_unauthorized
      expect(session[:return_to]).not_to be_nil
    end
  end

  describe "GET / (#index)" do

    context "with a zip parameter present" do
      it "queues a job to get all attachments for all submissions of a quiz" do
        user_session(@teacher)
        quiz = course_quiz !!:active
        expect(ContentZipper).to receive(:send_later_enqueue_args).with(:process_attachment,
          {priority: Delayed::LOW_PRIORITY, max_attempts: 1}, anything)
        get 'index', params: {quiz_id: quiz.id, zip: '1', course_id: @course}
      end
    end
  end

  describe "POST / (#extension)" do
    context "as a teacher in course" do
      let_once(:quiz) { course_quiz !!:active }
      it "should be able to extend own extra attempts" do
        user_session(@teacher)
        request.accept = "application/json"
        post 'extensions', params: {quiz_id: quiz.id, course_id: @course, user_id: @teacher.id, extra_attempts: 1}
        expect(response).to be_successful
        json = JSON.parse(response.body)
        expect(json).to have_key('extra_attempts')
        expect(json['extra_attempts']).to eq 1
      end

      it "should be able to reset the result lockdown flag" do
        user_session(@teacher)
        request.accept = "application/json"
        post 'extensions', params: {quiz_id: quiz.id, course_id: @course, user_id: @teacher.id, reset_has_seen_results: 1}
        expect(response).to be_successful
        json = JSON.parse(response.body)
        expect(json).to have_key('has_seen_results')
        expect(json['has_seen_results']).to eq false
      end
    end
  end
end
