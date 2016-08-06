require File.expand_path(File.dirname(__FILE__) + '/common')
require File.expand_path(File.dirname(__FILE__) + '/helpers/assignments_common')

describe 'omit from final grade assignments' do
  include_context "in-process server selenium tests"
  include AssignmentsCommon

  let(:test_course) { course(active_course: true) }
  let(:teacher)     { user(active_all: true) }
  let(:student)     { user(active_all: true) }
  let(:enroll_teacher_and_students) do
    test_course.enroll_user(teacher, 'TeacherEnrollment', enrollment_state: 'active')
    test_course.enroll_user(student, 'StudentEnrollment', enrollment_state: 'active')
  end
  let(:assignment_1) do
    test_course.assignments.create!(
      title: 'Points Assignment',
      grading_type: 'points',
      points_possible: 10,
      submission_types: 'online_text_entry'
    )
  end
  let(:assignment_2) do
    test_course.assignments.create!(
      title: 'Assignment not counted towards final grade',
      grading_type: 'points',
      points_possible: 10
    )
  end
  let(:assignment_3) do
    test_course.assignments.create!(
      title: 'Also not for final grade',
      grading_type: 'points',
      points_possible: 10,
      omit_from_final_grade: true
    )
  end
  let(:omit_from_final_checkbox) { f('#assignment_omit_from_final_grade') }

  context 'assignment edit and show pages' do
    before(:each) do
      enroll_teacher_and_students
      assignment_2
      user_session(teacher)
      get "/courses/#{test_course.id}/assignments/#{assignment_2.id}/edit"
    end

    it 'do not count towards final grade checkbox is visible on edit' do
      expect(omit_from_final_checkbox).to be_present
    end

    it 'saves setting with warning on assignment show page' do
      expect(f('#content')).not_to contain_jqcss('.omit-from-final-warning:visible')

      omit_from_final_checkbox.click
      submit_assignment_form

      expect(f('.omit-from-final-warning')).to include_text('This assignment does not count toward the final grade.')
    end
  end

  context 'in gradebook' do
    before(:each) do
      enroll_teacher_and_students
      assignment_1.grade_student(student, grade: 10)
      assignment_3.grade_student(student, grade: 5)
      user_session(teacher)
      get "/courses/#{test_course.id}/gradebook"
    end

    it 'displays triangle warning' do
      expect(f(".slick-header-column[title='Also not for final grade'] i")).to have_class('icon-warning')
    end

    it 'does not include omitted assignment in final' do
      total_grade = f('#gradebook_grid .container_1 .slick-row:nth-child(1) .total-cell .percentage')
      expect(total_grade).to include_text('10')
    end
  end

  context 'as a student' do
    before(:each) do
      enroll_teacher_and_students
      assignment_1.grade_student(student, grade: 10)
      assignment_3.grade_student(student, grade: 5)
      user_session(student)
      get "/courses/#{test_course.id}/grades"
    end

    it 'displays warning in the student grades page' do
      f('.icon-warning').click

      expect(f("#final_grade_info_#{assignment_3.id} th")).to include_text('Final Grade Info')
    end

    it 'displays correct total on student grades page' do
      expect(f('#submission_final-grade .grade')).to include_text('100%')
    end
  end
end