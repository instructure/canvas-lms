require_relative "../common"
require_relative "../helpers/quizzes_common"

describe 'grading quizzes' do
  include_context "in-process server selenium tests"
  include QuizzesCommon

  context 'as a teacher' do
    before(:once) do
      course_with_teacher(active_all: 1)
      student_in_course(active_all: 1)
      seed_quiz_with_submission(1, student: @student)
      user_session(@teacher)
    end

    context 'when on the course home page' do
      before(:each) { get "/courses/#{@course.id}" }

      it 'To Do List includes quizzes with submissions that need grading', priority: "1", test_id: 140614 do
        expect(f('.right-side-list.to-do-list')).to include_text 'Grade Quiz Me!'
      end
    end
  end
end
