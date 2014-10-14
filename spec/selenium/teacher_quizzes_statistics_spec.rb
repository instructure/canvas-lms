require File.expand_path(File.dirname(__FILE__) + '/helpers/quizzes_common')

describe "quiz statistics" do
  before :once do
    Account.default.enable_feature!(:draft_state)
  end

  include_examples "quizzes selenium tests"

  describe "item analysis" do

    def create_course_with_teacher_and_student
      course
      @course.offer!
      @teacher = user_with_pseudonym({:unique_id => 'teacher@example.com', :password => 'asdfasdf'})
      @course.enroll_user(@teacher, 'TeacherEnrollment').accept!
      @student = user_with_pseudonym({:unique_id => 'otheruser@example.com', :password => 'asdfasdf'})
      @course.enroll_user(@student, 'StudentEnrollment').accept!
    end

    def create_quiz
      @quiz = @course.quizzes.create
      @quiz.title = "Ganondorf"
      @quiz.save!
    end

    def quiz_question(name, question, id)
      answers = [
        {:weight=>100, :answer_text=>"A", :answer_comments=>"", :id=>1490},
        {:weight=>0, :answer_text=>"B", :answer_comments=>"", :id=>1020},
        {:weight=>0, :answer_text=>"C", :answer_comments=>"", :id=>7051}
      ]
      data = { :question_name=>name, :points_possible=>1, :question_text=>question,
        :answers=>answers, :question_type=>"multiple_choice_question"
      }
      @quiz.quiz_questions.create!(:question_data => data)
    end

    def preview_the_quiz
      login_as(@teacher.primary_pseudonym.unique_id, 'asdfasdf')
      get "/courses/#{@course.id}/quizzes/#{@quiz.id}"
      f("#preview_quiz_button").click
      wait_for_ajaximations
      answer_question
      submit_quiz
    end

    def publish_the_quiz
      @quiz.workflow_state = "available"
      @quiz.generate_quiz_data
      @quiz.published_at = Time.now
      @quiz.save!
    end

    def take_the_quiz_as_a_student
      login_as(@student.primary_pseudonym.unique_id, 'asdfasdf')
      get "/courses/#{@course.id}/quizzes/#{@quiz.id}"
      expect_new_page_load { fj("a:contains('Take the Quiz')").click }
      answer_question
      submit_quiz
    end

    def generate_item_analysis
      @quiz.reload
      Quizzes::QuizStatistics::ItemAnalysis::Summary.new(@quiz)
    end

    def answer_question
      f('.question_input').click
    end

    def submit_quiz
      expect_new_page_load { f('#submit_quiz_button').click }
    end

    before :each do
      create_course_with_teacher_and_student
      create_quiz
      quiz_question("Question 1", "How does one reach the Dark World?", 1)
    end

    it "should not include teacher previews" do
      preview_the_quiz
      publish_the_quiz
      take_the_quiz_as_a_student
      expect(generate_item_analysis.length).to eq 1
    end

  end

  context "as a teacher" do

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
        expect(ff('.question').count).to eq @quiz.quiz_questions.count
      end

      it "should validate number attempts on questions" do
        get "/courses/#{@course.id}/quizzes/#{@quiz.id}/statistics"
        ff('.question .question_attempts').each { |attempt| expect(attempt.text).to eq '1 attempt' }
      end

      it "should validate question graph tooltip" do
        update_quiz_submission_scores
        get "/courses/#{@course.id}/quizzes/#{@quiz.id}/statistics"

        @quiz.quiz_questions.each_with_index do |question, index|
          driver.execute_script("$('.tooltip_text:eq(#{index})').css('visibility', 'visible')")
          expect(fj(".tooltip_text:eq(#{index})")).to include_text '100%'
        end
      end

      it "should show a special message if the course is a MOOC" do
        @course.large_roster = true
        @course.save!
        get "/courses/#{@course.id}/quizzes/#{@quiz.id}/statistics"
        expect(f("#content")).to include_text "This course is too large to display statistics. They can still be downloaded from the right hand sidebar."
      end
    end

    describe "right side info bar with initial data" do

      before (:each) do
        get "/courses/#{@course.id}/quizzes/#{@quiz.id}/statistics"
      end

      it "should validate average time taken for quiz" do
        expect(summary_rows[0]).to include_text 'less than a minute'
      end

      %w(correct incorrect high_score low_score mean_score standard_deviation).each_with_index do |data_point, i|

        it "should validate #{data_point} number for initial info" do
          index = (i + 1) # + 1 to get rid of the first row
          index == 2 ? (expect(summary_rows[index]).to include_text("2")) : (expect(summary_rows[index]).to include_text("0"))
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
              expect(summary_rows[index]).to include_text(@expected_side_bar_numbers[0])
            when 2
              expect(summary_rows[index]).to include_text(@expected_side_bar_numbers[1])
            when 3..5
              expect(summary_rows[index]).to include_text(@expected_side_bar_numbers[2])
            when 6
              expect(summary_rows[index]).to include_text(@expected_side_bar_numbers[0])
          end
        end
      end
    end
  end
end
