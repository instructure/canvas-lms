require File.expand_path(File.dirname(__FILE__) + '/common')

describe "courses" do
  include_context "in-process server selenium tests"

  before do
    course_with_student_logged_in(:active_all => true)
    course_with_teacher(:active_all => true, :course => @course)

    @assignment = @course.assignments.new(:title => "some assignment")
    @assignment.workflow_state = "published"
    @assignment.save
    @submission = @assignment.grade_student(@student, grade: 3, grader: @teacher).first
  end

  it "should show badges in the left nav of a course" do
    get "/courses/#{@course.id}"
    expect(f("#section-tabs .grades .nav-badge").text).to eq "1"
  end

  it "should decrement the badge when the grades page is visited" do
    get "/courses/#{@course.id}"
    expect(f("#section-tabs .grades .nav-badge").text).to eq "1"

    get "/courses/#{@course.id}/grades"
    expect(f("#content")).not_to contain_css("#section-tabs .grades .nav-badge")
  end
end
