require File.expand_path(File.dirname(__FILE__) + '/common')

shared_examples_for "equation editor selenium tests" do
  it_should_behave_like "in-process server selenium tests"

  it "should support multiple equation editors on the same page" do
    course_with_teacher_logged_in

    get "/courses/#{@course.id}/quizzes"
    driver.find_element(:css, '.new-quiz-link').click 

    def save_question_and_wait(question)
      question.find_element(:css, "button[type='submit']").click
      wait_for_ajaximations
    end

    new_question_link = driver.find_element(:css, '.add_question_link')
    2.times do |time|
      new_question_link.click

      questions = find_all_with_jquery(".question_holder:visible")
      questions.length.should eql(time + 1)
      question = questions[time]

      wait_for_tiny(question.find_element(:css, 'textarea.question_content'))

      equation_editor = keep_trying_until do
        question.find_element(:css, '.mce_instructure_equation').click
        sleep 1
        equation_editor = find_with_jquery("#instructure_equation_prompt:visible")
        equation_editor.should_not be_nil
        equation_editor
      end
      equation_editor.find_element(:css, 'button').click
      question.find_element(:css, '.toggle_question_content_views_link').click
      question.find_element(:css, 'textarea.question_content').attribute(:value).should include('<img class="equation_image" title="1+1" src="/equation_images/1%2B1" alt="1+1" />')
      save_question_and_wait(question)

      question.find_elements(:css, 'img.equation_image').size.should == 1
      driver.find_element(:css, "#right-side .points_possible").text.should eql((time + 1).to_s)
    end
  end
end

describe "equation editor Windows-Firefox-Tests" do
  it_should_behave_like "equation editor selenium tests"
end
