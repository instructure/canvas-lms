require_relative "common"
require_relative "helpers/quizzes_common"
require_relative "helpers/assignment_overrides"

describe 'quizzes with draft state' do
  include_context "in-process server selenium tests"
  include_context "quizzes selenium tests"
  include AssignmentOverridesSeleniumHelper

  before(:each) do
    course_with_student_logged_in
    @course.update_attributes(name: 'teacher course')
    @course.save!
    @course.reload

    @context = @course
    @q = quiz_model
  end

  context 'with a student' do

    context 'with an unpublished quiz' do

      before(:each) do
        @q.unpublish!
      end

      it 'shows an error', priority: "1", test_id: 209419 do
        get "/courses/#{@course.id}/quizzes/#{@q.id}"
        wait_for_ajaximations
        expect(f('.ui-state-error')).to include_text 'Unauthorized'
      end

      it 'can\'t take an unpublished quiz', priority: "1", test_id: 209420 do
        get "/courses/#{@course.id}/quizzes/#{@q.id}/take"
        wait_for_ajaximations
        expect(f('.ui-state-error')).to include_text 'Unauthorized'
      end
    end

    context 'when the available date is in the future' do

      before(:each) do
        @q.unlock_at = Time.now.utc + 200.seconds
        @q.publish!
      end

      it 'shows an error', priority: "1", test_id: 209421 do
        get "/courses/#{@course.id}/quizzes/#{@q.id}/"
        wait_for_ajaximations
        expect(f('.lock_explanation')).to include_text 'This quiz is locked'
      end
    end
  end
end
