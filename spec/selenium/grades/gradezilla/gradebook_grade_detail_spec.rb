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
    init_course_with_students(2)
    create_course_late_policy
    create_assignments
    make_submissions
    grade_assignments
  end

  context "status" do
    before(:each) do
      user_session(@teacher)
      Gradezilla.visit(@course)
    end

    it 'missing submission has missing-radiobutton selected', priority: "1", test_id: 3337205 do
      Gradezilla::Cells.open_tray(@course.students.first, @a2)

      expect(Gradezilla::GradeDetailTray.is_radio_button_selected('missing')).to be true
    end

    it 'on-time submission has none-radiobutton selected', priority: "1", test_id: 3337203 do
      Gradezilla::Cells.open_tray(@course.students.first, @a3)

      expect(Gradezilla::GradeDetailTray.is_radio_button_selected('none')).to be true
    end

    it 'excused submission has excused-radiobutton selected', priority: "1", test_id: 3337204 do
      Gradezilla::Cells.open_tray(@course.students.first, @a4)

      expect(Gradezilla::GradeDetailTray.is_radio_button_selected('excused')).to be true
    end

    it 'updates status when excused-option is selected', priority: "1", test_id: 3337207 do
      Gradezilla::Cells.open_tray(@course.students.first, @a2)
      Gradezilla::GradeDetailTray.change_status_to('Excused')

      excuse_status = @course.students.first.submissions.find_by(assignment_id:@a2.id).excused

      expect(excuse_status).to be true
    end

    it 'updates status when none-option is selected', priority: "2", test_id: 3337208 do
      Gradezilla::Cells.open_tray(@course.students.first, @a2)
      Gradezilla::GradeDetailTray.change_status_to('None')

      late_policy_status = @course.students.first.submissions.find_by(assignment_id:@a2.id).late_policy_status

      expect(late_policy_status).to eq 'none'
    end

    it 'grade input is saved', priority: "1", test_id: 3369723 do
      Gradezilla::Cells.open_tray(@course.students.second, @a3)
      Gradezilla::GradeDetailTray.edit_grade(7)

      expect(Gradezilla::Cells.get_grade(@course.students.second, @a3)).to eq "7"
    end
  end

  context 'late status' do
    before(:each) do
      user_session(@teacher)
      Gradezilla.visit(@course)
      Gradezilla::Cells.open_tray(@course.students.first, @a1)
    end

    it 'late submission has late-radiobutton selected', test_id: 3337206, priority: '1' do
      expect(Gradezilla::GradeDetailTray.is_radio_button_selected('late')).to be true
    end

    it 'late submission has late-by days/hours', test_id: 3337209, priority: '1' do
      late_by_days_value = (@course.students.first.submissions.find_by(assignment_id:@a1.id).
        seconds_late/86400.to_f).round(2)

      expect(Gradezilla::GradeDetailTray.fetch_late_by_value.to_f).to eq late_by_days_value
    end

    it 'late submission has late penalty', test_id: 3337210, priority: '1' do
      late_penalty_value = "-" + @course.students.first.submissions.find_by(assignment_id:@a1.id).points_deducted.to_s

      # the data from rails and data from ui are not in the same format
      expect(Gradezilla::GradeDetailTray.late_penalty_text.to_f.to_s).to eq late_penalty_value
    end

    it 'late submission has final grade', test_id: 3415931, priority: '2' do
      final_grade_value = @course.students.first.submissions.find_by(assignment_id:@a1.id).published_grade

      expect(Gradezilla::GradeDetailTray.final_grade_text).to eq final_grade_value
    end

    it 'updates score when late_by value changes', test_id: 3337212, priority: '1' do
      Gradezilla::GradeDetailTray.edit_late_by_input(3)
      final_grade_value = @course.students.first.submissions.find_by(assignment_id:@a1.id).published_grade
      expect(final_grade_value).to eq "60"
      expect(Gradezilla::GradeDetailTray.final_grade_text).to eq "60"
      expect(Gradezilla::GradeDetailTray.late_penalty_text).to eq "-30"
    end
  end

  context 'navigation within tray' do
    before(:each) do
      user_session(@teacher)
    end

    context 'with default ordering' do
      before(:each) do
        Gradezilla.visit(@course)
      end

      it 'speedgrader link navigates to speedgrader page', test_id: 3337215, priority: '1' do
        Gradezilla::Cells.open_tray(@course.students[0], @a1)
        Gradezilla::GradeDetailTray.speedgrader_link.click

        expect(driver.current_url).to include "courses/#{@course.id}/gradebook/speed_grader?assignment_id=#{@a1.id}"
      end

      it 'clicking assignment name navigates to assignment page', test_id: 3337214, priority: '2' do
        Gradezilla::Cells.open_tray(@course.students.first, @a1)
        Gradezilla::GradeDetailTray.assignment_link(@a1.name).click

        expect(driver.current_url).to include "courses/#{@course.id}/assignments/#{@a1.id}"
      end

      it 'assignment right arrow loads the next assignment in the tray', test_id: 3337216, priority: '1' do
        Gradezilla::Cells.open_tray(@course.students.first, @a1)
        button = Gradezilla::GradeDetailTray.next_assignment_button
        keep_trying_until { button.click; true } # have to wait for InstUI animations

        expect(Gradezilla::GradeDetailTray.assignment_link(@a2.name)).to be_displayed
      end

      it 'assignment left arrow loads the previous assignment in the tray', test_id: 3337217, priority: '1' do
        Gradezilla::Cells.open_tray(@course.students.first, @a2)
        Gradezilla::GradeDetailTray.previous_assignment_button.click

        expect(Gradezilla::GradeDetailTray.assignment_link(@a1.name)).to be_displayed
      end

      it 'left arrow button is not present when leftmost assignment is selected', test_id: 3337219, priority: '2' do
        Gradezilla::Cells.open_tray(@course.students.first, @a1)

        expect(Gradezilla::GradeDetailTray.submission_tray_full_content).
          not_to contain_css('#assignment-carousel .left-arrow-button-container button')
      end

      it 'right arrow button is not present when rightmost assignment is selected', test_id: 3337218, priority: '2' do
        Gradezilla::Cells.open_tray(@course.students.first, @a4)

        expect(Gradezilla::GradeDetailTray.submission_tray_full_content).
          not_to contain_css('#assignment-carousel .right-arrow-button-container button')
      end

      it 'student right arrow navigates to next student', test_id: 3337223, priority: '1' do
        Gradezilla::Cells.open_tray(@course.students.first, @a1)
        button = Gradezilla::GradeDetailTray.next_student_button
        keep_trying_until { button.click; true } # have to wait for instUI Tray animation
        expect(Gradezilla::GradeDetailTray.student_link(@course.students.second.name)).to be_displayed
      end

      it 'student left arrow navigates to previous student', test_id: 3337224, priority: '1' do
        Gradezilla::Cells.open_tray(@course.students.second, @a1)
        button = Gradezilla::GradeDetailTray.previous_student_button
        keep_trying_until { button.click; true } # have to wait for instUI Tray animation

        expect(Gradezilla::GradeDetailTray.student_link(@course.students.first.name)).to be_displayed
      end

      it 'first student does not have left arrow', test_id: 3337226, priority: '1' do
        Gradezilla::Cells.open_tray(@course.students.first, @a1)

        expect(Gradezilla::GradeDetailTray.submission_tray_full_content).
          not_to contain_css(Gradezilla::GradeDetailTray.navigate_to_previous_student_selector)
      end

      it 'student name link navigates to student grades page', test_id: 3355448, priority: '2' do
        Gradezilla::Cells.open_tray(@course.students.first, @a1)
        Gradezilla::GradeDetailTray.student_link(@course.students.first.name).click

        expect(driver.current_url).to include "courses/#{@course.id}/grades/#{@course.students.first.id}"
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

      it 'clicking the left arrow loads the previous assignment in the tray', test_id: 3337220, priority: '2' do
        Gradezilla::Cells.open_tray(@course.students.first, @a4)
        button = Gradezilla::GradeDetailTray.previous_assignment_button
        keep_trying_until { button.click; true } # have to wait for instUI Tray animation


        expect(Gradezilla::GradeDetailTray.assignment_link(@a3.name)).to be_displayed
      end
    end
  end

  context "comments" do
    let(:comment_1) { "You are late1" }
    let(:comment_2) {"You are also late2"}

    before(:each) do
      user_session(@teacher)

      submission_comment_model({author: @teacher,
                                submission: @a1.find_or_create_submission(@course.students.first),
                                comment: comment_1})
      Gradezilla.visit(@course)
    end

    it "add a comment", test_id: 3339965, priority: '1' do
      Gradezilla::Cells.open_tray(@course.students.first, @a1)
      Gradezilla::GradeDetailTray.add_new_comment(comment_2)

      expect(Gradezilla::GradeDetailTray.comment(comment_2)).to be_displayed
    end

    it "delete a comment", test_id: 3339966, priority: '1' do
      skip_if_safari(:alert)
      Gradezilla::Cells.open_tray(@course.students.first, @a1)
      Gradezilla::GradeDetailTray.delete_comment(comment_1)

      # comment text is in a paragraph element and there is only one comment seeded
      expect(Gradezilla::GradeDetailTray.all_comments).not_to contain_css("p")
    end
  end
end
