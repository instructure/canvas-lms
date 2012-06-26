require File.expand_path(File.dirname(__FILE__) + '/../common')

describe "account admin courses tab" do
  it_should_behave_like "in-process server selenium tests"
  before (:each) do
    course_with_admin_logged_in
    get "/accounts/#{Account.default.id}"
  end

  def add_course course_name, has_student=false
    Account.default.courses.create(:name => course_name).offer!
    course = Course.find_by_name(course_name)
    if (has_student)
      user = User.create(:name => "student 1")
      course.enroll_user(user, "StudentEnrollment", {:enrollment_state => "active"})
    end
    # we need to refresh the page so the course shows up
    refresh_page
    f("#course_#{course.id}").should be_displayed
    f("#course_#{course.id}").should include_text course_name
    if (has_student)
      f("#course_#{course.id}").should include_text "1 Student"
    end
    course
  end

  it "should add a new course" do
    f(".add_course_link").click
    f("#add_course_form #course_name").send_keys("course 1")
    f("#course_course_code").send_keys("12345")
    submit_form("#add_course_form")
    # we need to refresh the page so the course shows up
    refresh_page
    course = Course.find_by_name("course 1")
    course.should be_present
    course.course_code.should eql "12345"
    f("#course_#{course.id}").should be_displayed
    f("#course_#{course.id}").should include_text "course 1"
  end

  it "should search a course and verify it goes to the course" do
    name = "course 1"
    course = add_course name, true
    name = name.split(" ")
    f("#course_name").send_keys(name[0])
    f("#course_name").send_keys(" "+name[1])
    ff(".ui-menu-item .ui-corner-all").count > 0
    keep_trying_until { fj(".ui-menu-item .ui-corner-all:visible").text.should include_text(course.name) }
    f("#new_course button").click
    wait_for_ajax_requests
    f("#crumb_course_#{course.id}").should be_displayed
  end

  it "should search a bogus course and it should not show up" do
    add_course "course 1"
    name = "courses 4"
    name = name.split(" ")
    f("#course_name").send_keys(name[0])
    f("#course_name").send_keys(" "+name[1])
    ff(".ui-menu-item .ui-corner-all").count.should eql 0
  end

  it "should hide enrollmentless courses" do
    name = "course 1"
    name2 = "course 2"
    course = add_course name
    course2 = add_course name2, true
    f("#enroll_filter_checkbox").click
    f(".filter_button").click
    wait_for_ajax_requests
    f("#course_#{course.id}").should be_nil
    f("#course_#{course2.id}").should be_displayed
  end

  it "should hide and then show enrollmentless courses" do
    name = "course 1"
    course = add_course name
    f("#enroll_filter_checkbox").click
    f(".filter_button").click
    wait_for_ajax_requests
    f("#course_#{course.id}").should be_nil
    f("#enroll_filter_checkbox").click
    f(".filter_button").click
    wait_for_ajax_requests
    f("#course_#{course.id}").should be_displayed
  end
end

