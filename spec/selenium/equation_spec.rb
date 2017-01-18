require_relative "common"
require_relative "helpers/quizzes_common"

describe "equation editor" do
  include_context "in-process server selenium tests"
  include QuizzesCommon

  let(:equation_selector){ "div[aria-label='Insert Math Equation'] button" }


  it "should remove bookmark when clicking close" do
    course_with_teacher_logged_in
    get "/courses/#{@course.id}/quizzes"
    f('.new-quiz-link').click

    wait_for_tiny(f("#quiz_description"))
    type_in_tiny 'textarea#quiz_description', 'foo'

    f(equation_selector).click
    equation_editor = fj(".mathquill-editor:visible")
    expect(equation_editor).not_to be_nil

    fj('.ui-dialog-titlebar-close:visible').click
    type_in_tiny 'textarea#quiz_description', 'bar'
    f('.save_quiz_button').click

    expect(f('.description')).to include_text 'foobar'
  end
end
