require_relative '../../helpers/gradebook2_common'

describe "gradebook2 - concluded courses and enrollments" do
  include_context "in-process server selenium tests"
  include Gradebook2Common

  let!(:setup) { gradebook_data_setup }
  let(:conclude_student_1) { @student_1.enrollments.where(course_id: @course).first.conclude }
  let(:deactivate_student_1) { @student_1.enrollments.where(course_id: @course).first.deactivate }

  context "active course" do
    let(:gradebook_settings_for_course) do
      -> (teacher, course) do
        teacher.reload
          .preferences.fetch(:gradebook_settings, {})[course.id]
      end
    end

    it "persists settings for displaying inactive enrollments", priority: "2", test_id: 1372593 do
      get course_gradebook2_path(@course)
      f('#gradebook_settings').click
      wait_for_ajaximations
      expect { f('label[for="show_inactive_enrollments"]').click }
        .to change { gradebook_settings_for_course.call(@teacher, @course)}
        .from(nil)
        .to({
          "show_inactive_enrollments" => "true",
          "show_concluded_enrollments" => "false",
        })
    end

    it "persists settings for displaying concluded enrollments", priority: "2", test_id: 1372592 do
      get course_gradebook2_path(@course)
      f('#gradebook_settings').click
      wait_for_ajaximations
      expect { f('label[for="show_concluded_enrollments"]').click }
        .to change { gradebook_settings_for_course.call(@teacher, @course) }
        .from(nil)
        .to({
          "show_inactive_enrollments" => "false",
          "show_concluded_enrollments" => "true",
        })
    end

    it "does not show concluded enrollments by default", priority: "1", test_id: 210020 do
      conclude_student_1
      expect(@course.students.count).to eq @all_students.size - 1
      expect(@course.all_students.count).to eq @all_students.size
      get "/courses/#{@course.id}/gradebook2"
      expect(ff('.student-name')).to have_size @course.students.count
    end

    it "shows/hides concluded enrollments when checked/unchecked in settings cog", priority: "1", test_id: 164223 do
      conclude_student_1
      get "/courses/#{@course.id}/gradebook2"

      # show concluded
      expect_new_page_load do
        f('#gradebook_settings').click
        f('label[for="show_concluded_enrollments"]').click
      end
      expect(ff('.student-name')).to have_size @course.all_students.count

      # hide concluded
      expect_new_page_load do
        f('#gradebook_settings').click
        f('label[for="show_concluded_enrollments"]').click
      end
      expect(ff('.student-name')).to have_size @course.students.count
    end

    it "does not show inactive enrollments by default", priority: "1", test_id: 1102065 do
      deactivate_student_1
      expect(@course.students.count).to eq @all_students.size - 1
      expect(@course.all_students.count).to eq @all_students.size
      get "/courses/#{@course.id}/gradebook2"
      expect(ff('.student-name')).to have_size @course.students.count
    end

    it "shows/hides inactive enrollments when checked/unchecked in settings cog", priority: "1", test_id: 1102066 do
      deactivate_student_1
      get "/courses/#{@course.id}/gradebook2"

      # show deactivated
      expect_new_page_load do
        f('#gradebook_settings').click
        f('label[for="show_inactive_enrollments"]').click
      end
      expect(ff('.student-name')).to have_size @course.all_students.count


      # hide deactivated
      expect_new_page_load do
        f('#gradebook_settings').click
        f('label[for="show_inactive_enrollments"]').click
      end
      expect(ff('.student-name')).to have_size @course.students.count
    end
  end

  context "concluded course" do
    it "does not allow editing grades", priority: "1", test_id: 210027 do
      @course.complete!
      get "/courses/#{@course.id}/gradebook2"
      cell = f('#gradebook_grid .container_1 .slick-row:nth-child(1) .l2')
      expect(cell.text).to eq '10'
      cell.click
      expect(cell).not_to contain_css('.grade') # no input box for entry
    end
  end
end
