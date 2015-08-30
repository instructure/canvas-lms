require File.expand_path(File.dirname(__FILE__) + '/common')
require File.expand_path(File.dirname(__FILE__) + '/helpers/grading_schemes_common')

describe "grading standards" do
  include_context "in-process server selenium tests"

  context "without Multiple Grading Periods" do

    it "should allow creating grading standards", priority: "1", test_id: 163993 do
      course_with_teacher_logged_in
      get "/courses/#{@course.id}/grading_standards"
      should_add_a_grading_scheme
    end

    it "should allow editing a grading standard", priority: "1", test_id: 210076 do
      course_with_teacher_logged_in
      get "/courses/#{@course.id}/grading_standards"
      should_edit_a_grading_scheme(@course, "/courses/#{@course.id}/grading_standards")
    end

    it "should allow deleting grading standards", priority: "1", test_id: 210112 do
      course_with_teacher_logged_in
      should_delete_a_grading_scheme(@course, "/courses/#{@course.id}/grading_standards")
    end

    it "should display correct info when multiple standards are added without refreshing page", priority: "1", test_id: 217598  do
      course_with_teacher_logged_in
      get "/courses/#{@course.id}/grading_standards"
      should_add_a_grading_scheme(name: "First Grading Standard")
      first_grading_standard = @new_grading_standard
      should_add_a_grading_scheme(name: "Second Grading Standard")
      second_grading_standard = @new_grading_standard
      expect(fj("#grading_standard_#{first_grading_standard.id} span:eq(1)").text).to eq("First Grading Standard")
      expect(fj("#grading_standard_#{second_grading_standard.id} span:eq(1)").text).to eq("Second Grading Standard")
    end

    it "should allow setting a grading standard for an assignment", priority: "1", test_id: 217599 do
      course_with_teacher_logged_in

      @assignment = @course.assignments.create!(:title => "new assignment")
      @standard = @course.grading_standards.create!(:title => "some standard", :standard_data => {:a => {:name => 'A', :value => '95'}, :b => {:name => 'B', :value => '80'}, :f => {:name => 'F', :value => ''}})

      get "/courses/#{@course.id}/assignments/#{@assignment.id}/edit"
      form = f("#edit_assignment_form")
      f("#assignment_points_possible").clear()
      f("#assignment_points_possible").send_keys("1")
      click_option('#assignment_grading_type', "Letter Grade")
      expect(f('.edit_letter_grades_link')).to be_displayed
      f('.edit_letter_grades_link').click

      dialog = f("#edit_letter_grades_form")
      expect(dialog.find_elements(:css, ".grading_standard_row").select(&:displayed?).length).to eq 12
      expect(dialog.find_elements(:css, ".grading_standard_row").select(&:displayed?).map { |e| e.find_element(:css, ".name").text }).to eq ["A", "A-", "B+", "B", "B-", "C+", "C", "C-", "D+", "D", "D-", "F"]

      dialog.find_element(:css, ".find_grading_standard_link").click
      keep_trying_until { expect(f(".find_grading_standard")).to have_class("loaded") }
      expect(dialog.find_element(:css, ".find_grading_standard")).to be_displayed
      expect(dialog.find_element(:css, ".display_grading_standard")).not_to be_displayed
      dialog.find_element(:css, ".cancel_find_grading_standard_link").click
      expect(dialog.find_element(:css, ".find_grading_standard")).not_to be_displayed
      expect(dialog.find_element(:css, ".display_grading_standard")).to be_displayed
      dialog.find_element(:css, ".find_grading_standard_link").click

      expect(dialog.find_elements(:css, ".grading_standard_select .title")[-1].text).to eq @standard.title
      dialog.find_elements(:css, ".grading_standard_select")[-1].click
      expect(dialog.find_element(:css, "#grading_standard_brief_#{@standard.id}")).to be_displayed
      dialog.find_element(:css, "#grading_standard_brief_#{@standard.id} .select_grading_standard_link").click
      expect(dialog.find_element(:css, "#grading_standard_brief_#{@standard.id}")).not_to be_displayed
      expect(dialog.find_element(:css, ".display_grading_standard")).to be_displayed
      expect(dialog.find_element(:css, ".standard_title .title").text).to eq @standard.title

      dialog.find_element(:css, ".done_button").click
      expect_new_page_load { submit_form('#edit_assignment_form') }

      expect(@assignment.reload.grading_standard_id).to eq @standard.id
    end

    it "should allow setting a grading standard for a course", priority: "1", test_id: 217600 do
      course_with_teacher_logged_in

      @standard = @course.grading_standards.create!(:title => "some standard", :standard_data => {:a => {:name => 'A', :value => '95'}, :b => {:name => 'B', :value => '80'}, :f => {:name => 'F', :value => ''}})

      get "/courses/#{@course.id}/settings"
      form = f("#course_form")
      form.find_element(:css, "#course_grading_standard_enabled").click
      expect(is_checked('#course_form #course_grading_standard_enabled')).to be_truthy

      expect(form.find_element(:css, ".edit_letter_grades_link")).to be_displayed
      form.find_element(:css, ".edit_letter_grades_link").click

      dialog = f("#edit_letter_grades_form")
      expect(dialog.find_elements(:css, ".grading_standard_row").select(&:displayed?).length).to eq(12)
      expect(dialog.find_elements(:css, ".grading_standard_row").select(&:displayed?).map { |e| e.find_element(:css, ".name").text }).to eq ["A", "A-", "B+", "B", "B-", "C+", "C", "C-", "D+", "D", "D-", "F"]

      dialog.find_element(:css, ".find_grading_standard_link").click
      keep_trying_until { expect(f(".find_grading_standard")).to have_class("loaded") }
      expect(dialog.find_elements(:css, ".grading_standard_select .title")[-1].text).to eq @standard.title
      dialog.find_elements(:css, ".grading_standard_select")[-1].click
      expect(standard_brief = dialog.find_element(:css, "#grading_standard_brief_#{@standard.id}")).to be_displayed
      rows = standard_brief.find_elements(:css, '.details_row')
      expect(rows.shift['class']).to match /blank/
      expect(rows.length).to eq @standard.data.length
      rows.each_with_index do |r, idx|
        expect(r.find_element(:css, '.name').text).to eq @standard.data[idx].first
        expect(r.find_element(:css, '.value').text).to eq(idx == 0 ? "100" : "< #{@standard.data[idx - 1].last * 100}")
        expect(r.find_element(:css, '.next_value').text).to eq "#{@standard.data[idx].last * 100}"
      end
      dialog.find_element(:css, "#grading_standard_brief_#{@standard.id} .select_grading_standard_link").click
      expect(dialog.find_element(:css, "#grading_standard_brief_#{@standard.id}")).not_to be_displayed
      expect(dialog.find_element(:css, ".display_grading_standard")).to be_displayed
      expect(dialog.find_element(:css, ".standard_title .title").text).to eq @standard.title

      expect(dialog.find_element(:css, ".remove_grading_standard_link")).to be_displayed
      dialog.find_element(:css, ".remove_grading_standard_link").click
      driver.switch_to.alert.accept
      driver.switch_to.default_content
      keep_trying_until { !dialog.displayed? }

      expect(is_checked('#course_form #course_grading_standard_enabled')).to be_falsey
    end

    it "should extend ranges to fractional values at the boundary with the next range", priority: "1", test_id: 217597 do
      student = user(:active_all => true)
      course_with_teacher_logged_in(:active_all => true)
      @course.enroll_student(student).accept!
      @course.update_attribute :grading_standard_id, 0
      @course.assignment_groups.create!
      @assignment = @course.assignments.create!(:title => "new assignment", :points_possible => 1000, :assignment_group => @course.assignment_groups.first, :grading_type => 'points')
      @assignment.grade_student(student, :grade => 899)
      get "/courses/#{@course.id}/grades/#{student.id}"
      grading_scheme = driver.execute_script "return ENV.grading_scheme"
      expect(grading_scheme[2][0]).to eq 'B+'
      expect(f("#right-side .final_grade .grade").text).to eq '89.9%'
      expect(f("#final_letter_grade_text").text).to eq 'B+'
    end

    it "should allow editing the standard again without reloading the page", priority: "1", test_id: 217601 do
      user_session(account_admin_user)
      @standard = simple_grading_standard(Account.default)
      get("/accounts/#{Account.default.id}/grading_standards")
      std = keep_trying_until { f("#grading_standard_#{@standard.id}") }
      std.find_element(:css, ".edit_grading_standard_link").click
      std.find_element(:css, "button.save_button").click
      wait_for_ajax_requests
      std = keep_trying_until { f("#grading_standard_#{@standard.id}") }
      std.find_element(:css, ".edit_grading_standard_link").click
      std.find_element(:css, "button.save_button")
      wait_for_ajax_requests
      expect(@standard.reload.data.length).to eq 3
    end
  end

  context "with Multiple Grading Periods enabled" do

    it "should contain a tab for grading schemes and grading periods", priority: "1", test_id: 217602 do
      course_with_teacher_logged_in
      should_contain_a_tab_for_grading_schemes_and_periods("/courses/#{@course.id}/grading_standards")
    end
  end
end
