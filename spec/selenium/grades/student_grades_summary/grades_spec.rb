require_relative "../../common"

describe "grades" do
  include_context "in-process server selenium tests"

  before (:each) do
    course_with_teacher(:active_all => true)
    student_in_course(:name => "Student 1", :active_all => true)
    @student_1 = @student
    student_in_course(:name => "Student 2", :active_all => true)
    @student_2 = @student

    #first assignment data
    due_date = Time.now.utc + 2.days
    @group = @course.assignment_groups.create!(:name => 'first assignment group', :group_weight => 33.3)
    @group2 = @course.assignment_groups.create!(:name => 'second assignment group', :group_weight => 33.3)
    @group3 = @course.assignment_groups.create!(:name => 'third assignment group', :group_weight => 33.3)
    @first_assignment = assignment_model({
      :course => @course,
      :title => 'first assignment',
      :due_at => due_date,
      :points_possible => 10,
      :submission_types => 'online_text_entry',
      :assignment_group => @group,
      :peer_reviews => true,
      :anonymous_peer_reviews => true
    })
    rubric_model
    @association = @rubric.associate_with(@first_assignment, @course, :purpose => 'grading')
    @assignment.assign_peer_review(@student_2, @student_1)
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
    @submission.add_comment({
      :author => @student_2,
      :comment => "Anonymous Peer Review"
    })
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
    @third_assignment = assignment_model({:title => 'third assignment', :due_at => due_date, :course => @course})
  end

  context "as a teacher" do
    before(:each) do
      user_session(@teacher)
    end

    context 'overall grades' do
      before(:each) do
        @course_names = []
        @course_names << @course
        3.times do |i|
          course = Course.create!(:name => "course #{i}", :account => Account.default)
          course.enroll_user(@teacher, 'TeacherEnrollment').accept!
          course.offer!
          @course_names << course
        end
        get '/grades'
      end

      it "should validate courses display", priority: "1", test_id: 222510 do
        course_details = f('.course_details')
        4.times { |i| expect(course_details).to include_text(@course_names[i].name) }
      end
    end

    it "should show the student outcomes report if enabled", priority: "1", test_id: 229447 do
      @outcome_group ||= @course.root_outcome_group
      @outcome = @course.created_learning_outcomes.create!(:title => 'outcome')
      @outcome_group.add_outcome(@outcome)
      Account.default.set_feature_flag!('student_outcome_gradebook', 'on')
      get "/courses/#{@course.id}/grades/#{@student_1.id}"
      expect(f('#navpills')).not_to be_nil
      f('a[href="#outcomes"]').click
      wait_for_ajaximations
      expect(ff('#outcomes li.outcome').count).to eq @course.learning_outcome_links.count
    end

    context 'student view' do
      it "should be available to student view student", priority: "1", test_id: 229448 do
        @fake_student = @course.student_view_student
        @fake_submission = @first_assignment.submit_homework(@fake_student, :body => 'fake student submission')
        @first_assignment.grade_student(@fake_student, :grade => 8)

        enter_student_view
        get "/courses/#{@course.id}/grades"

        expect(f("#submission_#{@first_assignment.id} .grade")).to include_text "8"
      end
    end
  end

  context "as a student" do
    before(:each) do
      user_session(@student_1)
    end

    it "should allow student to test modifying grades", priority: "1", test_id: 229660 do
      skip_if_chrome('issue with blur')
      get "/courses/#{@course.id}/grades"

      Assignment.any_instance.expects(:find_or_create_submission).twice.returns(@submission)

      #check initial total
      expect(f('#submission_final-grade .assignment_score .grade').text).to eq '33.33%'

      edit_grade = lambda do |field, score|
        field.click
        set_value field.find_element(:css, 'input'), score.to_s
        driver.execute_script '$("#grade_entry").blur()'
      end

      assert_grade = lambda do |grade|
        wait_for_ajaximations
        expect(f('#submission_final-grade .grade')).to include_text grade.to_s
      end

      # test changing existing scores
      first_row_grade = f("#submission_#{@submission.assignment_id} .assignment_score .grade")
      edit_grade.call(first_row_grade, 4)
      assert_grade.call("40%")

      #using find with jquery to avoid caching issues

      # test changing unsubmitted scores
      third_grade = f("#submission_#{@third_assignment.id} .assignment_score .grade")
      edit_grade.call(third_grade, 10)
      assert_grade.call("96.97%")

      driver.execute_script '$("#grade_entry").blur()'
    end

    it "should display rubric on assignment", priority: "1", test_id: 229661 do
      get "/courses/#{@course.id}/grades"

      #click rubric
      f("#submission_#{@first_assignment.id} .toggle_rubric_assessments_link").click
      wait_for_ajaximations
      expect(fj('.rubric_assessments:visible .rubric_title')).to include_text(@rubric.title)
      expect(fj('.rubric_assessments:visible .rubric_total')).to include_text('2')

      #check rubric comment
      expect(fj('.assessment-comments:visible div').text).to eq 'cool, yo'
    end

    it "should not display rubric on muted assignment", priority: "1", test_id: 229662 do
      get "/courses/#{@course.id}/grades"

      @first_assignment.muted = true
      @first_assignment.save!
      get "/courses/#{@course.id}/grades"

      expect(f("#submission_#{@first_assignment.id} .toggle_rubric_assessments_link")).not_to be_displayed
    end

    it "should not display letter grade score on muted assignment", priority: "1", test_id: 229663 do
      get "/courses/#{@course.id}/grades"

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
      expect(f('.score_value').text).to eq ''
    end

    it "should display assignment statistics", priority: "1", test_id: 229664 do
      5.times do
        s = student_in_course(:active_all => true).user
        @first_assignment.grade_student(s, :grade => 4)
      end

      get "/courses/#{@course.id}/grades"
      f('.toggle_score_details_link').click

      score_row = f('#grades_summary tr.grade_details')

      expect(score_row).to include_text('Mean:')
      expect(score_row).to include_text('High: 4')
      expect(score_row).to include_text('Low: 3')
    end

    it "should display teacher comments", priority: "1", test_id: 229665 do
      get "/courses/#{@course.id}/grades"

      #check comment
      f('.toggle_comments_link').click
      comment_row = f('#grades_summary tr.comments_thread')
      expect(comment_row).to include_text('submission comment')
    end

    it 'should not display name of anonymous reviewer', priority: "1", test_id: 229666 do
      get "/courses/#{@course.id}/grades"

      f('.toggle_comments_link').click
      comment_row = f('#grades_summary tr.comments_thread')
      expect(comment_row).to include_text('Anonymous User')
    end

    it "should not show assignment statistics on assignments with less than 5 submissions", 
        priority: "1", test_id: 229667 do
      get "/courses/#{@course.id}/grades"
      expect(f("#content")).not_to contain_css("#grade_info_#{@first_assignment.id} .tooltip")
    end

    it "should not show assignment statistics on assignments when it is diabled on the course", 
        priority: "1", test_id: 229668 do
      # get up to a point where statistics can be shown
      5.times do
        s = student_in_course(:active_all => true).user
        @first_assignment.grade_student(s, :grade => 4)
      end

      # but then prevent them at the course level
      @course.update_attributes(:hide_distribution_graphs => true)

      get "/courses/#{@course.id}/grades"
      expect(f("#content")).not_to contain_css("#grade_info_#{@first_assignment.id} .tooltip")
    end

    it "should show rubric even if there are no comments", priority: "1", test_id: 229669 do
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
      expect(fj('.rubric_assessments:visible .rubric_title')).to include_text(@rubric.title)
      expect(fj('.rubric_assessments:visible .rubric_total')).to include_text('2')

      #check rubric comment
      expect(fj('.assessment-comments:visible div').text).to eq 'not bad, not bad'
    end

    context "with outcome gradebook enabled" do
      before :once do
        Account.default.set_feature_flag!('student_outcome_gradebook', 'on')
      end

      before :each do
        @outcome_group ||= @course.root_outcome_group
        @outcome = @course.created_learning_outcomes.create!(:title => 'outcome')
        @outcome_group.add_outcome(@outcome)
      end

      it "should show the outcome gradebook", priority: "1", test_id: 229670 do
        get "/courses/#{@course.id}/grades/"
        expect(f('#navpills')).not_to be_nil
        f('a[href="#outcomes"]').click
        wait_for_ajaximations

        expect(ff('#outcomes li.outcome').count).to eq @course.learning_outcome_links.count
      end

      it "should show the outcome gradebook if the student is in multiple sections", priority: "1", test_id: 229671 do
        @other_section = @course.course_sections.create(:name => "the other section")
        @course.enroll_student(@student_1, :section => @other_section, :allow_multiple_enrollments => true)

        get "/courses/#{@course.id}/grades/"
        expect(f('#navpills')).not_to be_nil
        f('a[href="#outcomes"]').click
        wait_for_ajaximations

        expect(ff('#outcomes li.outcome').count).to eq @course.learning_outcome_links.count
      end
    end
  end

  context "as an observer" do
    it "should allow observers to see grades of all enrollment associations", priority: "1", test_id: 229883 do
      @obs = user_model(:name => "Observer")
      e1 = @course.observer_enrollments.create(:user => @obs, :workflow_state => "active")
      e1.associated_user = @student_1
      e1.save!
      e2 = @course.observer_enrollments.create(:user => @obs, :workflow_state => "active")
      e2.associated_user = @student_2
      e2.save!

      user_session(@obs)
      get "/courses/#{@course.id}/grades"

      expect(f("#observer_user_url")).to be_displayed
      expect(f("#observer_user_url option[selected]")).to include_text "Student 1"
      expect(f("#submission_#{@submission.assignment_id} .grade")).to include_text "3"

      click_option("#observer_user_url", "Student 2")
      wait_for_ajaximations

      expect(f("#observer_user_url")).to be_displayed
      expect(f("#observer_user_url option[selected]")).to include_text "Student 2"
      expect(f("#submission_#{@submission.assignment_id} .grade")).to include_text "4"

      click_option("#observer_user_url", "Student 1")
      wait_for_ajaximations

      expect(f("#observer_user_url")).to be_displayed
      expect(f("#observer_user_url option[selected]")).to include_text "Student 1"
      expect(f("#submission_#{@submission.assignment_id} .grade")).to include_text "3"
    end
  end
end
