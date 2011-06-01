require File.expand_path(File.dirname(__FILE__) + '/common')

shared_examples_for "course selenium tests" do
  it_should_behave_like "in-process server selenium tests"

  it "should properly hide the wizard and remember its hidden state" do
    course_with_teacher_logged_in

    get "/getting_started?fresh=1"
    driver.find_element(:css, ".save_button").click
    wizard_box = driver.find_element(:id, "wizard_box")
    keep_trying { wizard_box.displayed? }
    wizard_box.find_element(:css, ".close_wizard_link").click

    driver.navigate.refresh
    sleep 1 # we need to give the wizard a chance to pop up
    wizard_box = driver.find_element(:id, "wizard_box")
    wizard_box.displayed?.should be_false
  end

  it "should allow moving a student to a different section" do
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
      login_as(logged_in_user[:username], logged_in_user[:password])

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
          section_label = enrollment_element.find_element(:css, ".section") rescue nil
          section_dropdown = enrollment_element.find_element(:css, ".enrollment_course_section_form #course_section_id") rescue nil
          edit_section_link = enrollment_element.find_element(:css, ".edit_section_link") rescue nil
          unenroll_user_link = enrollment_element.find_element(:css, ".unenroll_user_link") rescue nil

          # Observers don't have a section
          if enrollment_type == :observer
            edit_section_link.nil?.should be_true
            section_label.nil?.should be_true
            next
          end
          section_label.nil?.should be_false
          section_label.displayed?.should be_true

          # "hover" over the user to make the links appear
          driver.execute_script("$('.user_list #enrollment_#{enrollment.id} .links').css('visibility', 'visible')")
          # All users can manage students; admins and teachers can manage all enrollment types
          can_modify = enrollment_type == :student || [:admin, :teacher].include?(user_type)
          if sis_type == :plain || logged_in_user == admin
            section_dropdown.displayed?.should be_false

            if can_modify
              edit_section_link.nil?.should be_false
              unenroll_user_link.nil?.should be_false

              # Move sections
              edit_section_link.click
              section_label.displayed?.should be_false
              section_dropdown.displayed?.should be_true
              section_dropdown.find_element(:css, "option[value=\"#{section.id.to_s}\"]").select

              keep_trying { !section_dropdown.displayed? }

              enrollment.reload
              enrollment.course_section_id.should == section.id
              section_label.displayed?.should be_true
              section_label.text.should == section.name

              # reset this enrollment for the next user
              enrollment.course_section = c.default_section
              enrollment.save!
            else
              edit_section_link.nil?.should be_true
              unenroll_user_link.nil?.should be_true
            end
          else
            edit_section_link.nil?.should be_true
            if can_modify
              unenroll_user_link.nil?.should be_false
              unenroll_user_link.attribute(:class).should match(/cant_unenroll/)
            else
              unenroll_user_link.nil?.should be_true
            end
          end
        end
      end
    end
  end
end

describe "course Windows-Firefox-Tests" do
  it_should_behave_like "course selenium tests"
end
