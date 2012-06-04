require File.expand_path(File.dirname(__FILE__) + '/common')

describe "courses" do
  it_should_behave_like "in-process server selenium tests"

  context "as a teacher" do

    before (:each) do
      account = Account.default
      account.settings = {:open_registration => true, :no_enrollments_can_create_courses => true, :teachers_can_create_courses => true}
      account.save!
    end

    it "should properly hide the wizard and remember its hidden state" do
      course_with_teacher_logged_in

      get "/getting_started?fresh=1"
      driver.find_element(:css, ".save_button").click
      wizard_box = driver.find_element(:id, "wizard_box")
      keep_trying_until { wizard_box.displayed? }
      wizard_box.find_element(:css, ".close_wizard_link").click

      refresh_page
      wait_for_animations # we need to give the wizard a chance to pop up
      wizard_box = driver.find_element(:id, "wizard_box")
      wizard_box.displayed?.should be_false

      # un-remember the setting
      driver.execute_script "localStorage.clear()"
    end

    it "should open and close wizard after initial close" do
      def find_wizard_box
        wizard_box = keep_trying_until do
          wizard_box = driver.find_element(:id, "wizard_box")
          wizard_box.should be_displayed
          wizard_box
        end
        wizard_box
      end

      course_with_teacher_logged_in
      get "/getting_started"

      expect_new_page_load { driver.find_element(:css, ".save_button").click }
      wait_for_animations
      wizard_box = find_wizard_box
      wizard_box.find_element(:css, ".close_wizard_link").click
      wait_for_animations
      wizard_box.should_not be_displayed
      checklist_button = driver.find_element(:css, '.wizard_popup_link')
      checklist_button.should be_displayed
      checklist_button.click
      wait_for_animations
      checklist_button.should_not be_displayed
      wizard_box = find_wizard_box
      wizard_box.find_element(:css, ".close_wizard_link").click
      wait_for_animations
      wizard_box.should_not be_displayed
      checklist_button.should be_displayed
    end

    it "should correctly update the course quota" do
      course_with_admin_logged_in

      # first try setting the quota explicitly
      get "/courses/#{@course.id}/details"
      driver.find_element(:link, 'Course Details').click
      form = driver.find_element(:css, "#course_form")
      driver.find_element(:css, "#course_form .edit_course_link").should be_displayed
      form.find_element(:css, ".edit_course_link").click
      quota_input = form.find_element(:css, "input#course_storage_quota_mb")
      quota_input.clear
      quota_input.send_keys("10")
      submit_form(form)
      keep_trying_until { driver.find_element(:css, ".loading_image_holder").nil? rescue true }
      form.find_element(:css, ".course_info.storage_quota_mb").text.should == "10"

      # then try just saving it (without resetting it)
      get "/courses/#{@course.id}/details"
      form = driver.find_element(:css, "#course_form")
      form.find_element(:css, ".course_info.storage_quota_mb").text.should == "10"
      form.find_element(:css, ".edit_course_link").click
      submit_form(form)
      keep_trying_until { driver.find_element(:css, ".loading_image_holder").nil? rescue true }
      form.find_element(:css, ".course_info.storage_quota_mb").text.should == "10"

      # then make sure it's right after a reload
      get "/courses/#{@course.id}/details"
      form = driver.find_element(:css, "#course_form")
      form.find_element(:css, ".course_info.storage_quota_mb").text.should == "10"
      @course.reload
      @course.storage_quota.should == 10.megabytes
    end

    it "should allow moving a student to a different section" do
      # this spec does lots of find_element where we expect that it won't exist.
      driver.manage.timeouts.implicit_wait = 0

      c = course :active_course => true
      users = {:plain => {}, :sis => {}}
      [:plain, :sis].each do |sis_type|
        [:student, :observer, :ta, :teacher].each do |enrollment_type|
          user = {
              :username => "#{enrollment_type}+#{sis_type}@example.com",
              :password => "#{enrollment_type}#{sis_type}1"
          }
          user[:user] = user_with_pseudonym :active_user => true,
                                            :username => user[:username],
                                            :password => user[:password]
          user[:enrollment] = c.enroll_user(user[:user], "#{enrollment_type.to_s.capitalize}Enrollment", :enrollment_state => 'active')
          if sis_type == :sis
            user[:enrollment].sis_source_id = "#{enrollment_type}.sis.1"
            user[:enrollment].save!
          end
          users[sis_type][enrollment_type] = user
        end
      end
      admin = {
          :username => 'admin@example.com',
          :password => 'admin1'
      }
      admin[:user] = account_admin_user :active_user => true
      user_with_pseudonym :user=> admin[:user],
                          :username => admin[:username],
                          :password => admin[:password]
      users[:plain][:admin] = admin

      section = c.course_sections.create!(:name => 'M/W/F')

      users[:plain].each do |user_type, logged_in_user|
        # Students and Observers can't do anything
        next if user_type == :student || user_type == :observer
        create_session(logged_in_user[:user].pseudonyms.first, false)

        get "/courses/#{c.id}/details"

        driver.find_element(:css, '#tab-users-link').click

        users.each do |sis_type, users2|
          users2.each do |enrollment_type, user|
            # Admin isn't actually enrolled
            next if enrollment_type == :admin
            # You can't move yourself
            next if user == logged_in_user

            enrollment = user[:enrollment]
            enrollment_element = driver.find_element(:css, "#enrollment_#{enrollment.id}")
            section_label = enrollment_element.find_element(:css, ".section_name") rescue nil
            section_dropdown = enrollment_element.find_element(:css, ".enrollment_course_section_form .course_section_id") rescue nil
            edit_section_link = enrollment_element.find_element(:css, ".edit_section_link") rescue nil
            unenroll_user_link = enrollment_element.find_element(:css, ".unenroll_user_link") rescue nil

            # Observers don't have a section
            if enrollment_type == :observer
              edit_section_link.should be_nil
              section_label.should be_nil
              next
            end
            section_label.should_not be_nil
            section_label.should be_displayed

            # "hover" over the user to make the links appear
            driver.execute_script("$('.user_list #enrollment_#{enrollment.id} .links').css('visibility', 'visible')")
            # All users can manage students; admins and teachers can manage all enrollment types
            can_modify = enrollment_type == :student || [:admin, :teacher].include?(user_type)
            if sis_type == :plain || logged_in_user == admin
              section_dropdown.should_not be_displayed

              if can_modify
                edit_section_link.should_not be_nil
                unenroll_user_link.should_not be_nil

                # Move sections
                edit_section_link.click
                section_label.should_not be_displayed
                section_dropdown.should be_displayed
                section_dropdown.find_element(:css, "option[value=\"#{section.id.to_s}\"]").click

                keep_trying_until { !section_dropdown.should_not be_displayed }

                enrollment.reload
                enrollment.course_section_id.should == section.id
                section_label.should be_displayed
                section_label.text.should == section.name

                # reset this enrollment for the next user
                enrollment.course_section = c.default_section
                enrollment.save!
              else
                edit_section_link.should be_nil
                unenroll_user_link.should be_nil
              end
            else
              edit_section_link.should be_nil
              if can_modify
                unenroll_user_link.should_not be_nil
                unenroll_user_link.should have_class('cant_unenroll')
              else
                unenroll_user_link.should be_nil
              end
            end
          end
        end
      end
    end

    it "should not redirect to the gradebook when switching courses when viewing a student's grades" do
      teacher = user_with_pseudonym(:username => 'teacher@example.com', :active_all => 1)
      student = user_with_pseudonym(:username => 'student@example.com', :active_all => 1)
      course1 = course_with_teacher_logged_in(:user => teacher, :active_all => 1).course
      student_in_course :user => student, :active_all => 1
      course2 = course_with_teacher(:user => teacher, :active_all => 1).course
      student_in_course :user => student, :active_all => 1
      create_session(teacher.pseudonyms.first, false)

      get "/courses/#{course1.id}/grades/#{student.id}"

      select = driver.find_element(:id, 'course_url')
      options = select.find_elements(:css, 'option')
      options.length.should == 2
      select.click
      find_with_jquery('#course_url option:not([selected])').click

      driver.current_url.should match %r{/courses/#{course2.id}/grades/#{student.id}}
    end
  end

  context "course as a student" do

    def enroll_student(student, accept_invitation)
      if accept_invitation
        @course.enroll_student(student).accept
      else
        @course.enroll_student(student)
      end
    end

    before (:each) do
      course_with_teacher(:active_all => true, :name => 'discussion course')
      @student = user_with_pseudonym(:active_user => true, :username => 'student@example.com', :name => 'student@example.com', :password => 'asdfasdf')
    end

    it "should accept the course invitation" do
      enroll_student(@student, false)

      login_as(@student.name)
      get "/courses/#{@course.id}"
      driver.find_element(:css, ".reminder .button[name='accept'] ").click
      assert_flash_notice_message /Invitation accepted!/
    end

    it "should reject a course invitation" do
      enroll_student(@student, false)

      login_as(@student.name)
      get "/courses/#{@course.id}"
      driver.find_element(:css, ".reminder .reject_button").click
      driver.switch_to.alert.accept
      assert_flash_notice_message /Invitation canceled./
    end

    it "should validate that a user cannot see a course they are not enrolled in" do
      login_as(@student.name)
      driver.find_element(:css, '#menu').should_not include_text('Courses')
    end
  end
end
