require File.expand_path(File.dirname(__FILE__) + '/common')

describe "speedgrader selenium tests" do
  it_should_behave_like "in-process server selenium tests"

  def student_submission()
    @student = user_with_pseudonym(:active_user => true, :username => 'student@example.com', :password => 'qwerty')
    @course.enroll_user(@student, "StudentEnrollment", :enrollment_state => 'active')
    @submission = @assignment.submit_homework(@student, :body => 'first student submission text')
    @submission.save!
  end

  before(:each) do
    stub_kaltura
    
    course_with_teacher_logged_in
    outcome_with_rubric
    @assignment = @course.assignments.create(:name => 'assignment with rubric')
    @rubric.associate_with(@assignment, @course, :purpose => 'grading')
  end

  it "should display submission of first student and then second student" do
    student_submission

    #create initial data for second student
    student_2 = user_with_pseudonym(:active_user => true, :username => 'student2@example.com', :password => 'qwerty')
    @course.enroll_user(student_2, "StudentEnrollment", :enrollment_state => 'active')
    submission_2 = @assignment.submit_homework(student_2, :body => 'second student submission text')

    get "/courses/#{@course.id}/gradebook/speed_grader?assignment_id=#{@assignment.id}"

    #check for assignment text in speedgrader iframe
    keep_trying_until{ driver.find_element(:id, 'speedgrader_iframe') }
    in_frame 'speedgrader_iframe' do
      driver.find_element(:id, 'main').should include_text(@submission.body)
    end

    #click to view next submission and check text
    driver.find_element(:css, '#gradebook_header .next').click
    wait_for_ajax_requests
    in_frame 'speedgrader_iframe' do
      driver.
        find_element(:id, 'main').should include_text(submission_2.body)
    end
  end

  it "should display discussion entries for only one student" do
    #make assignment a discussion assignment
    @assignment.points_possible = 5
    @assignment.submission_types = 'discussion_topic'
    @assignment.title = 'some topic'
    @assignment.description = 'a little bit of content'
    @assignment.save!
    @assignment.update_quiz_or_discussion_topic

    #create and entrol first student
    student = user_with_pseudonym(
      :name => 'first student',
      :active_user => true,
      :username => 'student@example.com',
      :password => 'qwerty'
    )
    @course.enroll_user(student, "StudentEnrollment", :enrollment_state => 'active')
    #create and enroll second student
    student_2 = user_with_pseudonym(
      :name => 'second student',
      :active_user => true,
      :username => 'student2@example.com',
      :password => 'qwerty'
    )
    @course.enroll_user(student_2, "StudentEnrollment", :enrollment_state => 'active')

    #create discussion entries
    first_message = 'first student message'
    second_message = 'second student message'
    discussion_topic = DiscussionTopic.find_by_assignment_id(@assignment.id)
    entry = discussion_topic.discussion_entries.
      create!(:user => student, :message => first_message) 
    entry.update_topic
    entry.context_module_action
    entry_2 = discussion_topic.discussion_entries.
      create!(:user => student_2, :message => second_message) 
    entry_2.update_topic
    entry_2.context_module_action

    get "/courses/#{@course.id}/gradebook/speed_grader?assignment_id=#{@assignment.id}"

    #check for correct submissions in speedgrader iframe
    keep_trying_until{ driver.find_element(:id, 'speedgrader_iframe') }
    in_frame 'speedgrader_iframe' do
      driver.
        find_element(:id, 'main').should include_text(first_message)
      driver.
        find_element(:id, 'main').should_not include_text(second_message)
    end
    driver.find_element(:css, '#gradebook_header a.next').click
    wait_for_ajax_requests
    in_frame 'speedgrader_iframe' do
      driver.
        find_element(:id, 'main').should_not include_text(first_message)
      driver.
        find_element(:id, 'main').should include_text(second_message)
    end
  end

  it "should grade assignment using rubric" do
    student_submission
    get "/courses/#{@course.id}/gradebook/speed_grader?assignment_id=#{@assignment.id}"
    wait_for_animations

    #test opening and closing rubric
    keep_trying_until{
      driver.find_element(:css, '.toggle_full_rubric').click
      driver.find_element(:id, 'rubric_full').should be_displayed
    }
    driver.find_element(:css, '#rubric_holder .hide_rubric_link').click
    wait_for_animations
    driver.find_element(:id, 'rubric_full').should_not be_displayed
    driver.find_element(:css, '.toggle_full_rubric').click
    driver.find_element(:id, 'rubric_full').should be_displayed

    #test rubric input
    driver.find_element(:css, '#rubric_full input.criterion_points').send_keys('3')
    driver.find_element(:css, '.criterion_comments img').click
    driver.find_element(:css, 'textarea.criterion_comments').send_keys('special rubric comment')
    driver.find_element(:css, '#rubric_criterion_comments_dialog .save_button').click
    driver.find_element(:css, '#rubric_full .save_rubric_button').click
    keep_trying_until{ driver.find_element(:css, '#rubric_summary_container > table').displayed? }
    driver.find_element(:css, '#rubric_summary_container').should include_text(@rubric.title)
  end

  it "should create a comment on assignment" do
    student_submission
    get "/courses/#{@course.id}/gradebook/speed_grader?assignment_id=#{@assignment.id}"
    wait_for_animations

    #check media comment
    keep_trying_until{ 
      #driver.find_element(:css, "#add_a_comment .media_comment_link").click
      driver.execute_script("$('#add_a_comment .media_comment_link').click();")
      driver.find_element(:id, "audio_record_option").should be_displayed
    }
    driver.find_element(:id, "video_record_option").should be_displayed
    driver.find_element(:css, '.ui-icon-closethick').click
    driver.find_element(:id, "audio_record_option").should_not be_displayed 

    #check for file upload comment
    driver.find_element(:css, '#add_attachment img').click
    driver.find_element(:css, '#comment_attachments input').should be_displayed
    driver.find_element(:css, '#comment_attachments a').click
    element_exists(:css, '#comment_attachments input').should be_false

    #add comment
    driver.find_element(:css, '#add_a_comment > textarea').send_keys('grader comment')
    driver.find_element(:css, '#add_a_comment *[type="submit"]').click
    keep_trying_until{ driver.find_element(:css, '#comments > .comment').displayed? }
    driver.find_element(:css, '#comments > .comment').should include_text('grader comment')

    #make sure gradebook link works
    driver.find_element(:css, '#x_of_x_students a').click
    driver.find_element(:css, 'body.grades').should be_displayed

  end

end
