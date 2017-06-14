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
require_relative '../page_objects/gradezilla_page'

describe "Gradezilla" do
  include_context "in-process server selenium tests"
  include GradezillaCommon
  include ColorCommon

  let(:extra_setup) { }

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
      Gradezilla.open_view_menu_and_arrange_by_menu
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

  context 'cell tooltip' do
    before { Gradezilla.visit(@course) }

    it 'is shown on hover' do
      Gradezilla.cell_hover(0, 0)
      expect(Gradezilla.cell_tooltip(0, 0)).to be_displayed
    end

    it 'is shown on focus' do
      Gradezilla.cell_click(0, 0)
      expect(Gradezilla.cell_tooltip(0, 0)).to be_displayed
    end
  end
end
