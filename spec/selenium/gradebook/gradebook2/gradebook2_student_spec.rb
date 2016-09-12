require_relative '../../helpers/gradebook2_common'
require_relative '../../helpers/multiple_grading_periods_common'

describe "gradebook2 - logged in as a student" do
  include_context "in-process server selenium tests"
  include Gradebook2Common
  include MultipleGradingPeriods::StudentPage
  include_context "student_page_components"

  it 'should display total grades as points', priority: "2", test_id: 164229 do
    course_with_student_logged_in
    assignment = @course.assignments.build
    assignment.publish
    assignment.grade_student(@student, {grade: 10})
    @course.show_total_grade_as_points = true
    @course.save!

    get "/courses/#{@course.id}/grades"
    expect(f('#submission_final-grade .grade')).to include_text("10")
  end

  context 'when testing multiple grading periods' do
    # enable mgp
    before(:each) do
      course_with_admin_logged_in
      student_in_course
      @course.root_account.enable_feature!(:multiple_grading_periods)
    end

    context 'with one past and one current period' do
      past_period_name = "Past Grading Period"
      current_period_name = "Current Grading Period"
      past_assignment_name = "Past Assignment"
      current_assignment_name = "Current Assignment"

      before(:each) do
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
        visit_student_grades_page(@course, @student)
      end

      it 'should only show assignments that belong to the selected grading period', priority: "1", test_id: 2528639 do
        select_period_by_name(past_period_name)
        expect(assignment_titles).to include(past_assignment_name)
        expect(assignment_titles).not_to include(current_assignment_name)
      end
    end
  end
end


