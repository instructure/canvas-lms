require File.expand_path(File.dirname(__FILE__) + '/common')
require File.expand_path(File.dirname(__FILE__) + '/helpers/quizzes_common')

describe "quiz statistics" do
  it_should_behave_like "quizzes selenium tests"

  def update_quiz_submission_scores(question_score = '1')
    @quiz_submission.update_scores({
                                       'context_id' => @course.id,
                                       'override_scores' => true,
                                       'context_type' => 'Course',
                                       'submission_version_number' => '1',
                                       "question_score_#{@questions[0].id}" => question_score
                                   })
  end

  def summary_rows
    ff('#statistics_summary tr')
  end

  before (:each) do
    quiz_with_graded_submission([{:question_data => {:name => 'question 1', :points_possible => 1, 'question_type' => 'true_false_question'}},
                                 {:question_data => {:name => 'question 2', :points_possible => 1, 'question_type' => 'true_false_question'}}])
    course_with_teacher_logged_in(:active_all => true, :course => @course)
  end

  describe "question graphs" do

    it "should validate correct number of questions are showing up" do
      get "/courses/#{@course.id}/quizzes/#{@quiz.id}/statistics"
      ff('.question').count.should == @quiz.quiz_questions.count
    end

    it "should validate number attempts on questions" do
      get "/courses/#{@course.id}/quizzes/#{@quiz.id}/statistics"
      ff('.question .question_attempts').each { |attempt| attempt.text.should == '1 attempt' }
    end

    it "should validate question graph tooltip" do
      update_quiz_submission_scores
      get "/courses/#{@course.id}/quizzes/#{@quiz.id}/statistics"
      (0..2).each do |i|
        driver.execute_script("$('.tooltip_text:eq(#{i})').css('visibility', 'visible')")
        if i == 0 || i == 1
          fj(".tooltip_text:eq(#{i})").should include_text '0%'
        else
          fj(".tooltip_text:eq(#{i})").should include_text '100%'
        end
      end
    end
  end

  describe "right side info bar with initial data" do

    before (:each) do
      get "/courses/#{@course.id}/quizzes/#{@quiz.id}/statistics"
    end

    it "should validate average time taken for quiz" do
      summary_rows[0].should include_text 'less than a minute'
    end

    %w(correct incorrect high_score low_score mean_score standard_deviation).each_with_index do |data_point, i|

      it "should validate #{data_point} number for initial info" do
        index = (i + 1) # + 1 to get rid of the first row
        index == 2 ? (summary_rows[index].should include_text("2")) : (summary_rows[index].should include_text("0"))
      end
    end
  end

  describe 'right side info bar with altered data' do

    before (:each) do
      update_quiz_submission_scores
      get "/courses/#{@course.id}/quizzes/#{@quiz.id}/statistics"
      @expected_side_bar_numbers = ["0", "2", "1"]
    end

    %w(correct incorrect high_score low_score mean_score standard_deviation).each_with_index do |data_point, i|

      it "should validate #{data_point} number for altered info" do
        index = (i + 1) # + 1 to get rid of the first row
        case index
          when 1
            summary_rows[index].should include_text(@expected_side_bar_numbers[0])
          when 2
            summary_rows[index].should include_text(@expected_side_bar_numbers[1])
          when 3..5
            summary_rows[index].should include_text(@expected_side_bar_numbers[2])
          when 6
            summary_rows[index].should include_text(@expected_side_bar_numbers[0])
        end
      end
    end
  end
end