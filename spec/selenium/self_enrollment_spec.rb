require File.expand_path(File.dirname(__FILE__) + '/common')

describe "self enrollment" do
  include_examples "in-process server selenium tests"

  context "in a full course" do
    it "should not be allowed" do
      Account.default.allow_self_enrollment!
      course(:active_all => true)
      @course.self_enrollment = true
      @course.self_enrollment_limit = 0
      @course.save!
      get "/enroll/#{@course.self_enrollment_code}"
      expect(f("form#enroll_form")).to be_nil
    end
  end

  shared_examples_for "open registration" do
    before do
      Account.default.update_attribute(:settings, :self_enrollment => 'any', :open_registration => true, :self_registration => true)
      course(:active_all => active_course)
      set_up_course
      @course.update_attribute(:self_enrollment, true)
    end

    it "should register a new user" do
      get "/enroll/#{@course.self_enrollment_code}"
      f("#student_email").send_keys('new@example.com')
      f('#initial_action input[value=create]').click
      f("#student_name").send_keys('new guy')
      f('#enroll_form input[name="user[terms_of_use]"]').click
      expect_new_page_load {
        submit_form("#enroll_form")
      }
      expect(f('.btn-primary').text).to eq primary_action
      get "/"
      assert_valid_dashboard
    end

    it "should authenticate and register an existing user" do
      user_with_pseudonym(:active_all => true, :username => "existing@example.com", :password => "asdfasdf")
      get "/enroll/#{@course.self_enrollment_code}"
      f("#student_email").send_keys("existing@example.com")
      f('#initial_action input[value=log_in]').click
      f("#student_password").send_keys("asdfasdf")
      expect_new_page_load {
        submit_form("#enroll_form")
      }
      expect(f('.btn-primary').text).to eq primary_action
      get "/"
      assert_valid_dashboard
    end
  
    it "should register an authenticated user" do
      user_logged_in
      get "/enroll/#{@course.self_enrollment_code}"
      # no option to log in/register, since already authenticated
      expect(f("input[name='pseudonym[unique_id]']")).to be_nil
      expect_new_page_load {
        submit_form("#enroll_form")
      }
      expect(f('.btn-primary').text).to eq primary_action
      get "/"
      assert_valid_dashboard
    end

    it "should not error with a user that is already enrolled" do
      user_with_pseudonym(:active_all => true, :username => "existing@example.com", :password => "asdfasdf")
      student_in_course(:course => @course, :user => @user, :active_enrollment => true)

      get "/enroll/#{@course.self_enrollment_code}"
      f("#student_email").send_keys("existing@example.com")
      f('#initial_action input[value=log_in]').click
      f("#student_password").send_keys("asdfasdf")
      expect_new_page_load {
        submit_form("#enroll_form")
      }
      expect(f('.form-horizontal p').text).to include("You are already enrolled")
      expect(f('.btn-primary').text).to eq primary_action
      get "/"
      assert_valid_dashboard
    end
  end

  shared_examples_for "closed registration" do
    before do
      Account.default.allow_self_enrollment!
      course(:active_all => active_course)
      set_up_course
      @course.update_attribute(:self_enrollment, true)
    end

    it "should not register a new user" do
      get "/enroll/#{@course.self_enrollment_code}"
      expect(f("input[type=radio][name=user_type]")).to be_nil
      expect(f("input[name='user[name]']")).to be_nil
    end

    it "should authenticate and register an existing user" do
      user_with_pseudonym(:active_all => true, :username => "existing@example.com", :password => "asdfasdf")
      get "/enroll/#{@course.self_enrollment_code}"
      f("#student_email").send_keys("existing@example.com")
      f("#student_password").send_keys("asdfasdf")
      expect_new_page_load {
        submit_form("#enroll_form")
      }
      expect(f('.btn-primary').text).to eq primary_action
      get "/"
      assert_valid_dashboard
    end
  
    it "should register an authenticated user" do
      user_logged_in
      get "/enroll/#{@course.self_enrollment_code}"
      # no option to log in/register, since already authenticated
      expect(f("input[name='pseudonym[unique_id]']")).to be_nil
      expect_new_page_load {
        submit_form("#enroll_form")
      }
      expect(f('.btn-primary').text).to eq primary_action
      get "/"
      assert_valid_dashboard
    end

    it "should not error with a user that is already enrolled" do
      user_with_pseudonym(:active_all => true, :username => "existing@example.com", :password => "asdfasdf")
      student_in_course(:course => @course, :user => @user, :active_enrollment => true)

      get "/enroll/#{@course.self_enrollment_code}"
      f("#student_email").send_keys("existing@example.com")
      f("#student_password").send_keys("asdfasdf")
      expect_new_page_load {
        submit_form("#enroll_form")
      }
      expect(f('.form-horizontal p').text).to include("You are already enrolled")
      expect(f('.btn-primary').text).to eq primary_action
      get "/"
      assert_valid_dashboard
    end
  end

  context "in a published course" do
    let(:active_course){ true }
    let(:set_up_course){ }
    let(:primary_action){ "Go to the Course" }
    let(:assert_valid_dashboard) {
      expect(f('#courses_menu_item')).to include_text("Courses")
    }
    
    context "with open registration" do
      include_examples "open registration"
    end
    context "without open registration" do
      include_examples "closed registration"
    end
  end

  context "in a not-yet-started course" do
    let(:active_course){ true }
    let(:set_up_course) {
      @course.start_at = 1.week.from_now
      @course.restrict_enrollments_to_course_dates = true
      @course.save!
    }
    let(:primary_action){ "Go to your Dashboard" }
    let(:assert_valid_dashboard) {
      expect(f('#courses_menu_item')).to include_text("Courses") # show for future course
      expect(f('#dashboard')).to include_text("You've enrolled in one or more courses that have not started yet")
    }
    context "with open registration" do
      include_examples "open registration"
    end
    context "without open registration" do
      include_examples "closed registration"
    end
  end

  context "in an unpublished course" do
    let(:active_course){ false }
    let(:set_up_course){ }
    let(:primary_action){ "Go to your Dashboard" }
    let(:assert_valid_dashboard) {
      expect(f('#courses_menu_item')).to include_text("Courses")
      expect(f('#dashboard')).to include_text("You've enrolled in one or more courses that have not started yet")
    }
    context "with open registration" do
      include_examples "open registration"
    end
    context "without open registration" do
      include_examples "closed registration"
    end
  end

end
