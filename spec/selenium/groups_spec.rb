require File.expand_path(File.dirname(__FILE__) + '/common')

describe "groups" do
  include_examples "in-process server selenium tests"

  it "should allow students to join self signup groups" do
    course_with_student_logged_in(:active_all => true)
    category1 = @course.group_categories.create!(:name => "category 1")
    category1.configure_self_signup(true, false)
    category1.save!
    g1 = @course.groups.create!(:name => "some group", :group_category => category1)

    get "/courses/#{@course.id}/groups"
    wait_for_ajaximations

    keep_trying_until do
      group_div = f("#group_#{g1.id}")
      group_div.find_element(:css, ".name").text.should == "some group"
      group_div.find_element(:css, ".management a").click
      wait_for_ajaximations
    end

    @student.group_memberships.should_not be_empty
    @student.group_memberships.first.should be_accepted
  end

  it "should allow students to join student organized open groups" do
    course_with_student_logged_in(:active_all => true)
    g1 = @course.groups.create!(:name => "my group", :join_level => "parent_context_auto_join")

    get "/courses/#{@course.id}/groups"
    wait_for_ajaximations

    group_div = f("#group_#{g1.id}")
    group_div.find_element(:css, ".name").text.should == "my group"

    group_div.find_element(:css, ".management a").click
    wait_for_ajaximations

    @student.group_memberships.should_not be_empty
    @student.group_memberships.first.should be_accepted
  end

  it "should not allow students to join self-signup groups that are full" do
    course_with_student_logged_in(:active_all => true)
    category1 = @course.group_categories.create!(:name => "category 1")
    category1.configure_self_signup(true, false)
    category1.group_limit = 2
    category1.save!
    g1 = @course.groups.create!(:name => "some group", :group_category => category1)

    g1.add_user user_model
    g1.add_user user_model

    get "/courses/#{@course.id}/groups"
    wait_for_ajaximations

    group_div = f("#group_#{g1.id}")
    f(".name", group_div).text.should == "some group"

    f(".management a", group_div).should be_blank
    f(".management", group_div).text.should == 'group full'
  end

  it "should not show student organized, invite only groups" do
    course_with_student_logged_in(:active_all => true)
    g1 = @course.groups.create!(:name => "my group")

    get "/courses/#{@course.id}/groups"
    wait_for_ajaximations

    ff("#group_#{g1.id}").should be_empty
  end

  it "should allow a student to create a group" do
    course_with_student_logged_in(:active_all => true)
    student_in_course
    student_in_course

    get "/courses/#{@course.id}/groups"
    wait_for_ajaximations

    keep_trying_until do
      f(".add_group_link").click
      wait_for_animations
    end

    f("#group_name").send_keys("My Group")
    ff("#group_join_level option").length.should == 2
    f("#invitees_#{@student.id}").click
    submit_form('#add_group_form')
    wait_for_ajaximations

    new_group_el = fj(".group:visible")
    members_link = new_group_el.find_element(:css, ".members_count")
    members_link.should include_text "2"
    members_link.click
    wait_for_ajaximations
    new_group_el.find_elements(:css, ".student").length.should == 2
  end

end
