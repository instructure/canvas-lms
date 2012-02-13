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

  it "should list all sections a student belongs to" do
    @other_section = @course.course_sections.create!(:name => "Other Section")
    student_in_course(:active_all => true)
    @course.student_enrollments.create!(:user => @student,
                                        :workflow_state => "active",
                                        :course_section => @other_section)

    gc1 = @course.group_categories.create(:name => "Group Category 1")

    get "/courses/#{@course.id}/groups"
    wait_for_ajaximations

    sections = driver.find_element(:css, ".user_id_#{@student.id} .section_code")
    sections.should include_text(@course.default_section.name)
    sections.should include_text(@other_section.name)

    driver.find_element(:css, "#category_#{gc1.id} .group_blank .user_count").should include_text("1")
  end

  it "should paginate and count users correctly" do
    students_count = 20
    students_count.times do |i|
      student_in_course(:name => "Student #{i}")
    end

    @other_section = @course.course_sections.create!(:name => "Other Section")
    @course.student_enrollments.create!(:user => @student,
                                        :workflow_state => "active",
                                        :course_section => @other_section)

    group_category = @course.group_categories.create(:name => "My Groups")

    get "/courses/#{@course.id}/groups"
    wait_for_ajaximations

    category = driver.find_element(:css, ".group_category")
    unassigned_div = category.find_element(:css, ".group_blank")

    unassigned_div.find_element(:css, ".user_count").should include_text(students_count.to_s)
    unassigned_div.find_elements(:css, ".student").length.should == 15
    # 15 comes from window.contextGroups.autoLoadGroupThreshold

    driver.find_element(:css, ".next_page").click
    wait_for_ajaximations

    unassigned_div.find_element(:css, ".user_count").should include_text(students_count.to_s)
    unassigned_div.find_elements(:css, ".student").length.should == 5
  end

  context "dragging a user between groups" do
    # use blank as the group id for "unassigned"
    def simulate_group_drag(user_id, from_group_id, to_group_id)
      from_group = (from_group_id == "blank" ? ".group_blank:visible" : "#group_#{from_group_id}")
      to_group   = (to_group_id == "blank"   ? ".group_blank:visible" : "#group_#{to_group_id}")
      driver.execute_script(<<-SCRIPT)
        window.contextGroups.moveToGroup(
          $('#{from_group} .user_id_#{user_id}'),
          $('#{to_group}'))
      SCRIPT
    end

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
      simulate_group_drag(john.id, "blank", group1.id)
      unassigned_div.find_elements(:css, ".user_id_#{john.id}").should be_empty
      group1_div.find_elements(:css, ".user_id_#{john.id}").should_not be_empty

      # from group1 to group2
      # driver.action.drag_and_drop(john_li, group2_div).perform
      simulate_group_drag(john.id, group1.id, group2.id)
      group1_div.find_elements(:css, ".user_id_#{john.id}").should be_empty
      group2_div.find_elements(:css, ".user_id_#{john.id}").should_not be_empty

      # from group2 to unassigned
      # driver.action.drag_and_drop(john_li, unassigned_div).perform
      simulate_group_drag(john.id, group2.id, "blank")
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
      simulate_group_drag(john.id, "blank", group1.id)
      unassigned_div.find_elements(:css, ".user_id_#{john.id}").should_not be_empty
      group1_div.find_elements(:css, ".user_id_#{john.id}").should_not be_empty

      # from group1 to group2
      # driver.action.drag_and_drop(john_li, group2_div).perform
      simulate_group_drag(john.id, group1.id, group2.id)
      group1_div.find_elements(:css, ".user_id_#{john.id}").should_not be_empty
      group2_div.find_elements(:css, ".user_id_#{john.id}").should_not be_empty

      # from group2 to unassigned
      # driver.action.drag_and_drop(john_li, unassigned_div).perform
      simulate_group_drag(john.id, group2.id, "blank")
      group2_div.find_elements(:css, ".user_id_#{john.id}").should be_empty
      unassigned_div.find_elements(:css, ".user_id_#{john.id}").should_not be_empty
    end

    it "should check all user sections for a section specific group" do
      @other_section = @course.course_sections.create!(:name => "Other Section")
      @third_section = @course.course_sections.create!(:name => "Third Section")

      @course.enroll_student(s1 = user_model(:name => "Student 1"))
      @course.enroll_student(s2 = user_model(:name => "Student 2"), :section => @other_section)
      @course.enroll_student(s3 = user_model(:name => "Student 3"), :section => @third_section)
      @course.enroll_student(s4 = user_model(:name => "Student 4"))

      @course.student_enrollments.create!(:user => s4,
                                          :workflow_state => "active",
                                          :course_section => @other_section)

      group_category = @course.group_categories.create(:name => "Other Groups")
      group1 = @course.groups.create(:name => "Group 1", :group_category => group_category)
      group2 = @course.groups.create(:name => "Group 2", :group_category => group_category)
      group3 = @course.groups.create(:name => "Group 3", :group_category => group_category)

      get "/courses/#{@course.id}/groups"
      wait_for_ajaximations

      category_div = driver.find_element(:css, ".group_category")
      group1_div = category_div.find_element(:css, "#group_#{group1.id}")
      group2_div = category_div.find_element(:css, "#group_#{group2.id}")
      group3_div = category_div.find_element(:css, "#group_#{group3.id}")

      edit_category(:enable_self_signup => true, :restrict_self_signup => true)
      simulate_group_drag(s1.id, "blank", group1.id)
      simulate_group_drag(s2.id, "blank", group2.id)
      simulate_group_drag(s3.id, "blank", group3.id)
      wait_for_ajaximations

      simulate_group_drag(s4.id, "blank", group1.id)
      wait_for_ajaximations

      group1.reload; group2.reload; group2.reload;
      group1.users.length.should == 2
      group2.users.length.should == 1
      group3.users.length.should == 1

      simulate_group_drag(s4.id, group1.id, group2.id)
      wait_for_ajaximations

      group1.reload; group2.reload; group2.reload;
      group1.users.length.should == 1
      group2.users.length.should == 2
      group3.users.length.should == 1

      simulate_group_drag(s4.id, group2.id, group3.id)
      wait_for_ajaximations

      group1.reload; group2.reload; group2.reload;
      group1.users.length.should == 1
      group2.users.length.should == 2
      group3.users.length.should == 1
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
      expected_display_name = 'Doe, John'
      keep_trying_until { driver.find_element(:css, '.right_side .student_list .student .name').should include_text(expected_display_name) }
      @student.groups.should be_empty

      assign_students(@category)

      @student.reload
      keep_trying_until { @student.groups.size.should == 1 }
      group = @student.groups.first

      driver.find_element(:css, '.right_side .student_list').should_not include_text(expected_display_name)
      group_element = find_with_jquery("#category_#{@category.id} #group_#{group.id} .user_id_#{@student.id}")
      group_element.should_not be_nil
      group_element.should include_text(expected_display_name)
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
