require File.expand_path(File.dirname(__FILE__) + '/common')

describe "calendar selenium tests" do
  it_should_behave_like "in-process server selenium tests"

  it "should not show students the description of an assignment that is locked" do
    course_with_student_logged_in
    
    assignment = @course.assignments.create(:name => "locked assignment", :description => "this is secret", :due_at => Time.now + 2.days, :unlock_at => Time.now + 1.day)
    assignment.locked_for?(@user).should_not be_nil
    
    get "/calendar"
    div = keep_trying_until { driver.find_element(:id, "event_assignment_#{assignment.id}") }
    div.click
    keep_trying_until { driver.find_element(:id, "event_details").displayed? }
    details = driver.find_element(:id, "event_details")
    details.find_element(:css, ".description").text.should_not match /secret/
    details.find_element(:css, ".lock_explanation").text.should match /is locked until/
  end
end
