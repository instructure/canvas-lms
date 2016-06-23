require_relative '../common'
require_relative '../helpers/quizzes_common'

describe 'publishing a quiz' do
  include_context "in-process server selenium tests"
  include QuizzesCommon

  context 'as a teacher' do
    before(:each) do
      course_with_teacher_logged_in
      @quiz = create_quiz_with_due_date(course: @course)
      @quiz.workflow_state = 'unavailable'
      @quiz.save!
    end

    context 'when on the quiz show page' do
      before(:each) do
        get "/courses/#{@course.id}/quizzes/#{@quiz.id}"
      end

      context 'after the ajax calls finish' do
        before(:each) do
          f('#quiz-publish-link').click
          wait_for_ajaximations
          wait_for_quiz_publish_button_to_populate
        end

        it 'changes the button\'s text to \'Published\'', priority: "1", test_id: 140649 do
          driver.mouse.move_to f('#footer')
          expect(f('#quiz-publish-link').text.strip!.split("\n")[0]).to eq 'Published'
        end

        it 'changes the button text on hover to |Unpublish|', priority: "1", test_id: 398936 do
          driver.mouse.move_to f('#quiz-publish-link')
          expect(f('#quiz-publish-link').text.strip!.split("\n")[0]).to eq 'Unpublish'
        end

        it 'removes the \'This quiz is unpublished\' message', priority: "1", test_id: 398937 do
          expect(f("#content")).not_to contain_css('.alert .unpublished_warning')
        end

        it 'adds links to the right sidebar', priority: "1", test_id: 398938 do
          links_text = []
          ff('ul.page-action-list li').each do |link|
            # also remove the trademark (TM) unicode character
            links_text << link.text.split("\n")[0].delete("^\u{0000}-\u{007F}")
          end

          expect(links_text).to include 'Moderate This Quiz'
          expect(links_text).to include 'SpeedGrader'
        end

        it 'displays both |Preview| buttons', priority: "1", test_id: 398939 do
          expect(ff('#preview_quiz_button').count).to eq 2
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
