require File.expand_path(File.dirname(__FILE__) + '/common')

describe "section tabs on the left side" do
  it_should_behave_like "in-process server selenium tests"

  it "should make the active tab white" do
    course_with_teacher_logged_in
    %w{assignments quizzes settings}.each do |feature|
      get "/courses/#{@course.id}/#{feature}"
      js = "return $('#section-tabs .#{feature}').css('background-color')"
      driver.execute_script(js).should eql('rgb(255, 255, 255)')
    end
  end
end