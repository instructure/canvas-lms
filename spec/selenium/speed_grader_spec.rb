require File.expand_path(File.dirname(__FILE__) + '/common')

describe "speedgrader" do
  it_should_behave_like "in-process server selenium tests"

  def student_submission(options = {})
    submission_model({:assignment => @assignment, :body => "first student submission text"}.merge(options))
  end

  before (:each) do
    stub_kaltura

    course_with_teacher_logged_in
    outcome_with_rubric
    @assignment = @course.assignments.create(:name => 'assignment with rubric')
    @association = @rubric.associate_with(@assignment, @course, :purpose => 'grading')
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
    keep_trying_until { driver.find_element(:id, 'speedgrader_iframe') }

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
    keep_trying_until { driver.find_element(:css, '#comments > .comment').displayed? }

    # the ajax from that add comment form comes back without a submission_history, the js should mimic it.
    driver.execute_script('return jsonData.studentsWithSubmissions[0].submission.submission_history.length').should == 1
  end

  context "as a course limited ta" do
    before(:each) do
      @taenrollment = course_with_ta(:course => @course, :active_all => true)
      @taenrollment.limit_privileges_to_course_section = true
      @taenrollment.save!
      user_logged_in(:user => @ta, :username => "imata@example.com")

      @section = @course.course_sections.create!
      student_in_course(:active_all => true); @student1 = @student
      student_in_course(:active_all => true); @student2 = @student
      @enrollment.course_section = @section; @enrollment.save

      @assignment.submission_types = "online_upload"
      @assignment.save

      @submission1 = @assignment.submit_homework(@student1, :submission_type => "online_text_entry", :body => "hi")
      @submission2 = @assignment.submit_homework(@student2, :submission_type => "online_text_entry", :body => "there")
    end

    it "should list the correct number of students" do
      get "/courses/#{@course.id}/gradebook/speed_grader?assignment_id=#{@assignment.id}"
      wait_for_ajax_requests

      f("#x_of_x_students").should include_text("1 of 1")
      ff("#students_selectmenu-menu li").count.should == 1
    end
  end

  it "should display submission late notice message" do
    @assignment.due_at = Time.now - 2.days
    @assignment.save!
    student_submission

    get "/courses/#{@course.id}/gradebook/speed_grader?assignment_id=#{@assignment.id}"
    keep_trying_until { driver.find_element(:id, 'speedgrader_iframe') }

    driver.find_element(:id, 'submission_late_notice').should be_displayed
  end


  it "should display no submission message if student does not make a submission" do
    @student = user_with_pseudonym(:active_user => true, :username => 'student@example.com', :password => 'qwerty')
    @course.enroll_user(@student, "StudentEnrollment", :enrollment_state => 'active')

    get "/courses/#{@course.id}/gradebook/speed_grader?assignment_id=#{@assignment.id}"

    keep_trying_until {
      driver.find_element(:id, 'submissions_container').should
      include_text(I18n.t('headers.no_submission', "This student does not have a submission for this assignment"))
      find_with_jquery('#this_student_does_not_have_a_submission').should be_displayed
    }
  end

  it "should hide answers of anonymous graded quizzes" do
    @assignment.points_possible = 10
    @assignment.submission_types = 'online_quiz'
    @assignment.title = 'Anonymous Graded Quiz'
    @assignment.save!
    @quiz = Quiz.find_by_assignment_id(@assignment.id)
    @quiz.update_attribute(:anonymous_submissions, true)
    student_submission
    get "/courses/#{@course.id}/gradebook/speed_grader?assignment_id=#{@assignment.id}"
    keep_trying_until {
      find_with_jquery('#this_student_has_a_submission').should be_displayed
    }
  end

  it "should update quiz grade automatically when the update button is clicked" do
    expected_points = "6"
    student = student_in_course(:active_user => true).user
    @assignment.points_possible = 10
    @assignment.submission_types = 'online_quiz'
    @assignment.title = 'Anonymous Graded Quiz'
    @assignment.save!
    q = Quiz.find_by_assignment_id(@assignment.id)
    q.quiz_questions.create!(:quiz => q, :question_data => {:position => 1, :question_type => "true_false_question", :points_possible => 3, :question_name => "true false question"})
    q.quiz_questions.create!(:quiz => q, :question_data => {:position => 2, :question_type => "essay_question", :points_possible => 7, :question_name => "essay question"})
    q.generate_quiz_data
    q.workflow_state = 'available'
    q.save!
    qs = q.generate_submission(student)
    qs.submission_data = {"foo" => "bar1"}
    qs.grade_submission

    get "/courses/#{@course.id}/gradebook/speed_grader?assignment_id=#{@assignment.id}"
    wait_for_ajaximations
    in_frame('speedgrader_iframe') do
      question_inputs = driver.find_elements(:css, '.question_input')
      question_inputs.each_with_index { |qi, i| replace_content(qi, 3) }
      driver.find_element(:css, 'button[type=submit]').click
    end
    keep_trying_until { driver.find_element(:css, '#grade_container input').attribute('value').should == expected_points }
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
    keep_trying_until { driver.find_element(:id, 'speedgrader_iframe') }
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
    @association.use_for_grading = true
    @association.save!

    get "/courses/#{@course.id}/gradebook/speed_grader?assignment_id=#{@assignment.id}"
    wait_for_animations

    #test opening and closing rubric
    keep_trying_until {
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
    second_criterion = rubric.find_element(:id, "criterion_#{@rubric.criteria[1][:id]}")
    second_criterion.find_element(:css, '.ratings .edge_rating').click
    rubric.find_element(:css, '.rubric_total').should include_text('8')
    driver.find_element(:css, '#rubric_full .save_rubric_button').click
    keep_trying_until { driver.find_element(:css, '#rubric_summary_container > table').displayed? }
    driver.find_element(:css, '#rubric_summary_container').should include_text(@rubric.title)
    driver.find_element(:css, '#rubric_summary_container .rubric_total').should include_text('8')
    wait_for_ajaximations
    driver.find_element(:css, '#grade_container input').attribute(:value).should == "8"
  end

  it "should create a comment on assignment" do
    student_submission
    get "/courses/#{@course.id}/gradebook/speed_grader?assignment_id=#{@assignment.id}"
    wait_for_animations

    #check media comment
    keep_trying_until {
      driver.execute_script("$('#add_a_comment .media_comment_link').click();")
      driver.find_element(:id, "audio_record_option").should be_displayed
    }
    driver.find_element(:id, "video_record_option").should be_displayed
    close_visible_dialog
    driver.find_element(:id, "audio_record_option").should_not be_displayed

    #check for file upload comment
    driver.find_element(:css, '#add_attachment img').click
    driver.find_element(:css, '#comment_attachments input').should be_displayed
    driver.find_element(:css, '#comment_attachments a').click
    element_exists('#comment_attachments input').should be_false

    #add comment
    driver.find_element(:css, '#add_a_comment > textarea').send_keys('grader comment')
    driver.find_element(:css, '#add_a_comment *[type="submit"]').click
    keep_trying_until { driver.find_element(:css, '#comments > .comment').displayed? }
    driver.find_element(:css, '#comments > .comment').should include_text('grader comment')

    #make sure gradebook link works
    driver.find_element(:css, '#x_of_x_students a').click
    find_with_jquery('body.grades').should be_displayed

  end

  it "should properly show avatar images only if avatars are enabled on the account" do
    # enable avatars
    @account = Account.default
    @account.enable_service(:avatars)
    @account.save!
    @account.service_enabled?(:avatars).should be_true

    student_submission
    get "/courses/#{@course.id}/gradebook/speed_grader?assignment_id=#{@assignment.id}"
    wait_for_animations
    
    # make sure avatar shows up for current student
    driver.find_elements(:css, "#avatar_image").length.should == 1
    driver.find_element(:css, "#avatar_image")['src'].should_not match(/blank.png/)

    #add comment
    driver.find_element(:css, '#add_a_comment > textarea').send_keys('grader comment')
    driver.find_element(:css, '#add_a_comment *[type="submit"]').click
    keep_trying_until{ driver.find_element(:css, '#comments > .comment').displayed? }
    driver.find_element(:css, '#comments > .comment').should include_text('grader comment')
    
    # make sure avatar shows up for user comment
    driver.find_element(:css, "#comments > .comment .avatar").should be_displayed

    # disable avatars
    @account = Account.default
    @account.disable_service(:avatars)
    @account.save!
    @account.service_enabled?(:avatars).should be_false
    get "/courses/#{@course.id}/gradebook/speed_grader?assignment_id=#{@assignment.id}"
    wait_for_animations
    
    driver.find_elements(:css, "#avatar_image").length.should == 0
    driver.find_elements(:css, "#comments > .comment .avatar").length.should == 1
    driver.find_elements(:css, "#comments > .comment .avatar")[0]['style'].should match(/display:\s*none/)
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

  context "multiple enrollments" do
    before(:each) do
      student_in_course
      @course_section = @course.course_sections.create!(:name => "Other Section")
      @enrollment = @course.enroll_student(@student,
                                           :enrollment_state => "active",
                                           :section => @course_section,
                                           :allow_multiple_enrollments => true)
    end

    def goto_section(section_id)
      driver.find_element(:css, "#combo_box_container .ui-selectmenu-icon").click
      driver.execute_script("$('#section-menu-link').trigger('mouseenter')")
      driver.find_element(:css, "#section-menu .section_#{section_id}").click
      wait_for_dom_ready
      wait_for_ajaximations
    end

    it "should not duplicate students" do
      get "/courses/#{@course.id}/gradebook/speed_grader?assignment_id=#{@assignment.id}"
      wait_for_ajaximations

      driver.find_elements(:css, "#students_selectmenu option").length.should == 1
    end

    it "should filter by section properly" do
      get "/courses/#{@course.id}/gradebook/speed_grader?assignment_id=#{@assignment.id}"
      wait_for_ajaximations

      sections = @course.course_sections
      goto_section(sections[0].id)
      driver.find_elements(:css, "#students_selectmenu option").length.should == 1
      goto_section(sections[1].id)
      driver.find_elements(:css, "#students_selectmenu option").length.should == 1
    end
  end

  it "should be able to change sorting and hide student names" do
    student_submission

    get "/courses/#{@course.id}/gradebook/speed_grader?assignment_id=#{@assignment.id}"
    wait_for_ajaximations

    driver.find_element(:css, "#settings_link").click
    driver.find_element(:css, 'select#eg_sort_by option[value="submitted_at"]').click
    driver.find_element(:css, '#hide_student_names').click
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
    first_criterion = rubric.find_element(:id, "criterion_#{@rubric.criteria[0][:id]}")
    first_criterion.find_element(:css, '.ratings .edge_rating').click
    second_criterion = rubric.find_element(:id, "criterion_#{@rubric.criteria[1][:id]}")
    second_criterion.find_element(:css, '.ratings .edge_rating').click
    rubric.find_element(:css, '.rubric_total').should include_text('8')
    driver.find_element(:css, '#rubric_full .save_rubric_button').click
    wait_for_ajaximations
    driver.find_element(:css, '.toggle_full_rubric').click
    wait_for_animations

    driver.execute_script("return $('#criterion_#{@rubric.criteria[0][:id]} input.criterion_points').val();").should == "3"
    driver.execute_script("return $('#criterion_#{@rubric.criteria[1][:id]} input.criterion_points').val();").should == "5"

    driver.find_element(:css, '#gradebook_header .next').click
    wait_for_ajaximations

    driver.find_element(:id, 'rubric_full').should be_displayed
    driver.execute_script("return $('#criterion_#{@rubric.criteria[0][:id]} input.criterion_points').val();").should == ""
    driver.execute_script("return $('#criterion_#{@rubric.criteria[1][:id]} input.criterion_points').val();").should == ""

    driver.find_element(:css, '#gradebook_header .prev').click
    wait_for_ajaximations

    driver.find_element(:id, 'rubric_full').should be_displayed
    driver.execute_script("return $('#criterion_#{@rubric.criteria[0][:id]} input.criterion_points').val();").should == "3"
    driver.execute_script("return $('#criterion_#{@rubric.criteria[1][:id]} input.criterion_points').val();").should == "5"
  end

  it "should handle versions correctly" do
    submission1 = student_submission :username => "student1@example.com", :body => 'first student, first version'
    submission2 = student_submission :username => "student2@example.com", :body => 'second student'
    submission3 = student_submission :username => "student3@example.com", :body => 'third student'

    # This is "no submissions" guy
    submission3.delete

    submission1.submitted_at = 10.minutes.from_now
    submission1.body = 'first student, second version'
    submission1.with_versioning(:explicit => true) { submission1.save }

    get "/courses/#{@course.id}/gradebook/speed_grader?assignment_id=#{@assignment.id}"
    wait_for_ajaximations

    # The first user shoud have multiple submissions. We want to make sure we go through the first student
    # because the original bug was caused by a user with multiple versions putting data on the page that
    # was carried through to other students, ones with only 1 version.
    driver.find_element(:id, 'submission_to_view').find_elements(:css, 'option').length.should == 2

    in_frame 'speedgrader_iframe' do
      driver.find_element(:id, 'content').should include_text('first student, second version')
    end

    Selenium::WebDriver::Support::Select.new(driver.find_element(:id, 'submission_to_view')).select_by(:value, '0')
    wait_for_ajaximations

    in_frame 'speedgrader_iframe' do
      wait_for_ajaximations
      driver.find_element(:id, 'content').should include_text('first student, first version')
    end

    driver.find_element(:css, '#gradebook_header .next').click
    wait_for_ajaximations

    # The second user just has one, and grading the user shouldn't trigger a page error.
    # (In the original bug, it would trigger a change on the select box for choosing submission versions,
    # which had another student's data in it, so it would try to load a version that didn't exist.)
    driver.find_element(:id, 'submission_to_view').find_elements(:css, 'option').length.should == 1
    driver.find_element(:id, 'grade_container').find_element(:css, 'input').send_keys("5\n")
    wait_for_ajaximations

    in_frame 'speedgrader_iframe' do
      driver.find_element(:id, 'content').should include_text('second student')
    end

    submission2.reload.score.should == 5

    driver.find_element(:css, '#gradebook_header .next').click
    wait_for_ajaximations

    driver.find_element(:id, 'this_student_does_not_have_a_submission').should be_displayed
  end

  it "should ignore rubric lines for grading" do
    student_submission
    @association.use_for_grading = true
    @association.save!
    @ignored = @course.learning_outcomes.create!(:description => 'just for reference')
    @rubric.data = @rubric.data + [{
                                       :points => 3,
                                       :description => "just for reference",
                                       :id => 3,
                                       :ratings => [
                                           {
                                               :points => 3,
                                               :description => "You Learned",
                                               :criterion_id => 3,
                                               :id => 6,
                                           },
                                           {
                                               :points => 0,
                                               :description => "No-learn-y",
                                               :criterion_id => 3,
                                               :id => 7,
                                           },
                                       ],
                                       :learning_outcome_id => @ignored.id,
                                       :ignore_for_scoring => '1',
                                   }]
    @rubric.instance_variable_set('@outcomes_changed', true)
    @rubric.save!

    get "/courses/#{@course.id}/gradebook/speed_grader?assignment_id=#{@assignment.id}"
    wait_for_ajaximations
    driver.find_element(:css, 'button.toggle_full_rubric').click
    driver.find_element(:css, "table.rubric.assessing tr:nth-child(1) table.ratings td:nth-child(1)").click
    driver.find_element(:css, "table.rubric.assessing tr:nth-child(3) table.ratings td:nth-child(1)").click
    driver.find_element(:css, "#rubric_holder button.save_rubric_button").click
    wait_for_ajaximations

    @submission.reload.score.should == 3
    driver.find_element(:css, "#grade_container input[type=text]").attribute(:value).should == '3'
    driver.find_element(:css, "#rubric_summary_container tr:nth-child(1) .editing").should be_displayed
    driver.find_element(:css, "#rubric_summary_container tr:nth-child(1) .ignoring").should_not be_displayed
    driver.find_element(:css, "#rubric_summary_container tr:nth-child(3) .editing").should_not be_displayed
    driver.find_element(:css, "#rubric_summary_container tr:nth-child(3) .ignoring").should be_displayed
    driver.find_element(:css, "#rubric_summary_container tr.summary .rubric_total").text.should == '3'

    # check again that initial page load has the same data.
    get "/courses/#{@course.id}/gradebook/speed_grader?assignment_id=#{@assignment.id}"
    wait_for_ajaximations
    driver.find_element(:css, "#grade_container input[type=text]").attribute(:value).should == '3'
    driver.find_element(:css, "#rubric_summary_container tr:nth-child(1) .editing").should be_displayed
    driver.find_element(:css, "#rubric_summary_container tr:nth-child(1) .ignoring").should_not be_displayed
    driver.find_element(:css, "#rubric_summary_container tr:nth-child(3) .editing").should_not be_displayed
    driver.find_element(:css, "#rubric_summary_container tr:nth-child(3) .ignoring").should be_displayed
    driver.find_element(:css, "#rubric_summary_container tr.summary .rubric_total").text.should == '3'
  end

  it "should included the student view student for grading" do
    @fake_student = @course.student_view_student
    get "/courses/#{@course.id}/gradebook/speed_grader?assignment_id=#{@assignment.id}"
    wait_for_ajaximations

    driver.find_elements(:css, "#students_selectmenu option").length.should == 1
  end
end
