require File.expand_path(File.dirname(__FILE__) + '/common')

describe "assignment rubrics" do
  it_should_behave_like "in-process server selenium tests"

  context "assignment rubrics as a teacher" do
    before (:each) do
      course_with_teacher_logged_in
    end

    def create_assignment_with_points(points)
      assignment_name = 'first test assignment'
      due_date = Time.now.utc + 2.days
      @group = @course.assignment_groups.create!(:name => "default")
      @assignment = @course.assignments.create(
          :name => assignment_name,
          :due_at => due_date,
          :points_possible => points,
          :assignment_group => @group
      )
      @assignment
    end

    it "should add a new rubric to assignment and verify points" do
      initial_points = 2.5
      rubric_name = 'new rubric'
      create_assignment_with_points(initial_points)
      get "/courses/#{@course.id}/assignments/#{@assignment.id}"

      f('.add_rubric_link').click
      set_value(f('.rubric_title input[name="title"]'), rubric_name)
      criterion_points = find_with_jquery('.criterion_points:visible')
      set_value(criterion_points, initial_points)
      criterion_points.send_keys(:return)
      driver.find_element(:id, 'grading_rubric').click
      wait_for_ajax_requests
      submit_form('#edit_rubric_form')
      wait_for_ajaximations
      rubric = Rubric.last
      rubric.data.first[:points].should eql(initial_points)
      rubric.data.first[:ratings].first[:points].should eql(initial_points)
      f('#rubrics .rubric .rubric_title .displaying .title').should include_text(rubric_name)

      #Commented out because we still want this test to run but this is the part where the bug is
      #BUG 7193 - Rubric total overwrites assignment total despite choosing to leave them different
      #get "/courses/#{@course.id}/assignments"
      #f('.points_text').should include_text(initial_points.to_s)
    end

    it "should carry decimal values through rubric to grading" do
      student_in_course
      @assignment = create_assignment_with_points(2.5)
      rubric_model(:title => 'new rubric', :data =>
          [{
          :description => "Some criterion",
          :points => 2.5,
          :id => 'crit1',
          :ratings =>
              [{:description => "Good", :points => 2.5, :id => 'rat1', :criterion_id => 'crit1'}]
          }], :description => 'new rubric description')
      @association = @rubric.associate_with(@assignment, @course, :purpose => 'grading', :use_for_grading => false)

      get "/courses/#{@course.id}/gradebook/speed_grader?assignment_id=#{@assignment.id}"
      wait_for_ajax_requests
      full_rubric_button =
          keep_trying_until do
            full_rubric_button = find_with_jquery('.toggle_full_rubric')
            full_rubric_button.should be_displayed
            full_rubric_button
          end
      full_rubric_button.click
      find_with_jquery('#rubric_holder .criterion:visible .rating').click
      f('#rubric_holder .save_rubric_button').click
      wait_for_ajaximations

      f('#rubric_summary_container .rubric_total').text.should == '2.5'
    end

    it "should import rubric to assignment" do
      create_assignment_with_points(2)

      outcome_with_rubric
      @rubric.associate_with(@course, @course, :purpose => 'grading')

      get "/courses/#{@course.id}/assignments/#{@assignment.id}"

      f('.add_rubric_link').click
      f('#rubric_new .editing .find_rubric_link').click
      wait_for_ajax_requests
      f('#rubric_dialog_'+@rubric.id.to_s+' .title').should include_text(@rubric.title)
      f('#rubric_dialog_'+@rubric.id.to_s+' .select_rubric_link').click
      wait_for_ajaximations
      f('#rubric_'+@rubric.id.to_s+' > thead .title').should include_text(@rubric.title)

    end

    it "should not adjust assignment points possible for grading rubric" do
      create_assignment_with_points(2)

      get "/courses/#{@course.id}/assignments/#{@assignment.id}"
      f("#full_assignment .points_possible").text.should == '2'

      f('.add_rubric_link').click
      driver.find_element(:id, 'grading_rubric').click
      submit_form('#edit_rubric_form')
      find_with_jquery('.ui-dialog-buttonset .ui-button:contains("Leave different")').click
      wait_for_ajaximations
      f('#rubrics span .rubric_total').text.should == '5'
      f("#full_assignment .points_possible").text.should == '2'
    end

    it "should adjust assignment points possible for grading rubric" do
      create_assignment_with_points(2)

      get "/courses/#{@course.id}/assignments/#{@assignment.id}"
      f("#full_assignment .points_possible").text.should == '2'

      f('.add_rubric_link').click
      driver.find_element(:id, 'grading_rubric').click
      submit_form('#edit_rubric_form')
      find_with_jquery('.ui-dialog-buttonset .ui-button:contains("Change")').click
      wait_for_ajaximations

      f('#rubrics span .rubric_total').text.should == '5'
      f("#full_assignment .points_possible").text.should == '5'
    end

    it "should not allow XSS attacks through rubric descriptions" do
      skip_if_ie('Unexpected page behavior')

      student = user_with_pseudonym :active_user => true,
                                    :username => "student@example.com",
                                    :password => "password"
      @course.enroll_user(student, "StudentEnrollment", :enrollment_state => 'active')

      @assignment = @course.assignments.create(:name => 'assignment with rubric')
      @rubric = Rubric.new(:title => 'My Rubric', :context => @course)
      @rubric.data = [
          {
              :points => 3,
              :description => "XSS Attack!",
              :long_description => "<b>This text should not be bold</b>",
              :id => 1,
              :ratings => [
                  {
                      :points => 3,
                      :description => "Rockin'",
                      :criterion_id => 1,
                      :id => 2
                  },
                  {
                      :points => 0,
                      :description => "Lame",
                      :criterion_id => 1,
                      :id => 3
                  }
              ]
          }
      ]
      @rubric.save!
      @rubric.associate_with(@assignment, @course, :purpose => 'grading')

      get "/courses/#{@course.id}/assignments/#{@assignment.id}"

      driver.find_element(:id, "rubric_#{@rubric.id}").find_element(:css, ".long_description_link").click
      f("#rubric_long_description_dialog div.displaying .long_description").
          text.should == "<b>This text should not be bold</b>"
      close_visible_dialog

      get "/courses/#{@course.id}/gradebook/speed_grader?assignment_id=#{@assignment.id}"

      f(".toggle_full_rubric").click
      wait_for_animations
      f('#criterion_1 .long_description_link').click
      keep_trying_until { driver.find_element(:id, 'rubric_long_description_dialog').should be_displayed }
      f("#rubric_long_description_dialog div.displaying .long_description").
          text.should == "<b>This text should not be bold</b>"
    end

    it "should follow learning outcome ignore_for_scoring" do
      student_in_course(:active_all => true)
      outcome_with_rubric
      @assignment = @course.assignments.create(:name => 'assignment with rubric')
      @association = @rubric.associate_with(@assignment, @course, :purpose => 'grading', :use_for_grading => true)
      @submission = @assignment.submit_homework(@student, {:url => "http://www.instructure.com/"})
      @rubric.data[0][:ignore_for_scoring] = '1'
      @rubric.points_possible = 5
      @rubric.instance_variable_set('@outcomes_changed', true)
      @rubric.save!
      @assignment.points_possible = 5
      @assignment.save!

      get "/courses/#{@course.id}/assignments/#{@assignment.id}/submissions/#{@student.id}"
      f('.assess_submission_link').click
      f('.total_points_holder .assessing').should include_text "out of 5"
      f("#rubric_#{@rubric.id} tbody tr:nth-child(2) .ratings td:nth-child(1)").click
      f('.rubric_total').should include_text "5"
      f('.save_rubric_button').click
      wait_for_ajaximations
      f('.grading_value').attribute(:value).should == "5"
    end

    def mark_rubric_for_grading(rubric, expect_confirmation)
      f("#rubric_#{rubric.id} .edit_rubric_link").click
      driver.switch_to.alert.accept if expect_confirmation
      find_with_jquery(".grading_rubric_checkbox:visible").click
      find_with_jquery(".save_button:visible").click
      wait_for_ajaximations
    end

    it "should allow multiple rubric associations for grading" do
      outcome_with_rubric
      @assignment1 = @course.assignments.create!(:name => "assign 1", :points_possible => @rubric.points_possible)
      @assignment2 = @course.assignments.create!(:name => "assign 2", :points_possible => @rubric.points_possible)

      @association1 = @rubric.associate_with(@assignment1, @course, :purpose => 'grading')
      @association2 = @rubric.associate_with(@assignment2, @course, :purpose => 'grading')

      get "/courses/#{@course.id}/assignments/#{@assignment1.id}"
      mark_rubric_for_grading(@rubric, true)

      get "/courses/#{@course.id}/assignments/#{@assignment2.id}"
      mark_rubric_for_grading(@rubric, true)

      @association1.reload.use_for_grading.should be_true
      @association1.rubric.id.should == @rubric.id
      @association2.reload.use_for_grading.should be_true
      @association2.rubric.id.should == @rubric.id
    end
  end

  context "assignment rubrics as a student" do
    before (:each) do
      course_with_student_logged_in
    end

    it "should properly show rubric criterion details for learning outcomes" do
      @assignment = @course.assignments.create(:name => 'assignment with rubric')
      outcome_with_rubric

      @rubric.associate_with(@assignment, @course, :purpose => 'grading')

      get "/courses/#{@course.id}/assignments/#{@assignment.id}"

      f("#rubrics .rubric_title").text.should == "My Rubric"
      f(".criterion_description .long_description_link").click
      f(".ui-dialog div.long_description").text.should == "This is awesome."
    end

    it "should show criterion comments" do
      # given
      comment = 'a comment'
      teacher_in_course(:course => @course)
      assignment = @course.assignments.create(:name => 'assignment with rubric')
      outcome_with_rubric
      association = @rubric.associate_with(assignment, @course, :purpose => 'grading')
      assessment = association.assess(:user => @student,
                                      :assessor => @teacher,
                                      :artifact => assignment.find_or_create_submission(@student),
                                      :assessment => {
                                        :assessment_type => 'grading',
                                        :"criterion_#{@rubric.criteria_object.first.id}" => {
                                        :points => 3,
                                          :comments => comment,
                                        }
                                      })
      # when
      get "/courses/#{@course.id}/assignments/#{assignment.id}/submissions/#{@student.id}"
      f('a.assess_submission_link').click
      # expect
      ee = ff('.criterion_comments')
      ee.first.should be_displayed
      ee.last.should_not be_displayed
    end
  end

  context "assignment rubrics as an designer" do
    before (:each) do
      course_with_designer_logged_in
    end

    it "should allow an designer to create a course rubric" do
      pending "Bug #7136 - Rubrics cannot be created by designers" do
        rubric_name = 'this is a new rubric'
        get "/courses/#{@course.id}/rubrics"

        expect {
          f('.add_rubric_link').click
          replace_content(f('.rubric_title input'), rubric_name)
          submit_form('#edit_rubric_form')
          wait_for_ajaximations
        }.to change(Rubric, :count).by(1)
        refresh_page
        f('#rubrics .title').text.should == rubric_name
      end
    end
  end
end
