require File.expand_path(File.dirname(__FILE__) + '/common')

describe "question bank" do
  it_should_behave_like "in-process server selenium tests"

  it "deleting AJAX-loaded questions should work" do
    course_with_teacher_logged_in
    @bank = @course.assessment_question_banks.create!(:title=>'Test Bank')
    (1..60).each { |idx| @bank.assessment_questions.create!(:question_data => {'question_name' => "test question #{idx}", 'answers' => [{'id' => 1}, {'id' => 2}]}) }
    get "/courses/#{@course.id}/question_banks/#{@bank.id}"
    driver.find_element(:css, ".more_questions_link").click
    keep_trying_until { find_all_with_jquery('.question_teaser:visible').length == 60 }
    driver.execute_script("$('.question_teaser .links').css('visibility', 'visible')")
    driver.execute_script("window.confirm = function(msg) { return true; };")
    find_with_jquery(".question_teaser:visible:last .delete_question_link").click
    keep_trying_until { find_all_with_jquery('.question_teaser:visible').length == 59 }
    @bank.reload
    @bank.assessment_questions.select { |aq| !aq.deleted? }.length.should == 59
  end
end
