require File.expand_path(File.dirname(__FILE__) + '/../common')
require File.expand_path(File.dirname(__FILE__) + '/../helpers/manage_groups_common')
require 'thread'

describe "manage admin groups" do
  it_should_behave_like "manage groups selenium tests"

  def add_account_category (account, name)
    driver.find_element(:css, ".add_category_link").click
    form = driver.find_element(:css, "#add_category_form")
    replace_content form.find_element(:css, "input[type=text]"), name
    submit_form(form)
    wait_for_ajaximations
    category = account.group_categories.find_by_name(name)
    category.should_not be_nil
    category
  end

  before (:each) do
    course_with_admin_logged_in
    @admin_account = Account.default
  end

  it "should show one div.group_category per category" do
    group_categories = create_categories @course.account
    create_new_set_groups(@course.account, group_categories[0], group_categories[1], group_categories[1], group_categories[2])
    get "/accounts/#{@course.account.id}/groups"
    group_divs = find_all_with_jquery("div.group_category")
    group_divs.size.should == 4 # three groups + blank
    ids = group_divs.map { |div| div.attribute(:id) }
    group_categories.each { |category| ids.should include("category_#{category.id}") }
    ids.should include("category_template")
  end

  it "should show one li.category per category" do
    group_categories = create_categories @admin_account
    create_new_set_groups(@admin_account, group_categories[0], group_categories[1], group_categories[1], group_categories[2])
    get "/accounts/#{@admin_account.id}/groups"
    group_divs = driver.find_elements(:css, "li.category")
    group_divs.size.should == 3
    labels = group_divs.map { |div| div.find_element(:css, "a").text }
    group_categories.each { |category| labels.should be_include(category.name) }
  end

  context "single category" do
    before (:each) do
      @courses_group_category = @admin_account.group_categories.create(:name => "Existing Category")
      groups_student_enrollment 1
    end

    it "should add new categories at the end of the tabs" do
      create_new_set_groups @admin_account, @courses_group_category
      get "/accounts/#{@admin_account.id}/groups"
      driver.find_elements(:css, "#category_list li").size.should == 1
      # submit new category form
      add_account_category @admin_account, 'New Category'
      driver.find_elements(:css, "#category_list li").size.should == 2
      driver.find_elements(:css, "#category_list li a").last.text.should eql "New Category"
    end

    it "should remove tab and sidebar entries for deleted category" do
      get "/accounts/#{@admin_account.id}/groups"
      driver.find_element(:css, "#category_#{@courses_group_category.id}").should be_displayed
      driver.find_element(:css, "#sidebar_category_#{@courses_group_category.id}").should be_displayed
      driver.find_element(:css, "#category_#{@courses_group_category.id} .delete_category_link").click
      confirm_dialog = driver.switch_to.alert
      confirm_dialog.accept
      wait_for_ajaximations
      find_with_jquery("#category_#{@courses_group_category.id}").should be_nil
      find_with_jquery("#sidebar_category_#{@courses_group_category.id}").should be_nil
    end

    it "should populate sidebar with new category when adding a category" do
      group = @admin_account.groups.create(:name => "Group 1", :group_category => @courses_group_category)
      get "/accounts/#{Account.default.id}/groups"
      f("#sidebar_category_#{@courses_group_category.id}").should be_displayed
      f("#sidebar_category_#{@courses_group_category.id} #sidebar_group_#{group.id}").should be_displayed
      new_category = add_account_category(@admin_account, 'New Category')
      # We need to refresh the page because it doesn't update the sidebar,
      # This is should probably be reported as a bug
      refresh_page
      driver.find_element(:id, "sidebar_category_#{new_category.id}").should be_displayed
    end

    it "should populate sidebar with new category when adding a category and group" do
      group = @admin_account.groups.create(:name => "Group 1", :group_category => @courses_group_category)
      get "/accounts/#{Account.default.id}/groups"
      driver.find_element(:css, "#sidebar_category_#{@courses_group_category.id}").should be_displayed
      f("#sidebar_category_#{@courses_group_category.id} #sidebar_group_#{group.id}").should be_displayed
      new_category = add_account_category(@admin_account, 'New Category')
      group2 = add_group_to_category new_category, "New Group Category 2"
      driver.find_element(:id, "sidebar_category_#{new_category.id}").should be_displayed
      driver.find_element(:css, "#sidebar_category_#{new_category.id} #sidebar_group_#{group2.id}").should be_displayed
    end

    it "should preserve group to category association when editing a group" do
      group = @admin_account.groups.create(:name => "Group 1", :group_category => @courses_group_category)
      get "/accounts/#{Account.default.id}/groups"
      wait_for_ajaximations
      find_with_jquery("#category_#{@courses_group_category.id} #group_#{group.id}").should be_displayed
      # submit new category form
      hover_and_click(".edit_group_link")
      form = driver.find_element(:css, "#edit_group_form")
      replace_content form.find_element(:css, "input[type=text]"), "New Name"
      submit_form(form)
      driver.find_element(:css, "#category_#{@courses_group_category.id} #group_#{group.id}").should be_displayed
    end

    it "should populate a group tag and check if it's there" do
      get "/accounts/#{@admin_account.id}/groups"
      category = add_account_category @admin_account, 'New Category'
      category_tabs = driver.find_elements(:css, '#category_list li')
      category_tabs[1].click
      category_name = driver.find_element(:css, "#category_#{category.id} .category_name").text
      category_name.should include_text(category.name)
    end

    it "should add another group and see that the group is there" do
      get "/accounts/#{@admin_account.id}/groups"
      group = add_group_to_category @courses_group_category, 'group 1'
      driver.find_element(:css, "#group_#{group.id} .group_name").text.should eql(group.name)
    end

    it "should add multiple groups and validate they exist" do
      groups = add_groups_in_category @courses_group_category
      get "/accounts/#{Account.default.id}/groups"
      category_groups = driver.find_elements(:css, ".left_side .group .name")
      category_groups.each_with_index { |cg, i| cg.text.should include_text(groups[i].name)}
    end

    it "should add multiple groups and be sure they are all deleted" do
      add_groups_in_category @courses_group_category
      get "/accounts/#{@admin_account.id}/groups"
      delete = driver.find_element(:css, ".delete_category_link")
      delete.click
      confirm_dialog = driver.switch_to.alert
      confirm_dialog.accept
      wait_for_ajaximations
      driver.find_elements(:css, ".left_side .group").should be_empty
      @admin_account.group_categories.all.count.should eql 0
    end

    it "should edit an individual group" do
      get "/accounts/#{@admin_account.id}/groups"
      group = add_group_to_category @courses_group_category, "group 1"
      driver.find_element(:id, "group_#{group.id}").click
      driver.find_element(:css, "#group_#{group.id} .edit_group_link").click
      name = "new group 1"
      driver.find_element(:css, "#group_name").send_keys(name)
      driver.find_element(:css, "#group_#{group.id} .button").click
      wait_for_ajaximations
      new_group = @admin_account.groups.find_by_name(name)
      group.should_not be_nil
    end

    it "should delete an individual group" do
      get "/accounts/#{@admin_account.id}/groups"
      group = add_group_to_category @courses_group_category, "group 1"
      driver.find_element(:id, "group_#{group.id}").click
      driver.find_element(:css, "#group_#{group.id} .delete_group_link").click
      confirm_dialog = driver.switch_to.alert
      confirm_dialog.accept
      wait_for_ajaximations
      driver.find_elements(:css, ".left_side .group").should be_empty
      @admin_account.group_categories.last.groups.last.workflow_state =='deleted'
    end

    it "should drag a user to a group" do
      student = @course.students.last
      get "/accounts/#{@admin_account.id}/groups"
      group = add_group_to_category @courses_group_category, "group 1"
      simulate_group_drag(student.id, "blank", group.id)
      group_div = driver.find_element(:css, "#group_#{group.id}")
      group_div.find_element(:css, ".user_id_#{student.id}").should be_displayed
    end

    it "should drag a user to 2 different groups" do
      student = @course.students.last
      groups = add_groups_in_category @courses_group_category, 2
      get "/accounts/#{@admin_account.id}/groups"
      wait_for_ajax_requests
      simulate_group_drag(student.id, "blank", groups[0].id)
      group1_div = driver.find_element(:css, "#group_#{groups[0].id}")
      group1_div.find_element(:css, ".user_id_#{student.id}").should be_displayed
      simulate_group_drag(student.id, groups[0].id, groups[1].id)
      group2_div = driver.find_element(:css, "#group_#{groups[1].id}")
      group2_div.find_element(:css, ".user_id_#{student.id}").should be_displayed
    end

    it "should drag a user to 2 different groups and back to the unassigned group" do
      student = @course.students.last
      groups = add_groups_in_category @courses_group_category, 2
      get "/accounts/#{@admin_account.id}/groups"
      wait_for_ajax_requests
      simulate_group_drag(student.id, "blank", groups[0].id)
      group1_div = driver.find_element(:css, "#group_#{groups[0].id}")
      group1_div.find_element(:css, ".user_id_#{student.id}").should be_displayed
      simulate_group_drag(student.id, groups[0].id, groups[1].id)
      group2_div = driver.find_element(:css, "#group_#{groups[1].id}")
      group2_div.find_element(:css, ".user_id_#{student.id}").should be_displayed
      unassigned_div = driver.find_element(:css, "#category_#{@courses_group_category.id} .group_blank")
      simulate_group_drag(student.id, groups[1].id, "blank")
      unassigned_div.find_elements(:css, ".user_id_#{student.id}").should_not be_empty
    end

    it "should create a category and should be able to edit it" do
      get "/accounts/#{@admin_account.id}/groups"
      @admin_account.group_categories.last.name.should == "Existing Category"
      driver.find_element(:css, "#category_#{@courses_group_category.id} .edit_category_link").click
      form = driver.find_element(:id, "edit_category_form")
      input_box = form.find_element(:css, "input[type=text]")
      category_name = "New Category"
      replace_content input_box, category_name
      submit_form(form)
      wait_for_ajaximations
      @admin_account.group_categories.last.name.should eql category_name
    end

    it "should create a category and should be able to check the Allow self sign-up box" do
      get "/accounts/#{@admin_account.id}/groups"
      @admin_account.group_categories.last.name.should == "Existing Category"
      driver.find_element(:css, "#category_#{@courses_group_category.id} .edit_category_link").click
      form = driver.find_element(:id, "edit_category_form")
      form.find_element(:id, "category_enable_self_signup").click
      is_checked('#category_enable_self_signup').should be_true
      submit_form(form)
      wait_for_ajaximations
      driver.find_element(:css, "#category_#{@courses_group_category.id} .self_signup_text").should include_text "Self sign-up is enabled"
    end

    it "should create a category and should be able to check the Allow self sign-up box and the Require group members to be in the same section" do
      get "/accounts/#{@admin_account.id}/groups"
      @admin_account.group_categories.last.name.should == "Existing Category"
      driver.find_element(:css, "#category_#{@courses_group_category.id} .edit_category_link").click
      form = driver.find_element(:id, "edit_category_form")
      form.find_element(:id, "category_enable_self_signup").click
      is_checked('#category_enable_self_signup').should be_true
      form.find_element(:id, "category_restrict_self_signup").click
      is_checked('#category_restrict_self_signup').should be_true
      submit_form(form)
      wait_for_ajaximations
      driver.find_element(:css, ".self_signup_text").should include_text "Self sign-up is enabled"
      driver.find_element(:css, ".restricted_self_signup_text").should include_text "All students in a group are required to be in the same section"
    end

    it "should click on  the self signup help link " do
      get "/accounts/#{@admin_account.id}/groups"
      @admin_account.group_categories.last.name.should include "Existing Category"
      driver.find_element(:css, "#category_#{@courses_group_category.id} .edit_category_link").click
      form = driver.find_element(:id, "edit_category_form")
      form.find_element(:css, ".self_signup_help_link").click
      driver.find_element(:id, "self_signup_help_dialog").should be_displayed
    end
  end
end
