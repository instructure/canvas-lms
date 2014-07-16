require File.expand_path(File.dirname(__FILE__) + '/helpers/manage_groups_common')
require 'thread'

describe "manage groups" do
  include_examples "in-process server selenium tests"

  before (:each) do
    course_with_teacher_logged_in
  end

  context "2.0" do
    before do
      #TODO: Remove this setting once made the default behavior?
      account = Account.default
      account.settings[:enable_manage_groups2] = true
      account.save!
    end

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
        f('#group_categories_tabs .collectionViewItems').text.should include('Everyone')
        f('#group_categories_tabs .collectionViewItems').text.should include('zomg')

        run_jobs

        groups = nil
        keep_trying_until {
          groups = ff('.collectionViewItems > .group')
          groups.present?
        }
        groups.size.should == 2
      end
    end

    it "should allow a teacher to create a group set, a group, and add a user" do
      course_with_teacher_logged_in(:active_all => true)
      student_in_course
      student_in_course

      get "/courses/#{@course.id}/groups"
      wait_for_ajaximations

      keep_trying_until do
        fj("#add-group-set").click
        wait_for_animations
      end
      f("#new_category_name").send_keys('Group Set 1')
      f("form.group-category-create").submit
      wait_for_ajaximations

      # verify the group set tab is created
      fj("#group_categories_tabs li[role='tab']:nth-child(2)").text.should == 'Group Set 1'
      # verify has the two created but unassigned students
      ff("div[data-view='unassignedUsers'] .group-user-name").length.should == 2

      # click the first visible "Add Group" button
      fj(".add-group:visible:first").click
      wait_for_animations
      f("#group_name").send_keys("New Test Group A")
      f("form.group-edit-dialog").submit
      wait_for_ajaximations

      # Add user to the group
      fj(".group-summary:visible:first").text.should == "0 students"
      ff("div[data-view='unassignedUsers'] .assign-to-group").first.click
      wait_for_animations
      ff(".assign-to-group-menu .set-group").first.click
      wait_for_ajaximations
      fj(".group-summary:visible:first").text.should == "1 student"
      ff("div[data-view='unassignedUsers'] .assign-to-group").length.should == 1

      # Remove added user from the group
      fj(".groups .group .toggle-group:first").click
      wait_for_ajaximations
      fj(".groups .group .group-user-actions:first").click
      wait_for_ajaximations
      fj(".remove-from-group:first").click
      wait_for_ajaximations
      fj(".group-summary:visible:first").text.should == "0 students"
      # should re-appear in unassigned
      ff("div[data-view='unassignedUsers'] .assign-to-group").length.should == 2
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
      ff(unassigned_users_selector).size.should == 5
      ff(group1_users_selector).size.should == 0
      ff(group2_users_selector).size.should == 0

      drag_and_drop_element( fj(first_unassigned_user), fj(group1_selector) )
      drag_and_drop_element( fj(first_unassigned_user), fj(group1_selector) )
      # assert there are 3 students in unassigned
      # assert there is 2 student in group 0
      # assert there is still 0 students in group 1
      ff(unassigned_users_selector).size.should == 3
      ff(group1_users_selector).size.should == 2
      ff(group2_users_selector).size.should == 0

      drag_and_drop_element( fj(first_group1_user), fj(unassigned_group_selector) )
      drag_and_drop_element( fj(first_group1_user), fj(group2_selector) )
      # assert there are 4 students in unassigned
      # assert there are 0 students in group 0
      # assert there is 1 student in group 1
      ff(unassigned_users_selector).size.should == 4
      ff(group1_users_selector).size.should == 0
      ff(group2_users_selector).size.should == 1
    end

    it "should support student-organized groups" do
      course_with_teacher_logged_in(:active_all => true)
      student_in_course
      student_in_course

      cat = GroupCategory.student_organized_for(@course)
      add_groups_in_category cat, 1

      get "/courses/#{@course.id}/groups"
      wait_for_ajaximations

      f('.group-category-actions .al-trigger').should be_nil # can't edit/delete etc.

      # user never leaves "Everyone" list, only gets added to a group once
      2.times do
        f('.unassigned-users-heading').text.should == "Everyone (2)"
        ff("div[data-view='unassignedUsers'] .assign-to-group").first.click
        wait_for_animations
        ff(".assign-to-group-menu .set-group").first.click
        wait_for_ajaximations
        fj(".group-summary:visible:first").text.should == "1 student"
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
      fj(".group-summary:visible:first").text.should == "0 students"
      ff("div[data-view='unassignedUsers'] .assign-to-group").first.click
      wait_for_animations
      ff(".assign-to-group-menu .set-group").first.click
      wait_for_ajaximations
      fj(".group-summary:visible:first").text.should == "1 student"
      fj(".group-summary:visible:last").text.should == "0 students"


      # Move the user from one group into the other
      fj(".groups .group .group-user .group-user-actions").click
      wait_for_ajaximations
      fj(".edit-group-assignment:first").click
      wait_for_ajaximations
      fj(".single-select:first option:first").click
      wait_for_ajaximations
      fj('.set-group:first').click
      wait_for_ajaximations
      fj(".group-summary:visible:first").text.should == "0 students"
      fj(".group-summary:visible:last").text.should == "1 student"

      # Move the user back
      fj(".groups .group .group-user .group-user-actions").click
      wait_for_ajaximations
      fj(".edit-group-assignment:last").click
      wait_for_ajaximations
      fj(".single-select:last option:first").click
      wait_for_ajaximations
      fj('.set-group:last').click
      wait_for_ajaximations
      fj(".group-summary:visible:first").text.should == "1 student"
      fj(".group-summary:visible:last").text.should == "0 students"
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
      fj([actions_button, message_users].join(" + ")).should be
      fj([actions_button, randomly_assign_users].join(" + ")).should be

      # assign the last unassigned member
      draggable_user = fj(".unassigned-students .group-user:first")
      droppable_group = fj(".group[data-id=\"#{group.id}\"]")
      drag_and_drop_element draggable_user, droppable_group
      wait_for_ajaximations

      # now the menu should not show unassigned-member options
      fj(actions_button).click
      wait_for_ajaximations
      fj([actions_button, message_users].join(" + ")).should be_nil
      fj([actions_button, randomly_assign_users].join(" + ")).should be_nil
    end
  end

  # TODO: Remove this whole section after new UI becomes default
  context "with old UI" do
    before :each do
      #TODO: Remove this setting once made the default behavior
      account = Account.default
      account.settings[:enable_manage_groups2] = false
      account.save!
    end

    it "should show one div.group_category per category" do
      groups_student_enrollment 3
      group_categories = create_categories @course
      create_new_set_groups(@course.account, group_categories[0], group_categories[1], group_categories[1], group_categories[2])
      get "/courses/#{@course.id}/groups"
      group_divs = ff(".group_category")
      group_divs.size.should == 4 # three groups + blank
      ids = group_divs.map { |div| div.attribute(:id) }
      group_categories.each { |category| ids.should include("category_#{category.id}") }
      ids.should include("category_template")
    end

    it "should flag div.group_category for student organized categories with student_organized class" do
      groups_student_enrollment 3
      group_category1 = GroupCategory.student_organized_for(@course)
      group_category2 = @course.group_categories.create(:name => "Other Groups")
      create_new_set_groups(@course.account, group_category1, group_category1, group_category2)
      get "/courses/#{@course.id}/groups"
      ff(".group_category").size.should == 3
      ff(".group_category.student_organized").size.should == 1
      f(".group_category.student_organized").should have_attribute(:id, "category_#{group_category1.id}")
    end

    it "should show one li.category per category" do
      groups_student_enrollment 3
      group_categories= create_categories @course
      create_new_set_groups(@course.account, group_categories[0], group_categories[1], group_categories[1], group_categories[2])
      get "/courses/#{@course.id}/groups"
      group_divs = ffj("li.category")
      group_divs.size.should == 3 # three groups, no blank on this one
      labels = group_divs.map { |div| div.find_element(:css, "a").text }
      group_categories.each { |category| labels.should include category.name }
    end

    it "should flag li.category for student organized categories with student_organized class" do
      groups_student_enrollment 3
      group_category1 = GroupCategory.student_organized_for(@course)
      group_category2 = @course.group_categories.create(:name => "Other Groups")
      @course.groups.create(:name => "Group 1", :group_category => group_category1)
      @course.groups.create(:name => "Group 2", :group_category => group_category1)
      @course.groups.create(:name => "Group 3", :group_category => group_category2)
      get "/courses/#{@course.id}/groups"
      ffj("li.category").size.should == 2
      ffj("li.category.student_organized").size.should == 1
      fj("li.category.student_organized a").text.should == group_category1.name
    end

    it "should add new categories at the end of the tabs" do
      groups_student_enrollment 3
      group_category = @course.group_categories.create(:name => "Existing Category")
      @course.groups.create(:name => "Group 1", :group_category => group_category)
      get "/courses/#{@course.id}/groups"
      ff("#category_list li").size.should == 1
      # submit new category form
      add_category(@course, 'New Category')
      ff("#category_list li").size.should == 2
      ff("#category_list li a").last.text.should == "New Category"
    end

    it "should keep the student organized category after any new categories" do
      groups_student_enrollment 3
      group_category = GroupCategory.student_organized_for(@course)
      @course.groups.create(:name => "Group 1", :group_category => group_category)

      get "/courses/#{@course.id}/groups"
      ff("#category_list li").size.should == 1
      # submit new category form
      add_category(@course, 'New Category')
      ff("#category_list li").size.should == 2
      ff("#category_list li a").first.text.should == "New Category"
      ff("#category_list li a").last.text.should == group_category.name
    end

    it "should remove tab and sidebar entries for deleted category" do
      groups_student_enrollment 3
      group_category = @course.group_categories.create(:name => "Some Category")
      get "/courses/#{@course.id}/groups"
      f("#category_#{group_category.id}").should be_displayed
      f("#sidebar_category_#{group_category.id}").should be_displayed
      f("#category_#{group_category.id} .delete_category_link").click
      confirm_dialog = driver.switch_to.alert
      confirm_dialog.accept
      keep_trying_until do
        fj("#category_#{group_category.id}").should be_nil
        fj("#sidebar_category_#{group_category.id}").should be_nil
      end
    end

    it "should populate sidebar with new category and groups when adding a category" do
      groups_student_enrollment 3
      group_category = @course.group_categories.create(:name => "Existing Category")
      group = @course.groups.create(:name => "Group 1", :group_category => group_category)
      get "/courses/#{@course.id}/groups"
      f("#sidebar_category_#{group_category.id}").should be_displayed
      f("#sidebar_category_#{group_category.id} #sidebar_group_#{group.id}").should be_displayed
      # submit new category form
      new_category = add_category(@course, 'New Category', :group_count => '1')
      new_category.groups.size.should == 1
      new_group = new_category.groups.first
      f("#sidebar_category_#{new_category.id}").should be_displayed
      f("#sidebar_category_#{new_category.id} #sidebar_group_#{new_group.id}").should be_displayed
    end

    it "should honor enable_self_signup when adding a category" do
      groups_student_enrollment 3
      get "/courses/#{@course.id}/groups"
      # submit new category form
      new_category = add_category(@course, 'New Category', :enable_self_signup => true)
      new_category.should be_self_signup
      new_category.should be_unrestricted_self_signup
    end

    it "should honor restrict_self_signup when adding a self signup category" do
      @course.enroll_student(user_model(:name => "John Doe"))
      get "/courses/#{@course.id}/groups"
      # submit new category form
      new_category = add_category(@course, 'New Category', :enable_self_signup => true, :restrict_self_signup => true)
      new_category.should be_self_signup
      new_category.should be_restricted_self_signup
    end

    it "should honor create_group_count when adding a self signup category" do
      @course.enroll_student(user_model(:name => "John Doe"))
      get "/courses/#{@course.id}/groups"
      # submit new category form
      new_category = add_category(@course, 'New Category', :enable_self_signup => true, :group_count => '2')
      new_category.groups.size.should == 2
    end

    it "should honor group_limit when adding a self signup category" do
      @course.enroll_student(user_model(:name => "John Doe"))
      get "/courses/#{@course.id}/groups"
      # submit new category form
      new_category = add_category(@course, 'New Category', :enable_self_signup => true, :group_limit => '2')
      new_category.group_limit.should == 2
    end

    it "should preserve group to category association when editing a group" do
      groups_student_enrollment 3
      group_category = @course.group_categories.create(:name => "Existing Category")
      group = @course.groups.create(:name => "Group 1", :group_category => group_category)
      get "/courses/#{@course.id}/groups"
      f("#category_#{group_category.id} #group_#{group.id}").should be_displayed
      # submit new category form
      driver.execute_script("$('#group_#{group.id} .edit_group_link').hover().click()") #move_to occasionally breaks in the hudson build
      form = f("#edit_group_form")
      replace_content(form.find_element(:css, "input[type=text]"), "New Name")
      submit_form(form)
      f("#category_#{group_category.id} #group_#{group.id}").should be_displayed
    end

    it "should not show the Make a New Set of Groups button if there are no students in the course" do
      get "/courses/#{@course.id}/groups"
      f('.add_category_link').should be_nil
      f('#no_students_message').should be_displayed
    end
    it "should show the Make a New Set of Groups button if there are students in the course" do
      student_in_course
      get "/courses/#{@course.id}/groups"
      f('.add_category_link').should be_displayed
      f('#no_students_message').should be_nil
    end

    it "should let you message students not in a group" do
      groups_student_enrollment 3
      group_category1 = @course.group_categories.create(:name => "Project Groups")
      group_category2 = @course.group_categories.create(:name => "Self Signup Groups")
      group_category2.configure_self_signup(true, false)
      group_category2.save
      get "/courses/#{@course.id}/groups"
      wait_for_ajaximations

      ff(".group_category").size.should == 3
      keep_trying_until { !f("#category_#{group_category1.id} .right_side .loading_members").displayed? }
      f('.group_category .student_links').should be_displayed
      f('.group_category .message_students_link').should_not be_displayed # only self signup can do it
      ff('.ui-tabs-anchor')[1].click

      keep_trying_until { !f("#category_#{group_category2.id} .right_side .loading_members").displayed? }
      message_students_link =  ff('.group_category .message_students_link')[1]
      message_students_link.should be_displayed
      message_students_link.click

      keep_trying_until{ f('.message-students-dialog').should be_displayed }
    end

    context "data validation" do
      before (:each) do
        student_in_course
        get "/courses/#{@course.id}/groups"
        @form = keep_trying_until do
          f('.add_category_link').click
          @form = f('#add_category_form')
          @form.should be_displayed
          @form
        end
      end

      max_length_name = "jkljfdklfjsaklfjasfjlsaklfjsafsaffdafdjasklsajfjskjkljfdklfjsaklfjasfjlsaklfjsafsaffdafdjasklsajfjskjkljfdklfjsaklfjasfjlsaklfjsafsaffdafdjasklsajfjskjkljfdklfjsaklfjasfjlsaklfjsafsaffdafdjasklsajfjskjkljfdklfjsaklfjasfjlsaklfjsafsaffdafdjasklsajfjskfffff"

      it "should create a new group category with a 255 character name when creating groups manually" do
        replace_content(f('#add_category_form input[name="category[name]"]'), max_length_name)
        submit_form(@form)
        wait_for_ajaximations
        GroupCategory.find_by_name(max_length_name).should be_present
      end

      it "should not create a new group category if the generated group names will exceed 255 characters" do
        replace_content(f('#add_category_form input[name="category[name]"]'), max_length_name)
        f('#category_split_groups').click
        submit_form(@form)
        wait_for_ajaximations
        ff('.error_box').last.text.should == 'Enter a shorter category name'
        GroupCategory.find_by_name(max_length_name).should_not be_present
        @form.should be_displayed
      end

      it "should validate split groups radio button adds a 1 to the input" do
        f('#category_split_groups').click
        f('#category_split_group_count').should have_attribute(:value, '1')
      end

      it "should validate create groups manually radio button clears the input" do
        f('#category_split_groups').click
        group_count = f('#category_split_group_count')
        group_count.should have_attribute(:value, '1')
        f('#category_no_groups').click
        f('#category_split_group_count').should have_attribute(:value, '')
      end
    end
  end
end
