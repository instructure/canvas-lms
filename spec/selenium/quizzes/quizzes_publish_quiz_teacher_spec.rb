require_relative '../common'
require_relative '../helpers/quizzes_common'

describe 'publishing a quiz' do
  include_context "in-process server selenium tests"

  let(:quiz_helper) { Class.new { extend QuizzesCommon } }

  context 'as a teacher' do
    before(:each) do
      course_with_teacher_logged_in
      @quiz = quiz_helper.create_quiz_with_due_date(course: @course)
      @quiz.workflow_state = 'unavailable'
      @quiz.save!
    end

    context 'when on the quiz show page' do
      before(:each) do
        get "/courses/#{@course.id}/quizzes/#{@quiz.id}"
        f('#quiz-publish-link').click
      end

      context 'before the ajax calls finish' do
        it 'temporarily changes the button text to |Publishing...|', priority: "1", test_id: 398935 do
          expect(fj('.publish-text', '#quiz-publish-link').text).to include_text 'Publishing...'
        end
      end

      context 'after the ajax calls finish' do
        before(:each) do
          wait_for_ajaximations
          wait = Selenium::WebDriver::Wait.new(timeout: 5)
          wait.until do
            f('#quiz-publish-link').present? &&
            f('#quiz-publish-link').text.present? &&
            f('#quiz-publish-link').text.strip!.split("\n") != []
          end
        end

        it 'changes the button\'s text to \'Published\'', priority: "1", test_id: 140649 do
          driver.mouse.move_to f('#footer')
          expect(f('#quiz-publish-link').text.strip!.split("\n")[0]).to eq 'Published'
        end

        it 'changes the button text on hover to |Unpublish|', priority: "1", test_id: 398936 do
          expect(f('#quiz-publish-link').text.strip!.split("\n")[0]).to eq 'Unpublish'
        end

        it 'removes the \'This quiz is unpublished\' message', priority: "1", test_id: 398937 do
          expect(fj('.unpublished_warning', '.alert')).to be_nil
        end

        it 'adds links to the right sidebar', priority: "1", test_id: 398938 do
          links_text = []
          ffj('li', 'ul.page-action-list').each do |link|
            # also remove the trademark (TM) unicode character
            links_text << link.text.split("\n")[0].delete("^\u{0000}-\u{007F}")
          end

          expect(links_text).to include 'Moderate This Quiz'
          expect(links_text).to include 'SpeedGrader'
        end

        it 'displays the |Take the Quiz| button', priority: "1", test_id: 398939 do
          expect(f('#take_quiz_link').text).to eq 'Take the Quiz'
        end

        context 'when clicking the cog menu tool' do
          before(:each) do
            fj('a.al-trigger', '.header-group-right').click
            wait_for_ajaximations
          end

          it 'shows updated options', priority: "1", test_id: 398940 do
            items = ffj('li.ui-menu-item', 'ul#toolbar-1')
            items_text = []
            items.each { |i| items_text << i.text.split("\n")[0] }

            expect(items_text).to include 'Show Rubric'
            expect(items_text).to include 'Preview'
            expect(items_text).to include 'Lock this Quiz Now'
            expect(items_text).to include 'Show Student Quiz Results'
            expect(items_text).to include 'Message Students Who...'
            expect(items_text).to include 'Delete'
          end
        end
      end
    end
  end
end
