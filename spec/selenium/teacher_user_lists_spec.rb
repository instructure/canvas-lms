require File.expand_path(File.dirname(__FILE__) + '/common')

describe "user" do
  it_should_behave_like "in-process server selenium tests"

  context "as a teacher" do

    before (:each) do
      account = Account.default
      account.settings = {:open_registration => true, :no_enrollments_can_create_courses => true, :teachers_can_create_courses => true}
      account.save!
    end

    def add_users_to_user_list(include_short_name = true, enrollment_type = 'StudentEnrollment', use_user_id = false)
      user = User.create!(:name => 'login_name user')
      user.pseudonyms.create!(:unique_id => "A124123", :account => @course.root_account)
      user.communication_channels.create!(:path => "A124123")
      user_list = <<eolist
    user1@example.com, "bob sagat" <bob@thesagatfamily.name>, A124123
eolist
      if (ff('#enrollment_type').length > 0)
        click_option("#enrollment_type", enrollment_type, :value)
        wait_for_ajaximations
      end
      f("textarea.user_list").send_keys(user_list)
      f("button.verify_syntax_button").click
      wait_for_ajaximations
      f("button.add_users_button").click
      wait_for_ajaximations
      unique_ids = ["user1@example.com", "bob@thesagatfamily.name", "A124123"]
      browser_text = ["user1@example.com\nuser1@example.com\nuser1@example.com", "sagat, bob\nbob sagat\nbob@thesagatfamily.name", "user, login_name\nlogin_name user\nA124123"] if include_short_name
      browser_text = ["user1@example.com\nuser1@example.com", "sagat, bob\nbob@thesagatfamily.name", "user, login_name\nA124123"] unless include_short_name
      enrollments = Enrollment.where("(workflow_state='invited' OR workflow_state='creation_pending') AND type=?", enrollment_type).all
      (enrollments.count > 2).should be_true
      unique_ids.each do |id|
        enrollment = find_enrollment_by_id(enrollments, id)
        enrollment.should be_present
        selector = use_user_id ? "#user_#{enrollment.user_id}" : "#enrollment_#{enrollment.id}"
        f(selector).text.should include(browser_text.shift)
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

    it "should support adding an enrollment to an enrollmentless course" do
      user_logged_in
      Account.default.add_user(@user)
      course
      get "/courses/#{@course.id}/details"
      f("#tab-users-link").click
      f("#tab-users a.add_users_link").click
      add_users_to_user_list(true, 'StudentEnrollment', true)
    end

    context "enrollments by email addresses and user names on course details page" do
      before(:each) do
        course_with_teacher_logged_in(:active_all => true)
        get "/courses/#{@course.id}/details"
        f("#tab-users-link").click
        wait_for_ajaximations
        f("#tab-users a.add_users_link").click
      end

      it "should support adding student enrollments" do
        add_users_to_user_list(true, 'StudentEnrollment', true)
      end

      it "should support adding teacher enrollments" do
        add_users_to_user_list(true, 'TeacherEnrollment', true)
      end

      it "should support adding Ta enrollments" do
        add_users_to_user_list(true, 'TaEnrollment', true)
      end

      it "should support adding observer enrollments" do
        add_users_to_user_list(true, 'ObserverEnrollment', true)
      end

      it "should support adding designer enrollments" do
        add_users_to_user_list(true, 'DesignerEnrollment', true)
      end
    end
  end
end
