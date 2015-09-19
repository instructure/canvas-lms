require File.expand_path(File.dirname(__FILE__) + '/../helpers/quizzes_common')

describe 'editing a quiz' do
  include_context 'in-process server selenium tests'

  context 'with a teacher' do

    before(:each) do
      course_with_teacher_logged_in
    end

    context 'when the quiz is published' do

      it 'hides the \'Save and Publish\' button', priority: "1", test_id: 255478 do
        @quiz = course_quiz true
        get "/courses/#{@course.id}/quizzes/#{@quiz.id}/edit"

        expect(f('.save_and_publish')).to be_nil
      end
    end

    context 'when the quiz isn\'t published' do

      it 'shows the \'Save and Publish\' button', priority: "1", test_id: 255479 do
        @quiz = course_quiz false
        get "/courses/#{@course.id}/quizzes/#{@quiz.id}/edit"

        expect(f('.save_and_publish')).to be_displayed
      end
    end
  end
end