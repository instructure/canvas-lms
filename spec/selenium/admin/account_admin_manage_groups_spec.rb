require File.expand_path(File.dirname(__FILE__) + '/../helpers/manage_groups_common')
require 'thread'

describe "account admin manage groups" do
  include_examples "in-process server selenium tests"

  def add_account_category (account, name)
    f(".add_category_link").click
    form = f("#add_category_form")
    replace_content form.find_element(:css, "input[type=text]"), name
    submit_form(form)
    wait_for_ajaximations
    category = account.group_categories.where(name: name).first
    expect(category).not_to be_nil
    category
  end

  before (:each) do
    skip
		#course_with_admin_logged_in
    #@admin_account = Account.default
    #@admin_account.settings[:enable_manage_groups2] = false
    #@admin_account.save!
  end

  it "should show one div.group_category per category" do
    group_categories = create_categories @course.account
    create_new_set_groups(@course.account, group_categories[0], group_categories[1], group_categories[1], group_categories[2])
    get "/accounts/#{@course.account.id}/groups"
    group_divs = find_all_with_jquery("div.group_category")
    expect(group_divs.size).to eq 4 # three groups + blank
    ids = group_divs.map { |div| div.attribute(:id) }
    group_categories.each { |category| expect(ids).to include("category_#{category.id}") }
    expect(ids).to include("category_template")
  end

  it "should show one li.category per category" do
    group_categories = create_categories @admin_account
    create_new_set_groups(@admin_account, group_categories[0], group_categories[1], group_categories[1], group_categories[2])
    get "/accounts/#{@admin_account.id}/groups"
    group_divs = driver.find_elements(:css, "li.category")
    expect(group_divs.size).to eq 3
    labels = group_divs.map { |div| div.find_element(:css, "a").text }
    group_categories.each { |category| expect(labels).to be_include(category.name) }
  end

  context "single category" do
    before (:each) do
      @courses_group_category = @admin_account.group_categories.create(:name => "Existing Category")
      groups_student_enrollment 1
    end

    it "should add new categories at the end of the tabs" do
      create_new_set_groups @admin_account, @courses_group_category
      get "/accounts/#{@admin_account.id}/groups"
      expect(driver.find_elements(:css, "#category_list li").size).to eq 1
      # submit new category form
      add_account_category @admin_account, 'New Category'
      expect(driver.find_elements(:css, "#category_list li").size).to eq 2
      expect(driver.find_elements(:css, "#category_list li a").last.text).to eq "New Category"
    end

    it "should remove tab and sidebar entries for deleted category" do
      get "/accounts/#{@admin_account.id}/groups"
      expect(f("#category_#{@courses_group_category.id}")).to be_displayed
      expect(f("#sidebar_category_#{@courses_group_category.id}")).to be_displayed
      f("#category_#{@courses_group_category.id} .delete_category_link").click
      confirm_dialog = driver.switch_to.alert
      confirm_dialog.accept
      wait_for_ajaximations
      expect(find_with_jquery("#category_#{@courses_group_category.id}")).to be_nil
      expect(find_with_jquery("#sidebar_category_#{@courses_group_category.id}")).to be_nil
    end

    it "should populate sidebar with new category when adding a category" do
      group = @admin_account.groups.create(:name => "Group 1", :group_category => @courses_group_category)
      get "/accounts/#{Account.default.id}/groups"
      expect(f("#sidebar_category_#{@courses_group_category.id}")).to be_displayed
      expect(f("#sidebar_category_#{@courses_group_category.id} #sidebar_group_#{group.id}")).to be_displayed
      new_category = add_account_category(@admin_account, 'New Category')
      # We need to refresh the page because it doesn't update the sidebar,
      # This is should probably be reported as a bug
      refresh_page
      expect(f("#sidebar_category_#{new_category.id}")).to be_displayed
    end

    it "should populate sidebar with new category when adding a category and group" do
      group = @admin_account.groups.create(:name => "Group 1", :group_category => @courses_group_category)
      get "/accounts/#{Account.default.id}/groups"
      expect(f("#sidebar_category_#{@courses_group_category.id}")).to be_displayed
      expect(f("#sidebar_category_#{@courses_group_category.id} #sidebar_group_#{group.id}")).to be_displayed
      new_category = add_account_category(@admin_account, 'New Category')
      group2 = add_group_to_category new_category, "New Group Category 2"
      expect(f("#sidebar_category_#{new_category.id}")).to be_displayed
      expect(driver.find_element(:css, "#sidebar_category_#{new_category.id} #sidebar_group_#{group2.id}")).to be_displayed
    end

    it "should preserve group to category association when editing a group" do
      group = @admin_account.groups.create(:name => "Group 1", :group_category => @courses_group_category)
      get "/accounts/#{Account.default.id}/groups"
      wait_for_ajaximations
      expect(find_with_jquery("#category_#{@courses_group_category.id} #group_#{group.id}")).to be_displayed
      # submit new category form
      hover_and_click(".edit_group_link")
      form = f("#edit_group_form")
      replace_content form.find_element(:css, "input[type=text]"), "New Name"
      submit_form(form)
      expect(f("#category_#{@courses_group_category.id} #group_#{group.id}")).to be_displayed
    end

    it "should populate a group tag and check if it's there" do
      get "/accounts/#{@admin_account.id}/groups"
      category = add_account_category @admin_account, 'New Category'
      category_tabs = driver.find_elements(:css, '#category_list li')
      category_tabs[1].click
      category_name = f("#category_#{category.id} .category_name").text
      expect(category_name).to include_text(category.name)
    end

    it "should add another group and see that the group is there" do
      get "/accounts/#{@admin_account.id}/groups"
      group = add_group_to_category @courses_group_category, 'group 1'
      expect(f("#group_#{group.id} .group_name").text).to eq group.name
    end

    it "should add multiple groups and validate they exist" do
      groups = add_groups_in_category @courses_group_category
      get "/accounts/#{Account.default.id}/groups"
      category_groups = driver.find_elements(:css, ".left_side .group .name")
      category_groups.each_with_index { |cg, i| expect(cg.text).to include_text(groups[i].name)}
    end

    it "should add multiple groups and be sure they are all deleted" do
      add_groups_in_category @courses_group_category
      get "/accounts/#{@admin_account.id}/groups"
      make_full_screen
      delete = f(".delete_category_link")
      delete.click
      confirm_dialog = driver.switch_to.alert
      confirm_dialog.accept
      wait_for_ajaximations
      expect(driver.find_elements(:css, ".left_side .group")).to be_empty
      expect(@admin_account.group_categories.all.count).to eq 0
    end

    it "should edit an individual group" do
      get "/accounts/#{@admin_account.id}/groups"
      group = add_group_to_category @courses_group_category, "group 1"
      expect(group).not_to be_nil
      f("#group_#{group.id}").click
      wait_for_ajaximations
      f("#group_#{group.id} .edit_group_link").click
      wait_for_ajaximations
      name = "new group 1"
      f("#group_name").send_keys(name)
      f("#group_#{group.id} .btn").click
      wait_for_ajaximations
      group = @admin_account.groups.where(name: name).first
      expect(group).not_to be_nil
    end

    it "should delete an individual group" do
      get "/accounts/#{@admin_account.id}/groups"
      group = add_group_to_category @courses_group_category, "group 1"
      f("#group_#{group.id}").click
      driver.find_element(:css, "#group_#{group.id} .delete_group_link").click
      confirm_dialog = driver.switch_to.alert
      confirm_dialog.accept
      wait_for_ajaximations
      expect(driver.find_elements(:css, ".left_side .group")).to be_empty
      @admin_account.group_categories.last.groups.last.workflow_state =='deleted'
    end

    it "should drag a user to a group" do
      student = @course.students.last
      get "/accounts/#{@admin_account.id}/groups"
      group = add_group_to_category @courses_group_category, "group 1"
      simulate_group_drag(student.id, "blank", group.id)
      group_div = f("#group_#{group.id}")
      expect(group_div.find_element(:css, ".user_id_#{student.id}")).to be_displayed
    end

    it "should drag a user to 2 different groups" do
      student = @course.students.last
      groups = add_groups_in_category @courses_group_category, 2
      get "/accounts/#{@admin_account.id}/groups"
      wait_for_ajax_requests
      simulate_group_drag(student.id, "blank", groups[0].id)
      group1_div = f("#group_#{groups[0].id}")
      expect(group1_div.find_element(:css, ".user_id_#{student.id}")).to be_displayed
      simulate_group_drag(student.id, groups[0].id, groups[1].id)
      group2_div = f("#group_#{groups[1].id}")
      expect(group2_div.find_element(:css, ".user_id_#{student.id}")).to be_displayed
    end

    it "should drag a user to 2 different groups and back to the unassigned group" do
      student = @course.students.last
      groups = add_groups_in_category @courses_group_category, 2
      get "/accounts/#{@admin_account.id}/groups"
      wait_for_ajax_requests
      simulate_group_drag(student.id, "blank", groups[0].id)
      group1_div = f("#group_#{groups[0].id}")
      expect(group1_div.find_element(:css, ".user_id_#{student.id}")).to be_displayed
      simulate_group_drag(student.id, groups[0].id, groups[1].id)
      group2_div = f("#group_#{groups[1].id}")
      expect(group2_div.find_element(:css, ".user_id_#{student.id}")).to be_displayed
      unassigned_div = f("#category_#{@courses_group_category.id} .group_blank")
      simulate_group_drag(student.id, groups[1].id, "blank")
      expect(unassigned_div.find_elements(:css, ".user_id_#{student.id}")).not_to be_empty
      get "/accounts/#{@admin_account.id}/groups"
      unassigned_div =f("#category_#{@courses_group_category.id} .group_blank")
      expect(unassigned_div.find_elements(:css, ".user_id_#{student.id}")).not_to be_empty
    end

    it "should create a category and should be able to edit it" do
      get "/accounts/#{@admin_account.id}/groups"
      expect(@admin_account.group_categories.last.name).to eq "Existing Category"
      make_full_screen
      f("#category_#{@courses_group_category.id} .edit_category_link .icon-edit").click
      wait_for_ajaximations
      form = f("#edit_category_form")
      input_box = form.find_element(:css, "input[type=text]")
      category_name = "New Category"
      replace_content input_box, category_name
      submit_form(form)
      wait_for_ajaximations
      expect(@admin_account.group_categories.last.name).to eq category_name
    end

    it "should not be able to check the Allow self sign-up box" do
      get "/accounts/#{@admin_account.id}/groups"
      expect(@admin_account.group_categories.last.name).to eq "Existing Category"
      make_full_screen
      f("#category_#{@courses_group_category.id} .edit_category_link .icon-edit").click
      wait_for_ajaximations
      form = driver.find_element(:id, "edit_category_form")
      expect(ff("#category_enable_self_signup", form)).to be_empty
      submit_form(form)
      wait_for_ajaximations
      expect(f("#category_#{@courses_group_category.id} .self_signup_text")).not_to include_text "Self sign-up is enabled"
    end
  end
end
