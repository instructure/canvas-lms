require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe Quizzes::QuizSubmissionsController do
  before do
    course_with_student_logged_in(:active_all => true)
    quiz_model(:course => @course)
    @quiz.update_attribute :one_question_at_a_time, true
    @qs = @quiz.generate_submission(@student, false)
    @qs.quiz_data = [
      {
        :id => 1,
        :position => 1,
        :points_possible => 1,
        :question_name => 'Question 1',
        :name => 'Question 1',
        :question_type => 'short_answer_question',
        :question_text => '',
        :answers => [
          :text => 'blah',
          :id => 1234,
        ],
      },
      {
        :id => 2,
        :position => 2,
        :points_possible => 1,
        :question_name => 'Question 2',
        :name => 'Question 2',
        :question_type => 'short_answer_question',
        :question_text => '',
        :answers => [
          :text => 'M&Ms',
          :id => 1235,
        ],
      },
    ]
    @qs.save!
  end

  def record_answer_1
    post "/courses/#{@course.id}/quizzes/#{@quiz.id}/submissions/#{@qs.id}/record_answer",
         :question_1 => 'blah', :last_question_id => 1, :validation_token => @qs.validation_token
    response.should be_redirect
  end

  def backup_answer_1
    put  "/courses/#{@course.id}/quizzes/#{@quiz.id}/submissions/backup",
         :question_1 => 'blah_overridden', :validation_token => @qs.validation_token
    response.should be_success
  end

  def record_answer_2
    post "/courses/#{@course.id}/quizzes/#{@quiz.id}/submissions/#{@qs.id}/record_answer",
         :question_2 => 'M&Ms', :last_question_id => 2, :validation_token => @qs.validation_token
    response.should be_redirect
  end

  describe "record_answer / backup" do
    it "shouldn't allow overwriting answers for cant_go_back" do
      @quiz.update_attribute :cant_go_back, true
      record_answer_1
      backup_answer_1
      @qs.reload.submission_data[:question_1].should == 'blah'
    end

    it "should allow overwriting answers otherwise" do
      record_answer_1
      backup_answer_1
      @qs.reload.submission_data[:question_1].should == 'blah_overridden'
    end

    it "should redirect back to take quiz if the user loses connection" do
      get "/courses/#{@course.id}/quizzes/#{@quiz.id}/submissions/#{@qs.id}/record_answer",
         :question_1 => 'blah', :last_question_id => 1, :validation_token => @qs.validation_token
      response.should be_redirect
    end
  end

  def submit_quiz
    post "/courses/#{@course.id}/quizzes/#{@quiz.id}/submissions/",
         :question_1 => 'password', :attempt => 1, :validation_token => @qs.validation_token
    response.should be_redirect
  end

  describe "submit quiz" do
    it "doesn't allow overwriting answers for cant_go_back" do
      @quiz.update_attribute :cant_go_back, true
      @quiz.save!

      record_answer_1
      submit_quiz

      @qs.reload.submission_data[0][:correct].should be_true
    end

    it "allows overwriting answers otherwise" do
      record_answer_1
      submit_quiz

      @qs.reload.submission_data[0][:correct].should be_false
    end

    context "with a symbol in an answer" do
      it "should mark the answer as correct" do
        record_answer_2
        submit_quiz

        @qs.reload.submission_data[1][:correct].should be_true
      end
    end
  end

end
