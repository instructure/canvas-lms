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
      course_quiz(:active => true)
      
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
      q1.quiz_group_id = 5
      q1.save!
      q2 = quiz_question
      g3 = quiz_group
      q1.position.should eql(1)
      q2.position.should eql(1)
      g3.position.should eql(2)
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
    
    it "should not allow viewing other submissions if not a teacher" do
      u = user(:active_all => true)
      course_with_student_logged_in(:active_all => true)
      course_quiz
      s = @quiz.generate_submission(u)
      @submission = @quiz.generate_submission(@user)
      get 'history', :course_id => @course.id, :quiz_id => @quiz.id, :user_id => u.id
      response.should be_success
      assigns[:user].should_not be_nil
      assigns[:user].should eql(@user)
      assigns[:quiz].should_not be_nil
      assigns[:quiz].should eql(@quiz)
      assigns[:submission].should_not be_nil
      assigns[:submission].should eql(@submission)
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
  
