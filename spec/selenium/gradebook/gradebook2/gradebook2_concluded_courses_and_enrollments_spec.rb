require_relative '../../helpers/gradebook2_common'

describe "gradebook2 - concluded courses and enrollments" do
  include_context "in-process server selenium tests"
  include Gradebook2Common

  let!(:setup) { gradebook_data_setup }

  context "active course" do
    it "does not show concluded enrollments in active courses by default", priority: "1", test_id: 210020 do
      @student_1.enrollments.where(course_id: @course).first.conclude

      expect(@course.students.count).to eq @all_students.size - 1
      expect(@course.all_students.count).to eq @all_students.size

      get "/courses/#{@course.id}/gradebook2"

      expect(ff('.student-name').count).to eq @course.students.count

      # show concluded
      expect_new_page_load do
        f('#gradebook_settings').click
        f('label[for="show_concluded_enrollments"]').click
      end
      wait_for_ajaximations

      expect(ff('.student-name').count).to eq @course.all_students.count

      # hide concluded
      expect_new_page_load do
        f('#gradebook_settings').click
        f('label[for="show_concluded_enrollments"]').click
      end
      wait_for_ajaximations

      expect(ff('.student-name').count).to eq @course.students.count
    end

    it "does not show inactive enrollments by default and they can be toggled", priority: "1" do
      @student_1.enrollments.where(course_id: @course).first.deactivate

      expect(@course.students.count).to eq @all_students.size - 1
      expect(@course.all_students.count).to eq @all_students.size

      get "/courses/#{@course.id}/gradebook2"

      expect(ff('.student-name').count).to eq @course.students.count

      # show deactivated
      expect_new_page_load do
        f('#gradebook_settings').click
        f('label[for="show_inactive_enrollments"]').click
      end
      wait_for_ajaximations

      expect(ff('.student-name').count).to eq @course.all_students.count

      # hide deactivated
      expect_new_page_load do
        f('#gradebook_settings').click
        f('label[for="show_inactive_enrollments"]').click
      end
      wait_for_ajaximations

      expect(ff('.student-name').count).to eq @course.students.count
    end

    it "should not throw an error when setting the default grade when concluded enrollments exist" do
      skip("bug 7413 - Error assigning default grade when one student's enrollment has been concluded.")
      conclude_and_unconclude_course
      3.times { student_in_course }

      get "/courses/#{@course.id}/gradebook2"


      # TODO: when show concluded enrollments fix goes in we probably have to add that code right here
      # for the test to work correctly

      set_default_grade(2, 5)
      grade_grid = f('#gradebook_grid')
      @course.student_enrollments.each_with_index do |e, n|
        next if e.completed?
        expect(find_slick_cells(n, grade_grid)[2].text).to eq 5
      end
    end
  end

  context "concluded course" do
    before do
      @course.complete!
      get "/courses/#{@course.id}/gradebook2"
    end

    it "should show concluded enrollments in concluded courses by default", priority: "1", test_id: 210021 do
      expect(ff('.student-name').count).to eq @course.all_students.count

      # the checkbox should fire an alert rather than changing to not showing concluded
      expect_fired_alert do
        f('#gradebook_settings').click
        f('label[for="show_concluded_enrollments"]').click
      end
      expect(ff('.student-name').count).to eq @course.all_students.count
    end

    it "does not allow editing grades", priority: "1", test_id: 210027 do
      cell = f('#gradebook_grid .container_1 .slick-row:nth-child(1) .l2')
      expect(cell.text).to eq '10'
      cell.click
      expect(f('.grade', cell)).to be_nil # no input box for entry
    end
  end
end
