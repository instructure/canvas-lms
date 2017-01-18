require_relative '../../helpers/gradebook2_common'

describe "gradebook2 - logged in as a student" do
  include_context "in-process server selenium tests"
  include Gradebook2Common

  it 'should display total grades as points', priority: "2", test_id: 164229 do
    course_with_student_logged_in
    assignment = @course.assignments.build
    assignment.publish
    assignment.grade_student(@student, {grade: 10})
    @course.show_total_grade_as_points = true
    @course.save!

    get "/courses/#{@course.id}/grades"
    expect(f('#submission_final-grade .grade')).to include_text("10")
  end
end
