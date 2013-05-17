require File.expand_path(File.dirname(__FILE__) + '/helpers/manage_groups_common')
require 'thread'

describe "manage groups" do
  it_should_behave_like "in-process server selenium tests"

  before (:each) do
    course_with_teacher_logged_in
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

    it "should create a new student group with a 255 character name when creating groups manually" do
      replace_content(f('#add_category_form input[name="category[name]"]'), max_length_name)
      submit_form(@form)
      wait_for_ajaximations
      GroupCategory.find_by_name(max_length_name).should be_present
    end

    it "should not create a new student group if the name is over 250 characters" do
      replace_content(f('#add_category_form input[name="category[name]"]'), max_length_name)
      f('#category_split_groups').click
      submit_form(@form)
      wait_for_ajaximations
      ff('.error_box').last.text.should == 'Enter a shorter category name to split students into groups'
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
