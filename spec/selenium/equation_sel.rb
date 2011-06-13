require File.expand_path(File.dirname(__FILE__) + '/common')

shared_examples_for "equation editor selenium tests" do
  it_should_behave_like "in-process server selenium tests"
  
  it "should support multiple equation editors on the same page" do
    username = "nobody@example.com"
    password = "asdfasdf"
    u = user_with_pseudonym :active_user => true,
                            :username => username,
                            :password => password
    u.save!
    e = course_with_teacher :active_course => true,
                            :user => u,
                            :active_enrollment => true
    e.save!
    login_as(username, password)
    
    get "/courses/#{e.course_id}/quizzes"
    driver.find_element(:partial_link_text, "Create a New Quiz").click
    
    driver.current_url.should match %r{/courses/\d+/quizzes/(\d+)\/edit}
    driver.current_url =~ %r{/courses/\d+/quizzes/(\d+)\/edit}
    quiz_id = $1.to_i
    quiz_id.should be > 0
    quiz = Quiz.find(quiz_id)


    def save_question_and_wait(question)
      question.find_element(:css, "button[type='submit']").click
      keep_trying_until { question.find_element(:css, ".loading_image_holder").nil? rescue true }
    end
    
    new_question_link = driver.find_element(:link, "New Question")
    2.times do |time|
      new_question_link.click
      
      questions = find_all_with_jquery(".question_holder:visible")
      questions.length.should eql(time + 1)
      question = questions[time]
      
      wait_for_tiny(question.find_element(:css, 'textarea.question_content'))
      question.find_element(:css, '.mce_instructure_equation').click
  
      equation_editor = find_with_jquery("#instructure_equation_prompt:visible")
      equation_editor.find_element(:css, 'button').click
      question.find_element(:link, "Switch Views").click
      question.find_element(:css, 'textarea.question_content').value.should include('<img class="equation_image" title="1+1" src="http://latex.codecogs.com/gif.latex?1+1" alt="1+1" />')
      save_question_and_wait(question)

      question.find_elements(:css, 'img.equation_image').size.should == 1
      driver.find_element(:css, "#right-side .points_possible").text.should eql((time + 1).to_s)
    end
  end
end

describe "equation editor Windows-Firefox-Tests" do
  it_should_behave_like "equation editor selenium tests"
end
