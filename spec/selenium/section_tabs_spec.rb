require File.expand_path(File.dirname(__FILE__) + '/common')

describe "section tabs on the left side" do
  it_should_behave_like "in-process server selenium tests"

  it "should make the active tab white" do
    course_with_teacher_logged_in
    %w{assignments quizzes settings}.each do |feature|
      get "/courses/#{@course.id}/#{feature}"
      js = "return $('#section-tabs .#{feature}').css('background-color')"
      element_that_is_not_left_side = driver.find_element(:id, 'content')
      # make sure to mouse off the link so the :hover and :focus styles do not apply
      driver.action.move_to(element_that_is_not_left_side).perform
      driver.execute_script(js).should eql('rgb(214, 236, 252)')
    end
  end
end
