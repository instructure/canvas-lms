require_relative '../common'
require_relative '../helpers/quizzes_common'

describe 'unpublishing a quiz on the quiz show page' do
  include_context "in-process server selenium tests"
  include QuizzesCommon

  def unpublish_quiz_via_ui
    get "/courses/#{@course.id}/quizzes/#{@quiz.id}"
    f('#quiz-publish-link').click
    wait_for_ajaximations
    wait_for_quiz_publish_button_to_populate
  end

  context 'as a teacher' do
    before(:each) do
      course_with_teacher_logged_in
      create_quiz_with_due_date
    end

    it 'performs all expected changes on the page', priority: "1", test_id: 401338 do
      unpublish_quiz_via_ui

      # changes the button's text to |Unpublished|
      driver.mouse.move_to f('#footer')
      expect(f('#quiz-publish-link').text.strip!.split("\n")[1].split('.')[0]).to eq 'Unpublished'

      # changes the button text on hover to |Publish|
      expect(f('#quiz-publish-link').text.strip!.split("\n")[0]).to eq 'Publish'

      # displays the 'This quiz is unpublished' message
      expect(fj('.unpublished_warning', '.alert')).to be_displayed

      # removes links from the right sidebar
      links_text = []
      ffj('li', 'ul.page-action-list').each { |link| links_text << link.text }
      expect(links_text.size).to eq 0

      # removes the |Take the Quiz| button
      expect(f('#take_quiz_link')).to be_nil

      # shows pre-published options when clicking the cog menu tool
      fj('a.al-trigger', '.header-group-right').click
      wait_for_ajaximations

      items = ffj('li.ui-menu-item', 'ul#toolbar-1')
      items_text = []
      items.each { |i| items_text << i.text.split("\n")[0] }

      expect(items_text).to include 'Show Rubric'
      expect(items_text).to include 'Lock this Quiz Now'
      expect(items_text).to include 'Delete'

      expect(items_text).to_not include 'Preview'
      expect(items_text).to_not include 'Show Student Quiz Results'
      expect(items_text).to_not include 'Message Students Who...'
    end
  end
end
