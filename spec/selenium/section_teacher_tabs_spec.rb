require File.expand_path(File.dirname(__FILE__) + '/common')

describe "section tabs on the left side" do
  include_context "in-process server selenium tests"

  context "as a teacher" do

    it "should highlight which tab is active" do
      course_with_teacher_logged_in
      %w{assignments quizzes settings}.each do |feature|
        get "/courses/#{@course.id}/#{feature}"
        js = "return $('#section-tabs .#{feature}').css('background-color')"
        element_that_is_not_left_side = f('#content')
        # make sure to mouse off the link so the :hover and :focus styles do not apply
        driver.action.move_to(element_that_is_not_left_side).perform
        active_tab_highlight_color = ENV['CANVAS_FORCE_USE_NEW_STYLES'] ? 'rgb(0, 150, 219)' : 'rgb(255, 255, 255)'
        expect(driver.execute_script(js)).to eq(active_tab_highlight_color)
      end
    end
  end
end