require_relative '../../helpers/gradezilla_common'
require_relative '../../helpers/groups_common'
require_relative '../page_objects/gradezilla_page'

describe "Gradezilla - Assignment Column Options" do
  include_context "in-process server selenium tests"
  include GradezillaCommon
  include GroupsCommon

  let(:gradezilla_page) { Gradezilla::MultipleGradingPeriods.new }

  before(:once) do
    course_with_teacher(active_all: true)

    # enroll three students
    3.times do |i|
      student = User.create!(name: "Student #{i+1}")
      student.register!
      @course.enroll_student(student).update!(workflow_state: 'active')
    end

    @assignment = @course.assignments.create!(
      title: "An Assignment",
      points_possible: 10,
      due_at: 1.day.from_now
    )

    @course.student_enrollments.collect(&:user).each do |student|
      @assignment.submit_homework(student, body: 'a body')
      @assignment.grade_student(student, grade: 10, grader: @teacher)
    end
  end

  before(:each) { user_session(@teacher) }

  describe "Sorting" do
    it "sorts by Missing" do
      third_student = @course.students.find_by!(name: 'Student 3')
      @assignment.submissions.find_by!(user: third_student).destroy!
      gradezilla_page.visit(@course)
      gradezilla_page.open_assignment_options_and_select_by(
        assignment_id: @assignment.id,
        menu_item_id: 'sort-by-missing'
      )

      expect(gradezilla_page.student_names).to eq ["Student 3", "Student 1", "Student 2"]
    end

    it "sorts by Late" do
      third_student = @course.students.find_by!(name: 'Student 3')
      submission = @assignment.submissions.find_by!(user: third_student)
      submission.update!(submitted_at: 2.days.from_now) # make late
      gradezilla_page.visit(@course)
      gradezilla_page.open_assignment_options_and_select_by(
        assignment_id: @assignment.id,
        menu_item_id: 'sort-by-late'
      )

      expect(gradezilla_page.student_names).to eq ["Student 3", "Student 1", "Student 2"]
    end
  end
end
