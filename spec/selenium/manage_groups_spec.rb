require File.expand_path(File.dirname(__FILE__) + '/common')
require 'thread'

describe "manage_groups selenium tests" do
  it_should_behave_like "in-process server selenium tests"

  it "should show one div.group_category per category" do
    course_with_teacher_logged_in

    @course.enroll_student(user_model(:name => "John Doe"))
    @course.enroll_student(user_model(:name => "Jane Doe"))
    @course.enroll_student(user_model(:name => "Spot the Dog"))

    group_category1 = @course.group_categories.create(:name => "Group Category 1")
    group_category2 = @course.group_categories.create(:name => "Group Category 2")
    group_category3 = @course.group_categories.create(:name => "Group Category 3")

    @course.groups.create(:name => "Group 1", :group_category => group_category1)
    @course.groups.create(:name => "Group 2", :group_category => group_category2)
    @course.groups.create(:name => "Group 3", :group_category => group_category2)
    @course.groups.create(:name => "Group 4", :group_category => group_category3)

    get "/courses/#{@course.id}/groups"

    group_divs = find_all_with_jquery("div.group_category")
    group_divs.size.should == 4 # three groups + blank

    ids = group_divs.map{ |div| div.attribute(:id) }
    ids.should be_include("category_#{group_category1.id}")
    ids.should be_include("category_#{group_category2.id}")
    ids.should be_include("category_#{group_category3.id}")
    ids.should be_include("category_template")
  end

  it "should flag div.group_category for student organized categories with student_organized class" do
    course_with_teacher_logged_in

    @course.enroll_student(user_model(:name => "John Doe"))
    @course.enroll_student(user_model(:name => "Jane Doe"))
    @course.enroll_student(user_model(:name => "Spot the Dog"))

    group_category1 = GroupCategory.student_organized_for(@course)
    group_category2 = @course.group_categories.create(:name => "Other Groups")

    @course.groups.create(:name => "Group 1", :group_category => group_category1)
    @course.groups.create(:name => "Group 2", :group_category => group_category1)
    @course.groups.create(:name => "Group 3", :group_category => group_category2)

    get "/courses/#{@course.id}/groups"

    find_all_with_jquery("div.group_category").size.should == 3
    find_all_with_jquery("div.group_category.student_organized").size.should == 1
    find_with_jquery("div.group_category.student_organized").attribute(:id).
      should == "category_#{group_category1.id}"
  end

  it "should show one li.category per category" do
    course_with_teacher_logged_in

    @course.enroll_student(user_model(:name => "John Doe"))
    @course.enroll_student(user_model(:name => "Jane Doe"))
    @course.enroll_student(user_model(:name => "Spot the Dog"))

    group_category1 = @course.group_categories.create(:name => "Group Category 1")
    group_category2 = @course.group_categories.create(:name => "Group Category 2")
    group_category3 = @course.group_categories.create(:name => "Group Category 3")

    @course.groups.create(:name => "Group 1", :group_category => group_category1)
    @course.groups.create(:name => "Group 2", :group_category => group_category2)
    @course.groups.create(:name => "Group 3", :group_category => group_category2)
    @course.groups.create(:name => "Group 4", :group_category => group_category3)

    get "/courses/#{@course.id}/groups"

    group_divs = find_all_with_jquery("li.category")
    group_divs.size.should == 3 # three groups, no blank on this one

    labels = group_divs.map{ |div| div.find_element(:css, "a").text }
    labels.should be_include(group_category1.name)
    labels.should be_include(group_category2.name)
    labels.should be_include(group_category3.name)
  end

  it "should flag li.category for student organized categories with student_organized class" do
    course_with_teacher_logged_in

    @course.enroll_student(user_model(:name => "John Doe"))
    @course.enroll_student(user_model(:name => "Jane Doe"))
    @course.enroll_student(user_model(:name => "Spot the Dog"))

    group_category1 = GroupCategory.student_organized_for(@course)
    group_category2 = @course.group_categories.create(:name => "Other Groups")

    @course.groups.create(:name => "Group 1", :group_category => group_category1)
    @course.groups.create(:name => "Group 2", :group_category => group_category1)
    @course.groups.create(:name => "Group 3", :group_category => group_category2)

    get "/courses/#{@course.id}/groups"

    find_all_with_jquery("li.category").size.should == 2
    find_all_with_jquery("li.category.student_organized").size.should == 1
    find_with_jquery("li.category.student_organized a").text.should == group_category1.name
  end

  context "dragging a user between groups" do
    it "should remove a user from the old group if the category is not student organized" do
      course_with_teacher_logged_in

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
      course_with_teacher_logged_in

      @course.enroll_student(john = user_model(:name => "John Doe"))

      group_category = GroupCategory.student_organized_for(@course)

      group2 = @course.groups.create(:name => "Group 2", :group_category => group_category)
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

  it "should add new categories at the end of the tabs" do
    course_with_teacher_logged_in

    @course.enroll_student(user_model(:name => "John Doe"))
    group_category = @course.group_categories.create(:name => "Existing Category")
    @course.groups.create(:name => "Group 1", :group_category => group_category)

    get "/courses/#{@course.id}/groups"
    driver.find_elements(:css, "#category_list li").size.should == 1

    # submit new category form
    add_category(@course, 'New Category')
    driver.find_elements(:css, "#category_list li").size.should == 2
    driver.find_elements(:css, "#category_list li a").last.text.should == "New Category"
  end

  it "should keep the student organized category after any new categories" do
    course_with_teacher_logged_in

    @course.enroll_student(user_model(:name => "John Doe"))
    group_category = GroupCategory.student_organized_for(@course)
    @course.groups.create(:name => "Group 1", :group_category => group_category)

    get "/courses/#{@course.id}/groups"
    driver.find_elements(:css, "#category_list li").size.should == 1

    # submit new category form
    add_category(@course, 'New Category')
    driver.find_elements(:css, "#category_list li").size.should == 2
    driver.find_elements(:css, "#category_list li a").first.text.should == "New Category"
    driver.find_elements(:css, "#category_list li a").last.text.should == group_category.name
  end

  it "should move students from a deleted group back to unassigned" do
    course_with_teacher_logged_in

    @course.enroll_student(john = user_model(:name => "John Doe"))
    group_category = @course.group_categories.create(:name => "Some Category")
    group = @course.groups.create(:name => "Group 1", :group_category => group_category)
    group.add_user(john)
    @course.groups.create(:name => "Group 2", :group_category => group_category)

    get "/courses/#{@course.id}/groups"

    category = find_with_jquery(".group_category:visible")
    category.find_elements(:css, ".group_blank .user_id_#{john.id}").should be_empty

    driver.execute_script("$('#group_#{group.id} .delete_group_link').hover().click()") #move_to occasionally breaks in the hudson build
    confirm_dialog = driver.switch_to.alert
    confirm_dialog.accept
    wait_for_ajaximations

    category.find_elements(:css, ".group_blank .user_id_#{john.id}").should_not be_empty
  end

  it "should remove tab and sidebar entries for deleted category" do
    course_with_teacher_logged_in
    @course.enroll_student(john = user_model(:name => "John Doe"))
    group_category = @course.group_categories.create(:name => "Some Category")

    get "/courses/#{@course.id}/groups"

    find_with_jquery("#category_#{group_category.id}").should_not be_nil
    find_with_jquery("#sidebar_category_#{group_category.id}").should_not be_nil

    find_with_jquery("#category_#{group_category.id} .delete_category_link").click()
    confirm_dialog = driver.switch_to.alert
    confirm_dialog.accept
    wait_for_ajax_requests
    wait_for_ajaximations

    find_with_jquery("#category_#{group_category.id}").should be_nil
    find_with_jquery("#sidebar_category_#{group_category.id}").should be_nil
  end

  it "should populate sidebar with new category and groups when adding a category" do
    course_with_teacher_logged_in
    @course.enroll_student(john = user_model(:name => "John Doe"))
    group_category = @course.group_categories.create(:name => "Existing Category")
    group = @course.groups.create(:name => "Group 1", :group_category => group_category)

    get "/courses/#{@course.id}/groups"

    find_with_jquery("#sidebar_category_#{group_category.id}").should_not be_nil
    find_with_jquery("#sidebar_category_#{group_category.id} #sidebar_group_#{group.id}").should_not be_nil

    # submit new category form
    new_category = add_category(@course, 'New Category', :group_count => '1')
    new_category.groups.size.should == 1
    new_group = new_category.groups.first

    find_with_jquery("#sidebar_category_#{new_category.id}").should_not be_nil
    find_with_jquery("#sidebar_category_#{new_category.id} #sidebar_group_#{new_group.id}").should_not be_nil
  end

  it "should honor enable_self_signup when adding a category" do
    course_with_teacher_logged_in
    @course.enroll_student(john = user_model(:name => "John Doe"))

    get "/courses/#{@course.id}/groups"

    # submit new category form
    new_category = add_category(@course, 'New Category', :enable_self_signup => true)
    new_category.should be_self_signup
    new_category.should be_unrestricted_self_signup
  end

  it "should honor restrict_self_signup when adding a self signup category" do
    course_with_teacher_logged_in
    @course.enroll_student(john = user_model(:name => "John Doe"))

    get "/courses/#{@course.id}/groups"

    # submit new category form
    new_category = add_category(@course, 'New Category', :enable_self_signup => true, :restrict_self_signup => true)
    new_category.should be_self_signup
    new_category.should be_restricted_self_signup
  end

  it "should honor create_group_count when adding a self signup category" do
    course_with_teacher_logged_in
    @course.enroll_student(john = user_model(:name => "John Doe"))

    get "/courses/#{@course.id}/groups"

    # submit new category form
    new_category = add_category(@course, 'New Category', :enable_self_signup => true, :group_count => '2')
    new_category.groups.size.should == 2
  end

  it "should preserve group to category association when editing a group" do
    course_with_teacher_logged_in

    @course.enroll_student(user_model(:name => "John Doe"))
    group_category = @course.group_categories.create(:name => "Existing Category")
    group = @course.groups.create(:name => "Group 1", :group_category => group_category)

    get "/courses/#{@course.id}/groups"

    find_with_jquery("#category_#{group_category.id} #group_#{group.id}").should_not be_nil

    # submit new category form
    driver.execute_script("$('#group_#{group.id} .edit_group_link').hover().click()") #move_to occasionally breaks in the hudson build
    form = driver.find_element(:css, "#edit_group_form")
    form.find_element(:css, "input[type=text]").clear
    form.find_element(:css, "input[type=text]").send_keys("New Name")
    form.submit
    wait_for_ajax_requests
    wait_for_ajaximations

    find_with_jquery("#category_#{group_category.id} #group_#{group.id}").should_not be_nil
  end

  context "assign_students_link" do
    before :each do
      course_with_teacher_logged_in
      @student = @course.enroll_student(user_model(:name => "John Doe")).user
      get "/courses/#{@course.id}/groups"
      @category = add_category(@course, "New Category", :enable_self_signup => true, :group_count => '2')
    end

    it "should be visible iff category is not restricted self signup" do
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
      @student.groups.size.should == 1
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
      should_flash(:error, 'Nothing to do.')
    end

    it "should give 'Students assigned to groups.' success flash otherwise" do
      assign_students(@category)
      should_flash(:notice, 'Students assigned to groups.')
    end
  end
