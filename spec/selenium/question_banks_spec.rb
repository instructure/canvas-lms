require File.expand_path(File.dirname(__FILE__) + '/common')

describe "question bank" do
  include_examples "in-process server selenium tests"

  it "deleting AJAX-loaded questions should work" do
    course_with_teacher_logged_in
    @bank = @course.assessment_question_banks.create!(:title => 'Test Bank')
    (1..60).each { |idx| @bank.assessment_questions.create!(:question_data => {'question_name' => "test question #{idx}", 'answers' => [{'id' => 1}, {'id' => 2}]}) }
    get "/courses/#{@course.id}/question_banks/#{@bank.id}"
    f(".more_questions_link").click
    wait_for_ajaximations
    keep_trying_until do
      ffj('.display_question:visible').length.should == 60
      driver.execute_script("$('.display_question .links a').css('left', '0')")
      wait_for_ajaximations
      driver.execute_script("window.confirm = function(msg) { return true; };")
      wait_for_ajaximations
      fj(".display_question:visible:last .delete_question_link").click
      wait_for_ajaximations
      ffj('.display_question:visible').length.should == 59
    end
    @bank.reload
    wait_for_ajaximations
    @bank.assessment_questions.select { |aq| !aq.deleted? }.length.should == 59
  end
end
