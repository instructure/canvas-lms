require 'spec_helper'

describe "QuizRegrading" do

  def create_quiz_question!(data)
    question = @quiz.quiz_questions.create!
    data.merge!(:id => question.id)
    question.write_attribute(:question_data, data.to_hash)
    question.save!
    question
  end

  def reset_submission_data!
    @submission.submission_data = {
      "question_#{@true_false_question.id}"=> "2",
      "question_#{@multiple_choice_question.id}" => "4",
      "question_#{@multiple_answers_question.id}_answer_5" => "1",
      "question_#{@multiple_answers_question.id}_answer_6" => "0",
      "question_#{@multiple_answers_question.id}_answer_7" => "0"
    }.with_indifferent_access
    Quizzes::SubmissionGrader.new(@submission).grade_submission
    @submission.save!
  end

  def set_regrade_option!(regrade_option)
    [@ttf_qqr,@maq_qqr,@mcq_qqr].each do |qqr|
      qqr.regrade_option = regrade_option
      qqr.save!
    end
    reset_submission_data!
    @quiz.reload
  end

  before do
    course_with_student_logged_in(active_all: true)
    quiz_model(course: @course)
    @regrade = @quiz.quiz_regrades.where(quiz_id: @quiz.id, quiz_version: @quiz.version_number).first_or_create(user: @student)
    @regrade.should_not be_new_record
    @true_false_question = create_quiz_question!({
      :points_possible => 1,
      :question_type => 'true_false_question',
      :question_name => 'True/False Question',
      :answers => [
        {:text => 'true', :id => 1, :weight => 100},
        {:text => 'false', :id => 2, :weight => 0}
      ]
    })
    @multiple_choice_question = create_quiz_question!({
      :points_possible => 1,
      :question_type => 'multiple_choice_question',
      :question_name => 'Multiple Choice Question',
      :answers => [
        {:text => "correct", :id => 3, :weight => 100 },
        {:text => "nope", :id => 4, :weight => 0}
      ]
    })
    @multiple_answers_question = create_quiz_question!({
      :points_possible => 1,
      :question_type => 'multiple_answers_question',
      :question_name => 'Multiple Answers Question',
      :answers => [
        {:text => "correct1", :id => 5, :weight => 100},
        {:text=> "correct2", :id => 6, :weight => 100},
        {:text => "nope", :id=> 7, :weight => 0 }
      ]
    })
    @maq_qqr = @regrade.quiz_question_regrades.create!(quiz_question_id: @multiple_answers_question.id, regrade_option: 'no_regrade')
    @mcq_qqr = @regrade.quiz_question_regrades.create!(quiz_question_id: @multiple_choice_question.id, regrade_option: 'no_regrade')
    @ttf_qqr = @regrade.quiz_question_regrades.create!(quiz_question_id: @true_false_question.id, regrade_option: 'no_regrade')
    @quiz.generate_quiz_data
    @quiz.workflow_state = 'available'
    @quiz.without_versioning { @quiz.save! }
    @submission = @quiz.generate_submission(@student)
    reset_submission_data!
    @submission.save!
    @submission.score.should == 0.5
  end

  it 'succesfully regrades the submissions and updates the scores' do
    set_regrade_option!('full_credit')
    Quizzes::QuizRegrader::Regrader.regrade!(quiz: @quiz)
    @submission.reload.score.should == 3

    set_regrade_option!('current_correct_only')
    data = @true_false_question.question_data
    data[:answers].first[:weight]  = 0
    data[:answers].second[:weight]  = 100
    @true_false_question.write_attribute(:question_data, data.to_hash)
    @true_false_question.save!
    data = @multiple_choice_question.question_data
    data[:answers].first[:weight] = 0
    data[:answers].second[:weight]  = 100
    @multiple_choice_question.write_attribute(:question_data, data.to_hash)
    @multiple_choice_question.save!
    data = @multiple_answers_question.reload.question_data
    data[:answers].second[:weight]  = 0
    @multiple_answers_question.write_attribute(:question_data, data.to_hash)
    @multiple_answers_question.save!
    @quiz.reload

    Quizzes::QuizRegrader::Regrader.regrade!(quiz: @quiz)
    @submission.reload.score.should == 3
  end

  it 'does not expose the question names' do
    set_regrade_option!('current_correct_only')

    data = @true_false_question.question_data
    data[:question_name] = 'foo'
    @true_false_question.question_data = data.to_hash
    @true_false_question.save!

    data = @multiple_choice_question.question_data
    data[:question_name] = 'bar'
    @multiple_choice_question.question_data = data.to_hash
    @multiple_choice_question.save!

    @quiz.generate_quiz_data
    @quiz.save!

    Quizzes::QuizRegrader::Regrader.regrade!(quiz: @quiz)

    @submission.reload
    @quiz.quiz_data[0][:question_name].should == 'foo'
    @quiz.quiz_data[1][:question_name].should == 'bar'
    @submission.quiz_data[0][:question_name].should == 'Question 1'
    @submission.quiz_data[1][:question_name].should == 'Question 2'
  end

end
