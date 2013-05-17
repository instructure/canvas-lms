require File.expand_path(File.dirname(__FILE__) + '/helpers/manage_groups_common')
require 'thread'

describe "manage groups students" do
  it_should_behave_like "in-process server selenium tests"

  before (:each) do
    course_with_teacher_logged_in
  end

  context "misc" do
    it "should click on the self signup help link " do
      @student = @course.enroll_student(user_model(:name => "John Doe")).user
      get "/courses/#{@course.id}/groups"
      f(".add_category_link").click
      form = f("#add_category_form")
      form.find_element(:css, ".self_signup_help_link").click
      f("#self_signup_help_dialog").should be_displayed
    end

    it "should move students from a deleted group back to unassigned" do
      student = groups_student_enrollment(1).last
      group_category = @course.group_categories.create(:name => "Some Category")
      group = add_groups_in_category(group_category, 1).last
      group.add_user student

      get "/courses/#{@course.id}/groups"
      category = fj(".group_category:visible")
      category.find_elements(:css, ".group_blank .user_id_#{student.id}").should be_empty

      driver.execute_script("$('#group_#{group.id} .delete_group_link').hover().click()") #move_to occasionally breaks in the hudson build
      keep_trying_until do
        driver.switch_to.alert.should_not be_nil
        driver.switch_to.alert.accept
        true
      end
      wait_for_ajaximations
      category.find_elements(:css, ".group_blank .user_id_#{student.id}").should_not be_empty
    end

    it "should list all sections a student belongs to" do
      @other_section = @course.course_sections.create!(:name => "Other Section")
      student_in_course(:active_all => true)
      @course.enroll_student(@student,
                             :enrollment_state => "active",
                             :section => @other_section,
                             :allow_multiple_enrollments => true)

      gc1 = @course.group_categories.create(:name => "Group Category 1")

      get "/courses/#{@course.id}/groups"
      wait_for_ajaximations

      sections = f(".user_id_#{@student.id} .section_code")
      sections.should include_text(@course.default_section.name)
      sections.should include_text(@other_section.name)

      f("#category_#{gc1.id} .group_blank .user_count").should include_text("1")
    end

    it "should not show sections for students when managing from an account" do
      course_with_admin_logged_in(:course => @course, :username => "admin@example.com")
      student_in_course(:name => "Student 1", :active_all => true)

      @account = Account.default
      gc1 = @account.group_categories.create(:name => "Group Category 1")

      get "/accounts/#{@account.id}/groups"
      wait_for_ajaximations

      f(".group_blank .user_id_#{@student.id} .name").should include_text @student.sortable_name
      f(".group_blank .user_id_#{@student.id} .section_code").text.should be_blank
    end

    it "should paginate and count users correctly" do
      students_count = 20
      students_count.times do |i|
        student_in_course(:name => "Student #{i}")
      end

      @other_section = @course.course_sections.create!(:name => "Other Section")
      @course.enroll_student(@student,
                             :enrollment_state => "active",
                             :section => @other_section,
                             :allow_multiple_enrollments => true)

      group_category = @course.group_categories.create(:name => "My Groups")

      get "/courses/#{@course.id}/groups"
      wait_for_ajaximations

      category = f(".group_category")
      unassigned_div = category.find_element(:css, ".group_blank")

      unassigned_div.find_element(:css, ".user_count").should include_text(students_count.to_s)
      unassigned_div.find_elements(:css, ".student").length.should == 15
      # 15 comes from window.contextGroups.autoLoadGroupThreshold

      f(".next_page").click
      wait_for_ajaximations

      unassigned_div.find_element(:css, ".user_count").should include_text(students_count.to_s)
      unassigned_div.find_elements(:css, ".student").length.should == 5
    end

    it "should not include student view student in the unassigned student list at the course level" do
      @fake_student = @course.student_view_student
      group_category1 = @course.group_categories.create(:name => "Group Category 1")

      get "/courses/#{@course.id}/groups"
      wait_for_ajaximations

      ffj(".group_category:visible .user_id_#{@fake_student.id}").should be_empty
    end

    it "should not include student view student in the unassigned student list at the account level" do
      site_admin_logged_in
      @account = Account.default
      @fake_student = @course.student_view_student
      group_category1 = @account.group_categories.create(:name => "Group Category 1")

      get "/accounts/#{@account.id}/groups"
      wait_for_ajaximations

      ffj(".group_category:visible .user_id_#{@fake_student.id}").should be_empty
    end
  end

  context "dragging a user between groups" do
    # use blank as the group id for "unassigned"
    it "should remove a user from the old group if the category is not student organized" do
      student = groups_student_enrollment(1).last
      group_category = @course.group_categories.create(:name => "Other Groups")
      groups = add_groups_in_category group_category, 2
      get "/courses/#{@course.id}/groups"
      category = f(".group_category")
      unassigned_div = category.find_element(:css, ".group_blank")
      group1_div = category.find_element(:css, "#group_#{groups[0].id}")
      group2_div = category.find_element(:css, "#group_#{groups[1].id}")
      unassigned_div.find_elements(:css, ".user_id_#{student.id}").should_not be_empty

      # from unassigned to group1
      # drag_and_drop version doesn't work for some reason
      # driver.action.drag_and_drop(john_li, group1_div).perform
      simulate_group_drag(student.id, "blank", groups[0].id)
      unassigned_div.find_elements(:css, ".user_id_#{student.id}").should be_empty
      group1_div.find_elements(:css, ".user_id_#{student.id}").should_not be_empty

      # from group1 to group2
      # driver.action.drag_and_drop(john_li, group2_div).perform
      simulate_group_drag(student.id, groups[0].id, groups[1].id)
      group1_div.find_elements(:css, ".user_id_#{student.id}").should be_empty
      group2_div.find_elements(:css, ".user_id_#{student.id}").should_not be_empty

      # from group2 to unassigned
      # driver.action.drag_and_drop(john_li, unassigned_div).perform
      simulate_group_drag(student.id, groups[1].id, "blank")
      group2_div.find_elements(:css, ".user_id_#{student.id}").should be_empty
      unassigned_div.find_elements(:css, ".user_id_#{student.id}").should_not be_empty
    end

    it "should not remove a user from the old group if the category is student organized unless dragging to unassigned" do
      student = groups_student_enrollment(1).last
      group_category = GroupCategory.student_organized_for(@course)
      @course.groups.create(:name => "Group 2", :group_category => group_category)
      groups = add_groups_in_category group_category, 2
      get "/courses/#{@course.id}/groups"

      category = f(".group_category")
      unassigned_div = category.find_element(:css, ".group_blank")
      group1_div = category.find_element(:css, "#group_#{groups[0].id}")
      group2_div = category.find_element(:css, "#group_#{groups[1].id}")
      unassigned_div.find_elements(:css, ".user_id_#{student.id}").should_not be_empty

      # from unassigned to group1
      # drag_and_drop version doesn't work for some reason
      # driver.action.drag_and_drop(john_li, group1_div).perform
      simulate_group_drag(student.id, "blank", groups[0].id)
      unassigned_div.find_elements(:css, ".user_id_#{student.id}").should_not be_empty
      group1_div.find_elements(:css, ".user_id_#{student.id}").should_not be_empty

      # from group1 to group2
      # driver.action.drag_and_drop(john_li, group2_div).perform
      simulate_group_drag(student.id, groups[0].id, groups[1].id)
      group1_div.find_elements(:css, ".user_id_#{student.id}").should_not be_empty
      group2_div.find_elements(:css, ".user_id_#{student.id}").should_not be_empty

      # from group2 to unassigned
      # driver.action.drag_and_drop(john_li, unassigned_div).perform
      simulate_group_drag(student.id, groups[1].id, "blank")
      group2_div.find_elements(:css, ".user_id_#{student.id}").should be_empty
      unassigned_div.find_elements(:css, ".user_id_#{student.id}").should_not be_empty
    end

    it "should check all user sections for a section specific group" do
      @other_section = @course.course_sections.create!(:name => "Other Section")
      @third_section = @course.course_sections.create!(:name => "Third Section")

      students = groups_student_enrollment 4, "2" => {:section => @other_section}, "3" => {:section => @third_section}
      @course.enroll_student(students[3],
                             :workflow_state => "active",
                             :section => @other_section,
                             :allow_multiple_enrollments => true)

      group_category = @course.group_categories.create(:name => "Other Groups")
      groups = add_groups_in_category group_category, 3
      get "/courses/#{@course.id}/groups"
      wait_for_ajaximations
      category_div = f(".group_category")
      group1_div = category_div.find_element(:css, "#group_#{groups[0].id}")
      group2_div = category_div.find_element(:css, "#group_#{groups[1].id}")
      group3_div = category_div.find_element(:css, "#group_#{groups[2].id}")

      edit_category(:enable_self_signup => true, :restrict_self_signup => true)
      simulate_group_drag(students[0].id, "blank", groups[0].id)
      simulate_group_drag(students[1].id, "blank", groups[1].id)
      simulate_group_drag(students[2].id, "blank", groups[2].id)
      wait_for_ajaximations

      simulate_group_drag(students[3].id, "blank", groups[0].id)
      wait_for_ajaximations

      3.times { |i| groups[i].reload }
      groups[0].users.length.should == 2
      groups[1].users.length.should == 1
      groups[2].users.length.should == 1

      simulate_group_drag(students[3].id, groups[0].id, groups[1].id)
      wait_for_ajaximations

      3.times { |i| groups[i].reload }
      groups[0].users.length.should == 1
      groups[1].users.length.should == 2
      groups[2].users.length.should == 1
      simulate_group_drag(students[3].id, groups[1].id, groups[2].id)
      wait_for_ajaximations

      3.times { |i| groups[i].reload }
      groups[0].users.length.should == 1
      groups[1].users.length.should == 2
      groups[2].users.length.should == 1
    end

    it "should prevent you from loading a paginated group list page that would be empty" do
      @students = []
      16.times do |i|
        name = "Student %02d" % (i+1).to_s
        student_in_course(:active_all => true, :name => name)
        @students.push @student
      end
      group_category = @course.group_categories.create(:name => "Existing Category")
      group = add_groups_in_category(group_category, 1).last
      get "/courses/#{@course.id}/groups"
      wait_for_ajaximations

      simulate_group_drag(@students[0].id, "blank", group.id)
      wait_for_ajaximations

      f(".unassigned_members_pagination .next_page").click
      wait_for_ajaximations

      ff(".group_blank .student").length.should == 15
    end
  end

  context "single category" do
    before (:each) do
      @courses_group_category = @course.group_categories.create(:name => "Existing Category")
      groups_student_enrollment 1
    end
    it "should add multiple groups and be sure they are all deleted" do
      add_groups_in_category @courses_group_category
      get "/courses/#{@course.id}/groups"
      driver.execute_script("$('.delete_category_link').click()")
      confirm_dialog = driver.switch_to.alert
      confirm_dialog.accept
      ff(".left_side .group").should be_empty
      @course.group_categories.all.count.should == 0
    end

    it "should edit an individual group" do
      get "/courses/#{@course.id}/groups"
      group = add_group_to_category(@courses_group_category, "group 1")
      group.should_not be_nil
      f("#group_#{group.id}").click
      wait_for_ajaximations
      f("#group_#{group.id} .edit_group_link").click
      wait_for_ajaximations
      name = "new group 1"
      f("#group_name").send_keys(name)
      submit_form("#edit_group_form")
      wait_for_ajaximations
      group = @course.groups.find_by_name(name)
      group.should_not be_nil
    end


    it "should delete an individual group" do
      get "/courses/#{@course.id}/groups"
      group = add_group_to_category @courses_group_category, "group 1"
      f("#group_#{group.id}").click
      f("#group_#{group.id} .delete_group_link").click
      confirm_dialog = driver.switch_to.alert
      confirm_dialog.accept
      wait_for_ajaximations
      ff(".left_side .group").should be_empty
      @course.group_categories.last.groups.last.workflow_state =='deleted'
    end
  end

  context "assign_students_link" do
    def assign_students(category)
      assign_students = fj("#category_#{category.id} .assign_students_link:visible")
      assign_students.should_not be_nil
      assign_students.click
      confirm_dialog = driver.switch_to.alert
      confirm_dialog.accept
      wait_for_ajax_requests
      keep_trying_until { f('.right_side .group .user_count').text.should == '0 students' }
    end

    before (:each) do
      @student = @course.enroll_student(user_model(:name => "John Doe")).user
      get "/courses/#{@course.id}/groups"
      @category = add_category(@course, "New Category", :enable_self_signup => true, :group_count => '2')
    end

    it "should be visible iff category is not restricted self signup" do
      new_category = add_category(@course, "Unrestricted Self-Signup Category", :enable_self_signup => true, :restrict_self_signup => false)
      fj("#category_#{new_category.id} .assign_students_link:visible").should_not be_nil

      edit_category(:restrict_self_signup => true)
      fj("#category_#{new_category.id} .assign_students_link:visible").should be_nil

      new_category = add_category(@course, "Restricted Self-Signup Category", :enable_self_signup => true, :restrict_self_signup => true)
      fj("#category_#{new_category.id} .assign_students_link:visible").should be_nil

      edit_category(:restrict_self_signup => false)
      fj("#category_#{new_category.id} .assign_students_link:visible").should_not be_nil
    end

    it "should assign students in DB and in UI" do
      expected_display_name = 'Doe, John'
      keep_trying_until { f('.right_side .student_list .student .name').should include_text(expected_display_name) }
      @student.groups.should be_empty

      assign_students(@category)

      @student.reload
      keep_trying_until { @student.groups.size.should == 1 }
      group = @student.groups.first

      f('.right_side .student_list').should_not include_text(expected_display_name)
      group_element = fj("#category_#{@category.id} #group_#{group.id} .user_id_#{@student.id}")
      group_element.should_not be_nil
      group_element.should include_text(expected_display_name)
    end

    it "should give 'Nothing to do.' error flash if no unassigned students" do
      assign_students(@category)
      assign_students(@category)
      assert_flash_error_message /Nothing to do/
    end

    it "should give Students assigned to groups. success flash otherwise" do
      assign_students(@category)
      assert_flash_notice_message /Students assigned to groups/
    end

    it "should give Assigning Students... visual feedback" do
      #pending "causes whatever spec follows this to fail even in different files"
        assign_students = fj("#category_#{@category.id} .assign_students_link:visible")
        assign_students.should_not be_nil
        assign_students.click
        # Do some magic to make sure the next ajax request doesn't complete until we're ready for it to
        lock = Mutex.new
        lock.lock
        GroupsController.before_filter { lock.lock; lock.unlock; true }
        confirm_dialog = driver.switch_to.alert
        confirm_dialog.accept
        loading = fj("#category_#{@category.id} .group_blank .loading_members:visible")
        loading.text.should == 'Assigning Students...'
        lock.unlock
        GroupsController.filter_chain.pop
        # make sure we wait before moving on
        wait_for_ajax_requests
      end
    end
  end
