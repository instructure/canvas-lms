require_relative '../common'
require_relative '../helpers/quizzes_common'
require_relative '../helpers/assignment_overrides'


describe 'quizzes with draft state' do
  include_context "in-process server selenium tests"
  include QuizzesCommon
  include AssignmentOverridesSeleniumHelper

  before(:each) do
    course_with_student_logged_in
    @course.update_attributes(name: 'teacher course')
    @course.save!
    @course.reload

    @context = @course
    @quiz = quiz_model
  end

  context 'with a student' do

    context 'with an unpublished quiz' do

      before(:each) do
        @quiz.unpublish!
      end

      it 'shows an error', priority: "1", test_id: 209419 do
        open_quiz_edit_form
        wait_for_ajaximations
        expect(f('.ui-state-error')).to include_text 'Unauthorized'
      end

      it 'can\'t take an unpublished quiz', priority: "1", test_id: 209420 do
        get "/courses/#{@course.id}/quizzes/#{@quiz.id}/take"
        wait_for_ajaximations
        expect(f('.ui-state-error')).to include_text 'Unauthorized'
      end
    end

    context 'when the available date is in the future' do

      before(:each) do
        @quiz.unlock_at = Time.now.utc + 200.seconds
        @quiz.publish!
      end

      it 'shows an error', priority: "1", test_id: 209421 do
        open_quiz_show_page
        wait_for_ajaximations
        expect(f('.lock_explanation')).to include_text 'This quiz is locked'
      end
    end
  end
end
