require File.expand_path(File.dirname(__FILE__) + '/common')

describe "user selenium tests" do
  it_should_behave_like "in-process server selenium tests"

  context "logins" do
    it "should allow setting passwords for new pseudonyms" do
      admin = User.create!
      Account.site_admin.add_user(admin)
      user_session(admin)

      @user = User.create!
      course.enroll_student(@user)

      get "/users/#{@user.id}"
      pseudonym_form = f('#edit_pseudonym_form')
      driver.find_element(:css, ".add_pseudonym_link").click
      pseudonym_form.find_element(:css, "#pseudonym_unique_id").send_keys('new_user')
      pseudonym_form.find_element(:css, "#pseudonym_password").send_keys('qwerty1')
      pseudonym_form.find_element(:css, "#pseudonym_password_confirmation").send_keys('qwerty1')
      submit_form(pseudonym_form)
      wait_for_ajaximations

      new_login = driver.find_elements(:css, '.login').select { |e| e.attribute(:class) !~ /blank/ }.first
      new_login.should_not be_nil
      new_login.find_element(:css, '.account_name').text().should_not be_blank
      pseudonym = Pseudonym.by_unique_id('new_user').first
      pseudonym.valid_password?('qwerty1').should be_true
    end
  end

  context "admin merge" do
    STUDENT_1_ID = 'student1@example.com'
    STUDENT_2_ID = 'student2@example.com'
    WORKFLOW_STATES = %w(registered deleted)

    def setup_user_merge(users)
      2.times { |i| get "/users/#{users[i].id}/admin_merge" }
    end

    def reload_users(users)
      users.each { |user| user.reload }
    end

    def submit_merge
      expect_new_page_load { f('#prepare_to_merge').click }
      expect_new_page_load { f('button[type="submit"]').click }
    end

    def validate_login_info(user_id)
      f('#login_information').should include_text(user_id)
    end

    before (:each) do
      course_with_admin_logged_in
      @student_1 = User.create!(:name => 'Student One')
      @student_1.register!
      @student_1.pseudonyms.create!(:unique_id => STUDENT_1_ID, :password => 'asdfasdf', :password_confirmation => 'asdfasdf')
      @course.enroll_user(@student_1).accept!

      @student_2 = User.create!(:name => 'Student Two')
      @student_2.register!
      @student_2.pseudonyms.create!(:unique_id => STUDENT_2_ID, :password => 'asdfasdf', :password_confirmation => 'asdfasdf')
      @course.enroll_user(@student_2).accept!
      @users = [@student_1, @student_2]
    end

    it "should merge user a with user b with navigate to another user function" do
      setup_user_merge(@users)
      submit_merge
      reload_users(@users)
      @student_1.workflow_state.should == 'registered'
      @student_2.workflow_state.should == 'deleted'
      validate_login_info(STUDENT_1_ID)
    end

    it "should merge user b with user a with enter user id function" do
      get "/users/#{@student_1.id}/admin_merge"
      f('#manual_user_id').send_keys(@student_2.id)
      expect_new_page_load { f('button[type="submit"]').click }
      submit_merge
      reload_users(@users)
      @student_1.workflow_state.should == 'deleted'
      @student_2.workflow_state.should == 'registered'
      validate_login_info(STUDENT_2_ID)
    end

    it "should validate switching the users to merge" do
      setup_user_merge(@users)
      user_names = ff('.result td')
      user_names[0].should include_text(@student_2.name)
      user_names[1].should include_text(@student_1.name)
      f('#switch_user_positions').click
      wait_for_ajax_requests
      user_names = ff('.result td')
      user_names[0].should include_text(@student_1.name)
      user_names[1].should include_text(@student_2.name)
      submit_merge
      reload_users(@users)
      @student_1.workflow_state.should == 'deleted'
      @student_2.workflow_state.should == 'registered'
      validate_login_info(STUDENT_1_ID)
    end

    it "should cancel a merge and validate both users still exist" do
      setup_user_merge(@users)
      expect_new_page_load { f('#prepare_to_merge').click }
      expect_new_page_load { f('.button-secondary').click }
      f('#courses_menu_item').should be_displayed
      @student_1.workflow_state.should == 'registered'
      @student_2.workflow_state.should == 'registered'
    end
  end
end
