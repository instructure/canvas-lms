require File.expand_path(File.dirname(__FILE__) + '/../common')

module Gradebook2SRGBCommon
  shared_context 'srgb_components' do
    let(:main_grade_input) { f('#student_and_assignment_grade') }
    let(:grade_for_label) { f("label[for='student_and_assignment_grade']") }
    let(:next_assignment_button) { fj("button:contains('Next Assignment')") }
    let(:submission_details_button) { f('#submission_details') }
    let(:group_weights_button) { f('#ag_weights') }
    let(:show_notes_option) { f('#show_notes') }
    let(:notes_field) { f('#student_information textarea') }
  end
  shared_context 'srgb_course' do
    let(:test_course) { course() }
    let(:teacher)     { user(active_all: true) }
    let(:student)     { user(active_all: true) }
    let(:enroll_teacher_and_students) do
      test_course.enroll_user(teacher, 'TeacherEnrollment', enrollment_state: 'active')
      test_course.enroll_user(student, 'StudentEnrollment', enrollment_state: 'active')
    end
    let(:assignment_group_1) { test_course.assignment_groups.create! name: 'Group 1' }
    let(:assignment_group_2) { test_course.assignment_groups.create! name: 'Group 2' }
    let(:assignment_1) do
      test_course.assignments.create!(
        title: 'Points Assignment',
        grading_type: 'points',
        points_possible: 10,
        submission_types: 'online_text_entry',
        due_at: 2.days.ago,
        assignment_group: assignment_group_1
      )
    end
    let(:assignment_2) do
      test_course.assignments.create!(
        title: 'Percent Assignment',
        grading_type: 'percent',
        points_possible: 10,
      )
    end
    let(:assignment_3) do
      test_course.assignments.create!(
        title: 'Complete/Incomplete Assignment',
        grading_type: 'pass_fail',
        points_possible: 10
      )
    end
    let(:assignment_4) do
      test_course.assignments.create!(
        title: 'Letter Grade Assignment',
        grading_type: 'letter_grade',
        points_possible: 10
      )
    end
    let(:assignment_5) do
      test_course.assignments.create!(
        title: 'Zero Points Possible',
        grading_type: 'points',
        points_possible: 0,
        assignment_group: assignment_group_2
      )
    end
    let(:student_submission) do
      assignment_1.submit_homework(
        student,
        submission_type: 'online_text_entry',
        body: 'Hello!'
      )
    end
  end

  def basic_setup(num=1)
    init_course_with_students num
    @course.assignments.create!(
      title: 'Test 1',
      submission_types: 'online_text_entry',
      points_possible: 20,
      grading_type: 'percent'
    )
  end

  def select_assignment(assignment)
    click_option('#assignment_select', assignment.name)
  end

  def select_student(student)
    click_option('#student_select', student.name)
  end

  # made this method just to improve readability / more descriptive name
  def grade_srgb_assignment(input, grade)
    replace_content(input, grade)
  end

  def turn_on_group_weights
    f('#ag_weights').click
    f('#group_weighting_scheme').click
    f('button .ui-button-text').click
  end

  def tab_out_of_input(input_selector)
    # This is a hack for a timing issue with SRGB
    2.times { input_selector.send_keys(:tab) }
    wait_for_ajaximations
  end

  def drop_lowest(num_assignment)
    ag = test_course.assignment_groups.first
    ag.rules_hash = {"drop_lowest"=>num_assignment}
    ag.save!
  end
end
