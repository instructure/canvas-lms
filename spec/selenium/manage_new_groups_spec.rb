require File.expand_path(File.dirname(__FILE__) + '/helpers/manage_groups_common')
require 'thread'

describe "manage groups" do
  include_context "in-process server selenium tests"
  include ManageGroupsCommon

  before(:each) do
    course_with_teacher_logged_in
  end

  context "2.0" do
    describe "group category creation" do
      it "should auto-split students into groups" do
        groups_student_enrollment 4
        get "/courses/#{@course.id}/groups"

        f('#add-group-set').click
        set_value f('#new_category_name'), "zomg"
        f('[name=split_groups]').click
        driver.execute_script("$('[name=create_group_count]:enabled').val(2)")
        submit_form f('.group-category-create')

        wait_for_ajaximations

        # yay, added
        expect(f('#group_categories_tabs .collectionViewItems').text).to include('Everyone')
        expect(f('#group_categories_tabs .collectionViewItems').text).to include('zomg')

        run_jobs

        groups = ff('.collectionViewItems > .group')
        expect(groups.size).to eq 2
      end
    end

    it "should allow a teacher to create a group set, a group, and add a user" do
      course_with_teacher_logged_in(:active_all => true)
      student_in_course
      student_in_course

      get "/courses/#{@course.id}/groups"
      wait_for_ajaximations

      f("#add-group-set").click
      wait_for_animations
      f("#new_category_name").send_keys('Group Set 1')
      f("form.group-category-create").submit
      wait_for_ajaximations

      # verify the group set tab is created
      expect(fj("#group_categories_tabs li[role='tab']:nth-child(2)").text).to eq 'Group Set 1'
      # verify has the two created but unassigned students
      expect(ff("div[data-view='unassignedUsers'] .group-user-name").length).to eq 2

      # click the first visible "Add Group" button
      fj(".add-group:visible:first").click
      wait_for_animations
      f("#group_name").send_keys("New Test Group A")
      f("form.group-edit-dialog").submit
      wait_for_ajaximations

      # Add user to the group
      expect(fj(".group-summary:visible:first").text).to eq "0 students"
      ff("div[data-view='unassignedUsers'] .assign-to-group").first.click
      wait_for_animations
      ff(".assign-to-group-menu .set-group").first.click
      wait_for_ajaximations
      expect(fj(".group-summary:visible:first").text).to eq "1 student"
      expect(ff("div[data-view='unassignedUsers'] .assign-to-group").length).to eq 1

      # Remove added user from the group
      fj(".groups .group .toggle-group:first").click
      wait_for_ajaximations
      fj(".groups .group .group-user-actions:first").click
      wait_for_ajaximations
      fj(".remove-from-group:first").click
      wait_for_ajaximations
      expect(fj(".group-summary:visible:first").text).to eq "0 students"
      # should re-appear in unassigned
      expect(ff("div[data-view='unassignedUsers'] .assign-to-group").length).to eq 2
    end

    it "should allow a teacher to drag and drop a student among groups" do
      students = groups_student_enrollment 5
      group_categories = create_categories(@course, 1)
      groups = add_groups_in_category(group_categories[0])
      get "/courses/#{@course.id}/groups"
      wait_for_ajaximations

      # expand groups
      expand_group(groups[0].id)
      expand_group(groups[1].id)

      unassigned_group_selector = ".unassigned-students"
      group1_selector = ".group[data-id=\"#{groups[0].id}\"]"
      group2_selector = ".group[data-id=\"#{groups[1].id}\"]"
      group_user_selector = ".group-user"
      first_group_user_selector = ".group-user:first"

      first_unassigned_user = "#{unassigned_group_selector} #{first_group_user_selector}"
      first_group1_user = "#{group1_selector} #{first_group_user_selector}"

      unassigned_users_selector = "#{unassigned_group_selector} #{group_user_selector}"
      group1_users_selector = "#{group1_selector} #{group_user_selector}"
      group2_users_selector = "#{group2_selector} #{group_user_selector}"

      # assert all 5 students are in unassigned
      expect(ff(unassigned_users_selector).size).to eq 5
      expect(f("#content")).not_to contain_css(group1_users_selector)
      expect(f("#content")).not_to contain_css(group2_users_selector)

      drag_and_drop_element( fj(first_unassigned_user), fj(group1_selector) )
      drag_and_drop_element( fj(first_unassigned_user), fj(group1_selector) )
      # assert there are 3 students in unassigned
      # assert there is 2 student in group 0
      # assert there is still 0 students in group 1
      expect(ff(unassigned_users_selector).size).to eq 3
      expect(ff(group1_users_selector).size).to eq 2
      expect(f("#content")).not_to contain_css(group2_users_selector)

      drag_and_drop_element( fj(first_group1_user), fj(unassigned_group_selector) )
      drag_and_drop_element( fj(first_group1_user), fj(group2_selector) )
      # assert there are 4 students in unassigned
      # assert there are 0 students in group 0
      # assert there is 1 student in group 1
      expect(ff(unassigned_users_selector).size).to eq 4
      expect(f("#content")).not_to contain_css(group1_users_selector)
      expect(ff(group2_users_selector).size).to eq 1
    end

    it "should support student-organized groups" do
      course_with_teacher_logged_in(:active_all => true)
      student_in_course
      student_in_course

      cat = GroupCategory.student_organized_for(@course)
      add_groups_in_category cat, 1

      get "/courses/#{@course.id}/groups"
      wait_for_ajaximations

      expect(f("#content")).not_to contain_css('.group-category-actions .al-trigger') # can't edit/delete etc.

      # user never leaves "Everyone" list, only gets added to a group once
      2.times do
        expect(f('.unassigned-users-heading').text).to eq "Everyone (2)"
        ff("div[data-view='unassignedUsers'] .assign-to-group").first.click
        wait_for_animations
        ff(".assign-to-group-menu .set-group").first.click
        wait_for_ajaximations
        expect(fj(".group-summary:visible:first").text).to eq "1 student"
      end
    end

    it "should allow a teacher to reassign a student with an accessible modal dialog" do
      students = groups_student_enrollment 2
      group_categories = create_categories(@course, 1)
      groups = add_groups_in_category(group_categories[0],2)
      get "/courses/#{@course.id}/groups"
      wait_for_ajaximations

      # expand groups
      expand_group(groups[0].id)
      expand_group(groups[1].id)

      # Add an unassigned user to the first group
      expect(fj(".group-summary:visible:first").text).to eq "0 students"
      ff("div[data-view='unassignedUsers'] .assign-to-group").first.click
      wait_for_animations
      ff(".assign-to-group-menu .set-group").first.click
      wait_for_ajaximations
      expect(fj(".group-summary:visible:first").text).to eq "1 student"
      expect(fj(".group-summary:visible:last").text).to eq "0 students"


      # Move the user from one group into the other
      fj(".groups .group .group-user .group-user-actions").click
      wait_for_ajaximations
      fj(".edit-group-assignment:first").click
      wait_for_ajaximations
      fj(".single-select:first option:first").click
      wait_for_ajaximations
      fj('.set-group:first').click
      wait_for_ajaximations
      expect(fj(".group-summary:visible:first").text).to eq "0 students"
      expect(fj(".group-summary:visible:last").text).to eq "1 student"

      # Move the user back
      fj(".groups .group .group-user .group-user-actions").click
      wait_for_ajaximations
      fj(".edit-group-assignment:last").click
      wait_for_ajaximations
      fj(".single-select:last option:first").click
      wait_for_ajaximations
      fj('.set-group:last').click
      wait_for_ajaximations
      expect(fj(".group-summary:visible:first").text).to eq "1 student"
      expect(fj(".group-summary:visible:last").text).to eq "0 students"
    end

    it "should give a teacher the option to assign unassigned students to groups" do
      group_category, _ = create_categories(@course, 1)
      group, _ = add_groups_in_category(group_category, 1)
      student_in_course
      get "/courses/#{@course.id}/groups"
      wait_for_ajaximations

      actions_button = "#group-category-#{group_category.id}-actions"
      message_users = ".al-options .message-all-unassigned"
      randomly_assign_users = ".al-options .randomly-assign-members"

      # category menu should show unassigned-member options
      fj(actions_button).click
      wait_for_ajaximations
      expect(fj([actions_button, message_users].join(" + "))).to be
      expect(fj([actions_button, randomly_assign_users].join(" + "))).to be
      fj(actions_button).click # close the menu, or it can prevent the next step

      # assign the last unassigned member
      draggable_user = fj(".unassigned-students .group-user:first")
      droppable_group = fj(".group[data-id=\"#{group.id}\"]")
      drag_and_drop_element draggable_user, droppable_group
      wait_for_ajaximations

      # now the menu should not show unassigned-member options
      fj(actions_button).click
      wait_for_ajaximations
      expect(f("#content")).not_to contain_css([actions_button, message_users].join(" + "))
      expect(f("#content")).not_to contain_css([actions_button, randomly_assign_users].join(" + "))
    end
  end

  it "should let students create groups and invite other users" do
    course_with_student_logged_in(:active_all => true)
    student_in_course(:course => @course, :active_all => true, :name => "other student")
    other_student = @student

    get "/courses/#{@course.id}/groups"
    f('.add_group_link').click
    wait_for_ajaximations
    f('#groupName').send_keys("group name")
    click_option('#joinLevelSelect', 'invitation_only', :value)
    ff('#add_group_form input[type=checkbox]').each(&:click)
    wait_for_ajaximations

    submit_form(f('#add_group_form'))
    wait_for_ajaximations
    new_group = @course.groups.first
    expect(new_group.name).to eq "group name"
    expect(new_group.join_level).to eq "invitation_only"
    expect(new_group.users).to include(other_student)
  end
end
