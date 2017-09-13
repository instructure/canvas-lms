#
# Copyright (C) 2017 - present Instructure, Inc.
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

require_relative '../pages/gradezilla_page'
require_relative '../pages/gradezilla_cells_page'
require_relative '../pages/gradezilla_grade_detail_tray_page'
require_relative '../../helpers/gradezilla_common'

describe 'Grade Detail Tray:' do
  include_context "in-process server selenium tests"
  include GradezillaCommon
  include_context "late_policy_course_setup"

  before(:once) do
    # create course with students, assignments, submissions and grades
    init_course_with_students(1)
    create_course_late_policy
    create_assignments
    make_submissions
    grade_assignments
  end

  context "status" do
    before(:each) do
      ENV["GRADEBOOK_DEVELOPMENT"] = 'true'
      user_session(@teacher)
      Gradezilla.visit(@course)
    end

    after(:each) { ENV.delete("GRADEBOOK_DEVELOPMENT") }

    it 'missing submission has missing-radiobutton selected' do
      Gradezilla::Cells.open_tray(@course.students[0], @a2)

      expect(Gradezilla::GradeDetailTray.is_radio_button_selected('missing')).to be true
    end

    it 'on-time submission has none-radiobutton selected' do
      Gradezilla::Cells.open_tray(@course.students[0], @a3)

      expect(Gradezilla::GradeDetailTray.is_radio_button_selected('none')).to be true
    end

    it 'excused submission has excused-radiobutton selected' do
      Gradezilla::Cells.open_tray(@course.students[0], @a4)

      expect(Gradezilla::GradeDetailTray.is_radio_button_selected('excused')).to be true
    end

    it 'updates status when excused-option is selected' do
      Gradezilla::Cells.open_tray(@course.students[0], @a2)
      Gradezilla::GradeDetailTray.change_status_to('excused')

      excuse_status = @course.students[0].submissions.find_by(assignment_id:@a2.id).excused

      expect(excuse_status).to be true
    end

    it 'updates status when none-option is selected' do
      Gradezilla::Cells.open_tray(@course.students[0], @a2)
      Gradezilla::GradeDetailTray.change_status_to('none')

      late_policy_status = @course.students[0].submissions.find_by(assignment_id:@a2.id).late_policy_status

      expect(late_policy_status).to eq 'none'
    end
  end

  context 'late status' do
    before(:each) do
      ENV["GRADEBOOK_DEVELOPMENT"] = 'true'
      user_session(@teacher)
      Gradezilla.visit(@course)
      Gradezilla::Cells.open_tray(@course.students[0], @a1)
    end

    after(:each) { ENV.delete("GRADEBOOK_DEVELOPMENT") }

    it 'late submission has late-radiobutton selected', test_id: 3196973, priority: '1' do
      expect(Gradezilla::GradeDetailTray.is_radio_button_selected('late')).to be true
    end

    it 'late submission has late-by days/hours' do
      late_by_days_value = ((@course.students[0].submissions.find_by(assignment_id:@a1.id).seconds_late)/86400.to_f).round(2)

      expect(Gradezilla::GradeDetailTray.fetch_late_by_value.to_f).to eq late_by_days_value
    end

    it 'late submission has late penalty' do
      late_penalty_value = "-" + @course.students[0].submissions.find_by(assignment_id:@a1.id).points_deducted.to_s

      # the data from rails and data from ui are not in the same format
      expect(Gradezilla::GradeDetailTray.late_penalty_text.to_f.to_s).to eq late_penalty_value
    end

    it 'late submission has final grade' do
      final_grade_value = @course.students[0].submissions.find_by(assignment_id:@a1.id).published_grade

      expect(Gradezilla::GradeDetailTray.final_grade_text).to eq final_grade_value
    end

    it 'updates score when late_by value changes' do
      Gradezilla::GradeDetailTray.edit_late_by_input(3)
      final_grade_value = @course.students[0].submissions.find_by(assignment_id:@a1.id).published_grade

      expect(final_grade_value).to eq "60"
      expect(Gradezilla::GradeDetailTray.final_grade_text).to eq "60"
      expect(Gradezilla::GradeDetailTray.late_penalty_text).to eq "-30"
    end
  end

  context 'navigation' do
    before(:each) do
      ENV['GRADEBOOK_DEVELOPMENT'] = 'true'
      user_session(@teacher)
    end
    after(:each) { ENV.delete("GRADEBOOK_DEVELOPMENT") }

    context 'with default ordering' do
      before(:each) do
        Gradezilla.visit(@course)
      end

      it 'speedgrader link navigates to speedgrader page' do
        Gradezilla::Cells.open_tray(@course.students[0], @a1)
        Gradezilla::GradeDetailTray.speedgrader_link.click

        expect(driver.current_url).to include "courses/#{@course.id}/gradebook/speed_grader?assignment_id=#{@a1.id}"
      end

      it 'clicking assignment name navigates to assignment page' do
        Gradezilla::Cells.open_tray(@course.students[0], @a1)
        Gradezilla::GradeDetailTray.assignment_link(@a1.name).click

        expect(driver.current_url).to include "courses/#{@course.id}/assignments/#{@a1.id}"
      end

      it 'assignment right arrow loads the next assignment in the tray' do
        Gradezilla::Cells.open_tray(@course.students[0], @a1)
        Gradezilla::GradeDetailTray.submission_tray_right_arrow_button.click

        expect(Gradezilla::GradeDetailTray.assignment_link(@a2.name)).to be_displayed
      end

      it 'assignment left arrow loads the previous assignment in the tray' do
        Gradezilla::Cells.open_tray(@course.students[0], @a2)
        Gradezilla::GradeDetailTray.submission_tray_left_arrow_button.click

        expect(Gradezilla::GradeDetailTray.assignment_link(@a1.name)).to be_displayed
      end

      it 'left arrow button is not present when leftmost assignment is selected' do
        Gradezilla::Cells.open_tray(@course.students[0], @a1)

        expect(Gradezilla::GradeDetailTray.submission_tray_full_content).
          not_to contain_css(Gradezilla::GradeDetailTray.submission_tray_left_arrow_selector)
      end

      it 'right arrow button is not present when rightmost assignment is selected' do
        Gradezilla::Cells.open_tray(@course.students[0], @a4)

        expect(Gradezilla::GradeDetailTray.submission_tray_full_content).
          not_to contain_css(Gradezilla::GradeDetailTray.submission_tray_right_arrow_selector)
      end
    end

    context 'when the rightmost column is an assignment column' do
      before(:each) do
        unless @teacher.preferences.key?(:gradebook_column_order)
          @teacher.preferences[:gradebook_column_order] = {}
        end

        @teacher.preferences[:gradebook_column_order][@course.id] = {
          sortType: 'custom',
          customOrder: [
            "assignment_#{@a1.id}",
            "assignment_#{@a2.id}",
            "assignment_group_#{@a1.assignment_group_id}",
            "assignment_#{@a3.id}",
            'total_grade',
            "assignment_#{@a4.id}"
          ]
        }
        @teacher.save!
        Gradezilla.visit(@course)
      end

      it 'clicking the left arrow loads the previous assignment in the tray' do
        Gradezilla::Cells.open_tray(@course.students[0], @a4)
        Gradezilla::GradeDetailTray.submission_tray_left_arrow_button.click

        expect(Gradezilla::GradeDetailTray.assignment_link(@a3.name)).to be_displayed
      end
    end
  end
end
