# frozen_string_literal: true

#
# Copyright (C) 2011 - present Instructure, Inc.
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

require_relative "../common"

describe "people" do
  include_context "in-process server selenium tests"

  def add_user(option_text, username, user_list_selector)
    click_option("#enrollment_type", option_text)
    f("textarea.user_list").send_keys(username)
    f(".verify_syntax_button").click
    wait_for_ajax_requests
    expect(f("#user_list_parsed")).to include_text(username)
    f(".add_users_button").click
    wait_for_ajaximations
    expect(f(user_list_selector)).to include_text(username)
  end

  def open_student_group_dialog
    f("#add-group-set").click
    dialog = f(%(span[data-testid="modal-create-groupset"]))
    expect(dialog).to be_displayed
    dialog
  end

  def create_student_group(group_text = "new student group")
    expect_new_page_load do
      f("#people-options .Button").click
      fln("View User Groups").click
    end
    open_student_group_dialog
    replace_and_proceed f("#new-group-set-name"), group_text
    f(%(button[data-testid="group-set-save"])).click
    wait_for_ajaximations
    expect(f(".collectionViewItems")).to include_text(group_text)
  end

  def enroll_student(student)
    e1 = @course.enroll_student(student)
    e1.workflow_state = "active"
    e1.save!
    @course.reload
  end

  def enroll_ta(ta)
    e1 = @course.enroll_ta(ta)
    e1.workflow_state = "active"
    e1.save!
    @course.reload
  end

  def create_user(student_name)
    user = User.create!(name: student_name)
    user.register!
    user.pseudonyms.create!(unique_id: student_name, password: "qwertyuiop", password_confirmation: "qwertyuiop")
    @course.reload
    user
  end

  def enroll_more_students
    student_1 = create_user("jake@test.com")
    student_2 = create_user("test@test.com")
    student_3 = create_user("new@test.com")
    student_4 = create_user("this@test.com")
    enroll_student(student_1)
    enroll_student(student_2)
    enroll_student(student_3)
    enroll_student(student_4)
  end

  def open_dropdown_menu(selector = ".rosterUser")
    row = f(selector)
    driver.action.move_to(row).perform
    f("#{selector} .admin-links a.al-trigger").click
    expect(f("#{selector} .admin-links ul.al-options")).to be_displayed
  end

  def expect_dropdown_item(option, selector = ".rosterUser")
    expect(f("#{selector} .admin-links ul.al-options li a[data-event=#{option}]")).to be_truthy
  end

  def expect_no_dropdown_item(option, selector = ".rosterUser")
    expect(f("#{selector} .admin-links ul.al-options")).not_to contain_css("li a[data-event=#{option}]")
  end

  # Returns visibility boolean, assumes existence
  def dropdown_item_visible?(option, selector = ".rosterUser")
    f("#{selector} .admin-links ul.al-options li a[data-event=#{option}]").displayed?
  end

  def close_dropdown_menu
    driver.action.send_keys(:escape).perform
  end

  context "people as a teacher" do
    before :once do
      course_with_teacher active_user: true, active_course: true, active_enrollment: true, name: "Mrs. Commanderson"
      # add first student
      @student_1 = create_user("student@test.com")

      enroll_student(@student_1)

      # adding users for tests to work correctly
      @student_2 = create_user("student2@test.com")
      @test_ta = create_user("ta@test.com")

      enroll_ta(@test_ta)
    end

    before do
      user_session @teacher
    end

    it "has tabs" do
      get "/courses/#{@course.id}/users"
      expect(f(".collectionViewItems>li:first-child").text).to match "Everyone"
    end

    it "displays a dropdown menu when item cog is clicked" do
      get "/courses/#{@course.id}/users"
      open_dropdown_menu
    end

    it "displays the option to remove a student from a course if manually enrolled" do
      get "/courses/#{@course.id}/users"
      open_dropdown_menu("tr[id=user_#{@student_1.id}]")
      expect(dropdown_item_visible?("removeFromCourse", "tr[id=user_#{@student_1.id}]")).to be true
    end

    it "displays the option to remove a student from a course has a SIS ID", priority: "1" do
      @course.sis_source_id = "xyz"
      @course.save
      enroll_student(@student_2)
      # need to hit /users page again to show enrollment of 2nd student
      get "/courses/#{@course.id}/users"
      wait_for_ajaximations
      # check 1st student
      open_dropdown_menu("tr[id=user_#{@student_1.id}]")
      expect(dropdown_item_visible?("removeFromCourse", "tr[id=user_#{@student_1.id}]")).to be true
      close_dropdown_menu
      # check 2nd student
      open_dropdown_menu("tr[id=user_#{@student_2.id}]")
      expect(dropdown_item_visible?("removeFromCourse", "tr[id=user_#{@student_2.id}]")).to be true
    end

    it "displays remove option for student with/without SIS id", priority: "1" do
      enroll_student(@student_2)
      @student = user_with_managed_pseudonym
      @course.enroll_student(@student)
      @course.save
      get "/courses/#{@course.id}/users"
      # check 1st student
      open_dropdown_menu("tr[id=user_#{@student_1.id}]")
      expect(dropdown_item_visible?("removeFromCourse", "tr[id=user_#{@student_1.id}]")).to be true
      close_dropdown_menu
      # check 2nd student
      open_dropdown_menu("tr[id=user_#{@student_2.id}]")
      expect(dropdown_item_visible?("removeFromCourse", "tr[id=user_#{@student_2.id}]")).to be true
    end

    it "displays the option to remove a ta from the course" do
      get "/courses/#{@course.id}/users"
      open_dropdown_menu("tr[id=user_#{@test_ta.id}]")
      expect(dropdown_item_visible?("removeFromCourse", "tr[id=user_#{@test_ta.id}]")).to be true
    end

    it "displays activity report on clicking Student Interaction button", priority: "1" do
      get "/courses/#{@course.id}/users"
      f("#people-options .Button").click
      fln("Student Interactions Report").click
      expect(f("h1").text).to eq "Teacher Activity Report for #{@user.name}"
    end

    it "does not display Student Interaction button for a student", priority: "1" do
      user_session(@student_1)
      get "/courses/#{@course.id}/users"
      expect(f("#content")).not_to contain_link("Student Interactions Report")
    end

    it "does not display resend invitation dropdown item for a student when the granular add student permission is disabled" do
      @course.root_account.enable_feature!(:granular_permissions_manage_courses)
      RoleOverride.create!(context: Account.default, permission: "add_student_to_course", role: teacher_role, enabled: false)
      get "/courses/#{@course.id}/users"
      open_dropdown_menu("tr[id=user_#{@student_1.id}]")
      expect_no_dropdown_item("resendInvitation", "#user_#{@student_1.id}")
    end

    it "displays the resend invitation dropdown item for student with dual roles with granular permissions enabled for one of the roles" do
      enroll_ta(@student_1)
      @course.root_account.enable_feature!(:granular_permissions_manage_courses)
      RoleOverride.create!(context: Account.default, permission: "add_student_to_course", role: teacher_role, enabled: false)
      RoleOverride.create!(context: Account.default, permission: "add_ta_to_course", role: teacher_role, enabled: true)
      get "/courses/#{@course.id}/users"
      open_dropdown_menu("tr[id=user_#{@student_1.id}]")
      expect(dropdown_item_visible?("resendInvitation", "tr[id=user_#{@student_1.id}]")).to be true
    end

    context "when the deprecate_faculty_journal flag is disabled" do
      before { Account.site_admin.disable_feature!(:deprecate_faculty_journal) }

      it "has a working Faculty Journal menu option" do
        a = Account.default
        a.enable_user_notes = true
        a.save!
        get "/courses/#{@course.id}/users"
        open_dropdown_menu("tr[id=user_#{@student_1.id}]")
        wait_for_new_page_load { f("a[href='/users/#{@student_1.id}/user_notes']").click }
        expect(fj("h1:contains('Faculty Journal for #{@student_1.name}')")).to be_present
      end
    end

    it "focuses on the + Group Set button after the tabs" do
      get "/courses/#{@course.id}/users"
      driver.execute_script("$('.collectionViewItems > li:last a').focus()")
      active = driver.execute_script("return document.activeElement")
      active.send_keys(:tab)
      check_element_has_focus(f(".group-categories-actions .btn-primary"))
    end

    it "validates the main page" do
      get "/courses/#{@course.id}/users"
      users = ff(".roster_user_name")
      expect(users[1].text).to match @student_1.name
      expect(users[0].text).to match @teacher.name
    end

    it "navigates to registered services on profile page" do
      get "/courses/#{@course.id}/users"
      f("#people-options .Button").click
      fln("View Registered Services").click
      fln("Link web services to my account").click
      expect(f("#unregistered_services")).to be_displayed
    end

    it "makes a new set of student groups" do
      get "/courses/#{@course.id}/users"
      create_student_group
    end

    # This just duplicates a test in the Jest spec for the modal
    xit "tests self sign up functionality" do
      get "/courses/#{@course.id}/users"
      f("#people-options .Button").click
      expect_new_page_load { fln("View User Groups").click }
      dialog = open_student_group_dialog
      dialog.find_element(:css, "#enable_self_signup").click
      expect(dialog.find_element(:css, "#split_groups")).not_to be_displayed
      expect(dialog).to include_text("groups now")
    end

    it "tests self sign up / group structure functionality" do
      get "/courses/#{@course.id}/users"
      group_count = "4"
      expect_new_page_load do
        f("#people-options .Button").click
        fln("View User Groups").click
      end
      open_student_group_dialog
      replace_and_proceed f("#new-group-set-name"), "new group"
      fxpath("//input[@data-testid='checkbox-allow-self-signup']/..").click
      force_click('[data-testid="initial-group-count"]')
      f('[data-testid="initial-group-count"]').send_keys("4")
      f(%(button[data-testid="group-set-save"])).click
      wait_for_ajaximations
      expect(@course.groups.count).to eq 4
      expect(f(".groups-with-count")).to include_text("Groups (#{group_count})")
    end

    it "errors if the user tries to set the limit group members to 1" do
      get "/courses/#{@course.id}/users"
      expect_new_page_load do
        f("#people-options .Button").click
        fln("View User Groups").click
      end
      open_student_group_dialog
      replace_and_proceed f("#new-group-set-name"), "new group"
      fxpath("//input[@data-testid='checkbox-allow-self-signup']/..").click
      force_click('[data-testid="initial-group-count"]')
      f('[data-testid="group-member-limit"]').send_keys("1")
      f(%(button[data-testid="group-set-save"])).click
      wait_for_ajaximations
      expect(fj("span:contains('If you are going to define a limit group members, it must be greater than 1.')")).to be_truthy
    end

    it "tests group structure functionality" do
      skip "FOO-3810 (10/6/2023)"
      get "/courses/#{@course.id}/users"
      enroll_more_students

      group_count = "4"
      expect_new_page_load do
        f("#people-options .Button").click
        fln("View User Groups").click
      end
      open_student_group_dialog
      replace_and_proceed f("#new-group-set-name"), "new group"
      force_click('[data-testid="group-structure-selector"]')
      force_click('[data-testid="group-structure-num-groups"]')
      f('[data-testid="split-groups"]').send_keys(group_count)
      expect(@course.groups.count).to eq 0
      f(%(button[data-testid="group-set-save"])).click
      run_jobs
      wait_for_ajaximations
      expect(@course.groups.count).to eq group_count.to_i
      expect(f(".groups-with-count")).to include_text("Groups (#{group_count})")
    end

    it "auto-creates groups based on # of students" do
      skip "FOO-3810 (10/6/2023)"
      enroll_more_students
      get "/courses/#{@course.id}/groups#new"
      replace_and_proceed f("#new-group-set-name"), "Groups of 2"
      force_click('[data-testid="group-structure-selector"]')
      force_click('[data-testid="group-structure-students-per-group"]')
      f('[data-testid="num-students-per-group"]').send_keys("2")
      f('button[data-testid="group-set-save"]').click
      run_jobs
      wait_for_ajaximations
      expect(ff("li.group").size).to eq 3
    end

    it "edits a student group" do
      get "/courses/#{@course.id}/users"
      new_group_name = "new group edit name"
      create_student_group
      fj(".group-category-actions:visible a:visible").click
      f(".edit-category").click
      edit_form = f(".group-category-edit")
      edit_form.find_element(:css, 'input[name="name"]').send_keys(new_group_name)
      submit_form(edit_form)
      wait_for_ajaximations
      expect(f(".collectionViewItems")).to include_text(new_group_name)
    end

    it "deletes a student group" do
      group_category = GroupCategory.create(name: "new student group", context: @course)

      get "/courses/#{@course.id}/groups#tab-#{group_category.id}"
      fj(".group-category-actions:visible a:visible").click
      f(".delete-category").click
      accept_alert
      wait_for_ajaximations
      expect(f(".empty-groupset-instructions")).to be_displayed
    end

    it "tests prior enrollment functionality" do
      @course.complete
      get "/courses/#{@course.id}/users"
      expect_new_page_load do
        f("#people-options .Button").click
        fln("View Prior Enrollments").click
      end
      expect(f("#users")).to include_text(@student_1.name)
    end

    it "deals with observers linked to multiple students" do
      @students = []
      @obs = user_model(name: "The Observer")
      2.times do |i|
        student_in_course(name: "Student #{i}")
        @students << @student
        e = @course.observer_enrollments.create!(user: @obs, workflow_state: "active")
        e.associated_user_id = @student.id
        e.save!
      end

      2.times do |i|
        student_in_course(name: "Student #{i + 2}")
        @students << @student
      end

      get "/courses/#{@course.id}/users/#{@obs.id}"
      f(".more_user_information_link").click
      wait_for_ajaximations
      enrollments = ff(".enrollment")
      expect(enrollments.length).to eq 2

      expect(enrollments[0]).to include_text @students[0].name
      expect(enrollments[1]).to include_text @students[1].name
    end

    it "allows conclude/restore without profiles enabled" do
      get "/courses/#{@course.id}/users/#{@student_1.id}"
      f(".more_user_information_link").click
      wait_for_animations
      f(".conclude_enrollment_link").click
      accept_alert
      wait_for_ajaximations
      f(".unconclude_enrollment_link").click
      wait_for_ajaximations
      expect(f(".conclude_enrollment_link")).to be_displayed
    end

    it "allows conclude/restore with profiles enabled" do
      account = Account.default
      account.settings[:enable_profiles] = true
      account.save!

      get "/courses/#{@course.id}/users/#{@student_1.id}"
      f(".conclude_enrollment_link").click
      accept_alert
      wait_for_ajaximations
      f(".unconclude_enrollment_link").click
      wait_for_ajaximations
      expect(f(".conclude_enrollment_link")).to be_displayed
    end
  end

  context "people as a TA" do
    before :once do
      course_with_ta(active_all: true)
    end

    before do
      user_session @ta
    end

    it "validates that the TA cannot delete / conclude or reset course" do
      @course.root_account.disable_feature!(:granular_permissions_manage_courses)
      get "/courses/#{@course.id}/settings"
      expect(f("#content")).not_to contain_css(".delete_course_link")
      expect(f("#content")).not_to contain_css(".reset_course_content_button")
      get "/courses/#{@course.id}/confirm_action?event=conclude"
      expect(f("#unauthorized_message")).to include_text("Access Denied")
    end

    it "validates that the TA cannot delete or reset course (granular permissions)" do
      @course.root_account.enable_feature!(:granular_permissions_manage_courses)
      get "/courses/#{@course.id}/settings"
      expect(f("#content")).not_to contain_css(".delete_course_link")
      expect(f("#content")).not_to contain_css(".reset_course_content_button")
    end

    # TODO: reimplement per CNVS-29609, but make sure we're testing at the right level
    it "should validate that a TA cannot rename a teacher"

    it "includes login id column if the user has :view_user_logins, even if they don't have :manage_students" do
      RoleOverride.create!(context: Account.default, permission: "manage_students", role: ta_role, enabled: false)
      get "/courses/#{@course.id}/users"
      index = ff("table.roster th").map(&:text).find_index("Login ID")
      expect(index).not_to be_nil
      ta_row = ff("table.roster #user_#{@ta.id} td").map(&:text)
      expect(ta_row[index].strip).to eq @ta.pseudonym.unique_id
    end

    it "does not include login id column if the user does not have :view_user_logins, even if they do have :manage_students" do
      RoleOverride.create!(context: Account.default, permission: "view_user_logins", role: ta_role, enabled: false)
      get "/courses/#{@course.id}/users"
      index = ff("table.roster th").map(&:text).find_index("Login ID")
      expect(index).to be_nil
    end

    context "without view all grades permissions" do
      before do
        ["view_all_grades", "manage_grades"].each do |permission|
          RoleOverride.create!(permission:, enabled: false, context: @course.account, role: ta_role)
        end
      end

      it "doesn't show the Interactions Report link without view all grades permissions" do
        @student = create_user("student@test.com")
        enroll_student(@student)
        get "/courses/#{@course.id}/users/#{@student.id}"
        expect(f("#content")).not_to contain_link("Interactions Report")
      end

      it "doesn't show the Student Interactions Report link without view all grades permissions" do
        get "/courses/#{@course.id}/users/#{@ta.id}"
        expect(f("#content")).not_to contain_link("Student Interactions Report")
      end

      context "with new profile flag enabled" do
        before do
          @course.account.settings[:enable_profiles] = true
          @course.account.save!
          @student = create_user("student@test.com")
          enroll_student(@student)
        end

        it "doesn't show the Interactions Report link without permissions" do
          get "/courses/#{@course.id}/users/#{@student.id}"
          expect(f("#content")).not_to contain_link("Interactions Report")
        end

        it "doesn't show the Student Interactions Report link without permissions" do
          get "/courses/#{@course.id}/users/#{@ta.id}"
          expect(f("#content")).not_to contain_link("Student Interactions Report")
        end
      end
    end
  end

  context "people as a student" do
    before :once do
      course_with_student(active_all: true)
    end

    before do
      user_session @student
    end

    it "does not link avatars to a user's profile page if profiles are disabled" do
      @course.account.settings[:enable_profiles] = false
      @course.account.enable_service(:avatars)
      @course.account.save!
      get "/courses/#{@course.id}/users/#{@student.id}"
      expect(f(".avatar")["href"]).not_to be_present
    end
  end

  context "course with multiple sections", priority: "2" do
    before :once do
      course_with_teacher active_course: true, active_user: true
      @section2 = @course.course_sections.create!(name: "section2")
    end

    before do
      user_session @teacher
    end

    it "saves add people form data" do
      get "/courses/#{@course.id}/users"

      f("#addUsers").click
      wait_for_ajaximations

      expect(f(".addpeople")).to be_displayed
      replace_content(f(".addpeople__peoplesearch textarea"), "student@example.com")
      click_INSTUI_Select_option("#peoplesearch_select_role", ta_role.id.to_s, :value)
      click_INSTUI_Select_option("#peoplesearch_select_section", "Unnamed Course", :text)
      f("#addpeople_next").click
      wait_for_ajaximations

      expect(f(".peoplevalidationissues__missing")).to be_displayed
      f("#addpeople_back").click
      wait_for_ajaximations

      # verify form and options have not changed
      expect(f(".addpeople__peoplesearch")).to be_displayed
      expect(f(".addpeople__peoplesearch textarea").text).to eq "student@example.com"
      expect(f("#peoplesearch_select_role").attribute("value")).to eq "TA"
      expect(f("#peoplesearch_select_section").attribute("value")).to eq "Unnamed Course"
    end

    it "adds a student to a section", priority: "1" do
      student = create_user("student@example.com")
      enroll_student(student)
      get "/courses/#{@course.id}/users"
      f(".StudentEnrollment .icon-more").click
      fln("Edit Sections").click
      f(".token_input.browsable").click
      section_input_element = driver.find_element(:name, "token_capture")
      section_input_element.send_keys("section2")
      f(".last.context").click
      wait_for_ajaximations
      ff(".ui-button-text")[1].click
      wait_for_ajaximations
      expect(ff(".StudentEnrollment")[0]).to include_text("section2")
    end

    it "removes a student from a section", priority: "1" do
      @student = user_factory
      @course.enroll_student(@student, allow_multiple_enrollments: true)
      @course.enroll_student(@student, section: @section2, allow_multiple_enrollments: true)
      get "/courses/#{@course.id}/users"
      f(".StudentEnrollment .icon-more").click
      fln("Edit Sections").click
      fln("Remove user from section2").click
      ff(".ui-button-text")[1].click
      wait_for_ajaximations
      expect(ff(".StudentEnrollment")[0]).not_to include_text("section2")
    end

    it "edits a designer's sections" do
      designer = create_user("student@example.com")
      @course.enroll_designer(designer, enrollment_state: "active")
      get "/courses/#{@course.id}/users"
      f(".DesignerEnrollment .icon-more").click
      fln("Edit Sections").click
      f(".token_input.browsable").click
      section_input_element = driver.find_element(:name, "token_capture")
      section_input_element.send_keys("section2")
      f(".last.context").click
      wait_for_ajaximations
      ff(".ui-button-text")[1].click
      wait_for_ajaximations
      expect(ff(".DesignerEnrollment")[0]).to include_text("section2")
    end

    it "removes students linked to an observer" do
      @student1 = user_factory
      @course.enroll_student(@student1, enrollment_state: :active)
      @student2 = user_factory
      @course.enroll_student(@student2, enrollment_state: :active)
      @observer = user_factory
      @course.enroll_user(@observer, "ObserverEnrollment", enrollment_state: :active, associated_user_id: @student1.id, allow_multiple_enrollments: true)
      @course.enroll_user(@observer, "ObserverEnrollment", enrollment_state: :active, associated_user_id: @student2.id, allow_multiple_enrollments: true)
      get "/courses/#{@course.id}/users"
      f(".ObserverEnrollment .icon-more").click
      fln("Link to Students").click
      fln("Remove linked student #{@student1.name}", f("#token_#{@student1.id}")).click
      f(".ui-dialog-buttonset .btn-primary").click
      wait_for_ajax_requests
      expect(@observer.enrollments.not_deleted.map(&:associated_user_id)).not_to include @student1.id
      expect(@observer.enrollments.not_deleted.map(&:associated_user_id)).to include @student2.id
    end

    it "grays out sections the user doesn't have permission to remove" do
      @student = user_with_managed_pseudonym
      e = @course.enroll_student(@student, allow_multiple_enrollments: true)
      sis = @course.root_account.sis_batches.create
      e.sis_batch_id = sis.id
      e.save!
      get "/courses/#{@course.id}/users"
      ff(".icon-more")[1].click
      fln("Edit Sections").click
      expect(f("#user_sections li.cannot_remove").text).to include @course.default_section.name

      # add another section (not via SIS) and ensure it remains editable
      f(".token_input.browsable").click
      section_input_element = driver.find_element(:name, "token_capture")
      section_input_element.send_keys("section2")
      f(".last.context").click
      wait_for_ajaximations
      expect(f("a[title='Remove user from section2']")).not_to be_nil
      f(".ui-dialog-buttonset .btn-primary").click
      wait_for_ajaximations

      ff(".icon-more")[1].click
      fln("Edit Sections").click
      expect(f("#user_sections li.cannot_remove").text).to include @course.default_section.name
      expect(f("a[title='Remove user from section2']")).not_to be_nil
    end
  end

  it "gets the max total activity time" do
    course_with_admin_logged_in
    sec1 = @course.course_sections.create!(name: "section1")
    sec2 = @course.course_sections.create!(name: "section2")
    @student = user_factory
    e1 = @course.enroll_student(@student, section: sec1, allow_multiple_enrollments: true)
    @course.enroll_student(@student, section: sec2, allow_multiple_enrollments: true)
    Enrollment.where(id: e1).update_all(total_activity_time: 900)
    get "/courses/#{@course.id}/users"
    wait_for_ajaximations
    expect(f("#user_#{@student.id} td:nth-child(8)").text.strip).to eq "15:00"
  end

  it "filters by role ids" do
    account_model
    course_with_teacher_logged_in(account: @account)
    old_role = custom_student_role("Role")
    old_role.deactivate!

    new_role = @account.roles.new(name: old_role.name)
    new_role.base_role_type = "StudentEnrollment"
    new_role.save!

    student_in_course(course: @course, role: new_role, name: "number2")

    get "/courses/#{@course.id}/users"
    click_option("select[name=enrollment_role_id]", new_role.id.to_s, :value)
    wait_for_ajaximations
    expect(ff("tr.rosterUser").count).to eq 1
  end

  context "editing role" do
    before :once do
      course_factory
      @section = @course.course_sections.create!(name: "section1")

      @teacher = user_with_pseudonym(active_all: true)
      @enrollment = @course.enroll_teacher(@teacher, enrollment_state: "active")
    end

    before do
      admin_logged_in
    end

    it "lets observers have their roles changed if they don't have associated users" do
      @course.enroll_user(@teacher, "ObserverEnrollment", allow_multiple_enrollments: true)

      get "/courses/#{@course.id}/users"

      open_dropdown_menu("#user_#{@teacher.id}")
      expect_dropdown_item("editRoles", "#user_#{@teacher.id}")
    end

    it "does not let observers with associated users have their roles changed" do
      student = user_factory
      @course.enroll_student(student)
      @course.enroll_user(@teacher, "ObserverEnrollment", allow_multiple_enrollments: true, associated_user_id: student.id)

      get "/courses/#{@course.id}/users"

      open_dropdown_menu("#user_#{@teacher.id}")
      expect_no_dropdown_item("editRoles", "#user_#{@teacher.id}")
    end

    def open_role_dialog(user)
      f("#user_#{user.id} .admin-links a.al-trigger").click
      f("#user_#{user.id} .admin-links a[data-event='editRoles']").click
    end

    it "lets users change to an observer role" do
      get "/courses/#{@course.id}/users"

      open_role_dialog(@teacher)

      expect(fj("#edit_roles #role_id option:selected")).to include_text("Teacher")
      expect(f("#edit_roles #role_id option[value='#{student_role.id}']")).to be_present
      expect(f("#edit_roles #role_id option[value='#{observer_role.id}']")).to be_present
    end

    it "does not let users change to a type they don't have permission to manage" do
      @course.root_account.role_overrides.create!(role: admin_role, permission: "manage_students", enabled: false)

      get "/courses/#{@course.id}/users"

      open_role_dialog(@teacher)
      expect(f("#edit_roles #role_id option[value='#{ta_role.id}']")).to be_present
      expect(f("#content")).not_to contain_css("#edit_roles #role_id option[value='#{student_role.id}']")
    end

    it "retains the same enrollment state" do
      role_name = "Custom Teacher"
      role = @course.account.roles.create(name: role_name)
      role.base_role_type = "TeacherEnrollment"
      role.save!
      @enrollment.deactivate

      get "/courses/#{@course.id}/users"

      open_role_dialog(@teacher)
      click_option("#edit_roles #role_id", role.id.to_s, :value)
      f(".ui-dialog-buttonpane .btn-primary").click
      wait_for_ajaximations
      assert_flash_notice_message "Role successfully updated"

      expect(f("#user_#{@teacher.id}")).to include_text(role_name)
      @enrollment.reload
      expect(@enrollment).to be_deleted

      new_enrollment = @teacher.enrollments.not_deleted.first
      expect(new_enrollment.role).to eq role
      expect(new_enrollment.workflow_state).to eq "inactive"
    end

    it "works with enrollments in different sections" do
      enrollment2 = @course.enroll_user(@teacher, "TeacherEnrollment", allow_multiple_enrollments: true, section: @section)

      get "/courses/#{@course.id}/users"

      open_role_dialog(@teacher)
      click_option("#edit_roles #role_id", ta_role.id.to_s, :value)
      f(".ui-dialog-buttonpane .btn-primary").click
      wait_for_ajaximations
      assert_flash_notice_message "Role successfully updated"

      expect(@enrollment.reload).to be_deleted
      expect(enrollment2.reload).to be_deleted

      new_enrollment1 = @teacher.enrollments.not_deleted.where(course_section_id: @course.default_section).first
      new_enrollment2 = @teacher.enrollments.not_deleted.where(course_section_id: @section).first
      expect(new_enrollment1.role).to eq ta_role
      expect(new_enrollment2.role).to eq ta_role
    end

    it "works with preexiting enrollments in the destination role" do
      # should not try to overwrite this one
      enrollment2 = @course.enroll_user(@teacher, "TaEnrollment", allow_multiple_enrollments: true)

      get "/courses/#{@course.id}/users"

      open_role_dialog(@teacher)
      click_option("#edit_roles #role_id", ta_role.id.to_s, :value)
      f(".ui-dialog-buttonpane .btn-primary").click
      wait_for_ajaximations
      assert_flash_notice_message "Role successfully updated"

      expect(@enrollment.reload).to be_deleted
      expect(enrollment2.reload).to_not be_deleted
    end

    it "works with multiple enrollments in one section" do
      # shouldn't conflict with each other - should only add one enrollment for the new role
      enrollment2 = @course.enroll_user(@teacher, "TaEnrollment", allow_multiple_enrollments: true)

      get "/courses/#{@course.id}/users"

      open_role_dialog(@teacher)
      expect(f("#edit_roles")).to include_text("This user has multiple roles") # warn them that both roles will be removed
      click_option("#edit_roles #role_id", student_role.id.to_s, :value)
      f(".ui-dialog-buttonpane .btn-primary").click
      wait_for_ajaximations
      assert_flash_notice_message "Role successfully updated"

      expect(@enrollment.reload).to be_deleted
      expect(enrollment2.reload).to be_deleted

      new_enrollment = @teacher.enrollments.not_deleted.first
      expect(new_enrollment.role).to eq student_role
    end

    it "does not show the option to edit roles for a soft-concluded course" do
      @course.conclude_at = 2.days.ago
      @course.restrict_enrollments_to_course_dates = true
      @course.save!

      get "/courses/#{@course.id}/users"
      open_dropdown_menu("#user_#{@teacher.id}")
      expect_no_dropdown_item("editRoles", "#user_#{@teacher.id}")
    end

    it "does not show the option to edit roles for a SIS imported enrollment" do
      sis = @course.root_account.sis_batches.create
      student = user_with_pseudonym(active_all: true)
      enrollment = @course.enroll_teacher(student)
      enrollment.sis_batch_id = sis.id
      enrollment.save!

      user_session(@teacher)

      get "/courses/#{@course.id}/users"
      open_dropdown_menu("#user_#{student.id}")
      expect_no_dropdown_item("editRoles", "#user_#{student.id}")
    end

    it "redirects to groups page" do
      user_session(@teacher)

      get "/courses/#{@course.id}/users"

      group_link = ff("#group_categories_tabs .ui-tabs-nav li").last
      expect(group_link).to include_text("Groups")

      expect_new_page_load { group_link.click }
      expect(driver.current_url).to include("/courses/#{@course.id}/groups")
    end

    context "student tray" do
      before :once do
        @account = Account.default
        @student = create_user("student@test.com")
        @enrollment = @course.enroll_student(@student, enrollment_state: :active)
      end

      it "course people page should display student name in tray", priority: "1" do
        get("/courses/#{@course.id}/users")
        f("a[data-student_id='#{@student.id}']").click
        expect(f(".StudentContextTray-Header__Name h2 a")).to include_text("student@test.com")
        expect(f(".StudentContextTray-Header")).to contain_css("i.icon-email")
      end

      it "does not display the message button if the student enrollment is inactive" do
        @enrollment.deactivate
        get("/courses/#{@course.id}/users")
        f("a[data-student_id='#{@student.id}']").click
        expect(f(".StudentContextTray-Header")).not_to contain_css("i.icon-email")
      end

      context "student context card tool placement" do
        before :once do
          @tool = Account.default.context_external_tools.new(name: "a", domain: "google.com", consumer_key: "12345", shared_secret: "secret")
          @tool.student_context_card = {
            url: "http://www.example.com",
            text: "See data for this student or whatever",
            required_permissions: "view_all_grades,manage_grades"
          }
          @tool.save!
        end

        it "shows a link to the tool" do
          get("/courses/#{@course.id}/users")
          f("a[data-student_id='#{@student.id}']").click

          link = ff(".StudentContextTray-QuickLinks__Link a")[1]
          expect(link).to include_text(@tool.label_for(:student_context_card))
          expect(link["href"]).to eq course_external_tool_url(@course, @tool) + "?launch_type=student_context_card&student_id=#{@student.id}"
        end

        it "does not show link if the user doesn't have the permissions specified by the tool" do
          @course.account.role_overrides.create!(permission: "manage_grades", role: admin_role, enabled: false)
          get("/courses/#{@course.id}/users")
          f("a[data-student_id='#{@student.id}']").click

          link = ff(".StudentContextTray-QuickLinks__Link a")[1]
          expect(link).to be_nil
        end
      end
    end
  end

  it "does not show unenroll link to admins without permissions" do
    account_admin_user(active_all: true)
    user_session(@admin)

    course_with_student(active_all: true)
    get "/users/#{@student.id}"

    expect(f("#courses")).to contain_css(".unenroll_link")

    Account.default.role_overrides.create!(permission: "remove_student_from_course", enabled: false, role: admin_role)
    refresh_page

    expect(f("#courses")).to_not contain_css(".unenroll_link")
  end
end
