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

    context 'Individual Assignments' do
      let(:test_course) { course() }
      let(:teacher) { user(active_all: true) }
      let(:student) { user(active_all: true) }
      let!(:enroll_teacher) { test_course.enroll_user(teacher, 'TeacherEnrollment', enrollment_state: 'active') }
      let!(:enroll_student) { test_course.enroll_user(student, 'StudentEnrollment', enrollment_state: 'active') }
      let!(:assignment) do
        test_course.assignments.create!(
          title: 'Assignment Yeah',
          points_possible: 10,
          submission_types: 'online_text_entry'
        )
      end
      let!(:submit_assignment) { assignment.submit_homework(student, submission_types: 'online_text_entry', body: 'blah')}
      let!(:grade_homework) { assignment.grade_student(student, grade: 8) }
      let!(:grade_homework) { assignment.grade_student(student, grade: 10) }

      it 'toggles and displays grading history', priority: "2", test_id: 602872 do
        user_session(teacher)
        get "/courses/#{test_course.id}/gradebook/history"

        # expand grade history toggle
        fj('.assignment_header a').click
        wait_for_animations

        current_grade_column = fj(".current_grade.assignment_#{assignment.id}_user_#{student.id}_current_grade")
        expect(current_grade_column).to include_text('10')
      end
    end
  end
end
