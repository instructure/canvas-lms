require File.expand_path(File.dirname(__FILE__) + '/common')

describe "assignment groups" do
  it_should_behave_like "in-process server selenium tests"

  def get_assignment_groups
    driver.find_elements(:css, '#groups .assignment_group')
  end

  before (:each) do
    course_with_teacher_logged_in
  end

  it "should create an assignment group" do
    get "/courses/#{@course.id}/assignments"

    wait_for_animations
    driver.find_element(:css, '#right-side .add_group_link').click
    driver.find_element(:id, 'assignment_group_name').send_keys('test group')
    submit_form('#add_group_form')
    wait_for_animations
    driver.find_element(:id, 'add_group_form').should_not be_displayed
    driver.find_element(:css, '#groups .assignment_group').should include_text('test group')
  end


  it "should edit group details" do
    assignment_group = @course.assignment_groups.create!(:name => "first test group")
    assignment = @course.assignments.create(:title => 'assignment with rubric', :assignment_group => assignment_group)
    get "/courses/#{@course.id}/assignments"

    #edit group grading rules
    driver.find_element(:css, '.edit_group_link img').click
    #set number of lowest scores to drop
    driver.find_element(:css, '.add_rule_link').click
    driver.find_element(:css, 'input.drop_count').send_keys('2')
    #set number of highest scores to drop
    driver.find_element(:css, '.add_rule_link').click
    click_option('.form_rules div:nth-child(2) select', 'Drop the Highest')
    driver.find_element(:css, '.form_rules div:nth-child(2) input').send_keys('3')
    #set assignment to never drop
    driver.find_element(:css, '.add_rule_link').click
    never_drop_css = '.form_rules div:nth-child(3) select'
    click_option(never_drop_css, 'Never Drop')
    wait_for_animations
    assignment_css = '.form_rules div:nth-child(3) .never_drop_assignment select'
    keep_trying_until { driver.find_element(:css, assignment_css).displayed? }
    click_option(assignment_css, assignment.title)
    #delete second grading rule and save
    driver.find_element(:css, '.form_rules div:nth-child(2) a img').click
    submit_form('#add_group_form')

    #verify grading rules
    driver.find_element(:css, '.more_info_link').click
    driver.find_element(:css, '.assignment_group .rule_details').should include_text('2')
    driver.find_element(:css, '.assignment_group .rule_details').should include_text('assignment with rubric')
  end

  it "should edit assignment group's grade weights" do
    @course.assignment_groups.create!(:name => "first group")
    @course.assignment_groups.create!(:name => "second group")
    get "/courses/#{@course.id}/assignments"

    driver.find_element(:id, 'class_weighting_policy').click
    #wanted to change number but can only use clear because of the auto insert of 0 after clearing
    # the input
    driver.find_element(:css, 'input.weight').clear
    #need to wait for the total to update
    wait_for_animations
    keep_trying_until { find_with_jquery('#group_weight_total').text.should == '50%' }
  end

  it "should round assignment groups percentages to 2 decimal places" do
    pending("bug 7387 - Assignment group weight should be rounded to 2 decimal places. Not 10") do
      3.times do |i|
        @course.assignment_groups.create!(:name => "group_#{i}")
      end
      get "/courses/#{@course.id}/assignments"

      driver.find_element(:id, 'class_weighting_policy').click
      wait_for_ajaximations
      group_weights = driver.find_elements(:css, '.assignment_group .more_info_brief')
      group_weights.each_with_index do |gw, i|
        gw.text.should == "33.33%"
      end
      driver.find_element(:id, 'group_weight_total').text.should == "99.99%"
    end
  end

  it "should not allow all assignment groups to be deleted" do
    pending("bug 7480 - User should not be permitted to delete all assignment groups") do
      get "/courses/#{@course.id}/assignments"
      assignment_groups = get_assignment_groups
      assignment_groups.count.should == 1
      assignment_groups[0].find_element(:css, '.delete_group_link').should_not be_displayed
      refresh_page #refresh page to make sure the trashcan doesn't come back
      get_assignment_groups[0].find_element(:css, '.delete_group_link').should_not be_displayed
    end
  end

  it "should add multiple assignment groups and not allow the last one to be deleted" do
    pending("bug 7480 - User should not be permitted to delete all assignment groups") do
      4.times do |i|
        @course.assignment_groups.create!(:name => "group_#{i}")
      end
      get "/courses/#{@course.id}/assignments"

      assignment_groups = get_assignment_groups
      assignment_groups_count = (assignment_groups.count - 1)

      assignment_groups_count.downto(1) do |i|
        assignment_groups[i].find_element(:css, '.delete_group_link').click
        driver.switch_to.alert.accept
        wait_for_ajaximations
        driver.switch_to.default_content
      end
      assignment_groups[0].find_element(:css, '.delete_group_link').should_not be_displayed
      refresh_page ##refresh page to make sure the trashcan doesn't come back
      get_assignment_groups[0].find_element(:css, '.delete_group_link').should_not be_displayed
    end
  end
end
