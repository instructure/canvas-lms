require_relative '../../helpers/gradebook_common'

describe "gradebook" do
  include_context "in-process server selenium tests"
  include GradebookCommon

  context 'pass/fail assignment grading' do
    before :once do
      init_course_with_students 1
      @assignment = @course.assignments.create!(grading_type: 'pass_fail', points_possible: 0)
      @assignment.grade_student(@students[0], grade: 'pass', grader: @teacher)
    end

    before :each do
      user_session(@teacher)
    end

    it 'should allow pass grade on assignments worth 0 points', priority: "1", test_id: 330310 do
      get "/courses/#{@course.id}/gradebook"
      expect(f('button.gradebook-checkbox.gradebook-checkbox-pass')).to include_text('pass')
    end

    it 'should display pass/fail correctly when total points possible is changed', priority: "1", test_id: 419288 do
      @assignment.update_attributes(points_possible: 1)
      get "/courses/#{@course.id}/gradebook"
      expect(f('button.gradebook-checkbox.gradebook-checkbox-pass')).to include_text('pass')
    end
  end
end
