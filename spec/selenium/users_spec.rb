require File.expand_path(File.dirname(__FILE__) + '/common')

describe "users" do
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
      f(".add_pseudonym_link").click
      pseudonym_form.find_element(:css, "#pseudonym_unique_id").send_keys('new_user')
      pseudonym_form.find_element(:css, "#pseudonym_password").send_keys('qwerty1')
      pseudonym_form.find_element(:css, "#pseudonym_password_confirmation").send_keys('qwerty1')
      submit_form(pseudonym_form)
      wait_for_ajaximations

      new_login = ff('.login').select { |e| e.attribute(:class) !~ /blank/ }.first
      new_login.should_not be_nil
      new_login.find_element(:css, '.account_name').text().should_not be_blank
      pseudonym = Pseudonym.by_unique_id('new_user').first
      pseudonym.valid_password?('qwerty1').should be_true
    end
  end

  context "page views" do

    before (:each) do
      @teacher = course_with_teacher_logged_in
      @student = student_in_course.user
      Setting.set('enable_page_views', 'db')
    end

    it "should validate a basic page view" do
      page_view(:user => @student, :course => @course, :url => 'assignments')
      get "/users/#{@student.id}"
      rows = ff('#page_view_results tr')
      rows.count.should == 1
      page_view = rows.first
      page_view.should include_text('Firefox')
      page_view.should include_text('assignments')
      f('#page_view_results tr img').should be_nil # should not have a participation
    end

    it "should validate page view with a participation" do
      page_view(:user => @student, :course => @course, :participated => true)
      get "/users/#{@student.id}"
      f("#page_view_results img").should have_attribute(:src, '/images/checked.png')
    end

    it "should validate a page view url" do
      second_student_name = 'test student for page views'
      get "/users/#{@student.id}"
      page_view(:user => @student, :course => @course, :participated => true, :url => student_in_course(:name => second_student_name).user.id.to_s)
      refresh_page # in order to get the generated page view
      page_view_url = f('#page_view_results a')
      second_student = User.find_by_name(second_student_name)
      page_view_url.text.should == second_student.id.to_s
      expect_new_page_load { page_view_url.click }
      f('.user_details .name').text.should == second_student.name
      ff("#page_view_results tr").length.should == 0 # validate the second student has no page views
    end

    it "should validate all page views were loaded" do
      page_views_count = 100
      page_views_count.times { |i| page_view(:user => @student, :course => @course, :url => "#{"%03d" % i}") }
      get "/users/#{@student.id}"
      wait_for_ajaximations
      driver.execute_script("$('#pageviews').scrollTop($('#pageviews')[0].scrollHeight);")
      wait_for_ajaximations
      ff("#page_view_results tr").length.should == page_views_count
    end
  end

  context "admin merge" do
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
      @student_1_id = 'student1@example.com'
      @student_2_id = 'student2@example.com'

      course_with_admin_logged_in
      @student_1 = User.create!(:name => 'Student One')
      @student_1.register!
      @student_1.pseudonyms.create!(:unique_id => @student_1_id, :password => 'asdfasdf', :password_confirmation => 'asdfasdf')
      @course.enroll_user(@student_1).accept!

      @student_2 = User.create!(:name => 'Student Two')
      @student_2.register!
      @student_2.pseudonyms.create!(:unique_id => @student_2_id, :password => 'asdfasdf', :password_confirmation => 'asdfasdf')
      @course.enroll_user(@student_2).accept!
      @users = [@student_1, @student_2]
    end

    it "should merge user a with user b with navigate to another user function" do
      setup_user_merge(@users)
      submit_merge
      reload_users(@users)
      @student_1.workflow_state.should == 'registered'
      @student_2.workflow_state.should == 'deleted'
      validate_login_info(@student_1_id)
    end

    it "should merge user b with user a with enter user id function" do
      get "/users/#{@student_1.id}/admin_merge"
      f('#manual_user_id').send_keys(@student_2.id)
      expect_new_page_load { f('button[type="submit"]').click }
      submit_merge
      reload_users(@users)
      @student_1.workflow_state.should == 'deleted'
      @student_2.workflow_state.should == 'registered'
      validate_login_info(@student_2_id)
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
      validate_login_info(@student_1_id)
    end

    it "should cancel a merge and validate both users still exist" do
      setup_user_merge(@users)
      expect_new_page_load { f('#prepare_to_merge').click }
      expect_new_page_load { f('.button-secondary').click }
      f('#courses_menu_item').should be_displayed
      @student_1.workflow_state.should == 'registered'
      @student_2.workflow_state.should == 'registered'
    end

    it "should show an error if the user id entered is the current users" do
      get "/users/#{@student_1.id}/admin_merge"
      f('.static_message').should be_false
      f('#manual_user_id').send_keys(@student_1.id)
      expect_new_page_load { f('button[type="submit"]').click }
      f('.static_message').text.should =~ /You can't merge an account with itself./
    end

    it "should show an error if invalid text is entered in the id box" do
      get "/users/#{@student_1.id}/admin_merge"
      f('.static_message').should be_false
      f('#manual_user_id').send_keys("azxcvbytre34567uijmm23456yhj")
      expect_new_page_load { f('button[type="submit"]').click }
      f('.static_message').text.should =~ /No active user with that ID was found./
    end

    it "should show an error if the user id doesnt exist" do
      get "/users/#{@student_1.id}/admin_merge"
      f('.static_message').should be_false
      f('#manual_user_id').send_keys(1234567809)
      expect_new_page_load { f('button[type="submit"]').click }
      f('.static_message').text.should =~ /No active user with that ID was found./
    end
  end

  context "registration" do
    before :each do
      a = Account.default
      a.settings = {:self_registration => true}
      a.save!
    end

    it "should register a student with a join code" do
      course(:active_all => true)
      @course.update_attribute :self_enrollment, true

      get '/register'
      f('#signup_student').click

      form = fj('.ui-dialog:visible form')
      f('#student_join_code').send_keys(@course.self_enrollment_code)
      f('#student_name').send_keys('student!')
      form.find_element(:css, "select[name='user[birthdate(1i)]'] option[value='#{Time.now.year - 20}']").click
      form.find_element(:css, "select[name='user[birthdate(2i)]'] option[value='1']").click
      form.find_element(:css, "select[name='user[birthdate(3i)]'] option[value='1']").click
      f('#student_username').send_keys('student')
      f('#student_password').send_keys('asdfasdf')
      f('#student_password_confirmation').send_keys('asdfasdf')
      form.find_element(:css, 'input[name="user[terms_of_use]"]').click

      expect_new_page_load { form.submit }
      # confirm the user is authenticated into the dashboard
      f('#identity .logout').should be_present
      User.last.initial_enrollment_type.should eql 'student'
    end

    it "should register a student without a join code" do
      get '/register'
      f('#signup_student').click

      f('.registration-dialog .signup_link').click

      form = fj('.ui-dialog:visible form')
      f('#student_higher_ed_name').send_keys('student!')
      f('#student_higher_ed_email').send_keys('student@example.com')
      form.find_element(:css, "select[name='user[birthdate(1i)]'] option[value='#{Time.now.year - 20}']").click
      form.find_element(:css, "select[name='user[birthdate(2i)]'] option[value='1']").click
      form.find_element(:css, "select[name='user[birthdate(3i)]'] option[value='1']").click
      form.find_element(:css, 'input[name="user[terms_of_use]"]').click

      expect_new_page_load { form.submit }
      # confirm the user is authenticated into the dashboard
      f('#identity .logout').should be_present
      User.last.initial_enrollment_type.should eql 'student'
    end

    it "should register a teacher" do
      get '/register'
      f('#signup_teacher').click

      form = fj('.ui-dialog:visible form')
      f('#teacher_name').send_keys('teacher!')
      f('#teacher_email').send_keys('teacher@example.com')
      form.find_element(:css, 'input[name="user[terms_of_use]"]').click

      expect_new_page_load { form.submit }
      # confirm the user is authenticated into the dashboard
      f('#identity .logout').should be_present
      User.last.initial_enrollment_type.should eql 'teacher'
    end

    it "should register an observer" do
      user_with_pseudonym(:active_all => true, :password => 'lolwut')

      get '/register'
      f('#signup_parent').click

      form = fj('.ui-dialog:visible form')
      f('#parent_name').send_keys('parent!')
      f('#parent_email').send_keys('parent@example.com')
      f('#parent_child_username').send_keys(@pseudonym.unique_id)
      f('#parent_child_password').send_keys('lolwut')
      form.find_element(:css, 'input[name="user[terms_of_use]"]').click

      expect_new_page_load { form.submit }
      # confirm the user is authenticated into the dashboard
      f('#identity .logout').should be_present
      User.last.initial_enrollment_type.should eql 'observer'
    end
  end

  context "masquerading" do
    it "should masquerade as a user" do
      site_admin_logged_in(:name => "The Admin")
      user_with_pseudonym(:active_user => true, :name => "The Student")
      get "/users/#{@user.id}/masquerade"
      f('.masquerade_button').click
      wait_for_dom_ready
      f("#identity .user_name").should include_text "The Student"
      bar = f("#masquerade_bar")
      bar.should include_text "You are currently masquerading"
      bar.find_element(:css, ".stop_masquerading").click
      wait_for_dom_ready
      f("#identity .user_name").should include_text "The Admin"
    end
  end
end
