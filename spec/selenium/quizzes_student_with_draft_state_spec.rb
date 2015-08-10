require File.expand_path(File.dirname(__FILE__) + '/helpers/quizzes_common')
require File.expand_path(File.dirname(__FILE__) + '/helpers/assignment_overrides.rb')

describe 'quizzes with draft state' do

  include AssignmentOverridesSeleniumHelper
  include_context 'in-process server selenium tests'

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
        expect(f('#unauthorized_holder')).to be_displayed
      end

      it 'can\'t take an unpublished quiz', priority: "1", test_id: 209420 do
        get "/courses/#{@course.id}/quizzes/#{@q.id}/take"
        wait_for_ajaximations
        expect(f('#unauthorized_holder')).to be_displayed
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
        expect(f('.lock_explanation')).to be_displayed
      end
    end
  end
end