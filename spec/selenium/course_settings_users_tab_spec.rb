require File.expand_path(File.dirname(__FILE__) + '/common')

describe "course settings" do
  it_should_behave_like "in-process server selenium tests"

  before (:each) do
    course_with_teacher_logged_in :limit_privileges_to_course_section => false
    @account = @course.account
    custom_student_role("custom stu")
  end

  def add_user(email, type, section_name=nil)
    get "/courses/#{@course.id}/settings#tab-users"
    add_button = f('.add_users_link')
    keep_trying_until { add_button.should be_displayed }
    add_button.click
    click_option('#enrollment_type', type)
    click_option('#course_section_id_holder > #course_section_id', section_name) if section_name
    f('#user_list_boxes .user_list').send_keys(email)
    f('.verify_syntax_button').click
    wait_for_ajax_requests
    f('#user_list_parsed').should include_text(email)
    f('.add_users_button').click
    wait_for_ajax_requests
  end

  describe "course users" do
    def select_from_auto_complete(text, input_id)
      fj(".token_input input:visible").send_keys(text)
      keep_trying_until do
        driver.execute_script("return $('##{input_id}').data('token_input').selector.lastSearch") == text
      end
      elements = driver.execute_script("return $('.autocomplete_menu:visible .list').last().find('ul').last().find('li').toArray();").map { |e|
        [e, (e.find_element(:tag_name, :b).text rescue e.text)]
      }
      element = elements.detect { |e| e.last == text } or raise "menu item does not exist"

      element.first.click
    end

    def go_to_users_tab
      get "/courses/#{@course.id}/settings#tab-users"
      wait_for_ajaximations
    end

    def open_kyle_menu(user)
      cog = f("#user_#{user.id} .admin-links")
      f('button', cog).click
      cog
    end

    it "should add a user to a section" do
      user = user_with_pseudonym(:active_user => true, :username => 'user@example.com', :name => 'user@example.com')
      section_name = 'Add User Section'
      add_section(section_name)

      add_user(user.name, "custom stu", section_name)
      refresh_page #needed to update the student count on the next page

      get "/courses/#{@course.id}/settings/#tab-sections"
      new_section = ff('#sections > .section')[1]
      new_section.find_element(:css, '.users_count').should include_text("1")
    end

    it "should remove a user from the course" do
      username = "user@example.com"
      student_in_course(:name => username, :role_name => 'custom stu')
      add_section('Section1')
      @enrollment.course_section = @course_section; @enrollment.save!

      go_to_users_tab
      f('#tab-users').should include_text(username)

      cog = open_kyle_menu(@student)
      f('a[data-event="removeFromCourse"]', cog).click
      driver.switch_to.alert.accept
      wait_for_ajaximations
      f('#tab-users').should_not include_text(username)
    end

    def add_user_to_second_section(role_name=nil)
      student_in_course(:role_name => role_name)
      section_name = 'Another Section'
      add_section(section_name)
      # open tab
      go_to_users_tab
      f("#user_#{@student.id} .section").should_not include_text(section_name)
      # open dialog
      cog = open_kyle_menu(@student)
      f('a[data-event="editSections"]', cog).click
      wait_for_ajaximations
      # choose section
      select_from_auto_complete(section_name, 'section_input')
      f('.ui-dialog-buttonpane .btn-primary').click
      wait_for_ajaximations
      # expect
      f("#user_#{@student.id} .sections").should include_text(section_name)
      ff("#user_#{@student.id} .section").length.should == 2
      @student.reload
      @student.enrollments.each{|e|e.role_name.should == role_name}
    end

    it "should add a user without custom role to another section" do
      add_user_to_second_section
    end

    it "should view the users enrollment details" do
      username = "user@example.com"
      # add_section 'foo'
      student_in_course(:name => username, :active_all => true)

      go_to_users_tab
      # open dialog
      open_kyle_menu(@student)
      # when
      link = driver.find_element(:link, 'User Details')
      href = link['href']
      link.click
      wait_for_ajax_requests
      # expect
      driver.current_url.should include(href)
    end

    def use_link_dialog(observer)
      cog = open_kyle_menu(observer)
      f('a[data-event="linkToStudents"]', cog).click
      wait_for_ajaximations
      yield
      f('.ui-dialog-buttonpane .btn-primary').click
      wait_for_ajaximations
    end

    it "should deal with observers linked to multiple students" do
      students = []
      obs = user_model(:name => "The Observer")
      2.times do |i|
        student_in_course(:name => "Student #{i}")
        students << @student
        e = @course.observer_enrollments.create!(:user => obs, :workflow_state => 'active')
        e.associated_user_id = @student.id
        e.save!
      end
      student_in_course(:name => "Student 3")
      students << @student

      go_to_users_tab

      observeds = ff("#user_#{obs.id} .enrollment_type")
      observeds.length.should == 2
      observeds_txt = observeds.map(&:text).join(',')
      observeds_txt.should include_text students[0].name
      observeds_txt.should include_text students[1].name
      # remove an observer
      use_link_dialog(obs) do
        fj("#link_students input:visible").send_keys(:backspace)
      end
      # expect
      obs.reload.not_ended_enrollments.count.should == 1
      # add an observer
      use_link_dialog(obs) do
        select_from_auto_complete(students[2].name, 'student_input')
      end
      # expect
      obs.reload.not_ended_enrollments.count.should == 2
      obs.reload.not_ended_enrollments.map { |e| e.associated_user_id }.sort.should include(students[2].id)
    end

    it "should handle deleted observees" do
      custom_observer_role("obob")
      students = []
      obs = user_model(:name => "The Observer")
      student_in_course(:name => "Student 1", :active_all => true, :role_name => 'custom stu')
      @course.enroll_user(obs, 'ObserverEnrollment', :enrollment_state => 'active', :associated_user_id => @student.id, :role_name => 'obob')
      student_in_course(:name => "Student 2", :active_all => true, :role_name => 'custom stu')
      @course.enroll_user(obs, 'ObserverEnrollment', :enrollment_state => 'active', :associated_user_id => @student.id, :allow_multiple_enrollments => true, :role_name => 'obob')

      # bye bye Student 2
      @enrollment.destroy

      go_to_users_tab

      observeds = ff("#user_#{obs.id} .enrollment_type")
      observeds.length.should == 1
      observeds.first.text.should include "Student 1"
      observeds.first.text.should_not include "Student 2"

      # dialog loads too
      use_link_dialog(obs) do
        input = fj("#link_students")
        input.text.should include "Student 1"
        input.text.should_not include "Student 2"
      end
    end

    %w[ta designer].each do |et|
      it "should not let #{et}s remove admins from the course" do
        send "custom_#{et}_role", "custom"
        send "course_with_#{et}", :course => @course, :active_all => true, :custom_role => 'custom'
        user_session @user
        student_in_course :course => @course, :role_name => 'custom stu'

        go_to_users_tab

        # should NOT see remove link for teacher
        cog = open_kyle_menu @teacher
        f('a[data-event="removeFromCourse"]', cog).should be_nil
        # should see remove link for student
        cog = open_kyle_menu @student
        f('a[data-event="removeFromCourse"]', cog).should_not be_nil
      end
    end

    it "should not show the student view student" do
      @fake_student = @course.student_view_student
      go_to_users_tab
      ff(".student_enrollments #user_#{@fake_student.id}").should be_empty
    end

    context "custom roles" do

      it "should create new observer enrollments as custom type when adding observees" do
        custom_observer_role("custom observer")
        student_in_course :course => @course
        e = course_with_observer(:course => @course, :role_name => "custom observer")

        go_to_users_tab

        use_link_dialog(@observer) do
          select_from_auto_complete(@student.name, 'student_input')
        end

        @observer.reload
        @observer.enrollments.each{|e|e.role_name.should == 'custom observer'}
      end

      it "should create new enrollments as custom type when adding sections" do
        add_user_to_second_section('custom stu')
      end

      def select_new_role_type(type)
        get "/courses/#{@course.id}/settings#tab-users"
        add_button = f('.add_users_link')
        keep_trying_until { add_button.should be_displayed }
        add_button.click
        click_option('#enrollment_type', type)
      end

      %w[student teacher ta designer observer].each do |base_type|
        it "should allow adding custom #{base_type} enrollments" do
          user = user_with_pseudonym(:active_user => true, :username => "#{base_type}@example.com", :name => "#{base_type}@example.com")
          send "custom_#{base_type}_role", "custom"
          add_user(user.name, "custom")
          f("#user_#{user.id} .admin-links").should_not be_nil
        end

        if base_type == 'teacher' || base_type == 'ta'
          it "should show section limited checkbox for custom #{base_type} enrollments" do
            send "custom_#{base_type}_role", "custom"
            select_new_role_type("custom")
            f('#limit_privileges_to_course_section').should be_displayed
          end
        else
          it "should not show section limited checkbox for custom #{base_type} enrollments" do
            send "custom_#{base_type}_role", "custom"
            select_new_role_type("custom")
            f('#limit_privileges_to_course_section').should_not be_displayed
          end
        end
      end

    end
  end

end
