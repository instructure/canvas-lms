require File.expand_path(File.dirname(__FILE__) + "/common")

describe "jquery selenium tests" do
  it_should_behave_like "in-process server selenium tests"

  before do
    course_with_teacher_logged_in
    get "/"
  end

  # jquery keeps breaking attr() ... see http://bugs.jquery.com/ticket/10278
  # should be fixed in 1.7 (or 1.6.5?)
  it "should return the correct value for attr" do
    driver.execute_script("$(document.body).append('<input type=\"checkbox\" checked=\"checked\" id=\"checkbox_test\">')")

    checkbox = driver.find_element(:id, 'checkbox_test')
    driver.execute_script("return $('#checkbox_test').attr('checked');").should eql('checked')

    checkbox.click
    driver.execute_script("return $('#checkbox_test').attr('checked');").should be_nil
  end
end
