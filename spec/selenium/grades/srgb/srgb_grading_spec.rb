require_relative '../../helpers/gradebook_common'
require_relative '../page_objects/srgb_page'
require_relative '../setup/gradebook_setup'

describe 'Screenreader Gradebook grading' do
  include_context 'in-process server selenium tests'
  include_context 'reusable_course'
  include GradebookCommon
  include GradebookSetup

  let(:srgb_page) { SRGB }

  let(:course_setup) do
    enroll_teacher_and_students
    assignment_1
    assignment_2
    assignment_3
    assignment_4
    student_submission
  end

  let(:login_to_srgb) do
    user_session(teacher)
    srgb_page.visit(test_course.id)
    srgb_page.select_student(student)
  end

  context 'in Grades section' do
    before(:each) do
      course_setup
      login_to_srgb
    end

    it 'displays correct Grade for: label on assignments', prority: "1", test_id: 615692 do
      srgb_page.select_assignment(assignment_1)

      expect(srgb_page.grade_for_label).to include_text('Grade for: Points Assignment')
    end

    it 'displays correct Grade for: label on next assignment', prority: "1", test_id: 615953 do
      srgb_page.select_assignment(assignment_1)
      srgb_page.next_assignment_button.click

      expect(srgb_page.grade_for_label).to include_text('Grade for: Percent Assignment')
    end

    it 'displays correct points for graded by Points', priority: "1", test_id: 615695 do
      srgb_page.select_assignment(assignment_1)
      srgb_page.grade_srgb_assignment(srgb_page.main_grade_input, 8)
      srgb_page.tab_out_of_input(srgb_page.main_grade_input)

      expect(srgb_page.main_grade_input).to have_value('8')
    end

    it 'displays correct points for graded by Percent', prority: "1", test_id: 163999 do
      srgb_page.select_assignment(assignment_2)
      srgb_page.grade_srgb_assignment(srgb_page.main_grade_input, 8)
      srgb_page.tab_out_of_input(srgb_page.main_grade_input)

      expect(srgb_page.main_grade_input).to have_value('80%')
    end

    it 'displays correct points for graded by Complete/Incomplete', priority: "1", test_id: 615694 do
      srgb_page.select_assignment(assignment_3)
      click_option('#student_and_assignment_grade', 'Complete')
      srgb_page.tab_out_of_input(srgb_page.main_grade_input)

      expect(f('#grading div.ember-view')).to include_text('10 out of 10')
    end

    it 'displays correct points for graded by Letter Grade', prority: "1", test_id: 163999 do
      srgb_page.select_assignment(assignment_4)
      srgb_page.grade_srgb_assignment(srgb_page.main_grade_input, 8)
      srgb_page.tab_out_of_input(srgb_page.main_grade_input)

      expect(srgb_page.main_grade_input).to have_value('B-')
    end

    it 'displays submission details modal with correct grade', priority: "2", test_id: 615698 do
      srgb_page.select_assignment(assignment_1)
      srgb_page.grade_srgb_assignment(srgb_page.main_grade_input, 8)
      srgb_page.tab_out_of_input(srgb_page.main_grade_input)
      srgb_page.submission_details_button.click

      expect(f('.submission_details_dialog .assignment-name')).to include_text(assignment_1.name)
      expect(fj('.submission_details_grade_form input:visible')).to have_value('8')
    end

    it 'updates grade in submission details modal', priority: "2", test_id: 949577 do
      skip('fragile')
      srgb_page.select_assignment(assignment_2)
      replace_content(srgb_page.main_grade_input, 8)
      srgb_page.submission_details_button.click

      # change grade from 8 to 10 in the assignment details modal
      details_modal_grade_input = f('.submission_details_grade_form input')
      details_modal_grade_input.clear
      replace_content(details_modal_grade_input, 10)
      f("form.submission_details_grade_form button").click

      expect(srgb_page.main_grade_input).to have_value('100%')
    end
  end

  context 'displays warning' do
    before(:each) do
      course_setup
    end

    it 'on late submissions', priority: "2", test_id: 615701 do
      login_to_srgb
      srgb_page.select_assignment(assignment_1)
      expect(f('p.late.muted em')).to include_text('This submission was late.')
    end

    it 'on dropped assignments', priority: "2", test_id: 615700 do
      # create an assignment group with drop lowest 1 score rule
      srgb_page.drop_lowest(test_course, 1)

      # grade a few assignments with one really low grade
      assignment_1.grade_student(student, grade: 3, grader: teacher)
      assignment_2.grade_student(student, grade: 10, grader: teacher)

      login_to_srgb
      srgb_page.select_assignment(assignment_1)

      # indicates assignment_1 was dropped
      expect(f('.dropped.muted em')).to include_text('This grade is currently dropped for this student.')
    end

    it 'on resubmitted assignments', priority: "2", test_id: 164000 do
      # grade assignment
      assignment_1.grade_student(student, grade: 8, grader: teacher)

      # resubmit as student
      Timecop.travel(1.hour.from_now) do
        assignment_1.submit_homework(
          student,
          submission_type: 'online_text_entry',
          body: 're-submitting!'
        )
      end

      login_to_srgb
      srgb_page.select_assignment(assignment_1)

      # indicates assignment_1 was resubmitted
      expect(f('.resubmitted.muted em')).to include_text('This assignment has been resubmitted')

      # grade the assignment again
      srgb_page.grade_srgb_assignment(srgb_page.main_grade_input, 10)
      srgb_page.tab_out_of_input(srgb_page.main_grade_input)

      # warning should be removed
      expect(f("#content")).not_to contain_css('.resubmitted.muted em')
    end
  end

  context 'with grading periods' do
    before do
      term_name = "First Term"
      create_grading_periods(term_name)
      add_teacher_and_student
      associate_course_to_term(term_name)
      user_session(@teacher)
    end

    it 'assignment in ended gp should be gradable', test_id: 2947128, priority: "1" do
      assignment = @course.assignments.create!(due_at: 13.days.ago, title: "assign in ended")
      SRGB.visit(@course.id)
      SRGB.select_grading_period(@gp_ended)
      SRGB.select_student(student)
      SRGB.select_assignment(assignment)
      SRGB.enter_grade(8)

      expect(SRGB.current_grade).to eq "8"
      expect(Submission.where(assignment_id: assignment.id, user_id: @student.id).first.grade).to eq "8"
    end

    it 'assignment in closed gp should not be gradable', test_id: 2947127, priority: "1" do
      assignment = @course.assignments.create!(due_at: 18.days.ago, title: "assign in closed")
      SRGB.visit(@course.id)
      SRGB.select_grading_period(@gp_closed)
      SRGB.select_student(student)
      SRGB.select_assignment(assignment)

      expect(SRGB.grading_enabled?).to be false
      expect(Submission.where(assignment_id: assignment.id, user_id: @student.id).first).to eq nil
    end
  end
end