end

def add_category(course, name, opts={})
  driver.find_element(:css, ".add_category_link").click
  form = driver.find_element(:css, "#add_category_form")

  form.find_element(:css, "input[type=text]").clear
  form.find_element(:css, "input[type=text]").send_keys(name)

  enable_self_signup = form.find_element(:css, "#category_enable_self_signup")
  enable_self_signup.click unless !!enable_self_signup.attribute('checked') == !!opts[:enable_self_signup]

  restrict_self_signup = form.find_element(:css, "#category_restrict_self_signup")
  restrict_self_signup.click unless !!restrict_self_signup.attribute('checked') == !!opts[:restrict_self_signup]

  if opts[:group_count]
    if enable_self_signup.attribute('checked')
      form.find_element(:css, "#category_create_group_count").clear
      form.find_element(:css, "#category_create_group_count").send_keys(opts[:group_count].to_s)
    else
      form.find_element(:css, "#category_split_groups").click
      form.find_element(:css, "#category_split_group_count").clear
      form.find_element(:css, "#category_split_group_count").send_keys(opts[:group_count].to_s)
    end
  elsif enable_self_signup.attribute('checked')
    form.find_element(:css, "#category_create_group_count").clear
  else
    form.find_element(:css, "#category_no_groups").click
  end

  form.submit
  sleep 3 # wait_for_ajax_requests times out
  keep_trying_until { find_with_jquery("#add_category_form:visible").should be_nil }

  category = course.group_categories.find_by_name(name)
  category.should_not be_nil
  category
