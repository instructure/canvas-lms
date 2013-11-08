require File.expand_path(File.dirname(__FILE__) + '/common')

describe "course people" do
  it_should_behave_like "in-process server selenium tests"

  before (:each) do
    course_with_teacher_logged_in :limit_privileges_to_course_section => false
    @account = @course.account # for custom roles
    custom_student_role("custom stu")
  end

  def add_user(email, type, section_name=nil)
    get "/courses/#{@course.id}/users"
    add_button = f('#addUsers')
    keep_trying_until { add_button.should be_displayed }
    add_button.click
    wait_for_ajaximations

    click_option('#enrollment_type', type)
    click_option('#course_section_id', section_name) if section_name
    f('#user_list_textarea').send_keys(email)
    f('#next-step').click
    wait_for_ajaximations
    f('#create-users-verified').should include_text(email)
    f('#createUsersAddButton').click
    wait_for_ajax_requests
    f('.dialog_closer').click
    wait_for_ajaximations
  end

  describe "course users" do
    def select_from_auto_complete(text, input_id)
      fj(".token_input input:visible").send_keys(text)
      wait_for_ajaximations

      keep_trying_until { driver.execute_script("return $('##{input_id}').data('token_input').selector.list.query.search") == text }
      wait_for_js
      elements = ffj(".autocomplete_menu:visible .list:last ul:last li").map { |e|
        [e, (e.find_element(:tag_name, :b).text rescue e.text)]
      }
      wait_for_js
      element = elements.detect { |e| e.last == text }
      element.should_not be_nil
      element.first.click
      wait_for_ajaximations
    end

    def go_to_people_page
      get "/courses/#{@course.id}/users"
    end

    def kyle_menu(user, role = nil)
      if role
        role_name = if role.respond_to?(:name)
          role.name
        else
          role
        end
        f("#user_#{user.id}.#{role_name} .admin-links")
      else
        f("#user_#{user.id} .admin-links")
      end
    end

    def open_kyle_menu(user, role = nil)
      cog = kyle_menu(user, role)
      f('.al-trigger', cog).click
      wait_for_ajaximations
      cog
    end

    def remove_user(user, role = nil)
      cog = open_kyle_menu(user, role)
      f('a[data-event="removeFromCourse"]', cog).click
      driver.switch_to.alert.accept
      wait_for_ajaximations
    end

    it "should remove a user from the course" do
      username = "user@example.com"
      student_in_course(:name => username, :role_name => 'custom stu')
      add_section('Section1')
      @enrollment.course_section = @course_section; @enrollment.save!

      go_to_people_page
      f('.roster').should include_text(username)

      remove_user(@student)
      f('.roster').should_not include_text(username)
    end

    def add_user_to_second_section(role_name=nil)
      student_in_course(:role_name => role_name)
      section_name = 'Another Section'
      add_section(section_name)
      # open tab
      go_to_people_page
      f("#user_#{@student.id} .section").should_not include_text(section_name)
      # open dialog
      use_edit_sections_dialog(@student) do
        # choose section
        select_from_auto_complete(section_name, 'section_input')
      end
      # expect
      f("#user_#{@student.id}").should include_text(section_name)
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

      go_to_people_page
      # open dialog
      open_kyle_menu(@student)
      # when
      link = driver.find_element(:link, 'User Details')
      href = link['href']
      link.click
      wait_for_ajaximations
      wait_for_ajax_requests
      # expect
      driver.current_url.should include(href)
    end

    def use_link_dialog(observer, role = nil)
      cog = open_kyle_menu(observer, role)
      f('a[data-event="linkToStudents"]', cog).click
      wait_for_ajaximations
      yield
      f('.ui-dialog-buttonpane .btn-primary').click
      wait_for_ajaximations
    end

    def use_edit_sections_dialog(user, role = nil)
      cog = open_kyle_menu(user, role)
      f('a[data-event="editSections"]', cog).click
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

      go_to_people_page

      observer_row = ff("#user_#{obs.id}").map(&:text).join(',')
      observer_row.should include_text students[0].name
      observer_row.should include_text students[1].name
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

    it "should handle deleted observee enrollments" do
      custom_observer_role("obob")
      obs = user_model(:name => "The Observer")
      student_in_course(:name => "Student 1", :active_all => true, :role_name => 'custom stu')
      @course.enroll_user(obs, 'ObserverEnrollment', :enrollment_state => 'active', :associated_user_id => @student.id, :role_name => 'obob')
      student = student_in_course(:name => "Student 2", :active_all => true, :role_name => 'custom stu')
      obs_enrollment = @course.enroll_user(obs, 'ObserverEnrollment', :enrollment_state => 'active', :associated_user_id => @student.id, :allow_multiple_enrollments => true, :role_name => 'obob')

      # bye bye Student 2
      obs_enrollment.destroy

      go_to_people_page

      observer_row = ff("#user_#{obs.id}").map(&:text).join(',')
      observer_row.should include "Student 1"
      observer_row.should_not include "Student 2"

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

        go_to_people_page

        # should NOT see remove link for teacher
        kyle_menu(@teacher).should be_nil
        # should see remove link for student
        cog = open_kyle_menu @student
        fj('a[data-event="removeFromCourse"]', cog).should_not be_nil
      end
    end

    it "should not show the student view student" do
      @fake_student = @course.student_view_student
      go_to_people_page
      ff(".student_enrollments #user_#{@fake_student.id}").should be_empty
    end

    context "multiple enrollments" do
      it "should link an observer enrollment when other enrollment types exist" do
        course_with_student :course => @course, :active_all => true, :name => 'teh student'
        course_with_ta :course => @course, :active_all => true
        course_with_observer :course => @course, :active_all => true, :user => @ta

        go_to_people_page
        use_link_dialog(@observer, 'ObserverEnrollment') do
          select_from_auto_complete(@student.name, 'student_input')
        end

        @observer.enrollments.find_by_associated_user_id(@student.id).should_not be_nil
        f("#user_#{@observer.id}.ObserverEnrollment").text.should include("Observing: #{@student.name}")
      end
    end

    context "custom roles" do
      it "should create new observer enrollments as custom type when adding observees" do
        custom_observer_role("custom observer")
        student_in_course :course => @course
        e = course_with_observer(:course => @course, :role_name => "custom observer")

        go_to_people_page

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
        get "/courses/#{@course.id}/users"
        add_button = f('#addUsers')
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

    it "should not remove a base enrollment when adding a custom enrollment of the same base type" do
      @role = custom_teacher_role "Mentor"
      add_user(@teacher.name, "Mentor")
      teacher_row = f("#user_#{@teacher.id}")
      teacher_row.should have_class("TeacherEnrollment")
      teacher_row.should have_class("Mentor")
    end
  end

end
