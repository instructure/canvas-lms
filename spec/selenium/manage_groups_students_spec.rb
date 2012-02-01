require File.expand_path(File.dirname(__FILE__) + '/common')
require File.expand_path(File.dirname(__FILE__) + '/manage_groups_common')
require 'thread'

describe "manage groups students" do
  it_should_behave_like "manage groups selenium tests"

  before (:each) do
    course_with_teacher_logged_in
  end

  it "should move students from a deleted group back to unassigned" do
    skip_if_ie("Switch to alert and accept hangs in IE")

    @course.enroll_student(john = user_model(:name => "John Doe"))
    group_category = @course.group_categories.create(:name => "Some Category")
    group = @course.groups.create(:name => "Group 1", :group_category => group_category)
    group.add_user(john)
    @course.groups.create(:name => "Group 2", :group_category => group_category)

    get "/courses/#{@course.id}/groups"

    category = find_with_jquery(".group_category:visible")
    category.find_elements(:css, ".group_blank .user_id_#{john.id}").should be_empty

    driver.execute_script("$('#group_#{group.id} .delete_group_link').hover().click()") #move_to occasionally breaks in the hudson build
    keep_trying_until do
      driver.switch_to.alert.should_not be_nil
      driver.switch_to.alert.accept
      true
    end
    wait_for_ajaximations
    category.find_elements(:css, ".group_blank .user_id_#{john.id}").should_not be_empty
  end

  context "dragging a user between groups" do
    it "should remove a user from the old group if the category is not student organized" do
      @course.enroll_student(john = user_model(:name => "John Doe"))

      group_category = @course.group_categories.create(:name => "Other Groups")

      group1 = @course.groups.create(:name => "Group 1", :group_category => group_category)
      group2 = @course.groups.create(:name => "Group 2", :group_category => group_category)

      get "/courses/#{@course.id}/groups"

      category = driver.find_element(:css, ".group_category")
      unassigned_div = category.find_element(:css, ".group_blank")
      group1_div = category.find_element(:css, "#group_#{group1.id}")
      group2_div = category.find_element(:css, "#group_#{group2.id}")
      unassigned_div.find_elements(:css, ".user_id_#{john.id}").should_not be_empty

      # from unassigned to group1
      # drag_and_drop version doesn't work for some reason
      # driver.action.drag_and_drop(john_li, group1_div).perform
      driver.execute_script(<<-SCRIPT)
        window.contextGroups.moveToGroup(
          $('.group_category:visible .group_blank .user_id_#{john.id}'),
          $('#group_#{group1.id}'))
      SCRIPT
      unassigned_div.find_elements(:css, ".user_id_#{john.id}").should be_empty
      group1_div.find_elements(:css, ".user_id_#{john.id}").should_not be_empty

      # from group1 to group2
      # driver.action.drag_and_drop(john_li, group2_div).perform
      driver.execute_script(<<-SCRIPT)
        window.contextGroups.moveToGroup(
          $('#group_#{group1.id} .user_id_#{john.id}'),
          $('#group_#{group2.id}'))
      SCRIPT
      group1_div.find_elements(:css, ".user_id_#{john.id}").should be_empty
      group2_div.find_elements(:css, ".user_id_#{john.id}").should_not be_empty

      # from group2 to unassigned
      # driver.action.drag_and_drop(john_li, unassigned_div).perform
      driver.execute_script(<<-SCRIPT)
        window.contextGroups.moveToGroup(
          $('#group_#{group2.id} .user_id_#{john.id}'),
          $('.group_category:visible .group_blank'))
      SCRIPT
      group2_div.find_elements(:css, ".user_id_#{john.id}").should be_empty
      unassigned_div.find_elements(:css, ".user_id_#{john.id}").should_not be_empty
    end

    it "should not remove a user from the old group if the category is student organized unless dragging to unassigned" do
      @course.enroll_student(john = user_model(:name => "John Doe"))

      group_category = GroupCategory.student_organized_for(@course)

      @course.groups.create(:name => "Group 2", :group_category => group_category)
      group1 = @course.groups.create(:name => "Group 1", :group_category => group_category)
      group2 = @course.groups.create(:name => "Group 2", :group_category => group_category)

      get "/courses/#{@course.id}/groups"

      category = driver.find_element(:css, ".group_category")
      unassigned_div = category.find_element(:css, ".group_blank")
      group1_div = category.find_element(:css, "#group_#{group1.id}")
      group2_div = category.find_element(:css, "#group_#{group2.id}")
      unassigned_div.find_elements(:css, ".user_id_#{john.id}").should_not be_empty

      # from unassigned to group1
      # drag_and_drop version doesn't work for some reason
      # driver.action.drag_and_drop(john_li, group1_div).perform
      driver.execute_script(<<-SCRIPT)
        window.contextGroups.moveToGroup(
          $('.group_category:visible .group_blank .user_id_#{john.id}'),
          $('#group_#{group1.id}'))
      SCRIPT
      unassigned_div.find_elements(:css, ".user_id_#{john.id}").should_not be_empty
      group1_div.find_elements(:css, ".user_id_#{john.id}").should_not be_empty

      # from group1 to group2
      # driver.action.drag_and_drop(john_li, group2_div).perform
      driver.execute_script(<<-SCRIPT)
        window.contextGroups.moveToGroup(
          $('#group_#{group1.id} .user_id_#{john.id}'),
          $('#group_#{group2.id}'))
      SCRIPT
      group1_div.find_elements(:css, ".user_id_#{john.id}").should_not be_empty
      group2_div.find_elements(:css, ".user_id_#{john.id}").should_not be_empty

      # from group2 to unassigned
      # driver.action.drag_and_drop(john_li, unassigned_div).perform
      driver.execute_script(<<-SCRIPT)
        window.contextGroups.moveToGroup(
          $('#group_#{group2.id} .user_id_#{john.id}'),
          $('.group_category:visible .group_blank'))
      SCRIPT
      group2_div.find_elements(:css, ".user_id_#{john.id}").should be_empty
      unassigned_div.find_elements(:css, ".user_id_#{john.id}").should_not be_empty
    end
  end

  context "assign_students_link" do

    def assign_students(category)
      assign_students = find_with_jquery("#category_#{category.id} .assign_students_link:visible")
      assign_students.should_not be_nil
      assign_students.click
      confirm_dialog = driver.switch_to.alert
      confirm_dialog.accept
      wait_for_ajax_requests
      keep_trying_until { driver.find_element(:css, '.right_side .group .user_count').text.should == '0 students' }
    end

    before (:each) do
      @student = @course.enroll_student(user_model(:name => "John Doe")).user
      get "/courses/#{@course.id}/groups"
      @category = add_category(@course, "New Category", :enable_self_signup => true, :group_count => '2')
    end

    it "should be visible iff category is not restricted self signup" do
      skip_if_ie("Element must not be hidden, disabled or read-only line 378")
      new_category = add_category(@course, "Unrestricted Self-Signup Category", :enable_self_signup => true, :restrict_self_signup => false)
      find_with_jquery("#category_#{new_category.id} .assign_students_link:visible").should_not be_nil

      edit_category(:restrict_self_signup => true)
      find_with_jquery("#category_#{new_category.id} .assign_students_link:visible").should be_nil

      new_category = add_category(@course, "Restricted Self-Signup Category", :enable_self_signup => true, :restrict_self_signup => true)
      find_with_jquery("#category_#{new_category.id} .assign_students_link:visible").should be_nil

      edit_category(:restrict_self_signup => false)
      find_with_jquery("#category_#{new_category.id} .assign_students_link:visible").should_not be_nil
    end

    it "should assign students in DB and in UI" do
      find_with_jquery("#category_#{@category.id} .group_blank .user_id_#{@student.id}").should_not be_nil
      @student.groups.should be_empty

      assign_students(@category)

      @student.reload
      keep_trying_until { @student.groups.size.should == 1 }
      group = @student.groups.first

      find_with_jquery("#category_#{@category.id} .group_blank .user_id_#{@student.id}").should be_nil
      find_with_jquery("#category_#{@category.id} #group_#{group.id} .user_id_#{@student.id}").should_not be_nil
    end

    it "should give 'Assigning Students...' visual feedback" do
      assign_students = find_with_jquery("#category_#{@category.id} .assign_students_link:visible")
      assign_students.should_not be_nil
      assign_students.click

      # Do some magic to make sure the next ajax request doesn't complete until we're ready for it to
      lock = Mutex.new
      lock.lock
      GroupsController.before_filter { lock.lock; lock.unlock; true }

      confirm_dialog = driver.switch_to.alert
      confirm_dialog.accept
      loading = find_with_jquery("#category_#{@category.id} .group_blank .loading_members:visible")
      loading.text.should == 'Assigning Students...'

      lock.unlock
      GroupsController.filter_chain.pop

      # make sure we wait before moving on
      wait_for_ajax_requests
    end

    it "should give 'Nothing to do.' error flash if no unassigned students" do
      assign_students(@category)
      assign_students(@category)
      assert_flash_error_message /Nothing to do/
    end

    it "should give 'Students assigned to groups.' success flash otherwise" do
      assign_students(@category)
      assert_flash_notice_message /Students assigned to groups/
    end
  end
end