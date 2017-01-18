require File.expand_path(File.dirname(__FILE__) + '/../common')

describe "account admin courses tab" do
  include_context "in-process server selenium tests"

  def add_course(course_name, has_student = false)
    Account.default.courses.create(:name => course_name).offer!
    course = Course.where(name: course_name).first
    if (has_student)
      user = User.create(:name => "student 1")
      course.enroll_user(user, "StudentEnrollment", {:enrollment_state => "active"})
    end
    # we need to refresh the page so the course shows up
    refresh_page
    expect(f("#course_#{course.id}")).to be_displayed
    expect(f("#course_#{course.id}")).to include_text course_name
    if (has_student)
      expect(f("#course_#{course.id}")).to include_text "1 Student"
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
        skip('sub account course creation, failing at wait_for_dom_ready') if account != Account.default
        course_name = 'course 1'
        course_code = '12345'
        get url

        f(".add_course_link").click
        wait_for_ajaximations
        f("#add_course_form #course_name").send_keys(course_name)
        f("#course_course_code").send_keys(course_code)
        submit_dialog_form("#add_course_form")
        refresh_page # we need to refresh the page so the course shows up
        course = Course.where(name: course_name).first
        expect(course).to be_present
        expect(course.course_code).to eq course_code
        expect(f("#course_#{course.id}")).to be_displayed
        expect(f("#course_#{course.id}")).to include_text(course_name)
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
      expect(fj(".ui-menu-item .ui-corner-all:visible")).to include_text(course.name)
      expect_new_page_load { f("#new_course button").click }
      expect(f("#crumb_course_#{course.id}")).to be_displayed
    end

    it "should search a bogus course and it should not show up" do
      add_course "course 1"
      name = "courses 4"
      name = name.split(" ")
      f("#course_name").send_keys(name[0])
      f("#course_name").send_keys(" "+name[1])
      expect(f("body")).not_to contain_css(".ui-menu-item .ui-corner-all")
    end

    it "should hide enrollmentless courses" do
      name = "course 1"
      name2 = "course 2"
      course = add_course name
      course2 = add_course name2, true
      f("#enroll_filter_checkbox").click
      f(".filter_button").click
      wait_for_ajax_requests
      expect(f("#content")).not_to contain_css("#course_#{course.id}")
      expect(f("#course_#{course2.id}")).to be_displayed
    end

    it "should hide and then show enrollmentless courses" do
      name = "course 1"
      course = add_course name
      f("#enroll_filter_checkbox").click
      f(".filter_button").click
      wait_for_ajax_requests
      expect(f("#content")).not_to contain_css("#course_#{course.id}")
      f("#enroll_filter_checkbox").click
      f(".filter_button").click
      wait_for_ajax_requests
      expect(f("#course_#{course.id}")).to be_displayed
    end
  end
end

