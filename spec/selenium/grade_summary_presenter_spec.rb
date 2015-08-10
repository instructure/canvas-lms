require File.expand_path(File.dirname(__FILE__) + '/common')

describe GradeSummaryPresenter do
  include_context "in-process server selenium tests"

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
    let(:student)  { user(active_user: true) }
    let(:observer) { user(active_user: true) }
    let(:observed_courses) do
      2.times.map { course(active_course: true, active_all: true) }
    end

    it 'should show the courses dropdown when logged in as observer' do
      observed_courses.each do |course|
        student_enrollment = course.enroll_student student
        student_enrollment.accept

        observer_enrollment = course.enroll_user(observer, 'ObserverEnrollment')
        observer_enrollment.update_attribute(:associated_user_id, student.id)
        observer_enrollment.accept
      end

      user_session observer
      get "/courses/#{observed_courses.first.id}/grades"

      expect(f('.course_selector')).to be_displayed
    end
  end
end
