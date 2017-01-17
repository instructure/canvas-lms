require_relative '../../helpers/gradebook_common'
require_relative '../page_objects/student_grades_page'

describe "gradebook - logged in as a student" do
  include_context "in-process server selenium tests"
  include GradebookCommon

  # Helpers
  def backend_group_helper
    Factories::GradingPeriodGroupHelper.new
  end

  def backend_period_helper
    Factories::GradingPeriodHelper.new
  end

  let(:student_grades_page) { StudentGradesPage.new }

  it 'should display total grades as points', priority: "2", test_id: 164229 do
    course_with_student_logged_in
    @teacher = User.create!
    @course.enroll_teacher(@teacher)
    assignment = @course.assignments.build
    assignment.publish
    assignment.grade_student(@student, grade: 10, grader: @teacher)
    @course.show_total_grade_as_points = true
    @course.save!

    student_grades_page.visit_as_student(@course)
    expect(student_grades_page.final_grade).to include_text("10")
  end

  context 'when testing grading periods' do
    before do
      course_with_admin_logged_in
      student_in_course
    end

    context 'with one past and one current period' do
      past_period_name = "Past Grading Period"
      current_period_name = "Current Grading Period"
      past_assignment_name = "Past Assignment"
      current_assignment_name = "Current Assignment"

      before do
        # create term
        term = @course.root_account.enrollment_terms.create!
        @course.update_attributes(enrollment_term: term)

        # create group and periods
        group = backend_group_helper.create_for_account(@course.root_account)
        term.update_attribute(:grading_period_group_id, group)
        backend_period_helper.create_with_weeks_for_group(group, 4, 2, past_period_name)
        backend_period_helper.create_with_weeks_for_group(group, 1, -3, current_period_name)

        # create assignments
        @course.assignments.create!(due_at: 3.weeks.ago, title: past_assignment_name)
        @course.assignments.create!(due_at: 1.week.from_now, title: current_assignment_name)

        # go to student grades page
        student_grades_page.visit_as_teacher(@course, @student)
      end

      it 'should only show assignments that belong to the selected grading period', priority: "1", test_id: 2528639 do
        student_grades_page.select_period_by_name(past_period_name)
        expect(student_grades_page.assignment_titles).to include(past_assignment_name)
        expect(student_grades_page.assignment_titles).not_to include(current_assignment_name)
      end
    end
  end
end


