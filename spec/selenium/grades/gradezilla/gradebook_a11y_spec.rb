#
# Copyright (C) 2016 - present Instructure, Inc.
#
# This file is part of Canvas.
#
# Canvas is free software: you can redistribute it and/or modify it under
# the terms of the GNU Affero General Public License as published by the Free
# Software Foundation, version 3 of the License.
#
# Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; wthout even the implied warranty of MERCHANTABILITY or FITNESS FOR
# A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
# details.
#
# You should have received a copy of the GNU Affero General Public License along
# with this program. If not, see <http://www.gnu.org/licenses/>

require_relative '../../helpers/gradezilla_common'
require_relative '../../helpers/color_common'
require_relative '../pages/gradezilla_page'
require_relative '../pages/gradezilla_cells_page'

describe "Gradezilla" do
  include_context "in-process server selenium tests"
  include GradezillaCommon
  include ColorCommon

  let(:extra_setup) { }
  let(:students) { @course.students }

  before(:once) { gradebook_data_setup }

  before do
    Account.default.set_feature_flag!('new_gradebook', 'on')
    extra_setup
    user_session(@teacher)
  end

  context "export menu" do
    before do
      Gradezilla.visit(@course)
      Gradezilla.open_action_menu
    end

    it "moves focus to Actions menu trigger button during current export", priority: "2", test_id: 720459 do
      Gradezilla.action_menu_item_selector("export").click

      expect(current_active_element.tag_name).to eq('button')
      expect(current_active_element.text).to eq('Actions')
    end

    context "when a csv already exists" do
      let(:extra_setup) do
        attachment = @course.attachments.create!(uploaded_data: default_uploaded_data)
        progress = @course.progresses.new(tag: 'gradebook_export')
        progress.workflow_state = 'completed'
        progress.save!
        @course.gradebook_csvs.create!(user: @teacher,
                                       progress: progress,
                                       attachment: attachment)
      end

      it "maintains focus to Actions menu trigger during past csv export", priority: "2", test_id: 720460 do
        Gradezilla.select_previous_grade_export

        expect(current_active_element.tag_name).to eq('button')
        expect(current_active_element.text).to eq('Actions')
      end
    end
  end

  context "return focus to settings menu when it closes" do
    before { Gradezilla.visit(@course) }

    it "after arrange columns is clicked", priority: "2", test_id: 720462 do
      view_menu = Gradezilla.open_view_menu_and_arrange_by_menu
      Gradezilla.select_gradebook_menu_option('Due Date - Oldest to Newest')
      expect(check_element_has_focus(Gradezilla.view_options_menu_selector)).to be true
    end
  end

  context "return focus to view options menu when it closes" do

    before { Gradezilla.visit(@course) }

    it 'returns focus to the view options menu after clicking the "Notes" option' do
      Gradezilla.select_view_dropdown
      Gradezilla.select_notes_option
      expect(check_element_has_focus(Gradezilla.view_options_menu_selector)).to be true
    end
  end

  context "assignment header contrast" do
    let(:assignment_title) { @course.assignments.first.title }

    context "without high contrast mode" do
      before do
        @teacher.disable_feature!(:high_contrast)
        Gradezilla.visit(@course)
      end

      it 'meets 3:1 contrast for column headers' do
        bg_color = rgba_to_hex Gradezilla.select_assignment_header_cell_element(assignment_title).style('background-color')
        text_color = rgba_to_hex Gradezilla.select_assignment_header_cell_label_element(assignment_title).style('color')

        expect(LuminosityContrast.ratio(bg_color, text_color).round(2)).to be >= 3
      end
    end

    context "with high contrast mode" do
      before do
        @teacher.enable_feature!(:high_contrast)
        Gradezilla.visit(@course)
      end

      it 'meets 4.5:1 contrast for column headers' do
        bg_color = rgba_to_hex Gradezilla.select_assignment_header_cell_element(assignment_title).style('background-color')
        text_color = rgba_to_hex Gradezilla.select_assignment_header_cell_label_element(assignment_title).style('color')

        expect(LuminosityContrast.ratio(bg_color, text_color).round(2)).to be >= 4.5
      end
    end
  end

  context 'keyboard shortcut "c"' do
    before do
      Gradezilla.visit(@course)
    end

    it 'opens the submissions tray when a cell has focus and is not in edit mode' do
      Gradezilla::Cells.send_keyboard_shortcut(@student_1, @first_assignment, 'c')

      expect(current_active_element.text.include?('Close')).to be(true)
      expect(Gradezilla.submission_tray).to be_displayed
    end

    it 'does not open the submission tray when a cell has focus and is in edit mode' do
      Gradezilla::Cells.grading_cell(@student_1, @first_assignment).click
      driver.action.send_keys('c').perform

      expect(Gradezilla.body).not_to contain_css(Gradezilla.submission_tray_selector)
    end

    it 'does not open the submission tray when grid does not have focus' do
      Gradezilla.body.click
      driver.action.send_keys('c').perform

      expect(Gradezilla.body).not_to contain_css(Gradezilla.submission_tray_selector)
    end
  end

  context 'keyboard shortcut "m"' do
    before do
      Gradezilla.visit(@course)
    end

    it 'opens the assignment header menu when a cell has focus and is not in edit mode' do
      Gradezilla::Cells.send_keyboard_shortcut(@student_1, @first_assignment, 'm')

      expect(Gradezilla.expanded_popover_menu).to be_displayed
    end

    it 'does not open the assignment header menu when a cell has focus and is in edit mode' do
      Gradezilla::Cells.grading_cell(@student_1, @first_assignment).click
      driver.action.send_keys('m').perform

      expect(Gradezilla.body).not_to contain_css(Gradezilla.expanded_popover_menu_selector)
    end

    it 'pressing escape closes the assignment header menu' do
      Gradezilla::Cells.send_keyboard_shortcut(@student_1, @first_assignment, 'm')
      expect(Gradezilla.expanded_popover_menu).to be_displayed

      driver.action.send_keys(:escape).perform

      expect(Gradezilla.body).not_to contain_css(Gradezilla.expanded_popover_menu_selector)
    end

    it 'opens the assignment group header menu when a cell has focus and is not in edit mode' do
      Gradezilla::Cells.send_keyboard_shortcut_to_assignment_group(@student_1, @group, 'm')

      expect(Gradezilla.expanded_popover_menu).to be_displayed
    end

    it 'pressing escape closes the assignment group header menu' do
      Gradezilla::Cells.send_keyboard_shortcut_to_assignment_group(@student_1, @group, 'm')
      expect(Gradezilla.expanded_popover_menu).to be_displayed

      driver.action.send_keys(:escape).perform

      expect(Gradezilla.body).not_to contain_css(Gradezilla.expanded_popover_menu_selector)
    end

    it 'opens the total header menu when a cell has focus and is not in edit mode' do
      Gradezilla::Cells.send_keyboard_shortcut_to_total(@student_1, 'm')

      expect(Gradezilla.expanded_popover_menu).to be_displayed
    end

    it 'pressing escape closes the total header menu' do
      Gradezilla::Cells.send_keyboard_shortcut_to_total(@student_1, 'm')
      expect(Gradezilla.expanded_popover_menu).to be_displayed

      driver.action.send_keys(:escape).perform

      expect(Gradezilla.body).not_to contain_css(Gradezilla.expanded_popover_menu_selector)
    end

    it 'does not open a menu when grid does not have focus' do
      Gradezilla.body.click
      driver.action.send_keys('m').perform

      expect(Gradezilla.body).not_to contain_css(Gradezilla.expanded_popover_menu_selector)
    end
  end

  context 'keyboard shortcut "s"' do
    before do
      Gradezilla.visit(@course)
    end

    # Default sort is by student name ascending, so first press of "s" will
    # toggle to descending sort
    it 'toggles sort order on student column by name' do
      cell = Gradezilla.student_cell
      driver.action.move_to(cell, 0, cell.size.height / 2 - 2).click.perform

      expect(Gradezilla.student_grades_link(Gradezilla.student_cell(0)).text).to eq(students[0].name)
      expect(Gradezilla.student_grades_link(Gradezilla.student_cell(1)).text).to eq(students[1].name)
      expect(Gradezilla.student_grades_link(Gradezilla.student_cell(2)).text).to eq(students[2].name)

      driver.action.send_keys('s').perform

      expect(Gradezilla.student_grades_link(Gradezilla.student_cell(0)).text).to eq(students[2].name)
      expect(Gradezilla.student_grades_link(Gradezilla.student_cell(1)).text).to eq(students[1].name)
      expect(Gradezilla.student_grades_link(Gradezilla.student_cell(2)).text).to eq(students[0].name)
    end

    it 'sorts assignment columns by score ascending' do
      Gradezilla.grading_cell.click
      driver.action.send_keys(:escape).perform
      driver.action.send_keys('s').perform

      expect(Gradezilla.gradebook_cell(0, 0).text).to eq('5')
      expect(Gradezilla.gradebook_cell(0, 1).text).to eq('5')
      expect(Gradezilla.gradebook_cell(0, 2).text).to eq('10')
    end

    it 'toggles sort on assignment columns' do
      Gradezilla.grading_cell.click
      driver.action.send_keys(:escape).perform
      driver.action.send_keys('s').perform
      driver.action.send_keys('s').perform

      expect(Gradezilla.gradebook_cell(0, 0).text).to eq('10')
      expect(Gradezilla.gradebook_cell(0, 1).text).to eq('5')
      expect(Gradezilla.gradebook_cell(0, 2).text).to eq('5')
    end

    it 'sorts assignment group columns by score ascending' do
      Gradezilla.grading_cell(3).click
      driver.action.send_keys('s').perform

      expect(Gradezilla.gradebook_cell_percentage(3, 0).text).to eq('66.67%')
      expect(Gradezilla.gradebook_cell_percentage(3, 1).text).to eq('66.67%')
      expect(Gradezilla.gradebook_cell_percentage(3, 2).text).to eq('100%')
    end

    it 'toggles sort on assignment group columns' do
      Gradezilla.grading_cell(3).click
      driver.action.send_keys('s').perform
      driver.action.send_keys('s').perform

      expect(Gradezilla.gradebook_cell_percentage(3, 0).text).to eq('100%')
      expect(Gradezilla.gradebook_cell_percentage(3, 1).text).to eq('66.67%')
      expect(Gradezilla.gradebook_cell_percentage(3, 2).text).to eq('66.67%')
    end

    it 'sorts total column by score ascending' do
      Gradezilla.grading_cell(4).click
      driver.action.send_keys('s').perform

      expect(Gradezilla.gradebook_cell_percentage(4, 0).text).to eq('66.67%')
      expect(Gradezilla.gradebook_cell_percentage(4, 1).text).to eq('66.67%')
      expect(Gradezilla.gradebook_cell_percentage(4, 2).text).to eq('100%')
    end

    it 'toggles sort on total columns' do
      Gradezilla.grading_cell(4).click
      driver.action.send_keys('s').perform
      driver.action.send_keys('s').perform

      expect(Gradezilla.gradebook_cell_percentage(4, 0).text).to eq('100%')
      expect(Gradezilla.gradebook_cell_percentage(4, 1).text).to eq('66.67%')
      expect(Gradezilla.gradebook_cell_percentage(4, 2).text).to eq('66.67%')
    end

    it 'sorts custom columns alphabetically' do
      Gradezilla.show_notes
      Gradezilla.add_notes

      Gradezilla.notes_cell(0).click
      driver.action.send_keys(:escape).perform
      driver.action.send_keys('s').perform

      expect(Gradezilla.notes_cell(0).text).to eq('A')
      expect(Gradezilla.notes_cell(1).text).to eq('B')
      expect(Gradezilla.notes_cell(2).text).to eq('C')
    end

    it 'toggle sort on custom columns' do
      Gradezilla.show_notes
      Gradezilla.add_notes

      Gradezilla.notes_cell(0).click
      driver.action.send_keys(:escape).perform
      driver.action.send_keys('s').perform
      driver.action.send_keys('s').perform

      expect(Gradezilla.notes_cell(0).text).to eq('C')
      expect(Gradezilla.notes_cell(1).text).to eq('B')
      expect(Gradezilla.notes_cell(2).text).to eq('A')
    end
  end

  context 'keyboard shortcut "g"' do
    before do
      Gradezilla.visit(@course)
    end

    it 'navigates to assignment details page if assignment cell is selected' do
      Gradezilla.grading_cell.click
      driver.action.send_keys(:escape).perform

      expect_new_page_load { driver.action.send_keys('g').perform }
      expect(driver.current_url.end_with?(@course.assignments.first.id.to_s)).to be(true)
    end
  end

  context "assignment header focus" do
    before { Gradezilla.visit(@course)}
    let(:assignment) { @course.assignments.first }

    it 'is placed on assignment header trigger upon sort' do
      Gradezilla.click_assignment_header_menu(assignment.id)
      Gradezilla.click_assignment_popover_sort_by('low-to-high')

      driver.action.send_keys(:escape).perform

      check_element_has_focus Gradezilla.assignment_header_menu_trigger_element(assignment.title)
    end

    %w[message-students-who curve-grades set-default-grade assignment-muter download-submissions].each do |dialog|
      it "is placed on assignment header trigger upon #{dialog} dialog close" do
        Gradezilla.click_assignment_header_menu_element(assignment.id,dialog)
        Gradezilla.close_open_dialog

        check_element_has_focus Gradezilla.assignment_header_menu_trigger_element(assignment.title)
      end
    end
  end
end
