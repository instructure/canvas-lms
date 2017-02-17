require_relative '../common'
require_relative '../helpers/assignments_common'

describe "quiz LTI assignments" do
  include_context "in-process server selenium tests"
  include AssignmentsCommon

  before do
    course_with_teacher_logged_in
    @course.require_assignment_group
    @tool = @course.context_external_tools.create!(
      name: 'Quizzes.Next',
      consumer_key: 'test123',
      shared_secret: 'test123',
      tool_id: 'Quizzes 2',
      url: 'http://example.com/launch'
    )
  end

  it "creates an LTI assignment", priority: "2" do
    get "/courses/#{@course.id}/assignments"
    f('.new_quiz_lti').click

    f('#assignment_name').send_keys('LTI quiz')
    submit_assignment_form

    assignment = @course.assignments.last
    expect(assignment).to be_present
    expect(assignment.quiz_lti?).to be true
  end
end
