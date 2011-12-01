require File.expand_path(File.dirname(__FILE__) + '/common')

describe "speedgrader selenium tests" do
  it_should_behave_like "in-process server selenium tests"

  def student_submission(options = {})
    submission_model(options.merge(:assignment => @assignment, :body => "first student submission text"))
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
    @student_2 = User.create!(:name => 'student 2')
    @student_2.register
    @student_2.pseudonyms.create!(:unique_id => 'student2@example.com', :password => 'qwerty', :password_confirmation => 'qwerty')
    @course.enroll_user(@student_2, "StudentEnrollment", :enrollment_state => 'active')
    @submission_2 = @assignment.submit_homework(@student_2, :body => 'second student submission text')

    get "/courses/#{@course.id}/gradebook/speed_grader?assignment_id=#{@assignment.id}#%7B%22student_id%22%3A#{@submission.student.id}%7D"
    keep_trying_until{ driver.find_element(:id, 'speedgrader_iframe') }

    #check for assignment title
    driver.find_element(:id, 'assignment_url').should include_text(@assignment.title)

    #check for assignment text in speedgrader iframe
    def check_first_student
      driver.find_element(:css, '#combo_box_container .ui-selectmenu-item-header').should include_text(@student.name)
      in_frame 'speedgrader_iframe' do
        driver.find_element(:id, 'main').should include_text(@submission.body)
      end
    end

    def check_second_student
      driver.find_element(:css, '#combo_box_container .ui-selectmenu-item-header').should include_text(@student_2.name)
      in_frame 'speedgrader_iframe' do
        driver.find_element(:id, 'main').should include_text(@submission_2.body)
      end
    end

    if driver.find_element(:css, '#combo_box_container .ui-selectmenu-item-header').text.include?(@student_2.name)
      check_second_student
      driver.find_element(:css, '#gradebook_header .next').click
      wait_for_ajax_requests
      check_first_student
    else
      check_first_student
      driver.find_element(:css, '#gradebook_header .next').click
      wait_for_ajax_requests
      check_second_student
   end

  end

  it "should not error if there are no submissions" do
    student_in_course
    get "/courses/#{@course.id}/gradebook/speed_grader?assignment_id=#{@assignment.id}"
    wait_for_ajax_requests
    driver.execute_script("return INST.errorCount").should == 0
  end

  it "should have a submission_history after a submitting a comment" do
    # a student without a submission
    @student_2 = User.create!(:name => 'student 2')
    @student_2.register
    @student_2.pseudonyms.create!(:unique_id => 'student2@example.com', :password => 'qwerty', :password_confirmation => 'qwerty')
    @course.enroll_user(@student_2, "StudentEnrollment", :enrollment_state => 'active')

    get "/courses/#{@course.id}/gradebook/speed_grader?assignment_id=#{@assignment.id}"
    wait_for_ajax_requests

    #add comment
    driver.find_element(:css, '#add_a_comment > textarea').send_keys('grader comment')
    driver.find_element(:css, '#add_a_comment *[type="submit"]').click
    keep_trying_until{ driver.find_element(:css, '#comments > .comment').displayed? }

    # the ajax from that add comment form comes back without a submission_history, the js should mimic it.
    driver.execute_script('return jsonData.studentsWithSubmissions[0].submission.submission_history.length').should == 1
  end

  it "should display submission late notice message" do
    @assignment.due_at = Time.now - 2.days
    @assignment.save!
    student_submission

    get "/courses/#{@course.id}/gradebook/speed_grader?assignment_id=#{@assignment.id}"
    keep_trying_until{ driver.find_element(:id, 'speedgrader_iframe') }

    driver.find_element(:id, 'submission_late_notice').should be_displayed
  end


  it "should display no submission message if student does not make a submission" do
    @student = user_with_pseudonym(:active_user => true, :username => 'student@example.com', :password => 'qwerty')
    @course.enroll_user(@student, "StudentEnrollment", :enrollment_state => 'active')

    get "/courses/#{@course.id}/gradebook/speed_grader?assignment_id=#{@assignment.id}"

    keep_trying_until {
      driver.find_element(:id, 'submissions_container').should
        include_text(I18n.t('headers.no_submission', "This student does not have a submission for this assignment"))
    }
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
    rubric = driver.find_element(:id, 'rubric_full')
    rubric.should be_displayed

    #test rubric input
    rubric.find_element(:css, 'input.criterion_points').send_keys('3')
    rubric.find_element(:css, '.criterion_comments img').click
    driver.find_element(:css, 'textarea.criterion_comments').send_keys('special rubric comment')
    driver.find_element(:css, '#rubric_criterion_comments_dialog .save_button').click
    second_criterion = rubric.find_element(:id, 'criterion_2')
    second_criterion.find_element(:css, '.ratings .edge_rating').click
    rubric.find_element(:css, '.rubric_total').should include_text('8')
    driver.find_element(:css, '#rubric_full .save_rubric_button').click
    keep_trying_until{ driver.find_element(:css, '#rubric_summary_container > table').displayed? }
    driver.find_element(:css, '#rubric_summary_container').should include_text(@rubric.title)
    driver.find_element(:css, '#rubric_summary_container .rubric_total').should include_text('8')

  end

  it "should create a comment on assignment" do
    student_submission
    get "/courses/#{@course.id}/gradebook/speed_grader?assignment_id=#{@assignment.id}"
    wait_for_animations

    #check media comment
    keep_trying_until{
      driver.execute_script("$('#add_a_comment .media_comment_link').click();")
      driver.find_element(:id, "audio_record_option").should be_displayed
    }
    driver.find_element(:id, "video_record_option").should be_displayed
    find_with_jquery('.ui-icon-closethick:visible').click
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

  it "should not show students in other sections if visibility is limited" do
    @enrollment.update_attribute(:limit_privileges_to_course_section, true)
    student_submission
    student_submission(:username => 'otherstudent@example.com', :section => @course.course_sections.create(:name => "another section"))
    get "/courses/#{@course.id}/gradebook/speed_grader?assignment_id=#{@assignment.id}"
    wait_for_animations

    keep_trying_until { find_all_with_jquery('#students_selectmenu option').size > 0 }
    find_all_with_jquery('#students_selectmenu option').size.should eql(1) # just the one student
    find_all_with_jquery('#section-menu ul li').size.should eql(1) # "Show all sections"
    find_with_jquery('#students_selectmenu #section-menu').should be_nil # doesn't get inserted into the menu
  end

  it "should be able to change sorting and hide student names" do
    student_submission

    get "/courses/#{@course.id}/gradebook/speed_grader?assignment_id=#{@assignment.id}"
    wait_for_ajaximations

    driver.find_element(:id, "settings_link").click
    driver.find_element(:css, 'select#eg_sort_by option[value="submitted_at"]').click
    driver.find_element(:id, 'hide_student_names').click
    expect_new_page_load {
      driver.find_element(:css, '#settings_form .submit_button').click
    }
    keep_trying_until { driver.find_element(:css, '#combo_box_container .ui-selectmenu .ui-selectmenu-item-header').text == "Student 1" }

    # make sure it works a second time too
    driver.find_element(:id, "settings_link").click
    driver.find_element(:css, 'select#eg_sort_by option[value="alphabetically"]').click
    expect_new_page_load {
      driver.find_element(:css, '#settings_form .submit_button').click
    }
    keep_trying_until { driver.find_element(:css, '#combo_box_container .ui-selectmenu .ui-selectmenu-item-header').text == "Student 1" }
  end

  it "should leave the full rubric open when switching submissions" do
    student_submission :username => "student1@example.com"
    student_submission :username => "student2@example.com"
    get "/courses/#{@course.id}/gradebook/speed_grader?assignment_id=#{@assignment.id}"
    wait_for_ajaximations

    keep_trying_until { driver.find_element(:css, '.toggle_full_rubric').displayed? }
    driver.find_element(:css, '.toggle_full_rubric').click
    wait_for_animations
    rubric = driver.find_element(:id, 'rubric_full')
    rubric.should be_displayed
    first_criterion = rubric.find_element(:id, 'criterion_1')
    first_criterion.find_element(:css, '.ratings .edge_rating').click
    second_criterion = rubric.find_element(:id, 'criterion_2')
    second_criterion.find_element(:css, '.ratings .edge_rating').click
    rubric.find_element(:css, '.rubric_total').should include_text('8')
    driver.find_element(:css, '#rubric_full .save_rubric_button').click
    wait_for_ajaximations
    driver.find_element(:css, '.toggle_full_rubric').click
    wait_for_animations

    driver.execute_script("return $('#criterion_1 input.criterion_points').val();").should == "3"
    driver.execute_script("return $('#criterion_2 input.criterion_points').val();").should == "5"

    driver.find_element(:css, '#gradebook_header .next').click
    wait_for_ajaximations

    driver.find_element(:id, 'rubric_full').should be_displayed
    driver.execute_script("return $('#criterion_1 input.criterion_points').val();").should == ""
    driver.execute_script("return $('#criterion_2 input.criterion_points').val();").should == ""

    driver.find_element(:css, '#gradebook_header .prev').click
    wait_for_ajaximations

    driver.find_element(:id, 'rubric_full').should be_displayed
    driver.execute_script("return $('#criterion_1 input.criterion_points').val();").should == "3"
    driver.execute_script("return $('#criterion_2 input.criterion_points').val();").should == "5"
  end

end
