require_relative '../../helpers/gradebook2_common'

describe "gradebook2 - Grading History" do
  include Gradebook2Common
  include_context "in-process server selenium tests"

  context 'Grading History' do
    it 'displays excused grades', priority: "1", test_id: 208844 do
      course_with_teacher_logged_in(name: 'Teacher')
      course_with_student(course: @course, active_all: true)

      assignment = @course.assignments.build
      assignment.publish
      assignment.grade_student(@student, {grade: 15})
      assignment.grade_student(@student, {excuse: true})

      get "/courses/#{@course.id}/gradebook/history"
      f('.assignment_header').click
      wait_for_ajaximations
      expect(f('.assignment_header .changes').text).to eq '1 change'

      changed_values = ff('.assignment_details td').map(& :text)
      expect(changed_values).to eq ['15', 'EX', 'EX']

      assignment.grade_student(@student, {grade: 10})
      refresh_page
      f('.assignment_header').click
      wait_for_ajaximations
      changed_values = ff('.assignment_details td').map(& :text)
      expect(changed_values).to eq ['EX', '10', '10']
    end
  end
end
