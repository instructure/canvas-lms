require_relative '../../helpers/gradebook2_common'
require_relative '../../helpers/gradebook2_srgb_common'

describe 'Screenreader Gradebook Student Information' do
  include_context 'in-process server selenium tests'
  include_context 'srgb_components'
  include_context 'reusable_course'
  include Gradebook2Common
  include Gradebook2SRGBCommon

  let(:course_setup) do
    enroll_teacher_and_students
    assignment_1
    assignment_5
    student_submission
  end
  let(:login_to_srgb) do
    user_session(teacher)
    get "/courses/#{test_course.id}/gradebook/change_gradebook_version?version=srgb"
  end

  before(:each) do
    course_setup
  end

  context 'in Student Information section' do
    it 'allows comments in Notes field', priority: "2", test_id: 615709 do
      login_to_srgb
      skip_if_chrome('fails in chrome - due to replace content')
      select_student(student)
      show_notes_option.click
      replace_content(notes_field, 'Good job!')
      tab_out_of_input(notes_field)

      expect(notes_field).to have_value('Good job!')
    end

    context 'displays no points possible warning' do
      before(:each) do
        @course.apply_assignment_group_weights = true
        @course.save!
        login_to_srgb
      end

      it "with only a student selected", priority: "2", test_id: 615711 do
        select_student(student)

        expect(f('span.text-error > i.icon-warning')).to be_displayed
        expect(f('#student_information > div.row')).to include_text('Score does not include assignments from the group')
      end

      it "with only an assignment is selected", priority: "2", test_id: 615691 do
        select_assignment(assignment_5)

        expect(f('a > i.icon-warning')).to be_displayed
        expect(f('#assignment_information > div.row')).to include_text('Assignments in this group have no points')
      end
    end
  end
end
