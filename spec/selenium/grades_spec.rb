require File.expand_path(File.dirname(__FILE__) + "/common")

describe "grades" do
  it_should_behave_like "in-process server selenium tests"

  before (:each) do
    course_with_teacher(:active_all => true)
    student_in_course(:name => "Student 1", :active_all => true)
    @student_1 = @student
    student_in_course(:name => "Student 2", :active_all => true)
    @student_2 = @student

    #first assignment data
    due_date = Time.now.utc + 2.days
    @group = @course.assignment_groups.create!(:name => 'first assignment group')
    @first_assignment = assignment_model({
      :course => @course,
      :title => 'first assignment',
      :due_at => due_date,
      :points_possible => 10,
      :submission_types => 'online_text_entry',
      :assignment_group => @group
    })
    rubric_model
    @association = @rubric.associate_with(@first_assignment, @course, :purpose => 'grading')
    @assignment.reload

    @submission = @first_assignment.submit_homework(@student_1, :body => 'student first submission')
    @first_assignment.grade_student(@user, :grade => 2)
    @assessment = @association.assess({
      :user => @student_1,
      :assessor => @teacher,
      :artifact => @submission,
      :assessment => {
        :assessment_type => 'grading',
        :criterion_crit1 => {
          :points => 2,
          :comments => "cool, yo"
        }
      }
    })
    @submission.reload
    @submission.score = 3
    @submission.add_comment(:author => @teacher, :comment => 'submission comment')
    @submission.save!

    #second student submission
    @student_2_submission = @first_assignment.submit_homework(@student_2, :body => 'second student second submission')
    @first_assignment.grade_student(@student_2, :grade => 4)
    @student_2_submission.score = 3
    @submission.save!

    #second assigmnent data
    due_date = due_date + 1.days
    @second_assignment = assignment_model({
      :course => @course,
      :title => 'second assignment',
      :due_at => due_date,
      :points_possible => 5,
      :submission_types => 'online_text_entry',
      :assignment_group => @group
    })

    @second_association = @rubric.associate_with(@second_assignment, @course, :purpose => 'grading')
    @second_submission = @second_assignment.submit_homework(@student_1, :body => 'student second submission')
    @second_assignment.grade_student(@student_1, :grade => 2)
    @second_submission.save!

    #third assignment data
    due_date = due_date + 1.days
    @third_assignment = assignment_model({ :title => 'third assignment', :due_at => due_date, :course => @course })
  end

  context "as a teacher" do
    before(:each) do
      user_session(@teacher)
    end

    it "should be available to student view student" do
      @fake_student = @course.student_view_student
      @fake_submission = @first_assignment.submit_homework(@fake_student, :body => 'fake student submission')
      @first_assignment.grade_student(@fake_student, :grade => 8)

      enter_student_view
      get "/courses/#{@course.id}/grades"

      f("#submission_#{@first_assignment.id} .grade").should include_text "8"
    end
  end

  context "as a student" do
    before(:each) do
      user_session(@student_1)
      get "/courses/#{@course.id}/grades"
      @grade_tbody = driver.find_element(:css, '#grades_summary > tbody')
    end

    it "should allow student to test modifying grades" do
      # just one ajax request
      Assignment.expects(:find_or_create_submission).once.returns(@submission)

      #check initial total
      driver.find_element(:css, '#submission_final-grade .assignment_score .grade').text.should == '33.3'

      #test changing existing scores
      first_row_grade = driver.find_element(:css, "#submission_#{@submission.assignment_id} .assignment_score .grade")
      first_row_grade.click
      set_value(first_row_grade.find_element(:css, 'input'), '4')
      first_row_grade.find_element(:css, 'input').send_keys(:return)

      #using find with jquery to avoid caching issues
      keep_trying_until { 
        wait_for_ajaximations
        find_with_jquery('#submission_final-grade .assignment_score .grade').text.should == '40'
      }
    end

    it "should display rubric on assignment" do
      #click rubric
      f("#submission_#{@first_assignment.id} .toggle_rubric_assessments_link").click
      wait_for_animations
      fj('.rubric_assessments:visible .rubric_title').should include_text(@rubric.title)
      fj('.rubric_assessments:visible .rubric_total').should include_text('2')

      #check rubric comment
      fj('.assessment-comments:visible div').text.should == 'cool, yo'
    end

    it "should not display rubric on muted assignment" do
      @first_assignment.muted = true
      @first_assignment.save!
      get "/courses/#{@course.id}/grades"

      f("#submission_#{@first_assignment.id} .toggle_rubric_assessments_link").should_not be_displayed
    end

    it "should not display letter grade score on muted assignment" do
      @another_assignment = assignment_model({
                                               :course => @course,
                                               :title => 'another assignment',
                                               :points_possible => 100,
                                               :submission_types => 'online_text_entry',
                                               :assignment_group => @group,
                                               :grading_type => 'letter_grade',
                                               :muted => 'true'
                                             })
      @another_submission = @another_assignment.submit_homework(@student_1, :body => 'student second submission')
      @another_assignment.grade_student(@student_1, :grade => 81)
      @another_submission.save!
      get "/courses/#{@course.id}/grades"
      f('.score_value').text.should == ''
    end

    it "should display teacher comment and assignment statistics" do
      #check comment
      driver.find_element(:css, '.toggle_comments_link img').click
      comment_row = driver.find_element(:css, '#grades_summary tr.comments')
      comment_row.should include_text('submission comment')

      #check tooltip text statistics
      driver.execute_script('$("#grades_summary tr.comments span.tooltip_text").css("visibility", "visible");')
      statistics_text = comment_row.find_element(:css, 'span.tooltip_text').text
      statistics_text.include?("#{before_label(:mean_score, "Mean")} 3.5").should be_true
      #statistics_text.include?('Mean: 3.5').should be_true
      #statistics_text.include?('High: 4').should be_true
      #statistics_text.include?('Low: 3').should be_true
    end

    it "should show rubric even if there are no comments" do
      @third_association = @rubric.associate_with(@third_assignment, @course, :purpose => 'grading')
      @third_submission = @third_assignment.submissions.create!(:user => @student_1) # unsubmitted submission :/

      @third_association.assess({
        :user => @student_1,
        :assessor => @teacher,
        :artifact => @third_submission,
        :assessment => {
          :assessment_type => 'grading',
          :criterion_crit1 => {
            :points => 2,
            :comments => "not bad, not bad"
          }
        }
      })

      get "/courses/#{@course.id}/grades"

      #click rubric
      f("#submission_#{@third_assignment.id} .toggle_rubric_assessments_link").click
      fj('.rubric_assessments:visible .rubric_title').should include_text(@rubric.title)
      fj('.rubric_assessments:visible .rubric_total').should include_text('2')

      #check rubric comment
      fj('.assessment-comments:visible div').text.should == 'not bad, not bad'
    end
  end

  context "as an observer" do
    it "should allow observers to see grades of all enrollment associations" do
      @obs = user_model(:name => "Observer")
      e1 = @course.observer_enrollments.create(:user => @obs, :workflow_state => "active")
      e1.associated_user = @student_1
      e1.save!
      e2 = @course.observer_enrollments.create(:user => @obs, :workflow_state => "active")
      e2.associated_user = @student_2
      e2.save!

      user_session(@obs)
      get "/courses/#{@course.id}/grades"

      driver.find_element(:css, "#observer_user_url").should be_displayed
      driver.find_element(:css, "#observer_user_url option[selected]").should include_text "Student 1"
      driver.find_element(:css, "#submission_#{@submission.assignment_id} .grade").should include_text "3"

      click_option("#observer_user_url", "Student 2")
      wait_for_dom_ready

      driver.find_element(:css, "#observer_user_url").should be_displayed
      driver.find_element(:css, "#observer_user_url option[selected]").should include_text "Student 2"
      driver.find_element(:css, "#submission_#{@submission.assignment_id} .grade").should include_text "4"

      click_option("#observer_user_url", "Student 1")
      wait_for_dom_ready

      driver.find_element(:css, "#observer_user_url").should be_displayed
      driver.find_element(:css, "#observer_user_url option[selected]").should include_text "Student 1"
      driver.find_element(:css, "#submission_#{@submission.assignment_id} .grade").should include_text "3"
    end
  end
end
