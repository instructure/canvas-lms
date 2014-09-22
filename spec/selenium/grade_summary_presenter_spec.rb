require File.expand_path(File.dirname(__FILE__) + '/common')

describe GradeSummaryPresenter do
  it_should_behave_like "in-process server selenium tests"

  describe 'deleted submissions', :priority => "2" do
    it 'should navigate to grade summary page' do
      course_with_student_logged_in

      a1, a2 = 2.times.map { @course.assignments.create! points_possible: 10 }
      a1.grade_student @student, grade: 10
      a2.grade_student @student, grade: 10
      a2.destroy

      get "/courses/#{@course.id}/grades"
      f('#grades_summary').should be_displayed
    end
  end
end