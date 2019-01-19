#
# Copyright (C) 2012 - present Instructure, Inc.
#
# This file is part of Canvas.
#
# Canvas is free software: you can redistribute it and/or modify it under
# the terms of the GNU Affero General Public License as published by the Free
# Software Foundation, version 3 of the License.
#
# Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
# A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
# details.
#
# You should have received a copy of the GNU Affero General Public License along
# with this program. If not, see <http://www.gnu.org/licenses/>.

require_relative '../common'
require_relative '../helpers/rubrics_common'

describe "assignment rubrics" do
  include_context "in-process server selenium tests"
  include RubricsCommon

  context "assignment rubrics as a teacher" do
    before(:each) do
      course_with_teacher_logged_in
    end

    def create_assignment_with_points(points)
      assignment_name = 'first test assignment'
      due_date = Time.now.utc + 2.days
      @group = @course.assignment_groups.create!(name: "default")
      @assignment = @course.assignments.create(
          name: assignment_name,
          due_at: due_date,
          points_possible: points,
          assignment_group: @group
      )
      @assignment
    end

    def get(url)
      super
      # terrible... some rubric dom handlers get set after dom ready
      sleep 1 if url =~ %r{\A/courses/\d+/assignments/\d+\z}
    end

    def mark_rubric_for_grading(rubric, expect_confirmation, expect_dialog = true)
      f("#rubric_#{rubric.id} .edit_rubric_link").click
      driver.switch_to.alert.accept if expect_confirmation
      fj(".grading_rubric_checkbox:visible").click
      fj(".save_button:visible").click
      # If change points possible dialog box is present
      if expect_dialog
        f(' .ui-button:nth-of-type(1)').click
      end
      wait_for_ajaximations
    end

    it "should add a new rubric", priority: "2", test_id: 56587 do
      get "/courses/#{@course.id}/outcomes"
      expect_new_page_load{f(' .manage_rubrics').click}

      expect do
       f('.add_rubric_link').click
       f('#add_criterion_container a:nth-of-type(1)').click
       f('#add_criterion_button').click
       set_value(f('#edit_criterion_form .description'), 'criterion 1')
       f('.ui-dialog-buttonset .save_button').click
       wait_for_ajaximations
       f('#criterion_2 .add_rating_link_after').click

       expect(f('#flash_screenreader_holder')).to have_attribute("textContent", "New Rating Created")
       set_value(f('.rating_description'), 'rating 1')
       fj('.ui-dialog-buttonset:visible .save_button').click
       wait_for_ajaximations
       submit_form('#edit_rubric_form')
       wait_for_ajaximations
      end.to change(Rubric, :count).by(1)
      expect(f('.rubric_table tbody tr:nth-of-type(3) .description_title')).
                                to include_text('criterion 1')
      expect(f('.rubric_table tbody tr:nth-of-type(3) .ratings td:nth-of-type(2) .rating_description_value')).
          to include_text('rating 1')
    end

    it "should add a new rubric to assignment and verify points", priority: "1", test_id: 114341 do
      initial_points = 2.5
      rubric_name = 'new rubric'
      create_assignment_with_points(initial_points)
      get "/courses/#{@course.id}/assignments/#{@assignment.id}"
      f('.add_rubric_link').click
      check_element_has_focus(fj('.find_rubric_link:visible:first'))
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

    it "should verify existing rubrics", priority: "2", test_id: 114342 do
      outcome_with_rubric(title: 'Course Rubric')
      @rubric.associate_with(@course, @course, :purpose => 'grading')
      assignment_with_rubric(10, 'Assignment Rubric ')
      get "/courses/#{@course.id}/rubrics"
      expect(fln('Course Rubric')).to be_present
      expect(fln('Assignment Rubric')).to be_present
    end

    it "should use an existing rubric to use for grading", priority: "2", test_id: 114344 do
      skip_if_safari(:alert)
      assignment_with_rubric(10)
      course_rubric = outcome_with_rubric
      course_rubric.associate_with(@course, @course, purpose: 'grading')
      get "/courses/#{@course.id}/assignments/#{@assignment.id}"
      f(' .rubric_title .icon-edit').click
      driver.switch_to.alert.accept
      wait_for_ajaximations
      fln('Find a Rubric').click
      wait_for_ajaximations
      fln('My Rubric').click
      wait_for_ajaximations
      f('#rubric_dialog_'+course_rubric.id.to_s+' .select_rubric_link').click
      wait_for_ajaximations
      expect(f('#rubric_'+course_rubric.id.to_s+' .rubric_title .title')).to include_text(course_rubric.title)

      # Find the associated rubric for the assignment we just edited
      association = RubricAssociation.where(title: "first test assignment")
      assignment2 = @course.assignments.create!(name: "assign 2", points_possible: 10)
      association2 = course_rubric.associate_with(assignment2, @course, purpose: 'grading')

      get "/courses/#{@course.id}/assignments/#{@assignment.id}"
      mark_rubric_for_grading(course_rubric, true)

      get "/courses/#{@course.id}/assignments/#{assignment2.id}"
      mark_rubric_for_grading(course_rubric, true)

      expect(association[0].reload.use_for_grading).to be_truthy
      expect(association[0].rubric.id).to eq course_rubric.id
      expect(association2.reload.use_for_grading).to be_truthy
      expect(association2.rubric.id).to eq course_rubric.id
    end

    it "should carry decimal values through rubric to grading", priority: "2", test_id: 220315 do
      student_in_course
      assignment_with_rubric(2.5)

      get "/courses/#{@course.id}/gradebook/speed_grader?assignment_id=#{@assignment.id}"
      full_rubric_button = f('.toggle_full_rubric')
      expect(full_rubric_button).to be_displayed
      full_rubric_button.click
      set_value(f('td.criterion_points input'), '2.5')
      f('#rubric_holder .save_rubric_button').click

      expect(f("span[data-selenium='rubric_total']")).to include_text '2.5'
    end

    it "should import rubric to assignment", priority: "1", test_id: 220317 do
      create_assignment_with_points(2)

      outcome_with_rubric
      @rubric.associate_with(@course, @course, purpose: 'grading')

      get "/courses/#{@course.id}/assignments/#{@assignment.id}"

      f('.add_rubric_link').click
      f('#rubric_new .editing .find_rubric_link').click
      wait_for_ajax_requests
      expect(f('#rubric_dialog_'+@rubric.id.to_s+' .title')).to include_text(@rubric.title)
      f('#rubric_dialog_'+@rubric.id.to_s+' .select_rubric_link').click
      wait_for_ajaximations
      expect(f('#rubric_'+@rubric.id.to_s+' .rubric_title .title')).to include_text(@rubric.title)
    end

    it "should not adjust points when importing an outcome to an assignment", priority: "1", test_id: 2896223 do
      skip_if_safari(:alert)
      create_assignment_with_points(2)

      outcome_with_rubric
      @rubric.associate_with(@course, @course, purpose: 'grading')

      get "/courses/#{@course.id}/assignments/#{@assignment.id}"

      # click on the + Rubric button
      f('.add_rubric_link').click
      wait_for_ajaximations
      # click on the Find Outcome link, which brings up a dialog
      f('#rubric_new .editing .find_outcome_link').click
      wait_for_ajax_requests
      # confirm the expected outcome is listed in the dialog
      expect(f('#import_dialog .ellipsis span')).to include_text(@outcome.title)
      # select the first outcome
      f('.outcome-link').click
      wait_for_ajaximations
      # click on the Import button
      f('.ui-dialog .btn-primary').click
      wait_for_ajaximations
      # pts should not be editable
      expect(f('#rubric_new .learning_outcome_criterion .points_form .editing').displayed?).to be_falsey
      expect(f('#rubric_new .learning_outcome_criterion .points_form .displaying').displayed?).to be_truthy
    end

    it "should not adjust assignment points possible for grading rubric", priority: "1", test_id: 220324 do
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

    it "should adjust assignment points possible for grading rubric", priority: "1", test_id: 220326 do
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

    it "should not allow XSS attacks through rubric descriptions", priority: "2", test_id: 220327 do
      student = user_with_pseudonym active_user: true,
                                    username: "student@example.com",
                                    password: "password"
      @course.enroll_user(student, "StudentEnrollment", enrollment_state: 'active')

      @assignment = @course.assignments.create(name: 'assignment with rubric')
      @rubric = Rubric.new(title: 'My Rubric', context: @course)
      @rubric.data = [
          {
              points: 3,
              description: "XSS Attack!",
              long_description: "<b>This text should not be bold</b>",
              id: 1,
              ratings: [
                  {
                      points: 3,
                      description: "Rockin'",
                      criterion_id: 1,
                      id: 2
                  },
                  {
                      points: 0,
                      description: "Lame",
                      criterion_id: 1,
                      id: 3
                  }
              ]
          }
      ]
      @rubric.save!
      @rubric.associate_with(@assignment, @course, purpose: 'grading')

      get "/courses/#{@course.id}/assignments/#{@assignment.id}"

      expect(f("#rubric_#{@rubric.id} .long_description").text).
        to eq "<b>This text should not be bold</b>"

      get "/courses/#{@course.id}/gradebook/speed_grader?assignment_id=#{@assignment.id}"

      f(".toggle_full_rubric").click
      wait_for_ajaximations
      fj("span:contains('view longer description')").find_element(:xpath, './parent::button').click
      expect(f("span[aria-label='Criterion Long Description']")).to include_text("This text should not be bold")
    end

    it "should follow learning outcome ignore_for_scoring", priority: "2", test_id: 220328 do
      student_in_course(active_all: true)
      outcome_with_rubric
      @assignment = @course.assignments.create(name: 'assignment with rubric')
      @association = @rubric.associate_with(@assignment, @course, purpose: 'grading', use_for_grading: true)
      @submission = @assignment.submit_homework(@student, {url: "http://www.instructure.com/"})
      @rubric.data[0][:ignore_for_scoring] = '1'
      @rubric.points_possible = 5
      @rubric.save!
      @assignment.points_possible = 5
      @assignment.save!

      get "/courses/#{@course.id}/assignments/#{@assignment.id}/submissions/#{@student.id}"
      f('.assess_submission_link').click
      wait_for_animations
      expect(f("span[data-selenium='rubric_total']")).to include_text "0 out of 5"
      fj("span:contains('Amazing'):visible").click
      expect(f("span[data-selenium='rubric_total']")).to include_text "5 out of 5"
      scroll_into_view('.save_rubric_button')
      f('.save_rubric_button').click
      expect(f('.grading_value')).to have_attribute(:value, '5')
    end

    it "should properly manage rubric focus on submission preview page", priority: "2", test_id: 220329 do
      student_in_course(:active_all => true)
      outcome_with_rubric
      @assignment = @course.assignments.create(:name => 'assignment with rubric')
      @association = @rubric.associate_with(@assignment, @course, purpose: 'grading', use_for_grading: true)
      @submission = @assignment.submit_homework(@student, {url: "http://www.instructure.com/"})
      get "/courses/#{@course.id}/assignments/#{@assignment.id}/submissions/#{@student.id}"
      wait_for_ajaximations
      f(".assess_submission_link").click
      wait_for_ajaximations
      check_element_has_focus(f(".hide_rubric_link"))
      driver.action.key_down(:shift)
        .send_keys(:tab)
        .key_up(:shift)
        .perform
      check_element_has_focus(f(".save_rubric_button"))
      driver.action.send_keys(:tab).perform
      check_element_has_focus(f(".hide_rubric_link"))
      f(".hide_rubric_link").click
      wait_for_ajaximations
      check_element_has_focus(f(".assess_submission_link"))
    end

    it "should allow multiple rubric associations for grading", priority: "1", test_id: 220330 do
      outcome_with_rubric
      @assignment1 = @course.assignments.create!(name: "assign 1", points_possible: @rubric.points_possible)
      @assignment2 = @course.assignments.create!(name: "assign 2", points_possible: @rubric.points_possible)

      @association1 = @rubric.associate_with(@assignment1, @course, purpose: 'grading')
      @association2 = @rubric.associate_with(@assignment2, @course, purpose: 'grading')

      get "/courses/#{@course.id}/assignments/#{@assignment1.id}"
      mark_rubric_for_grading(@rubric, true, false)

      get "/courses/#{@course.id}/assignments/#{@assignment2.id}"
      mark_rubric_for_grading(@rubric, true, false)

      expect(@association1.reload.use_for_grading).to be_truthy
      expect(@association1.rubric.id).to eq @rubric.id
      expect(@association2.reload.use_for_grading).to be_truthy
      expect(@association2.rubric.id).to eq @rubric.id
    end

    it "shows status of 'use_for_grading' properly", priority: "1", test_id: 220331 do
      outcome_with_rubric
      @assignment1 = @course.assignments.create!(
        name: "assign 1",
        points_possible: @rubric.points_possible
      )
      @association1 = @rubric.associate_with(
        @assignment1,
        @course,
        purpose: 'grading'
      )

      get "/courses/#{@course.id}/assignments/#{@assignment1.id}"
      mark_rubric_for_grading(@rubric, false, false)

      f("#rubric_#{@rubric.id} .edit_rubric_link").click
      expect(is_checked(".grading_rubric_checkbox:visible")).to be_truthy
    end

    it "allows user to set a long description", priority: "1", test_id: 220341 do
      assignment_with_editable_rubric(10, 'Assignment Rubric')

      get "/courses/#{@assignment.course.id}/assignments/#{@assignment.id}"

      f('.rubric_title .icon-edit').click
      wait_for_ajaximations

      hover_and_click('.criterion:nth-of-type(1) tbody tr td:nth-of-type(1) .edit_rating_link')
      wait_for_ajaximations

      set_value(f('#edit_rating_form .rating_long_description'), 'long description')

      f('.ui-dialog-buttonset .save_button').click
      wait_for_ajaximations
      submit_form('#edit_rubric_form')
      wait_for_ajaximations

      expect(fj('.criterion:visible .rating_long_description')).to include_text "long description"
    end

    it "deletes new criterion when user cancels creation", priority: "1", test_id: 220342 do
      assignment_with_editable_rubric(10, 'Assignment Rubric')

      get "/courses/#{@assignment.course.id}/assignments/#{@assignment.id}"

      f('.rubric_title .icon-edit').click
      wait_for_ajaximations

      expect(ffj(".criterion:visible").count).to eq 1
      f('#add_criterion_container a:nth-of-type(1)').click
      f('#add_criterion_button').click
      wait_for_ajaximations

      f('.ui-dialog-buttonset .cancel_button').click
      wait_for_ajaximations

      expect(ffj(".criterion:visible").count).to eq 1
    end

    context "ranged ratings" do
      before(:each) do
        @course.account.root_account.enable_feature!(:rubric_criterion_range)
        @assignment = @course.assignments.create(name: 'assignment with rubric')
        outcome_with_rubric
        @rubric.associate_with(@assignment, @course, purpose: 'grading')
      end

      it "should hide range option when using custom ratings", priority: "1", test_id: 220336 do
        get "/courses/#{@course.id}/assignments/#{@assignment.id}"

        f(' .rubric_title .icon-edit').click
        wait_for_ajaximations

        expect(ffj(".criterion_use_range:visible").count).to eq 1
        f('.rubric_custom_rating').click
        wait_for_ajaximations

        expect(f(".rubric_container")).not_to contain_jqcss(".criterion_use_range:visible")
      end

      it "should hide range option when using learning outcomes", priority: "1", test_id: 220336 do
        get "/courses/#{@course.id}/assignments/#{@assignment.id}"

        f(' .rubric_title .icon-edit').click
        wait_for_ajaximations

        expect(f('.criterion:nth-of-type(1) .criterion_use_range_div').css_value('display')).to eq 'none'
      end

      it "should show min points when range is selected", priority: "1", test_id: 220337 do
        get "/courses/#{@course.id}/assignments/#{@assignment.id}"

        f(' .rubric_title .icon-edit').click
        wait_for_ajaximations

        fj('.criterion_use_range:visible').click()
        wait_for_ajaximations

        expect(ffj(".range_rating:visible").count).to eq 2
      end

      it "should adjust the min points of a rating and the neighboring max points", priority: "1", test_id: 220338 do
        @rubric.data[1][:criterion_use_range] = true
        @rubric.save!

        get "/courses/#{@course.id}/assignments/#{@assignment.id}"

        f(' .rubric_title .icon-edit').click
        wait_for_ajaximations

        # The min points of the rating being edited should start at 3.
        expect(ffj('.range_rating:visible .min_points')[0]).to include_text "3"

        # The max points of the rating to the right should start at 3.
        expect(ff('.criterion:nth-of-type(2) tbody tr td:nth-of-type(2) .points')[1]).to include_text "3"

        hover_and_click('.criterion:nth-of-type(2) tbody tr td:nth-of-type(1) .edit_rating_link')
        wait_for_ajaximations

        set_value(f('#edit_rating_form .min_points'), '2')

        f('.ui-dialog-buttonset .save_button').click
        wait_for_ajaximations
        submit_form('#edit_rubric_form')
        wait_for_ajaximations

        # The min points of the cell being edited should now be 2.
        expect(ffj('.range_rating:visible .min_points')[0]).to include_text "2"

        # The max points of the cell to the right should now be 2.
        expect(ff('.criterion:nth-of-type(3) .points')[1]).to include_text "2"

        # The min points of the cell to the right should not have changed.
        expect(ffj('.range_rating:visible .min_points')[1]).to include_text "0"
      end

      it "should display explicit rating when range is infinitely small", priority: "1", test_id: 220339 do
        @rubric.data[1][:criterion_use_range] = true
        @rubric.save!

        get "/courses/#{@course.id}/assignments/#{@assignment.id}"

        f(' .rubric_title .icon-edit').click
        wait_for_ajaximations

        range_rating_element = '.criterion:nth-of-type(2) tbody tr td:nth-of-type(1) .range_rating'
        expect(f(range_rating_element).css_value('display')).to eq 'inline'
        hover_and_click('.criterion:nth-of-type(2) tbody tr td:nth-of-type(1) .edit_rating_link')
        wait_for_ajaximations

        set_value(f('#edit_rating_form .min_points'), '2')
        set_value(f('#edit_rating_form input[name="points"]'), '2')

        f('.ui-dialog-buttonset .save_button').click
        wait_for_ajaximations

        range_rating_element = '.criterion:nth-of-type(3) tbody tr td:nth-of-type(1) .range_rating'
        expect(f(range_rating_element).css_value('display')).to eq 'none'
      end

      it "should cap the range expansion based on neighboring cells", priority: "1", test_id: 220340 do
        @rubric.data[1][:criterion_use_range] = true
        @rubric.save!

        get "/courses/#{@course.id}/assignments/#{@assignment.id}"

        f(' .rubric_title .icon-edit').click
        wait_for_ajaximations

        hover_and_click('.criterion:nth-of-type(2) tbody tr td:nth-of-type(2) .edit_rating_link')
        wait_for_ajaximations

        set_value(f('#edit_rating_form .min_points'), '-1')
        set_value(f('#edit_rating_form input[name="points"]'), '100')

        f('.ui-dialog-buttonset .save_button').click
        wait_for_ajaximations
        submit_form('#edit_rubric_form')
        wait_for_ajaximations

        # The max points of the cell being edited should now be 5.
        expect(ff('.criterion:nth-of-type(3) .points')[1]).to include_text "5"

        # The min points of the cell being edited should now be 0.
        expect(ff('.criterion:nth-of-type(3) .min_points')[1]).to include_text "0"
      end
    end

    context "non-scoring rubrics" do
      before(:each) do
        @assignment = @course.assignments.create(name: 'NSR assignment')
        outcome_with_rubric
        @rubric.associate_with(@assignment, @course, purpose: 'grading')
      end

      it "should create and edit a non-scoring rubric" do
        get "/courses/#{@course.id}/assignments/#{@assignment.id}"

        f(' .rubric_title .icon-edit').click
        wait_for_ajaximations

        # Hide points on rubric
        f('#hide_points').click
        wait_for_ajaximations
        rating_points_elements = ff('.points')
        rating_points_elements.each do |points|
          expect(points).not_to be_displayed
        end
        total_points_elements = ff('[class="total_points_holder toggle_for_hide_points "]')
        total_points_elements.each do |total_points|
          expect(total_points).not_to be_displayed
        end

        # Add rating
        ff('.add_rating_link_after')[4].click
        expect(fj('span:contains("Edit Rating")')).to be_present
        rating_score_fields = ff('#rating_form_score_label')
        rating_score_fields.each do |rating_score_field|
          expect(rating_score_field).not_to be_displayed
        end
        wait_for_ajaximations
        set_value(ff('#rating_form_title')[0], 'Test rating 1')
        set_value(ff('#rating_form_description')[0], 'Test description 1')
        fj('span:contains("Update Rating")').click
        wait_for_ajaximations

        expect(ff('[class="description rating_description_value"]')[11].text).to eq "Test rating 1"
        expect(ff('[class="rating_long_description small_description"]')[11].text).to eq "Test description 1"

        # Save rubric
        find_button("Update Rubric").click
        wait_for_ajaximations

        expect(ff('[class="description rating_description_value"]')[6].text).to eq "Test rating 1"
        expect(ff('[class="rating_long_description small_description"]')[6].text).to eq "Test description 1"
        rating_points_elements = ff('.points')
        rating_points_elements.each do |points|
          expect(points).not_to be_displayed
        end
      end
    end

    context "criterion copy" do
      before(:each) do
        @course.account.root_account.enable_feature!(:rubric_criterion_range)
        @assignment = @course.assignments.create(name: 'assignment with rubric')
        outcome_with_rubric
        @rubric.associate_with(@assignment, @course, purpose: 'grading')
      end

      it "should copy an existing criterion", priority: "1", test_id: 220342 do
        get "/courses/#{@course.id}/assignments/#{@assignment.id}"

        f(' .rubric_title .icon-edit').click
        wait_for_ajaximations

        f('#add_criterion_container a:nth-of-type(1)').click
        f('#criterion_duplicate_menu ul li:nth-of-type(2)').click
        wait_for_ajaximations
        f('.ui-dialog-buttonset .save_button').click

        wait_for_ajaximations

        expect(ffj('.criterion:visible .description_title')[2]).to include_text "no outcome row"
      end

      it "should copy an existing learning outcome", priority: "1", test_id: 220343 do
        get "/courses/#{@course.id}/assignments/#{@assignment.id}"

        f(' .rubric_title .icon-edit').click
        wait_for_ajaximations

        f('#add_criterion_container a:nth-of-type(1)').click
        f('#criterion_duplicate_menu ul li:nth-of-type(1)').click
        wait_for_ajaximations

        expect(ffj('.criterion:visible .description_title')[2]).to include_text "Outcome row"
      end
    end
  end

  context "assignment rubrics as a student" do
    before(:each) do
      course_with_student_logged_in
    end

    it "should properly show rubric criterion details for learning outcomes", priority: "2", test_id: 220332 do
      @assignment = @course.assignments.create(name: 'assignment with rubric')
      outcome_with_rubric

      @rubric.associate_with(@assignment, @course, purpose: 'grading')

      get "/courses/#{@course.id}/assignments/#{@assignment.id}"

      expect(f("#rubrics .rubric_title").text).to eq "My Rubric"
      f(".criterion_description .long_description_link").click
      expect(f(".ui-dialog div.long_description").text).to eq "This is awesome."
    end

    it "should show criterion comments and only render when necessary", priority: "2", test_id: 220333 do
      # given
      comment = 'a comment'
      teacher_in_course(course: @course)
      assignment = @course.assignments.create(name: 'assignment with rubric')
      outcome_with_rubric
      association = @rubric.associate_with(assignment, @course, purpose: 'grading')
      association.assess(user: @student,
                         assessor: @teacher,
                         artifact: assignment.find_or_create_submission(@student),
                         assessment: {
                             assessment_type: 'grading',
                             :"criterion_#{@rubric.criteria_object.first.id}" => {
                                 points: 3,
                                 comments: comment,
                             }
                         }
                         )
      # when
      get "/courses/#{@course.id}/assignments/#{assignment.id}/submissions/#{@student.id}"
      f('.assess_submission_link').click
      # expect
      comments = ff('.rubric-freeform')
      expect(comments.length).to eq 1
      expect(comments.first).to include_text(comment)
    end

    it "shouldn't show 'update description' button in long description dialog", priority: "2", test_id: 220334 do
      @assignment = @course.assignments.create(name: 'assignment with rubric')
      rubric_for_course
      @rubric.associate_with(@assignment, @course, purpose: 'grading')

      get "/courses/#{@course.id}/assignments/#{@assignment.id}"

      expect(f("#content")).to contain_css(".criterion_description .long_description")
      expect(f("#content")).not_to contain_jqcss(".criterion_description .long_description_link:visible")
      expect(f("#content")).not_to contain_jqcss(".criterion_description .edit_criterion_link:visible")
    end
  end

  context "assignment rubrics as an designer" do
    before(:each) do
      course_with_designer_logged_in
    end

    it "should allow a designer to create a course rubric", priority: "2", test_id: 220335 do
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
