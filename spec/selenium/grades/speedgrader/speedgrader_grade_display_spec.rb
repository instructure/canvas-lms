require_relative "../../common"
require_relative "../../helpers/speed_grader_common"

describe "speed grader - grade display" do
  include_context "in-process server selenium tests"
  include SpeedGraderCommon

  before(:each) do
    course_with_teacher_logged_in
    @assignment = @course.assignments.create(name: 'assignment', points_possible: 10)
  end

  it "displays the score on the sidebar", priority: "1", test_id: 283993 do
    create_and_enroll_students(1)
    submit_and_grade_homework(@students[0], 3)

    get "/courses/#{@course.id}/gradebook/speed_grader?assignment_id=#{@assignment.id}"
    wait_for_ajaximations

    expect(f('#grade_container input[type=text]')).to have_attribute("value", "3")
  end

  it "displays total number of graded assignments to students", priority: "1", test_id: 283994 do
    create_and_enroll_students(2)
    submit_and_grade_homework(@students[0], 3)

    get "/courses/#{@course.id}/gradebook/speed_grader?assignment_id=#{@assignment.id}"
    wait_for_ajaximations

    expect(f("#x_of_x_graded")).to include_text("1/2")
  end

  it "displays average submission grade for total assignment submissions", priority: "1", test_id: 283995
end
