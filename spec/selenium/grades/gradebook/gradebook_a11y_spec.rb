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

describe "gradebook" do
  include_context "in-process server selenium tests"
  include GradebookCommon

  let(:extra_setup) { }
  let(:active_element) { driver.switch_to.active_element }

  before(:once) do
    gradebook_data_setup
  end

  before(:each) do
    extra_setup
    user_session(@teacher)
    get "/courses/#{@course.id}/gradebook"
  end

  context "export menu" do
    before { f('#download_csv').click }

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
    before { f('#gradebook_settings').click }

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
    it 'hides the icon from screen readers' do
      expect(f('#gradebook_settings .icon-settings')).to have_attribute('aria-hidden', 'true')
    end

    it 'has screen reader only text' do
      expect(f('#gradebook_settings .screenreader-only').text).to eq('Gradebook Settings')
    end
  end
end
