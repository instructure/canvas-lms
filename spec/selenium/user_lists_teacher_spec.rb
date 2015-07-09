require File.expand_path(File.dirname(__FILE__) + '/common')

describe "user" do
  include_examples "in-process server selenium tests"

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
      expect(enrollments.count > 2).to be_truthy
      unique_ids.each do |id|
        enrollment = find_enrollment_by_id(enrollments, id)
        expect(enrollment).to be_present
        selector = use_user_id ? "#user_#{enrollment.user_id}" : "#enrollment_#{enrollment.id}"
        expect(f(selector).text).to include(browser_text.shift)
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
  end
end
