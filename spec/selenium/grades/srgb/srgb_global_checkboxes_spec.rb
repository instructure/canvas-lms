require_relative '../../helpers/gradebook2_common'
require_relative '../../helpers/gradebook2_srgb_common'

describe "Screenreader Gradebook" do
  include_context 'in-process server selenium tests'
  include_context 'gradebook_components'
  include_context 'srgb_components'
  include_context 'reusable_course'
  include Gradebook2Common
  include Gradebook2SRGBCommon

  let(:course_setup) do
    enroll_teacher_and_students
    assignment_1
    assignment_2
    student_submission
  end
  let(:login_to_srgb) do
    user_session(teacher)
    get "/courses/#{test_course.id}/gradebook/change_gradebook_version?version=srgb"
    select_student(student)
  end

  before(:each) do
    course_setup
  end

  it 'toggles ungraded as 0 with correct grades', priority: "2", test_id: 615672 do
    assignment_1.grade_student(student, grade: 10)

    login_to_srgb
    select_assignment(assignment_1)
    ungraded_as_zero.click
    expect(final_grade).to include_text('50%')

    ungraded_as_zero.click
    expect(final_grade).to include_text('100%')
  end

  it 'hides student names', priority: "2", test_id: 615673 do
    login_to_srgb
    hide_student_names.click

    expect(secondary_id_label).to include_text('hidden')
  end

  it 'shows conluded enrollments', priority: "2", test_id: 615674 do
    login_to_srgb
    concluded_enrollments.click
    wait_for_ajaximations

    expect(student_dropdown).to include_text('Stewie Griffin')
  end

  it 'shows notes in student info', priority: "2", test_id: 615675 do
    login_to_srgb
    show_notes_option.click

    expect(notes_field).to be_present
  end
end