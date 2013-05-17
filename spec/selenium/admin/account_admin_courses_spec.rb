require File.expand_path(File.dirname(__FILE__) + '/../common')

describe "account admin courses tab" do
  it_should_behave_like "in-process server selenium tests"

  def add_course(course_name, has_student = false)
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

  context "add course basic" do
    describe "shared course specs" do
      let(:account) { Account.default }
      let(:url) { "/accounts/#{Account.default.id}" }

      before (:each) do
        course_with_admin_logged_in
      end

      it "should add a new course" do
        pending('sub account course creation, failing at wait_for_dom_ready') if account != Account.default
        course_name = 'course 1'
        course_code = '12345'
        get url

        f(".add_course_link").click
        wait_for_ajaximations
        f("#add_course_form #course_name").send_keys(course_name)
        f("#course_course_code").send_keys(course_code)
        submit_form("#add_course_form")
        refresh_page # we need to refresh the page so the course shows up
        course = Course.find_by_name(course_name)
        course.should be_present
        course.course_code.should == course_code
        f("#course_#{course.id}").should be_displayed
        f("#course_#{course.id}").should include_text(course_name)
      end
    end
  end

  context "add courses" do

    before (:each) do
      course_with_admin_logged_in
      get "/accounts/#{Account.default.id}"
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
      ff(".ui-menu-item .ui-corner-all").count.should == 0
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
end

