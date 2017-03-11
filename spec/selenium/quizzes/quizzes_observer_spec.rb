require_relative '../common'
require_relative '../helpers/quizzes_common'

describe 'quizzes observers' do
  include_context "in-process server selenium tests"
  include QuizzesCommon

  before(:once) do
    course_with_student(active_all: true)
    course_with_observer(active_all: true, course: @course).update_attribute(:associated_user_id, @student.id)
  end

  before(:each) do
    user_session(@observer)
  end

  context "when 'show correct answers after last attempt setting' is on" do
    before(:each) do
      quiz_with_submission
      @quiz.update_attributes(:show_correct_answers => true,
        :show_correct_answers_last_attempt => true, :allowed_attempts => 2)
      @quiz.save!
    end

    it "should not show correct answers on first attempt", priority: "1", test_id: 474288 do
      get "/courses/#{@course.id}/quizzes/#{@quiz.id}/history?quiz_submission_id=#{@qsub.id}"
      expect(f("#content")).not_to contain_css('.correct_answer')
    end
  end

  it "should show quiz descriptions" do
    @context = @course
    quiz = quiz_model
    description = "some description"
    quiz.description = description
    quiz.save!

    open_quiz_show_page
    expect(f(".description")).to include_text(description)
  end
end

