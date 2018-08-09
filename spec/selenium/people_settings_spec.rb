#
# Copyright (C) 2013 - present Instructure, Inc.
#
# This file is part of Canvas.
#
# Canvas is free software: you can redistribute it and/or modify it under
# the terms of the GNU Affero General Public License as published by the Free
# Software Foundation, version 3 of the License.
#
# Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
# A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
# details.
#
# You should have received a copy of the GNU Affero General Public License along
# with this program. If not, see <http://www.gnu.org/licenses/>.

require File.expand_path(File.dirname(__FILE__) + '/common')

describe "course people" do
  include_context "in-process server selenium tests"

  before(:once) do
    # in the people table, the kyle menu can be off the screen
    # and uninteractable if the window is too small
    make_full_screen
  end

  before (:each) do
    course_with_teacher_logged_in :limit_privileges_to_course_section => false
    @account = @course.account # for custom roles
    @custom_student_role = custom_student_role("custom stu")
  end

  def add_user(email, type, section_name=nil)
    get "/courses/#{@course.id}/users"
    add_button = f('#addUsers')
    expect(add_button).to be_displayed
    add_button.click
    wait_for_ajaximations

    click_option("#peoplesearch_select_role", type)
    click_option("#peoplesearch_select_section", section_name) if section_name
    replace_content(f(".addpeople__peoplesearch textarea"), email)

    f("#addpeople_next").click
    expect(f(".addpeople__peoplereadylist tbody tr")).to include_text(email)

    f("#addpeople_next").click
  end

  describe "course users" do
    def select_from_auto_complete(text, input_id)
      fj(".token_input input:visible").send_keys(text)
      wait_for_ajaximations

      keep_trying_until { driver.execute_script("return $('##{input_id}').data('token_input').selector.list.query.search") == text }
      wait_for_ajaximations
      elements = ffj(".autocomplete_menu:visible .list:last ul:last li").map { |e|
        [e, (e.find_element(:tag_name, :b).text rescue e.text)]
      }
      wait_for_ajaximations
      element = elements.detect { |e| e.last == text }
      expect(element).not_to be_nil
      element.first.click
      wait_for_ajaximations
    end

    def go_to_people_page
      get "/courses/#{@course.id}/users"
    end

    def kyle_menu_css(user, role = nil)
      if role
        role_name = if role.respond_to?(:name)
          role.name
        else
          role
        end
        "#user_#{user.id}.#{role_name} .admin-links"
      else
        "#user_#{user.id} .admin-links"
      end
    end

    def kyle_menu(user, role = nil)
      f(kyle_menu_css(user, role))
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
      student_in_course(:name => username, :role => @custom_student_role)
      add_section('Section1')
      @enrollment.course_section = @course_section; @enrollment.save!

      go_to_people_page
      expect(f('.roster')).to include_text(username)

      remove_user(@student)
      expect(f('.roster')).not_to include_text(username)
    end

    def add_user_to_second_section(role = nil, enrollment_state = 'invited')
      role ||= student_role
      student_in_course(:user => user_with_pseudonym, :role => role, :enrollment_state => enrollment_state)
      section_name = 'Another Section'
      add_section(section_name)
      # open tab
      go_to_people_page
      expect(f("#user_#{@student.id} .section")).not_to include_text(section_name)
      # open dialog
      use_edit_sections_dialog(@student) do
        # choose section
        select_from_auto_complete(section_name, 'section_input')
      end
      # expect
      expect(f("#user_#{@student.id}")).to include_text(section_name)
      expect(ff("#user_#{@student.id} .section").length).to eq 2
      @student.reload
      @student.enrollments.each{|e|expect(e.role_id).to eq role.id}
      @student.enrollments.each{|e|expect(e.workflow_state).to eq enrollment_state}
    end

    it "should add a user without custom role to another section" do
      add_user_to_second_section
    end

    it "adds an active enrollment to another section if the user has already accepted their enrollment" do
      add_user_to_second_section(nil, 'active')
    end

    it "should add a user to a second (active) section in a concluded course" do
      @course.start_at = 2.days.ago
      @course.conclude_at = 1.day.ago
      @course.restrict_enrollments_to_course_dates = true
      @course.save!

      student_in_course(:user => user_with_pseudonym, :role => student_role)
      section_name = 'Another Section'
      add_section(section_name)

      @course_section.end_at = 1.day.from_now
      @course_section.restrict_enrollments_to_section_dates = true
      @course_section.save!

      # open tab
      go_to_people_page
      expect(f("#user_#{@student.id} .section")).not_to include_text(section_name)
      # open dialog
      use_edit_sections_dialog(@student) do
        # choose section
        select_from_auto_complete(section_name, 'section_input')
      end
      # expect
      expect(f("#user_#{@student.id}")).to include_text(section_name)
      expect(ff("#user_#{@student.id} .section").length).to eq 2
      @student.reload
      expect(@student.enrollments.where(course_section: @course_section)).to be_exists
    end

    it "should view the users enrollment details" do
      username = "user@example.com"
      # add_section 'foo'
      student_in_course(:name => username, :active_all => true)

      go_to_people_page
      # open dialog
      open_kyle_menu(@student)
      # when
      links = ff(".admin-links li a")
      link = links.detect{|link| link.text.include?("User Details")}
      href = link['href']
      link.click
      wait_for_ajaximations
      wait_for_ajax_requests
      # expect
      expect(driver.current_url).to include(href)
    end

    it "should be able to deactivate and reactivate users" do
      username = "user@example.com"
      student_in_course(:name => username, :active_all => true)

      go_to_people_page
      cog = open_kyle_menu(@student)
      link = f('a[data-event="deactivateUser"]', cog)
      expect(link).to include_text("Deactivate User")
      link.click
      driver.switch_to.alert.accept
      wait_for_ajaximations

      expect(f("#user_#{@student.id} span.label")).to include_text("inactive")
      @enrollment.reload
      expect(@enrollment.workflow_state).to eq 'inactive'

      cog = open_kyle_menu(@student)
      link = f('a[data-event="reactivateUser"]', cog)
      expect(link).to include_text("Re-activate User")
      link.click
      wait_for_ajaximations
      expect(f("#content")).not_to contain_css("#user_#{@student.id} span.label")
      @enrollment.reload
      expect(@enrollment.workflow_state).to eq 'active'
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
      obs = user_with_pseudonym(:name => "The Observer")
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
      expect(observer_row).to include students[0].name
      expect(observer_row).to include students[1].name
      # remove an observer
      use_link_dialog(obs) do
        fj("#link_students input:visible").send_keys(:backspace)
      end
      # expect
      expect(obs.reload.not_ended_enrollments.count).to eq 1
      # add an observer
      use_link_dialog(obs) do
        select_from_auto_complete(students[2].name, 'student_input')
      end
      # expect
      expect(obs.reload.not_ended_enrollments.count).to eq 2
      expect(obs.reload.not_ended_enrollments.map { |e| e.associated_user_id }.sort).to include(students[2].id)
    end

    it "should handle deleted observee enrollments" do
      custom_observer_role = custom_observer_role("obob")

      obs = user_model(:name => "The Observer")
      student_in_course(:name => "Student 1", :active_all => true, :role => @custom_student_role)
      @course.enroll_user(obs, 'ObserverEnrollment', :enrollment_state => 'active', :associated_user_id => @student.id, :role => custom_observer_role)
      student = student_in_course(:name => "Student 2", :active_all => true, :role => @custom_student_role)
      obs_enrollment = @course.enroll_user(obs, 'ObserverEnrollment', :enrollment_state => 'active', :associated_user_id => @student.id, :allow_multiple_enrollments => true, :role => custom_observer_role)

      # bye bye Student 2
      obs_enrollment.destroy

      go_to_people_page

      observer_row = ff("#user_#{obs.id}").map(&:text).join(',')
      expect(observer_row).to include "Student 1"
      expect(observer_row).not_to include "Student 2"

      # dialog loads too
      use_link_dialog(obs) do
        input = fj("#link_students")
        expect(input.text).to include "Student 1"
        expect(input.text).not_to include "Student 2"
      end
    end

    %w[ta designer].each do |et|
      it "should not let #{et}s remove admins from the course" do
        send "custom_#{et}_role", "custom"
        send "course_with_#{et}", :course => @course, :active_all => true, :custom_role => 'custom'
        user_session @user
        student_in_course :user => user_with_pseudonym, :course => @course, :role => @custom_student_role

        go_to_people_page

        # should NOT see remove link for teacher
        expect(f("#content")).not_to contain_css(kyle_menu_css(@teacher))
        # should see remove link for student
        cog = open_kyle_menu @student
        expect(f('a[data-event="removeFromCourse"]', cog)).not_to be_nil
      end
    end

    it "should not show the student view student" do
      @fake_student = @course.student_view_student
      go_to_people_page
      expect(f("#content")).not_to contain_css(".student_enrollments #user_#{@fake_student.id}")
    end

    context "multiple enrollments" do
      it "should link an observer enrollment when other enrollment types exist" do
        course_with_student :course => @course, :active_all => true, :name => 'teh student'
        course_with_ta :user => user_with_pseudonym, :course => @course, :active_all => true
        course_with_observer :course => @course, :active_all => true, :user => @ta

        go_to_people_page
        use_link_dialog(@observer, 'ObserverEnrollment') do
          select_from_auto_complete(@student.name, 'student_input')
        end

        expect(@observer.enrollments.where(associated_user_id: @student)).to be_exists
        expect(f("#user_#{@observer.id}.ObserverEnrollment").text).to include("Observing: #{@student.name}")
      end
    end

    context "custom roles" do
      it "should create new observer enrollments as custom type when adding observees" do
        role = custom_observer_role("custom observer")
        student_in_course :course => @course
        e = course_with_observer(:course => @course, :role => role)

        go_to_people_page

        use_link_dialog(@observer) do
          select_from_auto_complete(@student.name, 'student_input')
        end

        @observer.reload
        @observer.enrollments.each{|e|expect(e.role_id).to eq role.id}
      end

      it "should create new enrollments as custom type when adding sections" do
        add_user_to_second_section(@custom_student_role)
      end

      def select_new_role_type(type)
        get "/courses/#{@course.id}/users"
        add_button = f('#addUsers')
        keep_trying_until { expect(add_button).to be_displayed }
        add_button.click
        click_option('#role_id', type)
      end

      %w[student teacher ta designer observer].each do |base_type|
        it "should allow adding custom #{base_type} enrollments" do
          user = user_with_pseudonym(:active_user => true, :username => "#{base_type}@example.com", :name => "#{base_type}@example.com")
          send "custom_#{base_type}_role", "custom"
          add_user(user.name, "custom")
          expect(f("#user_#{user.id} .admin-links")).not_to be_nil
        end
      end
    end

    it "should not remove a base enrollment when adding a custom enrollment of the same base type" do
      @role = custom_teacher_role "Mentor"
      add_user(@teacher.name, "Mentor")
      teacher_row = f("#user_#{@teacher.id}")
      expect(teacher_row).to have_class("TeacherEnrollment")
      expect(teacher_row).to have_class("Mentor")
    end
  end

end
