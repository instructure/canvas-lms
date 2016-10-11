require_relative '../common'
require_relative '../helpers/quizzes_common'

describe 'when a quiz is published' do
  include_context "in-process server selenium tests"

  context 'as a student' do
    include QuizzesCommon

    before(:each) do
      course_with_student_logged_in
      create_quiz_with_due_date(
        course: @course,
        due_at: default_time_for_due_date(Time.zone.now.advance(days: 2))
      )
    end

    context 'when on the course home page' do
      before(:each) { get "/courses/#{@course.id}" }

      it 'To Do List includes published, untaken quizzes that are due soon for students', priority: "1", test_id: 140613 do
        expect(f('.right-side-list.to-do-list')).to include_text 'Take Test Quiz'
      end
    end
  end
end
