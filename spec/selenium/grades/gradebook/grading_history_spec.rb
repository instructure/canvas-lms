require_relative '../../helpers/gradebook2_common'

describe "gradebook2 - Grading History" do
  include Gradebook2Common
  include_context 'in-process server selenium tests'
  include_context 'reusable_course'

  context 'Grading History' do
    before(:each) do
      enroll_teacher_and_students
      student_submission
      user_session(teacher)
    end

    it 'toggles and displays grading history', priority: "2", test_id: 602872 do
      assignment_1.grade_student(student, grade: 8, grader: teacher)
      assignment_1.grade_student(student, grade: 10, grader: teacher)

      get "/courses/#{test_course.id}/gradebook/history"

      # expand grade history toggle
      f('.assignment_header a').click
      wait_for_animations

      current_grade_column = fj(".current_grade.assignment_#{assignment_1.id}_user_#{student.id}_current_grade")
      expect(current_grade_column).to include_text('10')
    end

    it 'displays and reverts excused grades', priority: "1", test_id: 606308 do
      assignment_1.grade_student(student, excuse: true, grader: teacher)
      assignment_1.grade_student(student, grade: 15, grader: teacher)

      get "/courses/#{test_course.id}/gradebook/history"
      f('.assignment_header').click
      wait_for_ajaximations
      expect(f('.assignment_header .changes').text).to eq '1 change'

      changed_values = ff('.assignment_details td').map(& :text)
      expect(changed_values).to eq ['EX', '15', '15']

      assignment_1.grade_student(student, grade: 10, grader: teacher)
      refresh_page
      f('.assignment_header').click
      wait_for_ajaximations
      changed_values = ff('.assignment_details td').map(& :text)
      expect(changed_values).to eq ['15', '10', '10']
    end
  end
end
