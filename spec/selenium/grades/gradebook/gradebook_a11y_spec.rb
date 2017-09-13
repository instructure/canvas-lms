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
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
# A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
# details.
#
# You should have received a copy of the GNU Affero General Public License along
# with this program. If not, see <http://www.gnu.org/licenses/>.

require_relative '../../helpers/gradebook_common'
require_relative '../../helpers/color_common'
require_relative '../pages/gradebook_page'

describe "gradebook" do
  include_context "in-process server selenium tests"
  include GradebookCommon
  include ColorCommon

  let(:extra_setup) { }
  let(:active_element) { driver.switch_to.active_element }
  let(:page) { Gradebook::MultipleGradingPeriods.new }

  before(:once) do
    gradebook_data_setup
  end

  before(:each) do
    extra_setup
    user_session(@teacher)
  end

  context "export menu" do
    before do
      page.visit_gradebook(@course)
      f('#download_csv').click
    end

    it "moves focus to import button during current export", priority: "2", test_id: 720459 do
      f('.generate_new_csv').click
      expect(active_element).to have_class('ui-button')
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

      it "maintains focus on export button during past csv export", priority: "2", test_id: 720460 do
        wait_for_ajax_requests
        f('#csv_export_options .ui-menu-item:not(.generate_new_csv)').click
        expect(active_element).to have_attribute('id', 'download_csv')
      end
    end
  end

  context "return focus to settings menu when it closes" do
    before do
      page.visit_gradebook(@course)
      f('#gradebook_settings').click
    end

    it "after hide/show student names is clicked", priority: "2", test_id: 720461 do
      f(".student_names_toggle").click
      expect(active_element).to have_attribute('id', 'gradebook_settings')
    end

    it "after arrange columns is clicked", priority: "2", test_id: 720462 do
      f("[data-arrange-columns-by='due_date']").click
      expect(active_element).to have_attribute('id', 'gradebook_settings')
    end

    it "after show notes is clicked", priority: "2", test_id: 720463 do
      f('.create').click
      expect(active_element).to have_attribute('id', 'gradebook_settings')
    end
  end

  context 'settings menu is accessible' do
    before { page.visit_gradebook(@course) }

    it 'hides the icon from screen readers' do
      expect(f('#gradebook_settings .icon-settings')).to have_attribute('aria-hidden', 'true')
    end

    it 'has screen reader only text' do
      expect(f('#gradebook_settings .screenreader-only').text).to eq('Gradebook Settings')
    end
  end

  context "assignment header contrast" do
    let(:assignment_title) { @course.assignments.first.title }

    context "without high contrast mode" do
      before do
        @teacher.disable_feature!(:high_contrast)
        page.visit_gradebook(@course)
      end

      it 'meets 3:1 contrast for column headers' do
        bg_color = rgba_to_hex page.assignment_header(assignment_title).style('background-color')
        text_color = rgba_to_hex page.assignment_header_label(assignment_title).style('color')

        expect(LuminosityContrast.ratio(bg_color, text_color).round(2)).to be >= 3
      end

      it 'meets 3:1 contrast for hovered column headers' do
        hover page.assignment_header(assignment_title)

        bg_color = rgba_to_hex page.assignment_header(assignment_title).style('background-color')
        text_color = rgba_to_hex page.assignment_header_label(assignment_title).style('color')

        expect(LuminosityContrast.ratio(bg_color, text_color).round(2)).to be >= 3
      end
    end

    context "with high contrast mode" do
      before do
        @teacher.enable_feature!(:high_contrast)
        page.visit_gradebook(@course)
      end

      it 'meets 4.5:1 contrast for column headers' do
        bg_color = rgba_to_hex page.assignment_header(assignment_title).style('background-color')
        text_color = rgba_to_hex page.assignment_header_label(assignment_title).style('color')

        expect(LuminosityContrast.ratio(bg_color, text_color).round(2)).to be >= 4.5
      end

      it 'meets 4.5:1 contrast for hovered column headers' do
        hover page.assignment_header(assignment_title)

        bg_color = rgba_to_hex page.assignment_header(assignment_title).style('background-color')
        text_color = rgba_to_hex page.assignment_header_label(assignment_title).style('color')

        expect(LuminosityContrast.ratio(bg_color, text_color).round(2)).to be >= 4.5
      end
    end
  end

  context 'cell tooltip' do
    before { page.visit_gradebook(@course) }

    it 'is shown on hover' do
      page.cell_hover(0, 0)
      expect(page.cell_tooltip(0, 0)).to be_displayed
    end

    it 'is shown on focus' do
      page.cell_click(0, 0)
      expect(page.cell_tooltip(0, 0)).to be_displayed
    end
  end
end
