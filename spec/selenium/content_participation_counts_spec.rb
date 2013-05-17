require File.expand_path(File.dirname(__FILE__) + '/common')

describe "courses" do
  it_should_behave_like "in-process server selenium tests"

  before do
    course_with_student_logged_in(:active_all => true)
    course_with_teacher(:active_all => true, :course => @course)

    @assignment = @course.assignments.new(:title => "some assignment")
    @assignment.workflow_state = "published"
    @assignment.save
    @submission = @assignment.grade_student(@student, { :grade => 3 }).first
  end

  it "should show badges in the left nav of a course" do
    get "/courses/#{@course.id}"
    f("#section-tabs .grades .nav-badge").text.should == "1"
  end

  it "should derement the badge when the grades page is visited" do
    # visiting the page will decrement the count on the next page load
    get "/courses/#{@course.id}/grades"
    f("#section-tabs .grades .nav-badge").text.should == "1"

    get "/courses/#{@course.id}"
    f("#section-tabs .grades .nav-badge").should be_nil
  end
end
