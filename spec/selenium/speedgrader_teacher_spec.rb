require File.expand_path(File.dirname(__FILE__) + '/helpers/speed_grader_common')
require File.expand_path(File.dirname(__FILE__) + '/helpers/gradebook2_common')

describe "speed grader" do
  include_context "in-process server selenium tests"

  before (:each) do
    stub_kaltura

    course_with_teacher_logged_in
    outcome_with_rubric
    @assignment = @course.assignments.create(:name => 'assignment with rubric', :points_possible => 10)
    @association = @rubric.associate_with(@assignment, @course, :purpose => 'grading')
  end

  context "as a teacher" do
    it "alerts the teacher before leaving the page if comments are not saved", priority: "1", test_id: 283736 do
      student_in_course(:active_user => true).user
      get "/courses/#{@course.id}/gradebook/speed_grader?assignment_id=#{@assignment.id}"
      comment_textarea = f("#speedgrader_comment_textarea")
      replace_content(comment_textarea, "oh no i forgot to save this comment!")
      driver.close
      alert_shown = alert_present?
      dismiss_alert
      expect(alert_shown).to eq(true)
    end
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
      @assignment.save!

      @submission1 = @assignment.submit_homework(@student1, :submission_type => "online_text_entry", :body => "hi")
      @submission2 = @assignment.submit_homework(@student2, :submission_type => "online_text_entry", :body => "there")
    end

    it "lists the correct number of students", priority: "2", test_id: 283737 do
      get "/courses/#{@course.id}/gradebook/speed_grader?assignment_id=#{@assignment.id}"

      expect(f("#x_of_x_students")).to include_text("1 of 1")
      expect(ff("#students_selectmenu-menu li").count).to eq 1
    end
  end

  it "hides answers of anonymous graded quizzes", priority: "1", test_id: 283738 do
    @assignment.points_possible = 10
    @assignment.submission_types = 'online_quiz'
    @assignment.title = 'Anonymous Graded Quiz'
    @assignment.save!
    @quiz = Quizzes::Quiz.where(assignment_id: @assignment).first
    @quiz.update_attribute(:anonymous_submissions, true)
    student_in_course
    qs = @quiz.generate_submission(@student)
    qs.start_grading
    qs.complete
    get "/courses/#{@course.id}/gradebook/speed_grader?assignment_id=#{@assignment.id}"
    keep_trying_until {
      expect(fj('#this_student_has_a_submission')).to be_displayed
    }
  end

  it "updates quiz grade automatically when the update button is clicked", priority: "1", test_id: 283739 do
    expected_points = "6"
    student = student_in_course(:active_user => true).user
    @assignment.points_possible = 10
    @assignment.submission_types = 'online_quiz'
    @assignment.title = 'Anonymous Graded Quiz'
    @assignment.save!
    q = Quizzes::Quiz.where(assignment_id: @assignment).first
    q.quiz_questions.create!(:quiz => q, :question_data => {:position => 1, :question_type => "true_false_question", :points_possible => 3, :question_name => "true false question"})
    q.quiz_questions.create!(:quiz => q, :question_data => {:position => 2, :question_type => "essay_question", :points_possible => 7, :question_name => "essay question"})
    q.generate_quiz_data
    q.workflow_state = 'available'
    q.save!
    qs = q.generate_submission(student)
    qs.submission_data = {"foo" => "bar1"}
    Quizzes::SubmissionGrader.new(qs).grade_submission

    get "/courses/#{@course.id}/gradebook/speed_grader?assignment_id=#{@assignment.id}"
    wait_for_ajaximations
    in_frame('speedgrader_iframe') do
      question_inputs = ff('.header .question_input')
      question_inputs.each { |qi| replace_content(qi, 3) }
      submit_form('#update_history_form')
    end
    keep_trying_until { expect(f('#grade_container input')).to have_attribute('value', expected_points) }
  end

  it "properly displays student quiz results when the teacher also has a student enrollment", priority: "2", test_id: 283740 do
    student = student_in_course(:active_user => true).user
    @course.enroll_student(@teacher).accept!

    @assignment.points_possible = 10
    @assignment.submission_types = 'online_quiz'
    @assignment.title = 'Anonymous Graded Quiz'
    @assignment.save!

    q = Quizzes::Quiz.where(assignment_id: @assignment).first
    q.quiz_questions.create!(:quiz => q, :question_data => {
        :position => 1,
        :question_type => "true_false_question",
        :points_possible => 3,
        :question_name => "true false question"})
    q.generate_quiz_data
    q.workflow_state = 'available'
    q.save!

    [student, @teacher].each do |user|
      q.generate_submission(student).tap do |qs|
        qs.submission_data = {'foo' => 'bar1'}
        Quizzes::SubmissionGrader.new(qs).grade_submission
      end
    end

    get "/courses/#{@course.id}/gradebook/speed_grader?assignment_id=#{@assignment.id}#%7B%22student_id%22%3A#{student.id}%7D"
    wait_for_ajaximations

    in_frame('speedgrader_iframe') do
      expect(f('#content').text).to match(/User/)
      expect(f('#content').text).not_to match(/nobody@example.com/)
    end
  end

  context "url submissions" do
    before do
      @assignment.update_attributes! submission_types: 'online_url',
                                     title: "url submission"
      student_in_course
      @assignment.submit_homework(@student, :submission_type => "online_url", :workflow_state => "submitted", :url => "http://www.instructure.com")
    end

    it "properly shows and hides student name when name hidden toggled", priority: "2", test_id: 283741 do
      get "/courses/#{@course.id}/gradebook/speed_grader?assignment_id=#{@assignment.id}"

      in_frame 'speedgrader_iframe' do
        expect(f('.not_external')).to include_text("instructure")
        expect(f('.open_in_a_new_tab')).to include_text("View")
      end
    end
  end

  context "quiz submissions" do
    before do
      @assignment.update_attributes! points_possible: 10,
                                     submission_types: 'online_quiz',
                                     title: "Quiz"
      @quiz = Quizzes::Quiz.where(assignment_id: @assignment).first

      student_in_course
      2.times do |i|
        qs = @quiz.generate_submission(@student)
        opts = i == 0 ? {finished_at: (Date.today - 7) + 30.minutes} : {}
        Quizzes::SubmissionGrader.new(qs).grade_submission(opts)
      end
    end

    it "links to the quiz history page when there are too many quiz submissions", priority: "2", test_id: 283742 do
      Setting.set("too_many_quiz_submission_versions", 2)
      get "/courses/#{@course.id}/gradebook/speed_grader?assignment_id=#{@assignment.id}"
      expect(fj("#submission_to_view")).to be_nil
      uri = URI.parse(f(".see-all-attempts")[:href])
      expect(uri.path).to eq "/courses/#{@course.id}/quizzes/#{@quiz.id}/history"
      expect(uri.query).to eq "user_id=#{@student.id}"
    end

    it "lets you view previous quiz submissions", priority: "1", test_id: 283743 do
      get "/courses/#{@course.id}/gradebook/speed_grader?assignment_id=#{@assignment.id}"

      submission_dropdown = f("#submission_to_view")
      expect(submission_dropdown).to be_displayed

      submissions = submission_dropdown.find_elements(:css, "option")
      expect(submissions.size).to eq 2

      submissions.each do |s|
        s.click
        submission_date = s.text
        in_frame('speedgrader_iframe') do
          keep_trying_until { expect(fj('.quiz-submission').text).to include submission_date }
        end
      end
    end

    it "hides student's name from quiz if hide student names is enabled", priority: "1", test_id: 283744 do
      get "/courses/#{@course.id}/gradebook/speed_grader?assignment_id=#{@assignment.id}"

      f("#settings_link").click
      f('#hide_student_names').click
      expect_new_page_load { fj('.ui-dialog-buttonset .ui-button:visible:last').click }
      wait_for_ajaximations

      keep_trying_until { f('#speedgrader_iframe') }
      in_frame 'speedgrader_iframe' do
        expect(f('#main')).to include_text("Quiz Results for Student")
      end
    end
  end

  context "discussion submissions" do
    before do
      #make assignment a discussion assignment
      @assignment.update_attributes! points_possible: 5,
                                     submission_types: 'discussion_topic',
                                     title: 'some topic',
                                     description: 'a little bit of content'

      #create and enroll first student
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
      @first_message = 'first student message'
      @second_message = 'second student message'
      @discussion_topic = DiscussionTopic.find_by_assignment_id(@assignment.id)
      entry = @discussion_topic.discussion_entries.
          create!(:user => student, :message => @first_message)
      entry.update_topic
      entry.context_module_action
      @attachment_thing = attachment_model(:context => student_2, :filename => 'horse.js')
      entry_2 = @discussion_topic.discussion_entries.
          create!(:user => student_2, :message => @second_message, :attachment => @attachment_thing)
      entry_2.update_topic
      entry_2.context_module_action
    end

    it "displays discussion entries for only one student", priority: "1", test_id: 283745 do
        get "/courses/#{@course.id}/gradebook/speed_grader?assignment_id=#{@assignment.id}"

      #check for correct submissions in speed grader iframe
      keep_trying_until { f('#speedgrader_iframe') }
      in_frame 'speedgrader_iframe' do
        expect(f('#main')).to include_text(@first_message)
        expect(f('#main')).not_to include_text(@second_message)
      end
      f('#gradebook_header a.next').click
      wait_for_ajax_requests
      in_frame 'speedgrader_iframe' do
        expect(f('#main')).not_to include_text(@first_message)
        expect(f('#main')).to include_text(@second_message)
        url = f('#main div.attachment_data a')['href']
        expect(url).to be_include "/files/#{@attachment_thing.id}/download?verifier=#{@attachment_thing.uuid}"
        expect(url).not_to be_include "/courses/#{@course}"
      end
    end

    context "when student names hidden" do
      it "hides the name of student on discussion iframe", priority: "2", test_id: 283746 do
        get "/courses/#{@course.id}/gradebook/speed_grader?assignment_id=#{@assignment.id}"

        f("#settings_link").click
        f('#hide_student_names').click
        expect_new_page_load { fj('.ui-dialog-buttonset .ui-button:visible:last').click }
        wait_for_ajaximations

        #check for correct submissions in speed grader iframe
        keep_trying_until { f('#speedgrader_iframe') }
        in_frame 'speedgrader_iframe' do
          expect(f('#main')).to include_text("This Student")
        end
      end

      it "hides student names and shows name of grading teacher entries on both discussion links", priority: "2", test_id: 283747 do
        teacher = @course.teachers.first
        teacher_message = "why did the taco cross the road?"

        teacher_entry = @discussion_topic.discussion_entries.
          create!(:user => teacher, :message => teacher_message)
        teacher_entry.update_topic
        teacher_entry.context_module_action

        get "/courses/#{@course.id}/gradebook/speed_grader?assignment_id=#{@assignment.id}"

        f("#settings_link").click
        f('#hide_student_names').click
        expect_new_page_load { fj('.ui-dialog-buttonset .ui-button:visible:last').click }
        wait_for_ajaximations

        #check for correct submissions in speed grader iframe
        keep_trying_until { f('#speedgrader_iframe') }
        in_frame 'speedgrader_iframe' do
          f('#discussion_view_link').click
          authors = ff('h2.discussion-title span')
          expect(authors[0]).to include_text("This Student")
          expect(authors[1]).to include_text("Discussion Participant")
          expect(authors[2]).to include_text(teacher.name)
        end

        get "/courses/#{@course.id}/gradebook/speed_grader?assignment_id=#{@assignment.id}"

        keep_trying_until { f('#speedgrader_iframe') }
        in_frame 'speedgrader_iframe' do
          f('.header_title a').click
          authors = ff('h2.discussion-title span')
          expect(authors[0]).to include_text("This Student")
          expect(authors[1]).to include_text("Discussion Participant")
          expect(authors[2]).to include_text(teacher.name)
        end
      end

      it "hides avatars on entries on both discussion links", priority: "2", test_id: 283748 do
        get "/courses/#{@course.id}/gradebook/speed_grader?assignment_id=#{@assignment.id}"

        f("#settings_link").click
        f('#hide_student_names').click
        expect_new_page_load { fj('.ui-dialog-buttonset .ui-button:visible:last').click }
        wait_for_ajaximations

        #check for correct submissions in speed grader iframe
        keep_trying_until { f('#speedgrader_iframe') }
        in_frame 'speedgrader_iframe' do
          f('#discussion_view_link').click
          expect(ff('.avatar').length).to eq 0
        end

        get "/courses/#{@course.id}/gradebook/speed_grader?assignment_id=#{@assignment.id}"

        keep_trying_until { f('#speedgrader_iframe') }
        in_frame 'speedgrader_iframe' do
          f('.header_title a').click
          expect(ff('.avatar').length).to eq 0
        end
      end
    end
  end

  it "grades assignment using rubric", priority: "2", test_id: 283749 do
    student_submission
    @association.use_for_grading = true
    @association.save!

    get "/courses/#{@course.id}/gradebook/speed_grader?assignment_id=#{@assignment.id}"
    wait_for_ajaximations

    #test opening and closing rubric
    keep_trying_until do
      f('.toggle_full_rubric').click
      expect(f('#rubric_full')).to be_displayed
    end
    f('#rubric_holder .hide_rubric_link').click
    wait_for_ajaximations
    expect(f('#rubric_full')).not_to be_displayed
    f('.toggle_full_rubric').click
    rubric = f('#rubric_full')
    expect(rubric).to be_displayed

    #test rubric input
    rubric.find_element(:css, 'input.criterion_points').send_keys('3')
    rubric.find_element(:css, '.criterion_comments img').click
    f('textarea.criterion_comments').send_keys('special rubric comment')
    f('#rubric_criterion_comments_dialog .save_button').click
    second_criterion = rubric.find_element(:id, "criterion_#{@rubric.criteria[1][:id]}")
    second_criterion.find_element(:css, '.ratings .edge_rating').click
    expect(rubric.find_element(:css, '.rubric_total')).to include_text('8')
    f('#rubric_full .save_rubric_button').click
    keep_trying_until { expect(f('#rubric_summary_container > .rubric_container')).to be_displayed }
    expect(f('#rubric_summary_container')).to include_text(@rubric.title)
    expect(f('#rubric_summary_container .rubric_total')).to include_text('8')
    wait_for_ajaximations
    expect(f('#grade_container input')).to have_attribute(:value, '8')
  end

  it "allows commenting using rubric", priority: "1", test_id: 283750 do
    student_submission
    @association.use_for_grading = true
    @association.save!

    @rubric.data.detect{ |row| row[:learning_outcome_id] == @outcome.id }[:ignore_for_scoring] = true
    @rubric.save!

    get "/courses/#{@course.id}/gradebook/speed_grader?assignment_id=#{@assignment.id}"

    to_comment = 'special rubric comment'
    keep_trying_until do
      f('.toggle_full_rubric').click
      expect(f('#rubric_full')).to be_displayed
    end
    f('#rubric_full tr.learning_outcome_criterion .criterion_comments img').click
    f('textarea.criterion_comments').send_keys(to_comment)
    f('#rubric_criterion_comments_dialog .save_button').click
    f('#rubric_full .save_rubric_button').click
    wait_for_ajaximations
    saved_comment = f('#rubric_summary_container .rubric_table tr.learning_outcome_criterion .rating_comments_dialog_link')
    expect(saved_comment.text).to eq to_comment
  end

  it "should not convert invalid text to 0", priority: "2", test_id: 283751 do
    student_submission
    @association.save!

    get "/courses/#{@course.id}/gradebook/speed_grader?assignment_id=#{@assignment.id}"
    wait_for_ajaximations

    f('.toggle_full_rubric').click
    wait_for_ajaximations
    rubric = f('#rubric_full')

    #test rubric input
    rubric.find_element(:css, 'input.criterion_points').send_keys('SMRT')
    f('#rubric_full .save_rubric_button').click
    wait_for_ajaximations
    f('.toggle_full_rubric').click
    wait_for_ajaximations
    expect(f('.rubric_container .criterion_points').attribute(:value)).to eq('')
  end

  describe "when rounding .rubric_total" do
    it "should round to 2 decimal places", priority: "1", test_id: 283752 do
      setup_and_grade_rubric('1.001', '1.01')

      expect(f('#rubric_full .rubric_total').text).to eq('2.01') # while entering scores

      f('.save_rubric_button').click
      wait_for_ajaximations
      expect(f('#rubric_summary_holder .rubric_total').text).to eq('2.01') # seeing the summary after entering scores

      f('.toggle_full_rubric').click
      wait_for_ajaximations
      expect(f('#rubric_full .rubric_total').text).to eq('2.01') # after opening the rubric up again to re-score
    end

    it "should not display trailing zeros", priority: "1", test_id: 283753 do
      setup_and_grade_rubric('1', '1')

      expect(f('#rubric_full .rubric_total').text).to eq('2') # while entering scores

      f('.save_rubric_button').click
      wait_for_ajaximations
      expect(f('#rubric_summary_holder .rubric_total').text).to eq('2') # seeing the summary after entering scores

      f('.toggle_full_rubric').click
      wait_for_ajaximations
      expect(f('#rubric_full .rubric_total').text).to eq('2') # after opening the rubric up again to re-score
    end
  end

  it "creates a comment on assignment", priority: "1", test_id: 283754 do
    #pending("failing because it is dependant on an external kaltura system")

    student_submission
    get "/courses/#{@course.id}/gradebook/speed_grader?assignment_id=#{@assignment.id}"
    wait_for_ajaximations

    #check media comment
    keep_trying_until do
      driver.execute_script("$('#add_a_comment .media_comment_link').click();")
      expect(f("#audio_record_option")).to be_displayed
    end
    expect(f("#video_record_option")).to be_displayed
    close_visible_dialog
    expect(f("#audio_record_option")).not_to be_displayed

    #check for file upload comment
    f('#add_attachment').click
    expect(f('#comment_attachments input')).to be_displayed
    f('#comment_attachments a').click
    expect(element_exists('#comment_attachments input')).to be_falsey

    #add comment
    f('#add_a_comment > textarea').send_keys('grader comment')
    submit_form('#add_a_comment')
    keep_trying_until { expect(f('#comments > .comment')).to be_displayed }
    expect(f('#comments > .comment')).to include_text('grader comment')

    #make sure gradebook link works
    expect_new_page_load do
      f('#speed_grader_gradebook_link').click
    end
    expect(fj('body.grades')).to be_displayed
  end

  it "shows comment post time", priority: "1", test_id: 283755 do
    @submission = student_submission
    get "/courses/#{@course.id}/gradebook/speed_grader?assignment_id=#{@assignment.id}"
    wait_for_ajaximations

    #add comment
    f('#add_a_comment > textarea').send_keys('grader comment')
    submit_form('#add_a_comment')
    keep_trying_until { expect(f('#comments > .comment')).to be_displayed }
    @submission.reload
    @comment = @submission.submission_comments.first

    # immediately from javascript
    extend TextHelper
    expected_posted_at = datetime_string(@comment.created_at).gsub(/\s+/, ' ')
    expect(f('#comments > .comment .posted_at')).to include_text(expected_posted_at)

    # after refresh
    get "/courses/#{@course.id}/gradebook/speed_grader?assignment_id=#{@assignment.id}"
    wait_for_ajaximations
    expect(f('#comments > .comment .posted_at')).to include_text(expected_posted_at)
  end

  it "properly shows avatar images only if avatars are enabled on the account", priority: "1", test_id: 283756 do
    # enable avatars
    @account = Account.default
    @account.enable_service(:avatars)
    @account.save!
    expect(@account.service_enabled?(:avatars)).to be_truthy

    student_submission

    get "/courses/#{@course.id}/gradebook/speed_grader?assignment_id=#{@assignment.id}"
    wait_for_ajaximations

    # make sure avatar shows up for current student
    expect(ff("#avatar_image").length).to eq 1
    expect(f("#avatar_image")).not_to have_attribute('src', 'blank.png')

    #add comment
    f('#add_a_comment > textarea').send_keys('grader comment')
    submit_form('#add_a_comment')
    keep_trying_until { expect(f('#comments > .comment')).to be_displayed }
    expect(f('#comments > .comment')).to include_text('grader comment')

    # make sure avatar shows up for user comment
    expect(ff("#comments > .comment .avatar")[0]).to have_attribute('style', "display: inline\;")
    # disable avatars
    @account = Account.default
    @account.disable_service(:avatars)
    @account.save!
    expect(@account.service_enabled?(:avatars)).to be_falsey
    get "/courses/#{@course.id}/gradebook/speed_grader?assignment_id=#{@assignment.id}"
    wait_for_ajaximations

    expect(ff("#avatar_image").length).to eq 0
    expect(ff("#comments > .comment .avatar").length).to eq 1
    expect(ff("#comments > .comment .avatar")[0]).to have_attribute('style', "display: none\;")
  end

  it "hides student names and avatar images if Hide student names is checked", priority: "1", test_id: 283757 do
    # enable avatars
    @account = Account.default
    @account.enable_service(:avatars)
    @account.save!
    expect(@account.service_enabled?(:avatars)).to be_truthy

    sub = student_submission
    sub.add_comment(:comment => "ohai teacher")

    get "/courses/#{@course.id}/gradebook/speed_grader?assignment_id=#{@assignment.id}"
    keep_trying_until { expect(f("#avatar_image")).to be_displayed }

    f("#settings_link").click
    f('#hide_student_names').click
    expect_new_page_load { fj('.ui-dialog-buttonset .ui-button:visible:last').click }
    wait_for_ajaximations

    keep_trying_until do
      expect(f("#avatar_image")).not_to be_displayed
      expect(fj('#students_selectmenu-button .ui-selectmenu-item-header').text).to eq "Student 1"
    end

    expect(f('#comments > .comment')).to include_text('ohai')
    expect(f("#comments > .comment .avatar")).not_to be_displayed
    expect(f('#comments > .comment .author_name')).to include_text('Student')

    # add teacher comment
    f('#add_a_comment > textarea').send_keys('grader comment')
    submit_form('#add_a_comment')
    keep_trying_until { ff('#comments > .comment').size == 2 }

    # make sure name and avatar show up for teacher comment
    expect(ffj("#comments > .comment .avatar:visible").size).to eq 1
    expect(ff('#comments > .comment .author_name')[1]).to include_text('nobody@example.com')
  end

  it "does not show students in other sections if visibility is limited", priority: "1", test_id: 283758 do
    @enrollment.update_attribute(:limit_privileges_to_course_section, true)
    student_submission
    student_submission(:username => 'otherstudent@example.com', :section => @course.course_sections.create(:name => "another section"))
    get "/courses/#{@course.id}/gradebook/speed_grader?assignment_id=#{@assignment.id}"
    wait_for_ajaximations

    keep_trying_until { ffj('#students_selectmenu option').size > 0 }
    expect(ffj('#students_selectmenu option').size).to eq 1 # just the one student
    expect(ffj('#section-menu ul li').size).to eq 1 # "Show all sections"
    expect(fj('#students_selectmenu #section-menu')).to be_nil # doesn't get inserted into the menu
  end

  context "multiple enrollments" do
    before(:each) do
      student_in_course
      @course_section = @course.course_sections.create!(:name => "<h1>Other Section</h1>")
      @enrollment = @course.enroll_student(@student,
                                           :enrollment_state => "active",
                                           :section => @course_section,
                                           :allow_multiple_enrollments => true)
    end

    it "does not duplicate students", priority: "1", test_id: 283985 do
      get "/courses/#{@course.id}/gradebook/speed_grader?assignment_id=#{@assignment.id}"
      wait_for_ajaximations

      expect(ff("#students_selectmenu option").length).to eq 1
    end

    it "filters by section properly", priority: "1", test_id: 283986 do
      get "/courses/#{@course.id}/gradebook/speed_grader?assignment_id=#{@assignment.id}"
      wait_for_ajaximations

      sections = @course.course_sections
      expect(ff("#section-menu ul li a").map{|e| e.attribute('text')}).to be_include(@course_section.name)
      goto_section(sections[0].id)
      expect(ff("#students_selectmenu option").length).to eq 1
      goto_section(sections[1].id)
      expect(ff("#students_selectmenu option").length).to eq 1
    end
  end

  it "shows the first ungraded student with a submission", priority: "1", test_id: 283987 do
    s1, s2, s3 = n_students_in_course(3)
    s1.update_attribute :name, "A"
    s2.update_attribute :name, "B"
    s3.update_attribute :name, "C"

    @assignment.grade_student s1, score: 10
    @assignment.find_or_create_submission(s2).tap { |submission|
      submission.student_entered_score = 5
    }.save!
    @assignment.submit_homework(s3, body: "Homework!?")

    get "/courses/#{@course.id}/gradebook/speed_grader?assignment_id=#{@assignment.id}"
    wait_for_ajaximations

    expect(fj("#students_selectmenu option[value=#{s3.id}]")[:selected]).to be_truthy
  end

  it "allows the user to change sorting and hide student names", priority: "1", test_id: 283988 do
    student_submission(name: 'student@example.com')

    get "/courses/#{@course.id}/gradebook/speed_grader?assignment_id=#{@assignment.id}"
    wait_for_ajaximations

    # sort by submission date
    f("#settings_link").click
    f('select#eg_sort_by option[value="submitted_at"]').click
    expect_new_page_load { fj('.ui-dialog-buttonset .ui-button:visible:last').click }
    keep_trying_until { f('#combo_box_container .ui-selectmenu .ui-selectmenu-item-header').text == "student@example.com" }

    # hide student names
    f("#settings_link").click
    f('#hide_student_names').click
    expect_new_page_load { fj('.ui-dialog-buttonset .ui-button:visible:last').click }
    keep_trying_until { f('#combo_box_container .ui-selectmenu .ui-selectmenu-item-header').text == "Student 1" }

    # make sure it works a second time too
    f("#settings_link").click
    f('select#eg_sort_by option[value="alphabetically"]').click
    expect_new_page_load { fj('.ui-dialog-buttonset .ui-button:visible:last').click }
    keep_trying_until { f('#combo_box_container .ui-selectmenu .ui-selectmenu-item-header').text == "Student 1" }

    # unselect the hide option
    f("#settings_link").click
    f('#hide_student_names').click
    expect_new_page_load { fj('.ui-dialog-buttonset .ui-button:visible:last').click }
    keep_trying_until { expect(f('#combo_box_container .ui-selectmenu .ui-selectmenu-item-header').text).to eq "student@example.com" }
  end

  it "ignores rubric lines for grading", priority: "1", test_id: 283989 do
    student_submission
    @association.use_for_grading = true
    @association.save!
    @ignored = @course.created_learning_outcomes.create!(:title => 'outcome', :description => 'just for reference')
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
    @rubric.save!

    get "/courses/#{@course.id}/gradebook/speed_grader?assignment_id=#{@assignment.id}"
    wait_for_ajaximations
    f('button.toggle_full_rubric').click
    f(".rubric.assessing table.rubric_table tr:nth-child(1) table.ratings td:nth-child(1)").click
    f(".rubric.assessing table.rubric_table tr:nth-child(3) table.ratings td:nth-child(1)").click
    f("#rubric_holder button.save_rubric_button").click
    wait_for_ajaximations

    expect(@submission.reload.score).to eq 3
    expect(f("#grade_container input[type=text]")).to have_attribute(:value, '3')
    expect(f("#rubric_summary_container tr:nth-child(1) .editing")).to be_displayed
    expect(f("#rubric_summary_container tr:nth-child(1) .ignoring")).not_to be_displayed
    expect(f("#rubric_summary_container tr:nth-child(3) .editing")).not_to be_displayed
    expect(f("#rubric_summary_container tr:nth-child(3) .ignoring")).to be_displayed
    expect(f("#rubric_summary_container tr.summary .rubric_total").text).to eq '3'
    # check that null scores do not show a criterion level
    expect(f("#rubric_summary_container tr:nth-child(2) .description").text).to be_empty

    # check again that initial page load has the same data.
    get "/courses/#{@course.id}/gradebook/speed_grader?assignment_id=#{@assignment.id}"
    wait_for_ajaximations
    expect(f("#grade_container input[type=text]")).to have_attribute(:value, '3')
    expect(f("#rubric_summary_container tr:nth-child(1) .editing")).to be_displayed
    expect(f("#rubric_summary_container tr:nth-child(1) .ignoring")).not_to be_displayed
    expect(f("#rubric_summary_container tr:nth-child(3) .editing")).not_to be_displayed
    expect(f("#rubric_summary_container tr:nth-child(3) .ignoring")).to be_displayed
    expect(f("#rubric_summary_container tr.summary .rubric_total").text).to eq '3'
    expect(f("#rubric_summary_container tr:nth-child(2) .description").text).to be_empty
  end

  it "includes the student view student for grading", priority: "1", test_id: 283990 do
    @course.student_view_student
    get "/courses/#{@course.id}/gradebook/speed_grader?assignment_id=#{@assignment.id}"
    wait_for_ajaximations

    expect(ff("#students_selectmenu option").length).to eq 1
  end

  it "includes fake student (Student View Student) submissions in 'X/Y Graded' text", priority: "2", test_id: 283991 do
    fake_student = @course.student_view_student
    submission = @assignment.find_or_create_submission(fake_student)
    submission.submission_type = 'online_quiz'
    submission.workflow_state = 'submitted'
    submission.save!
    @assignment.grade_student(fake_student, grade: 8, grader: @teacher)
    get "/courses/#{@course.id}/gradebook/speed_grader?assignment_id=#{@assignment.id}"
    wait_for_ajaximations

    expect(f("#x_of_x_graded").text).to eq "1 / 1 Graded"
  end

  it "marks the checkbox of students for graded assignments", priority: "1", test_id: 283992 do
    student_submission

    get "/courses/#{@course.id}/gradebook/speed_grader?assignment_id=#{@assignment.id}"
    wait_for_ajaximations

    expect(f("#students_selectmenu-button")).to have_class("not_graded")

    #if this block loses focuses of the window the checkbox won't get checked
    keep_trying_until do
      f('#grade_container input[type=text]').click
      set_value(f('#grade_container input[type=text]'), 1)
      f(".ui-selectmenu-icon").click
      wait_for_ajaximations
      expect(f("#students_selectmenu-button")).to have_class("graded")
    end
  end

  context "grading display" do

    it "displays the score on the sidebar", priority: "1", test_id: 283993 do
      create_and_enroll_students(1)
      submit_and_grade_homework(@students[0], 3)

      get "/courses/#{@course.id}/gradebook/speed_grader?assignment_id=#{@assignment.id}"
      wait_for_ajaximations

      expect(f('#grade_container input[type=text]')).to have_attribute("value", "3")
    end

    it "displays total number of graded assignments to students", priority: "1", test_id: 283994 do
      create_and_enroll_students(2)
      submit_and_grade_homework(@students[0], 3)

      get "/courses/#{@course.id}/gradebook/speed_grader?assignment_id=#{@assignment.id}"
      wait_for_ajaximations

      expect(f("#x_of_x_graded")).to include_text("1 / 2 Graded")
    end

    it "displays average submission grade for total assignment submissions", priority: "1", test_id: 283995 do
      skip('testbot fragile')
      create_and_enroll_students(2)

      submit_and_grade_homework(@students[0], 10)
      submit_and_grade_homework(@students[1], 0)

      get "/courses/#{@course.id}/gradebook/speed_grader?assignment_id=#{@assignment.id}"
      wait_for_ajaximations

      expect(f("#average_score")).to include_text("5 / 10 (50%)")
    end
  end

  context "Pass / Fail assignments" do
    it "displays correct options in the speedgrader dropdown", priority: "1", test_id: 283996 do
      course_with_teacher_logged_in
      course_with_student(course: @course, active_all: true)

      @assignment = @course.assignments.build
      @assignment.grading_type = 'pass_fail'
      @assignment.publish

      get "/courses/#{@course.id}/gradebook/speed_grader?assignment_id=#{@assignment.id}"
      select_box_values = ff('#grading-box-extended option').map(&:text)
      expect(select_box_values).to eql(["---", "Complete", "Incomplete", "Excused"])
    end
  end

  it "only displays 2 decimal points on a quiz submission", priority: "1", test_id: 283997 do
    # generate a proper teacher and student in the course, then switch sessions to the teacher
    course_with_teacher_logged_in
    course_with_student(:course => @course, :active_all => true)

    # create our quiz and our multiple answers question
    @context = @course
    @q = quiz_model
    answers = [ {'id' => 1, 'text' => 'one', 'weight' => 100},
                {'id' => 2, 'text' => 'two', 'weight' => 100},
                {'id' => 3, 'text' => 'three', 'weight' => 100},
                {'id' => 4, 'text' => 'four', 'weight' => 0} ]
    @quest1 = @q.quiz_questions.create!(:question_data => {:name => "first question", 'question_type' => 'multiple_answers_question', 'answers' => answers, :points_possible => 4})
    @q.generate_quiz_data
    @q.tap(&:save)

    # create a submission and answer our question
    qs = @q.generate_submission(@student)
    (1..4).each do |var|
       qs.submission_data["question_#{@quest1.id}_answer_#{var}"] = "1"
    end
    Quizzes::SubmissionGrader.new(qs).grade_submission

    # navigate to speedgrader and confirm the point value is rounded to the nearest hundredth
    get "/courses/#{@course.id}/gradebook/speed_grader?assignment_id=#{@q.assignment_id}"
    in_frame('speedgrader_iframe') do
      # sometimes jquery likes to be slow to load, so we do a keep trying so it can try again if $ is undefined
      keep_trying_until { expect(driver.execute_script("return $('#question_#{@quest1.id} .question_input')[0].value")).to eq "2.67" }
    end
  end
end
