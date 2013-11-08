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

describe QuizSubmissionsController do

  describe "POST 'create'" do
    before do
      course_with_teacher(:active_all => true)
      @quiz = @course.quizzes.create!
      @quiz.workflow_state = "available"
      @quiz.quiz_data = [{:correct_comments=>"", :assessment_question_id=>nil, :incorrect_comments=>"", :question_name=>"Question 1", :points_possible=>1, :question_text=>"Which book(s) are required for this course?", :name=>"Question 1", :id=>128, :answers=>[{:weight=>0, :text=>"A", :comments=>"", :id=>1490}, {:weight=>0, :text=>"B", :comments=>"", :id=>1020}, {:weight=>0, :text=>"C", :comments=>"", :id=>7051}], :question_type=>"multiple_choice_question"}]
      @quiz.save!
    end

    it "should allow previewing" do
      user_session(@teacher)
      post 'create', :course_id => @quiz.context_id, :quiz_id => @quiz.id, :preview => 1
      response.should be_redirect
    end

    it "should not break trying to sanitize parameters of an already submitted quiz" do
      student_in_course(:active_all => true)
      user_session(@student)
      @quiz.one_question_at_a_time = true
      @quiz.cant_go_back = true
      @quiz.save!
      @submission = @quiz.find_or_create_submission(@student)
      @submission.grade_submission
      post 'create', :course_id => @quiz.context_id, :quiz_id => @quiz.id, :question_123 => 'hi', :validation_token => @submission.validation_token
      response.should be_redirect
    end

    it "clears the access code key in user's session" do
      student_in_course(:active_all => true)
      user_session(@student)
      @quiz.access_code = "Testing Testing 123"
      @quiz.save!
      access_code_key = @quiz.access_code_key_for_user(@student)
      session[access_code_key] = true
      @submission = @quiz.find_or_create_submission(@student)
      post 'create', :course_id => @quiz.context_id, :quiz_id => @quiz.id, :question_123 => 'hi', :validation_token => @submission.validation_token
      session.has_key?(access_code_key).should == false
    end

    it "should reject a submission when the validation token does not match" do
      student_in_course(:active_all => true)
      user_session(@student)
      @submission = @quiz.find_or_create_submission(@student)
      post 'create', :course_id => @quiz.context_id, :quiz_id => @quiz.id, :question_123 => 'hi', :validation_token => "xxx"
      response.should be_redirect
      flash[:error].should_not be_blank
    end
  end
  
  describe "PUT 'update'" do
    it "should require authentication" do
    course_with_teacher(:active_all => true)
      quiz_with_submission
      put 'update', :course_id => @quiz.context_id, :quiz_id => @quiz.id, :id => @qsub.id
      assert_unauthorized
    end
    
    it "should allow updating scores if the teacher is logged in" do
      course_with_teacher(:active_all => true)
      quiz_with_submission
      user_session(@teacher)
      put 'update', :course_id => @quiz.context_id, :quiz_id => @quiz.id, :id => @qsub.id, "question_score_128" => "2"
      response.should be_redirect
      assigns[:submission].should_not be_nil
      assigns[:submission].submission_data[0][:points].should == 2
    end
    
    it "should not allow updating if the course is concluded" do
      course_with_teacher(:active_all => true)
      quiz_with_submission
      @enrollment.conclude
      put 'update', :course_id => @quiz.context_id, :quiz_id => @quiz.id, :id => @qsub.id
      assert_unauthorized
    end
  end

  describe "PUT 'backup'" do
    it "should require authentication" do
      course_with_student(:active_all => true)
      quiz_model(:course => @course)
      @qs = @quiz.generate_submission(@student, false)
      QuizSubmission.where(:id => @qs).update_all(:updated_at => 1.hour.ago)

      put 'backup', :quiz_id => @quiz.id, :course_id => @course.id, :a => 'test', :validation_token => @qs.validation_token
      response.status.to_i.should == 401

      @qs.reload.submission_data[:a].should be_nil
    end

    it "should backup to the user's quiz submission" do
      course_with_student_logged_in(:active_all => true)
      quiz_model(:course => @course)
      @qs = @quiz.generate_submission(@student, false)
      QuizSubmission.where(:id => @qs).update_all(:updated_at => 1.hour.ago)

      put 'backup', :quiz_id => @quiz.id, :course_id => @course.id, :a => 'test', :validation_token => @qs.validation_token
      response.should be_success

      @qs.reload.submission_data[:a].should == 'test'
    end

    it "should return the time left to finish a quiz" do
      course_with_student_logged_in(:active_all => true)
      quiz_model(:course => @course)
      submission = @quiz.generate_submission(@student, false)
      submission.update_attribute(:end_at, Time.now + 1.hour)
      QuizSubmission.where(:id => submission).update_all(:updated_at => 1.hour.ago)

      put 'backup', :quiz_id => @quiz.id, :course_id => @course.id, :a => 'test', :validation_token => submission.validation_token
      json = JSON.parse(response.body)

      json.should have_key('time_left')
      json['time_left'].should == 60 * 60
    end

  end

  describe "POST 'record_answer'" do
    before do
      quiz_with_submission(!:complete_quiz)
      @quiz.update_attribute(:one_question_at_a_time, true)
    end

    it "should require authentication" do
      post 'record_answer', :quiz_id => @quiz.id, :course_id => @course.id, :id => @qsub.id, :a => 'test'
      response.status.to_i.should == 401

      @qsub.reload.submission_data[:a].should be_nil
    end

    it "should record the user's submission" do
      user_session(@student)

      post 'record_answer', :quiz_id => @quiz.id, :course_id => @course.id, :id => @qsub.id, :a => 'test'
      response.status.to_i.should == 401

      @qsub.reload.submission_data[:a].should be_nil
    end

    it "should redirect back to quiz after login if unauthorized" do
      post 'record_answer', :quiz_id => @quiz.id, :course_id => @course.id, :id => @qsub.id, :a => 'test'
      assert_unauthorized
      session[:return_to].should_not be_nil
    end
  end

  describe "GET / (#index)" do

    context "with a zip parameter present" do
      it "queues a job to get all attachments for all submissions of a quiz" do
        course_with_teacher_logged_in
        quiz = course_quiz !!:active
        ContentZipper.expects(:send_later_enqueue_args).with {|first_arg,second_arg|
          first_arg.should == :process_attachment
          second_arg.should == {priority: Delayed::LOW_PRIORITY, max_attempts: 1}
        }
        get 'index', quiz_id: quiz.id, zip: '1', course_id: @course
      end
    end
  end
end
