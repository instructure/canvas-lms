require File.expand_path(File.dirname(__FILE__) + '/common')

describe "assignment rubrics" do
  include_examples "in-process server selenium tests"

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
      criterion_points = fj('.criterion_points:visible')
      set_value(criterion_points, initial_points)
      criterion_points.send_keys(:return)
      f('#grading_rubric').click
      wait_for_ajax_requests
      submit_form('#edit_rubric_form')
      wait_for_ajaximations
      rubric = Rubric.last
      expect(rubric.data.first[:points]).to eq initial_points
      expect(rubric.data.first[:ratings].first[:points]).to eq initial_points
      expect(f('#rubrics .rubric .rubric_title .displaying .title')).to include_text(rubric_name)
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
            full_rubric_button = fj('.toggle_full_rubric')
            expect(full_rubric_button).to be_displayed
            full_rubric_button
          end
      full_rubric_button.click
      fj('#rubric_holder .criterion:visible .rating').click
      f('#rubric_holder .save_rubric_button').click
      wait_for_ajaximations

      expect(f('#rubric_summary_container .rubric_total').text).to eq '2.5'
    end

    it "should import rubric to assignment" do
      create_assignment_with_points(2)

      outcome_with_rubric
      @rubric.associate_with(@course, @course, :purpose => 'grading')

      get "/courses/#{@course.id}/assignments/#{@assignment.id}"

      f('.add_rubric_link').click
      f('#rubric_new .editing .find_rubric_link').click
      wait_for_ajax_requests
      expect(f('#rubric_dialog_'+@rubric.id.to_s+' .title')).to include_text(@rubric.title)
      f('#rubric_dialog_'+@rubric.id.to_s+' .select_rubric_link').click
      wait_for_ajaximations
      expect(f('#rubric_'+@rubric.id.to_s+' .rubric_title .title')).to include_text(@rubric.title)
    end

    it "should not adjust assignment points possible for grading rubric" do
      create_assignment_with_points(2)

      get "/courses/#{@course.id}/assignments/#{@assignment.id}"
      expect(f("#assignment_show .points_possible").text).to eq '2'

      f('.add_rubric_link').click
      f('#grading_rubric').click
      submit_form('#edit_rubric_form')
      fj('.ui-dialog-buttonset .ui-button:contains("Leave different")').click
      wait_for_ajaximations
      expect(f('#rubrics span .rubric_total').text).to eq '5'
      expect(f("#assignment_show .points_possible").text).to eq '2'
    end

    it "should adjust assignment points possible for grading rubric" do
      create_assignment_with_points(2)

      get "/courses/#{@course.id}/assignments/#{@assignment.id}"
      expect(f("#assignment_show .points_possible").text).to eq '2'

      f('.add_rubric_link').click
      f('#grading_rubric').click
      submit_form('#edit_rubric_form')
      fj('.ui-dialog-buttonset .ui-button:contains("Change")').click
      wait_for_ajaximations

      expect(f('#rubrics span .rubric_total').text).to eq '5'
      expect(f("#assignment_show .points_possible").text).to eq '5'
    end

    it "should not allow XSS attacks through rubric descriptions" do
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

      f("#rubric_#{@rubric.id}").find_element(:css, ".long_description_link").click
      expect(f("#rubric_long_description_dialog div.displaying .long_description").
          text).to eq "<b>This text should not be bold</b>"
      close_visible_dialog

      get "/courses/#{@course.id}/gradebook/speed_grader?assignment_id=#{@assignment.id}"

      f(".toggle_full_rubric").click
      wait_for_ajaximations
      f('#criterion_1 .long_description_link').click
      keep_trying_until { expect(f('#rubric_long_description_dialog')).to be_displayed }
      expect(f("#rubric_long_description_dialog div.displaying .long_description").
          text).to eq "<b>This text should not be bold</b>"
    end

    it "should follow learning outcome ignore_for_scoring" do
      student_in_course(:active_all => true)
      outcome_with_rubric
      @assignment = @course.assignments.create(:name => 'assignment with rubric')
      @association = @rubric.associate_with(@assignment, @course, :purpose => 'grading', :use_for_grading => true)
      @submission = @assignment.submit_homework(@student, {:url => "http://www.instructure.com/"})
      @rubric.data[0][:ignore_for_scoring] = '1'
      @rubric.points_possible = 5
      @rubric.save!
      @assignment.points_possible = 5
      @assignment.save!

      get "/courses/#{@course.id}/assignments/#{@assignment.id}/submissions/#{@student.id}"
      f('.assess_submission_link').click
      expect(f('.total_points_holder .assessing')).to include_text "out of 5"
      f("#rubric_#{@rubric.id} tbody tr:nth-child(2) .ratings td:nth-child(1)").click
      expect(f('.rubric_total')).to include_text "5"
      f('.save_rubric_button').click
      wait_for_ajaximations
      expect(f('.grading_value')).to have_attribute(:value, '5')
    end

    def mark_rubric_for_grading(rubric, expect_confirmation)
      f("#rubric_#{rubric.id} .edit_rubric_link").click
      driver.switch_to.alert.accept if expect_confirmation
      fj(".grading_rubric_checkbox:visible").click
      fj(".save_button:visible").click
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

      expect(@association1.reload.use_for_grading).to be_truthy
      expect(@association1.rubric.id).to eq @rubric.id
      expect(@association2.reload.use_for_grading).to be_truthy
      expect(@association2.rubric.id).to eq @rubric.id
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

      expect(f("#rubrics .rubric_title").text).to eq "My Rubric"
      f(".criterion_description .long_description_link").click
      expect(f(".ui-dialog div.long_description").text).to eq "This is awesome."
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
      f('.assess_submission_link').click
      # expect
      ee = ff('.criterion_comments')
      expect(ee.first).to be_displayed
      expect(ee.last).not_to be_displayed
    end

    it "shouldn't show 'update description' button in long description dialog" do
      @assignment = @course.assignments.create(:name => 'assignment with rubric')
      rubric_for_course
      @rubric.associate_with(@assignment, @course, :purpose => 'grading')

      get "/courses/#{@course.id}/assignments/#{@assignment.id}"

      f(".criterion_description .long_description_link").click
      expect(fj('.ui-dialog .save_button:visible')).to be_nil
    end
  end

  context "assignment rubrics as an designer" do
    before (:each) do
      course_with_designer_logged_in
    end

    it "should allow a designer to create a course rubric" do
      rubric_name = 'this is a new rubric'
      get "/courses/#{@course.id}/rubrics"

      expect {
        f('.add_rubric_link').click
        replace_content(f('.rubric_title input'), rubric_name)
        submit_form('#edit_rubric_form')
        wait_for_ajaximations
      }.to change(Rubric, :count).by(1)
      refresh_page
      expect(f('#rubrics .title').text).to eq rubric_name
    end
  end
end
