require_relative "../common"
require_relative "../helpers/quizzes_common"

describe 'taking a quiz' do
  include_context "in-process server selenium tests"
  include_context "quizzes selenium tests"

  context 'as a student' do
    before(:once) { course_with_student(active_all: 1) }
    before(:each) { user_session(@student) }

    context 'when the quiz has an access code and unlimited attempts' do
      let(:access_code) { '1234' }
      let(:quiz) do
        @context = @course
        quiz = quiz_model
        2.times { quiz.quiz_questions.create! question_data: true_false_question_data }
        quiz.access_code = access_code
        quiz.allowed_attempts = -1
        quiz.generate_quiz_data
        quiz.save!
        quiz.reload
      end

      def start_quiz_and_verify_reprompt_for_access_code
        @quiz = quiz
        take_and_answer_quiz(false, access_code)

        # exit quiz without submitting
        expect_new_page_load do
          fln('Quizzes').click
          driver.switch_to.alert.accept
        end

        yield if block_given?

        # Canvas should prompt for access code again
        expect(f('#quiz_access_code')).to be_truthy

      ensure
        # This prevents selenium from freezing when the dialog appears upon leaving the quiz
        fln('Quizzes').click
        driver.switch_to.alert.accept
      end

      def skip_if_firefox
        skip('Known issue fails in Firefox only: CNVS-24622') if driver.browser.to_s.capitalize == 'Firefox'
      end

      it 'prompts for access code upon resuming the quiz', priority: "1", test_id: 421218 do
        skip_if_firefox
        start_quiz_and_verify_reprompt_for_access_code do
          expect_new_page_load { fj('a.ig-title', '#assignment-quizzes').click }
          expect_new_page_load { fln('Resume Quiz').click }
        end
      end

      it 'prompts for an access code upon resuming the quiz via the browser back button', priority: "1", test_id: 421222 do
        skip_if_firefox
        start_quiz_and_verify_reprompt_for_access_code do
          expect_new_page_load { driver.navigate.back }
        end
      end
    end
  end
end
