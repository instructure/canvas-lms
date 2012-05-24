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
    if (ff('#enrollment_type').length > 0)
      click_option("#enrollment_type", enrollment_type, :value)
    end
    f("textarea.user_list").send_keys(user_list)
    f("button.verify_syntax_button").click
    f("button.add_users_button").click
    wait_for_ajaximations
    enrollment = user.reload.enrollments.last
    extra_line = ""
    extra_line = "\nlink to a student" if enrollment_type == 'ObserverEnrollment'
    keep_trying_until { f("#enrollment_#{enrollment.id}").text.should == ("user, login_name" + (include_short_name ? "\nlogin_name user" : "") + "\nA124123" + extra_line) }
    unique_ids = ["user1@example.com", "bob@thesagatfamily.name", "A124123"]
    browser_text = ["user1@example.com\nuser1@example.com\nuser1@example.com", "sagat, bob\nbob sagat\nbob@thesagatfamily.name", "user, login_name\nlogin_name user\nA124123"] if include_short_name
    browser_text = ["user1@example.com\nuser1@example.com", "sagat, bob\nbob@thesagatfamily.name", "user, login_name\nA124123"] unless include_short_name
    enrollments = Enrollment.all(:conditions => ["(workflow_state = 'invited' OR workflow_state = 'creation_pending') AND type = ? ", enrollment_type])
    (enrollments.count > 2).should be_true
    unique_ids.each do |id|
      enrollment = find_enrollment_by_id(enrollments, id)
      enrollment.should be_present
      f("#enrollment_#{enrollment.id}").text.should == browser_text.shift + extra_line
    end
  end

  def find_enrollment_by_id(enrollments, id)
    enrollment = nil
    enrollments.each do |e|
      if (e.user.communication_channels.first.path == id)
        enrollment = e
        break
      end
    end
    enrollment
  end

  context "enrollments by email addresses and user names on course details page" do
    before(:each) do
      skip_if_ie('Out of memory')
      course_with_teacher_logged_in(:active_all => true)
      get "/courses/#{@course.id}/details"
      f("#tab-users-link").click
      f("#tab-users a.add_users_link").click
    end

    it "should support adding student enrollments" do
      add_users_to_user_list(true)
    end

    it "should support adding teacher enrollments" do
      add_users_to_user_list(true, 'TeacherEnrollment')
    end

    it "should support adding Ta enrollments" do
      add_users_to_user_list(true, 'TaEnrollment')
    end

    it "should support adding observer enrollments" do
      add_users_to_user_list(true, 'ObserverEnrollment')
    end

    it "should support adding designer enrollments" do
      add_users_to_user_list(true, 'DesignerEnrollment')
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
    f("#tab-users-link").click
    f("#tab-users a.add_users_link").click
    add_users_to_user_list
  end
end