end

def edit_category(opts={})
  find_with_jquery(".edit_category_link:visible").click
  form = driver.find_element(:css, "#edit_category_form")

  if opts[:new_name]
    form.find_element(:css, "input[type=text]").clear
    form.find_element(:css, "input[type=text]").send_keys(opts[:new_name])
  end

  # click only if we're requesting a different state than current; if we're not
  # specifying a state, leave as is
  if opts.has_key?(:enable_self_signup)
    enable_self_signup = form.find_element(:css, "#category_enable_self_signup")
    enable_self_signup.click unless !!enable_self_signup.attribute('checked') == !!opts[:enable_self_signup]
  end

  if opts.has_key?(:restrict_self_signup)
    restrict_self_signup = form.find_element(:css, "#category_restrict_self_signup")
    restrict_self_signup.click unless !!restrict_self_signup.attribute('checked') == !!opts[:restrict_self_signup]
  end

  form.submit
  wait_for_ajaximations
end

def assign_students(category)
  assign_students = find_with_jquery("#category_#{category.id} .assign_students_link:visible")
  assign_students.should_not be_nil
  assign_students.click
  confirm_dialog = driver.switch_to.alert
  confirm_dialog.accept
  # wait_for_ajax_requests times out here
  sleep 5
end

def should_flash(type, message)
  [:notice, :error].should be_include(type)
  element = case type
    when :notice then '#flash_notice_message'
    when :error then '#flash_error_message'
    end
  keep_trying_until do
    flash = find_with_jquery("#{element}:visible")
    flash.should_not be_nil
    flash.text.should =~ /#{message}/
  end
end
