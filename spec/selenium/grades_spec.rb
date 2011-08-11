require File.expand_path(File.dirname(__FILE__) + "/common")

describe "grades selenium tests" do
  it_should_behave_like "in-process server selenium tests"

  before(:each) do
    course_with_student_logged_in
    #add teacher
    @teacher = User.create!
    @teacher.register!
    e = @course.enroll_teacher(@teacher)
    e.workflow_state = 'active'
    e.save!
    @course.reload
    #add second student
    @student_2 = User.create!(:name => 'nobody2@example.com')
    @student_2.register!
    pseudonym_2 = @student_2.pseudonyms.create!(:unique_id => 'nobody2@example.com', :path => 'nobody2@example.com', :password => 'qwerty', :password_confirmation => 'qwerty')

    e2 = @course.enroll_student(@student_2)
    e2.workflow_state = 'active'
    e2.save!
    @course.reload

    #first assignment data
    due_date = Time.now.utc + 2.days
    @group = @course.assignment_groups.create!(:name => 'first assignment group')
    @assignment = assignment_model({
      :course => @course,
      :name => 'first assignment',
      :due_at => due_date,
      :points_possible => 10,
      :submission_types => 'online_text_entry',
      :assignment_group => @group
    })
    rubric_model
    @association = @rubric.associate_with(@assignment, @course, :purpose => 'grading')
    @assignment.reload
    @submission = @assignment.submit_homework(@user, :body => 'student first submission') 
    @assignment.grade_student(@user, :grade => 2)
    @assessment = @association.assess({
      :user => @user,
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
    @student_2_submission = @assignment.submit_homework(@student_2, :body => 'second student second submission')
    @assignment.grade_student(@student_2, :grade => 4)
    @student_2_submission.score = 3
    @submission.save!

    #second assigmnent data
    due_date = due_date + 1.days
    @second_assignment = assignment_model({
      :course => @course,
      :name => 'second assignment',
      :due_at => due_date,
      :points_possible => 5,
      :submission_types => 'online_text_entry',
      :assignment_group => @group
    })
    @second_association = @rubric.associate_with(@second_assignment, @course, :purpose => 'grading')
    @second_submission = @second_assignment.submit_homework(@user, :body => 'student second submission')
    @second_assignment.grade_student(@user, :grade => 2)
    @second_submission.save!

    #third assignment data
    due_date = due_date + 1.days
    @third_assignment = assignment_model({ :name => 'third assignment', :due_at => due_date, :course => @course })
   
    get "/courses/#{@course.id}/grades"
    @grade_tbody = driver.find_element(:css, '#grades_summary > tbody')
  end

  it "should allow student to test modifying grades" do

    #check initial total
    final_row = driver.find_element(:css, '#submission_final-grade')
    final_row.find_element(:css, '.assignment_score .grade').text.should == '33.3'
    
    #test changing existing scores
    first_row_grade = driver.find_element(:css, "#submission_#{@submission.assignment_id} .assignment_score .grade")
    first_row_grade.click
    first_row_grade.find_element(:css, 'input').clear
    first_row_grade.find_element(:css, 'input').send_keys('4')
    driver.execute_script('$("#grade_entry").blur();')
    final_row.find_element(:css, '.assignment_score .grade').text.should == '40'
  end

  it "should display rubric on assignment" do
    
    #click rubric
    driver.find_element(:css, '.toggle_rubric_assessments_link').click
    wait_for_animations 
    driver.find_element(:css, '#assessor .rubric_title').text.include?(@rubric.title).should be_true

    driver.find_element(:css, '#assessor .rubric_total').text.include?('2').should be_true

    #check rubric comment
    driver.find_element(:css, "tr.rubric_assessments table#rubric_#{@rubric.id} tr div.displaying a.criterion_comments").click
    driver.find_element(:id, 'rubric_criterion_comments_dialog').should be_displayed
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

end
