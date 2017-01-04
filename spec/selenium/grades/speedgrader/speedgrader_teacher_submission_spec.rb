require_relative '../../helpers/speed_grader_common'

describe "speed grader submissions" do
  include_context "in-process server selenium tests"
  include SpeedGraderCommon

  before(:each) do
    stub_kaltura

    course_with_teacher_logged_in
    outcome_with_rubric
    @assignment = @course.assignments.create(:name => 'assignment with rubric', :points_possible => 10)
    @association = @rubric.associate_with(@assignment, @course, :purpose => 'grading')
  end

  context "as a teacher" do
    it "should display submission of first student and then second student", priority: "1", test_id: 283276 do
      student_submission

      #create initial data for second student
      @student_2 = User.create!(:name => 'student 2')
      @student_2.register
      @student_2.pseudonyms.create!(:unique_id => 'student2@example.com', :password => 'qwertyuiop', :password_confirmation => 'qwertyuiop')
      @course.enroll_user(@student_2, "StudentEnrollment", :enrollment_state => 'active')
      @submission_2 = @assignment.submit_homework(@student_2, :body => 'second student submission text')

      get "/courses/#{@course.id}/gradebook/speed_grader?assignment_id=#{@assignment.id}#%7B%22student_id%22%3A#{@submission.student.id}%7D"

      #check for assignment title
      expect(f('#assignment_url')).to include_text(@assignment.title)

      #check for assignment text in speed grader iframe
      check_first_student = -> do
        expect(f('#combo_box_container .ui-selectmenu-item-header')).to include_text(@student.name)
        in_frame 'speedgrader_iframe' do
          expect(f('#main')).to include_text(@submission.body)
        end
      end

      check_second_student = -> do
        expect(f('#combo_box_container .ui-selectmenu-item-header')).to include_text(@student_2.name)
        in_frame 'speedgrader_iframe' do
          expect(f('#main')).to include_text(@submission_2.body)
        end
      end

      if f('#combo_box_container .ui-selectmenu-item-header').text.include?(@student_2.name)
        check_second_student.call
        f('#gradebook_header .next').click
        wait_for_ajax_requests
        check_first_student.call
      else
        check_first_student.call
        f('#gradebook_header .next').click
        wait_for_ajax_requests
        check_second_student.call
      end
    end

    it "should not error if there are no submissions", priority: "2", test_id: 283277 do
      student_in_course
      get "/courses/#{@course.id}/gradebook/speed_grader?assignment_id=#{@assignment.id}"
      wait_for_ajax_requests
      expect(driver.execute_script("return INST.errorCount")).to eq 0
    end

    it "should have a submission_history after a submitting a comment", priority: "1", test_id: 283278 do
      # a student without a submission
      @student_2 = User.create!(:name => 'student 2')
      @student_2.register
      @student_2.pseudonyms.create!(:unique_id => 'student2@example.com', :password => 'qwertyuiop', :password_confirmation => 'qwertyuiop')
      @course.enroll_user(@student_2, "StudentEnrollment", :enrollment_state => 'active')

      get "/courses/#{@course.id}/gradebook/speed_grader?assignment_id=#{@assignment.id}"
      wait_for_ajax_requests

      #add comment
      f('#add_a_comment > textarea').send_keys('grader comment')
      submit_form('#add_a_comment')
      expect(f('#comments > .comment')).to be_displayed
    end

    it "should display submission late notice message", priority: "1", test_id: 283279 do
      @assignment.due_at = Time.zone.now - 2.days
      @assignment.save!
      student_submission

      get "/courses/#{@course.id}/gradebook/speed_grader?assignment_id=#{@assignment.id}"

      expect(f('#submission_late_notice')).to be_displayed
    end

    it "should not display a late message if an assignment has been overridden", priority: "1", test_id: 283280 do
      @assignment.update_attribute(:due_at, Time.now - 2.days)
      override = @assignment.assignment_overrides.build
      override.due_at = Time.now + 2.days
      override.due_at_overridden = true
      override.set = @course.course_sections.first
      override.save!
      student_submission

      get "/courses/#{@course.id}/gradebook/speed_grader?assignment_id=#{@assignment.id}"

      expect(f('#submission_late_notice')).not_to be_displayed
    end


    it "should display no submission message if student does not make a submission", priority: "1", test_id: 283499 do
      @student = user_with_pseudonym(:active_user => true, :username => 'student@example.com', :password => 'qwertyuiop')
      @course.enroll_user(@student, "StudentEnrollment", :enrollment_state => 'active')

      get "/courses/#{@course.id}/gradebook/speed_grader?assignment_id=#{@assignment.id}"

      expect(f('#this_student_does_not_have_a_submission')).to be_displayed
    end

    it "should handle versions correctly", priority: "2", test_id: 283500 do
      submission1 = student_submission(:username => "student1@example.com", :body => 'first student, first version')
      submission2 = student_submission(:username => "student2@example.com", :body => 'second student')
      submission3 = student_submission(:username => "student3@example.com", :body => 'third student')

      # This is "no submissions" guy
      submission3.delete

      submission1.submitted_at = 10.minutes.from_now
      submission1.body = 'first student, second version'
      submission1.with_versioning(:explicit => true) { submission1.save }

      get "/courses/#{@course.id}/gradebook/speed_grader?assignment_id=#{@assignment.id}"
      wait_for_ajaximations

      # The first user should have multiple submissions. We want to make sure we go through the first student
      # because the original bug was caused by a user with multiple versions putting data on the page that
      # was carried through to other students, ones with only 1 version.
      expect(f('#submission_to_view').find_elements(:css, 'option').length).to eq 2

      in_frame 'speedgrader_iframe' do
        expect(f('#content')).to include_text('first student, second version')
      end

      click_option('#submission_to_view', '0', :value)
      wait_for_ajaximations

      in_frame 'speedgrader_iframe' do
        wait_for_ajaximations
        expect(f('#content')).to include_text('first student, first version')
      end

      f('#gradebook_header .next').click
      wait_for_ajaximations

      # The second user just has one, and grading the user shouldn't trigger a page error.
      # (In the original bug, it would trigger a change on the select box for choosing submission versions,
      # which had another student's data in it, so it would try to load a version that didn't exist.)
      expect(f("#content")).not_to contain_css('#submission_to_view')
      f('#grade_container').find_element(:css, 'input').send_keys("5\n")
      wait_for_ajaximations

      in_frame 'speedgrader_iframe' do
        expect(f('#content')).to include_text('second student')
      end

      expect(submission2.reload.score).to eq 5

      f('#gradebook_header .next').click
      wait_for_ajaximations

      expect(f('#this_student_does_not_have_a_submission')).to be_displayed
    end

    it "should leave the full rubric open when switching submissions", priority: "1", test_id: 283501 do
      student_submission(:username => "student1@example.com")
      student_submission(:username => "student2@example.com")
      get "/courses/#{@course.id}/gradebook/speed_grader?assignment_id=#{@assignment.id}"

      expect(f('.toggle_full_rubric')).to be_displayed
      f('.toggle_full_rubric').click
      wait_for_ajaximations
      rubric = f('#rubric_full')
      expect(rubric).to be_displayed
      first_criterion = rubric.find_element(:id, "criterion_#{@rubric.criteria[0][:id]}")
      first_criterion.find_element(:css, '.ratings .edge_rating').click
      second_criterion = rubric.find_element(:id, "criterion_#{@rubric.criteria[1][:id]}")
      second_criterion.find_element(:css, '.ratings .edge_rating').click
      expect(rubric.find_element(:css, '.rubric_total')).to include_text('8')
      f('#rubric_full .save_rubric_button').click
      wait_for_ajaximations
      f('.toggle_full_rubric').click
      wait_for_ajaximations

      expect(f("#criterion_#{@rubric.criteria[0][:id]} input.criterion_points")).to have_attribute("value", "3")
      expect(f("#criterion_#{@rubric.criteria[1][:id]} input.criterion_points")).to have_attribute("value", "5")
      f('#gradebook_header .next').click
      wait_for_ajaximations

      expect(f('#rubric_full')).to be_displayed
      expect(f("#criterion_#{@rubric.criteria[0][:id]} input.criterion_points")).to have_attribute("value", "")
      expect(f("#criterion_#{@rubric.criteria[1][:id]} input.criterion_points")).to have_attribute("value", "")

      f('#gradebook_header .prev').click
      wait_for_ajaximations

      expect(f('#rubric_full')).to be_displayed
      expect(f("#criterion_#{@rubric.criteria[0][:id]} input.criterion_points")).to have_attribute("value", "3")
      expect(f("#criterion_#{@rubric.criteria[1][:id]} input.criterion_points")).to have_attribute("value", "5")
    end

    it "should highlight submitted assignments and not non-submitted assignments for students", priority: "1",
       test_id: 283502

    it "should display image submission in browser", priority: "1", test_id: 283503 do
      filename, fullpath, _data = get_file("graded.png")
      create_and_enroll_students(1)
      @assignment.submission_types ='online_upload'
      @assignment.save!

      add_attachment_student_assignment(filename, @students[0], fullpath)

      get "/courses/#{@course.id}/gradebook/speed_grader?assignment_id=#{@assignment.id}"
      expect(f('#speedgrader_iframe')).to be_displayed

      in_frame("speedgrader_iframe") do
        # validates the image\attachment is inside the iframe as expected
        image_element = f('img')

        expect(image_element.attribute('src')).to include('download')
        expect(image_element.attribute('style')).to include('max-height: 100')
        expect(image_element.attribute('style')).to include('max-width: 100')
      end
    end

    context "turnitin" do
      before(:each) do
        @assignment.turnitin_enabled = true
        @assignment.save!
      end

      it "should display a pending icon if submission status is pending", priority: "1", test_id: 283504 do
        student_submission
        set_turnitin_asset(@submission, {:status => 'pending'})

        get "/courses/#{@course.id}/gradebook/speed_grader?assignment_id=#{@assignment.id}"
        wait_for_ajaximations

        turnitin_icon = f('#grade_container .submission_pending')
        expect(turnitin_icon).not_to be_nil
        turnitin_icon.click
        wait_for_ajaximations
        expect(f('#grade_container .turnitin_info')).not_to be_nil
      end

      it "should display a score if submission has a similarity score", priority: "1", test_id: 283505 do
        student_submission
        set_turnitin_asset(@submission, {:similarity_score => 96, :state => 'failure', :status => 'scored'})

        get "/courses/#{@course.id}/gradebook/speed_grader?assignment_id=#{@assignment.id}"
        wait_for_ajaximations

        expect(f('#grade_container .turnitin_similarity_score')).to include_text "96%"
      end

      it "should display an error icon if submission status is error", priority: "2", test_id: 283506 do
        student_submission
        set_turnitin_asset(@submission, {:status => 'error'})

        get "/courses/#{@course.id}/gradebook/speed_grader?assignment_id=#{@assignment.id}"
        wait_for_ajaximations

        turnitin_icon = f('#grade_container .submission_error')
        expect(turnitin_icon).not_to be_nil
        turnitin_icon.click
        wait_for_ajaximations
        expect(f('#grade_container .turnitin_info')).not_to be_nil
        expect(f('#grade_container .turnitin_resubmit_button')).not_to be_nil
      end

      it "should show turnitin score for attached files", priority: "1", test_id: 283507 do
        @user = user_with_pseudonym({:active_user => true, :username => 'student@example.com', :password => 'qwertyuiop'})
        attachment1 = @user.attachments.new :filename => "homework1.doc"
        attachment1.content_type = "application/msword"
        attachment1.size = 10093
        attachment1.save!
        attachment2 = @user.attachments.new :filename => "homework2.doc"
        attachment2.content_type = "application/msword"
        attachment2.size = 10093
        attachment2.save!

        create_enrollments @course, [@user]
        student_submission({:user => @user, :submission_type => :online_upload, :attachments => [attachment1, attachment2], :course => @course})
        set_turnitin_asset(attachment1, {:similarity_score => 96, :state => 'failure', :status => 'scored'})
        set_turnitin_asset(attachment2, {:status => 'pending'})

        get "/courses/#{@course.id}/gradebook/speed_grader?assignment_id=#{@assignment.id}"
        wait_for_ajaximations

        expect(ff('#submission_files_list .turnitin_similarity_score').map(&:text).join).to match /96%/
        expect(f('#submission_files_list .submission_pending')).not_to be_nil
      end

      it "should successfully schedule resubmit when button is clicked", priority: "1", test_id: 283508 do
        student_submission
        set_turnitin_asset(@submission, {:status => 'error'})

        get "/courses/#{@course.id}/gradebook/speed_grader?assignment_id=#{@assignment.id}"
        wait_for_ajaximations

        f('#grade_container .submission_error').click
        wait_for_ajaximations
        expect_new_page_load { f('#grade_container .turnitin_resubmit_button').click}
        wait_for_ajaximations
        expect(Delayed::Job.find_by_tag('Submission#submit_to_turnitin')).not_to be_nil
        expect(f('#grade_container .submission_pending')).not_to be_nil
      end
    end
  end
end
