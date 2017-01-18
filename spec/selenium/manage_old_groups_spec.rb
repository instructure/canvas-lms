require_relative 'helpers/groups_common'
require_relative 'helpers/manage_groups_common'
require 'thread'

describe "manage groups" do
  include_context "in-process server selenium tests"
  include GroupsCommon
  include ManageGroupsCommon

  before(:each) do
    course_with_teacher_logged_in
  end

  # TODO: Remove this whole section after new UI becomes default
  context "with old UI" do
    before(:each) do
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
      expect(group_divs.size).to eq 4 # three groups + blank
      ids = group_divs.map { |div| div.attribute(:id) }
      group_categories.each { |category| expect(ids).to include("category_#{category.id}") }
      expect(ids).to include("category_template")
    end

    it "should flag div.group_category for student organized categories with student_organized class" do
      groups_student_enrollment 3
      group_category1 = GroupCategory.student_organized_for(@course)
      group_category2 = @course.group_categories.create(:name => "Other Groups")
      create_new_set_groups(@course.account, group_category1, group_category1, group_category2)
      get "/courses/#{@course.id}/groups"
      expect(ff(".group_category").size).to eq 3
      expect(ff(".group_category.student_organized").size).to eq 1
      expect(f(".group_category.student_organized")).to have_attribute(:id, "category_#{group_category1.id}")
    end

    it "should show one li.category per category" do
      groups_student_enrollment 3
      group_categories= create_categories @course
      create_new_set_groups(@course.account, group_categories[0], group_categories[1], group_categories[1], group_categories[2])
      get "/courses/#{@course.id}/groups"
      group_divs = ffj("li.category")
      expect(group_divs.size).to eq 3 # three groups, no blank on this one
      labels = group_divs.map { |div| div.find_element(:css, "a").text }
      group_categories.each { |category| expect(labels).to include category.name }
    end

    it "should flag li.category for student organized categories with student_organized class" do
      groups_student_enrollment 3
      group_category1 = GroupCategory.student_organized_for(@course)
      group_category2 = @course.group_categories.create(:name => "Other Groups")
      @course.groups.create(:name => "Group 1", :group_category => group_category1)
      @course.groups.create(:name => "Group 2", :group_category => group_category1)
      @course.groups.create(:name => "Group 3", :group_category => group_category2)
      get "/courses/#{@course.id}/groups"
      expect(ffj("li.category").size).to eq 2
      expect(ffj("li.category.student_organized").size).to eq 1
      expect(fj("li.category.student_organized a").text).to eq group_category1.name
    end

    it "should add new categories at the end of the tabs" do
      groups_student_enrollment 3
      group_category = @course.group_categories.create(:name => "Existing Category")
      @course.groups.create(:name => "Group 1", :group_category => group_category)
      get "/courses/#{@course.id}/groups"
      expect(ff("#category_list li").size).to eq 1
      # submit new category form
      add_category(@course, 'New Category')
      expect(ff("#category_list li").size).to eq 2
      expect(ff("#category_list li a").last.text).to eq "New Category"
    end

    it "should keep the student organized category after any new categories" do
      groups_student_enrollment 3
      group_category = GroupCategory.student_organized_for(@course)
      @course.groups.create(:name => "Group 1", :group_category => group_category)

      get "/courses/#{@course.id}/groups"
      expect(ff("#category_list li").size).to eq 1
      # submit new category form
      add_category(@course, 'New Category')
      expect(ff("#category_list li").size).to eq 2
      expect(ff("#category_list li a").first.text).to eq "New Category"
      expect(ff("#category_list li a").last.text).to eq group_category.name
    end

    it "should remove tab and sidebar entries for deleted category" do
      groups_student_enrollment 3
      group_category = @course.group_categories.create(:name => "Some Category")
      get "/courses/#{@course.id}/groups"
      expect(f("#category_#{group_category.id}")).to be_displayed
      expect(f("#sidebar_category_#{group_category.id}")).to be_displayed
      f("#category_#{group_category.id} .delete_category_link").click
      confirm_dialog = driver.switch_to.alert
      confirm_dialog.accept
      expect(f("#content")).not_to contain_jqcss("#category_#{group_category.id}")
      expect(f("#content")).not_to contain_jqcss("#sidebar_category_#{group_category.id}")
    end

    it "should populate sidebar with new category and groups when adding a category" do
      groups_student_enrollment 3
      group_category = @course.group_categories.create(:name => "Existing Category")
      group = @course.groups.create(:name => "Group 1", :group_category => group_category)
      get "/courses/#{@course.id}/groups"
      expect(f("#sidebar_category_#{group_category.id}")).to be_displayed
      expect(f("#sidebar_category_#{group_category.id} #sidebar_group_#{group.id}")).to be_displayed
      # submit new category form
      new_category = add_category(@course, 'New Category', :group_count => '1')
      expect(new_category.groups.size).to eq 1
      new_group = new_category.groups.first
      expect(f("#sidebar_category_#{new_category.id}")).to be_displayed
      expect(f("#sidebar_category_#{new_category.id} #sidebar_group_#{new_group.id}")).to be_displayed
    end

    it "should honor enable_self_signup when adding a category" do
      groups_student_enrollment 3
      get "/courses/#{@course.id}/groups"
      # submit new category form
      new_category = add_category(@course, 'New Category', :enable_self_signup => true)
      expect(new_category).to be_self_signup
      expect(new_category).to be_unrestricted_self_signup
    end

    it "should honor restrict_self_signup when adding a self signup category" do
      @course.enroll_student(user_model(:name => "John Doe"))
      get "/courses/#{@course.id}/groups"
      # submit new category form
      new_category = add_category(@course, 'New Category', :enable_self_signup => true, :restrict_self_signup => true)
      expect(new_category).to be_self_signup
      expect(new_category).to be_restricted_self_signup
    end

    it "should honor create_group_count when adding a self signup category" do
      @course.enroll_student(user_model(:name => "John Doe"))
      get "/courses/#{@course.id}/groups"
      # submit new category form
      new_category = add_category(@course, 'New Category', :enable_self_signup => true, :group_count => '2')
      expect(new_category.groups.size).to eq 2
    end

    it "should honor group_limit when adding a self signup category" do
      @course.enroll_student(user_model(:name => "John Doe"))
      get "/courses/#{@course.id}/groups"
      # submit new category form
      new_category = add_category(@course, 'New Category', :enable_self_signup => true, :group_limit => '2')
      expect(new_category.group_limit).to eq 2
    end

    it "should preserve group to category association when editing a group" do
      groups_student_enrollment 3
      group_category = @course.group_categories.create(:name => "Existing Category")
      group = @course.groups.create(:name => "Group 1", :group_category => group_category)
      get "/courses/#{@course.id}/groups"
      expect(f("#category_#{group_category.id} #group_#{group.id}")).to be_displayed
      # submit new category form
      driver.execute_script("$('#group_#{group.id} .edit_group_link').hover().click()") #move_to occasionally breaks in the hudson build
      form = f("#edit_group_form")
      replace_content(form.find_element(:css, "input[type=text]"), "New Name")
      submit_form(form)
      expect(f("#category_#{group_category.id} #group_#{group.id}")).to be_displayed
    end

    it "should not show the Make a New Set of Groups button if there are no students in the course" do
      get "/courses/#{@course.id}/groups"
      expect(f("#content")).not_to contain_css('.add_category_link')
      expect(f('#no_students_message')).to be_displayed
    end
    it "should show the Make a New Set of Groups button if there are students in the course" do
      student_in_course
      get "/courses/#{@course.id}/groups"
      expect(f('.add_category_link')).to be_displayed
      expect(f("#content")).not_to contain_css('#no_students_message')
    end

    it "should let you message students not in a group" do
      groups_student_enrollment 3
      group_category1 = @course.group_categories.create(:name => "Project Groups")
      group_category2 = @course.group_categories.create(:name => "Self Signup Groups")
      group_category2.configure_self_signup(true, false)
      group_category2.save
      get "/courses/#{@course.id}/groups"
      wait_for_ajaximations

      expect(ff(".group_category").size).to eq 3
      expect(f("#category_#{group_category1.id} .right_side .loading_members")).not_to be_displayed
      expect(f('.group_category .student_links')).to be_displayed
      expect(f('.group_category .message_students_link')).not_to be_displayed # only self signup can do it
      ff('.ui-tabs-anchor')[1].click

      expect(f("#category_#{group_category2.id} .right_side .loading_members")).not_to be_displayed
      message_students_link =  ff('.group_category .message_students_link')[1]
      expect(message_students_link).to be_displayed
      message_students_link.click

      expect(f('.message-students-dialog')).to be_displayed
    end

    context "data validation" do
      before(:each) do
        student_in_course
        get "/courses/#{@course.id}/groups"
        f('.add_category_link').click
        @form = f('#add_category_form')
        expect(@form).to be_displayed
      end

      max_length_name = "jkljfdklfjsaklfjasfjlsaklfjsafsaffdafdjasklsajfjskjkljfdklfjsaklfjasfjlsaklfjsafsaffdafdjasklsajfjskjkljfdklfjsaklfjasfjlsaklfjsafsaffdafdjasklsajfjskjkljfdklfjsaklfjasfjlsaklfjsafsaffdafdjasklsajfjskjkljfdklfjsaklfjasfjlsaklfjsafsaffdafdjasklsajfjskfffff"

      it "should create a new group category with a 255 character name when creating groups manually" do
        replace_content(f('#add_category_form input[name="category[name]"]'), max_length_name)
        submit_dialog_form(@form)
        wait_for_ajaximations
        expect(GroupCategory.where(name: max_length_name)).to be_exists
      end

      it "should not create a new group category if the generated group names will exceed 255 characters" do
        replace_content(f('#add_category_form input[name="category[name]"]'), max_length_name)
        f('#category_split_groups').click
        submit_dialog_form(@form)
        wait_for_ajaximations
        expect(ff('.error_box').last.text).to eq 'Enter a shorter category name'
        expect(GroupCategory.where(name: max_length_name)).not_to be_exists
        expect(@form).to be_displayed
      end

      it "should validate split groups radio button adds a 1 to the input" do
        f('#category_split_groups').click
        expect(f('#category_split_group_count')).to have_attribute(:value, '1')
      end

      it "should validate create groups manually radio button clears the input" do
        f('#category_split_groups').click
        group_count = f('#category_split_group_count')
        expect(group_count).to have_attribute(:value, '1')
        f('#category_no_groups').click
        expect(f('#category_split_group_count')).to have_attribute(:value, '')
      end
    end
  end
end
