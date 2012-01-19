require File.expand_path(File.dirname(__FILE__) + '/common')

describe "user" do
  it_should_behave_like "in-process server selenium tests"

  before (:each) do
    account = Account.default
    account.settings = {:open_registration => true, :no_enrollments_can_create_courses => true, :teachers_can_create_courses => true}
    account.save!
  end

  def add_users_to_user_list(include_short_name = true, enrollment_type = 'StudentEnrollment')
    user = User.create!(:name => 'login_name user')
    user.pseudonyms.create!(:unique_id => "A124123", :account => @course.root_account)
    user.communication_channels.create!(:path => "A124123")

    user_list = <<eolist
user1@example.com, "bob sagat" <bob@thesagatfamily.name>, A124123
eolist
    if driver.find_elements(:id, 'enrollment_type').length > 0
      driver.find_element(:id, 'enrollment_type').find_element(:css, "option[value=#{enrollment_type}]").click
    end
    driver.find_element(:css, "textarea.user_list").send_keys(user_list)
    driver.find_element(:css, "button.verify_syntax_button").click
    driver.find_element(:css, "button.add_users_button").click
    wait_for_ajax_requests
    wait_for_animations
    enrollment = user.reload.enrollments.last
    extra_line = ""
    extra_line = "\nlink to a student" if enrollment_type == 'ObserverEnrollment'
    keep_trying_until { driver.find_element(:css, "#enrollment_#{enrollment.id}").text.should == ("user, login_name" + (include_short_name ? "\nlogin_name user" : "") + "\nA124123" + extra_line) }

    unique_ids = ["user1@example.com", "bob@thesagatfamily.name", "A124123"]
    browser_text = ["user1@example.com\nuser1@example.com\nuser1@example.com", "sagat, bob\nbob sagat\nbob@thesagatfamily.name", "user, login_name\nlogin_name user\nA124123"] if include_short_name
    browser_text = ["user1@example.com\nuser1@example.com", "sagat, bob\nbob@thesagatfamily.name", "user, login_name\nA124123"] unless include_short_name
    Enrollment.all.last(3).sort_by { |e| unique_ids.index(e.user.communication_channels.first.path) }.each do |e|
      e.user.communication_channels.first.path.should == unique_ids.shift
      driver.find_element(:css, "#enrollment_#{e.id}").text.should == browser_text.shift + extra_line
    end
  end

  ['StudentEnrollment', 'TeacherEnrollment', 'TaEnrollment', 'ObserverEnrollment', 'DesignerEnrollment'].each do |type|
    it "should support adding #{type} enrollments by both email addresses and user names on the course details page" do
      skip_if_ie('Out of memory')
      course_with_teacher_logged_in(:active_all => true)
      get "/courses/#{@course.id}/details"
      driver.find_element(:css, "a#tab-users-link").click
      driver.find_element(:css, "div#tab-users a.add_users_link").click
      add_users_to_user_list(true, type)
    end
  end

  it "should support both email addresses and user names on the getting started page" do
    skip_if_ie('Out of memory')
    course_with_teacher_logged_in(:active_all => true)
    get "/getting_started/students"
    add_users_to_user_list(false)
  end

  it "should support adding an enrollment to an enrollmentless course" do
    skip_if_ie('Out of memory')
    user_logged_in
    Account.default.add_user(@user)
    course
    get "/courses/#{@course.id}/details"
    driver.find_element(:css, "a#tab-users-link").click
    driver.find_element(:css, "div#tab-users a.add_users_link").click
    add_users_to_user_list
  end
end
