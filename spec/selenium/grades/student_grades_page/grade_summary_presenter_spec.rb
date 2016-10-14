require_relative '../../common'
require_relative '../../helpers/gradebook2_common'

describe GradeSummaryPresenter do
  include_context 'in-process server selenium tests'
  include_context 'reusable_course'

  describe 'deleted submissions', priority: "2" do
    it 'should navigate to grade summary page' do
      course_with_student_logged_in

      a1, a2 = 2.times.map { @course.assignments.create! points_possible: 10 }
      a1.grade_student @student, grade: 10
      a2.grade_student @student, grade: 10
      a2.destroy

      get "/courses/#{@course.id}/grades"
      expect(f('#grades_summary')).to be_displayed
    end
  end

  describe "grade summary page" do
    before(:each) do
      enroll_teacher_and_students
    end

    let(:observed_courses) do
      2.times.map { course(active_course: true, active_all: true) }
    end
    let(:active_element) { driver.execute_script('return document.activeElement') }

    it 'shows the courses dropdown when logged in as observer' do
      observed_courses.each do |course|
        student_enrollment = course.enroll_student student
        student_enrollment.accept

        observer_enrollment = course.enroll_user(
          observer,
          'ObserverEnrollment',
          associated_user_id: student.id
        )
        observer_enrollment.accept
      end

      user_session(observer)
      get "/courses/#{observed_courses.first.id}/grades"

      expect(f('.course_selector')).to be_displayed
    end

    it 'maintains focus on show what-if/revert to original buttons', priority: 2, test_id: 229660 do
      student_submission.student_entered_score = 8
      student_submission.save!

      user_session(student)
      get "/courses/#{test_course.id}/grades"

      f('#student-grades-whatif button').click
      expect(active_element).to have_attribute('id', 'revert-all-to-actual-score')

      f('#revert-all-to-actual-score').click
      expect(active_element).to have_class('btn revert_all_scores_link')
    end
  end
end
