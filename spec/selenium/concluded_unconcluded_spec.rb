require File.expand_path(File.dirname(__FILE__) + '/common')

describe "concluded/unconcluded" do
  include_examples "in-process server selenium tests"

  before do
    username = "nobody@example.com"
    password = "asdfasdf"
    u = user_with_pseudonym :active_user => true,
                            :username => username,
                            :password => password
    u.save!
    @e = course_with_teacher :active_course => true,
                             :user => u,
                             :active_enrollment => true
    @e.save!

    user_model
    @student = @user
    @course.enroll_student(@student).accept
    @group = @course.assignment_groups.create!(:name => "default")
    @assignment = @course.assignments.create!(:submission_types => 'online_quiz', :title => 'quiz assignment', :assignment_group => @group)
    login_as(username, password)
  end

  it "should let the teacher edit the gradebook by default" do
    get "/courses/#{@course.id}/gradebook"
    wait_for_ajax_requests

    entry = f(".slick-cell.l2.r2")
    entry.should be_displayed
    entry.click
    entry.find_element(:css, ".gradebook-cell-editable").should be_displayed
  end

  it "should not let the teacher edit the gradebook when concluded" do
    @e.conclude
    get "/courses/#{@course.id}/gradebook"

    entry = f(".slick-cell.l2.r2")
    entry.should be_displayed
    entry.click
    entry.find_element(:css, ".gradebook-cell").should_not have_class('gradebook-cell-editable')
  end

  it "should let the teacher add comments to the gradebook by default" do
    get "/courses/#{@course.id}/gradebook"

    entry = f(".slick-cell.l2.r2")
    entry.should be_displayed
    driver.execute_script("$('.slick-cell.l2.r2').mouseover();")
    entry.find_element(:css, ".gradebook-cell-comment").click
    wait_for_animations
    f(".submission_details_dialog").should be_displayed
    f(".submission_details_dialog #add_a_comment").should be_displayed
  end

  it "should not let the teacher add comments to the gradebook when concluded" do
    @e.conclude
    get "/courses/#{@course.id}/gradebook"

    entry = f(".slick-cell.l2.r2")
    entry.should be_displayed
    driver.execute_script("$('.slick-cell.l2.r2').mouseover();")
    entry.find_element(:css, ".gradebook-cell-comment").should_not be_displayed
  end
end
