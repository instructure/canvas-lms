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
    Course.any_instance.stubs(:feature_enabled?).returns(false)
  end

  it "should let the teacher edit the gradebook by default" do
    get "/courses/#{@course.id}/gradebook"
    wait_for_ajax_requests

    keep_trying_until { f("#submission_#{@student.id}_#{@assignment.id} .grade").should be_displayed }
    entry = f("#submission_#{@student.id}_#{@assignment.id}")
    entry.find_element(:css, ".grade").should be_displayed
    # normally we hate sleeping in these tests, but in this case, i'm not sure what we're waiting to see happen,
    # and if we just try to click and click until it works, then things get jammed up.
    sleep 2
    entry.find_element(:css, ".grade").click
    entry.find_element(:css, ".grade").should_not be_displayed
    entry.find_element(:css, ".grading_value").should be_displayed
  end

  it "should not let the teacher edit the gradebook when concluded" do
    @e.conclude
    get "/courses/#{@course.id}/gradebook"

    keep_trying_until { f("#submission_#{@student.id}_#{@assignment.id} .grade").should be_displayed }
    entry = f("#submission_#{@student.id}_#{@assignment.id}")
    entry.find_element(:css, ".grade").should be_displayed
    sleep 2
    entry.find_element(:css, ".grade").click
    entry.find_element(:css, ".grade").should be_displayed
  end

  it "should let the teacher add comments to the gradebook by default" do
    get "/courses/#{@course.id}/gradebook"

    keep_trying_until { f("#submission_#{@student.id}_#{@assignment.id} .grade").should be_displayed }
    entry = f("#submission_#{@student.id}_#{@assignment.id}")

    driver.execute_script("$('#submission_#{@student.id}_#{@assignment.id} .grade').mouseover();")
    keep_trying_until do
      entry.send_keys('i')
      f("#submission_information").should be_displayed
    end

    f("#submission_information .add_comment").should be_displayed
    f("#submission_information .save_buttons").should be_displayed
  end

  it "should not let the teacher add comments to the gradebook when concluded" do
    @e.conclude
    get "/courses/#{@course.id}/gradebook"

    keep_trying_until { f("#submission_#{@student.id}_#{@assignment.id} .grade").should be_displayed }
    entry = f("#submission_#{@student.id}_#{@assignment.id}")

    driver.execute_script("$('#submission_#{@student.id}_#{@assignment.id} .grade').mouseover();")
    keep_trying_until {
      entry.send_keys('i')
      f("#submission_information").should be_displayed
    }

    f("#submission_information .add_comment").should_not be_displayed
    f("#submission_information .save_buttons").should_not be_displayed
  end
end
