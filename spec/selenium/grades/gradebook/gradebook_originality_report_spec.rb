#
# Copyright (C) 2018 - present Instructure, Inc.
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

describe "gradebook - originality reports" do
  include_context "in-process server selenium tests"
  include GradebookCommon

  before(:once) { gradebook_data_setup }
  before(:each) { user_session(@teacher) }

  it "should show originality data" do
    s1 = @first_assignment.submit_homework(@student_1, :submission_type => 'online_text_entry', :body => 'asdf')
    s1.originality_reports.create!(originality_score: 0.0)

    a = attachment_model(:context => @student_2, :content_type => 'text/plain')
    s2 = @first_assignment.submit_homework(@student_2, :submission_type => 'online_upload', :attachments => [a])
    s2.originality_reports.create!(originality_score: 1.0, attachment: a)

    get "/courses/#{@course.id}/gradebook"
    icons = ff('.gradebook-cell-turnitin')
    expect(icons).to have_size 2

    none        = f('.none-score')       # icons[0]
    acceptable  = f('.acceptable-score') # icons[1]
    # make sure it appears in each submission dialog

    cell = none.find_element(:xpath, '..')

        driver.action.move_to(f('#gradebook_settings')).move_to(cell).perform
        expect(cell.find_element(:css, "a")).to be_displayed
        cell.find_element(:css, "a").click

    fj('button.ui-dialog-titlebar-close:visible').click

    cell = acceptable.find_element(:xpath, '..')

    # This is a quick fix to change the keyboard focus so that an accessible
    # tooltip does not block the visibility of the cell.
    driver.action.send_keys(:tab).perform
    driver.action.move_to(f('#gradebook_settings')).move_to(cell).perform
    expect(cell.find_element(:css, "a")).to be_displayed
    cell.find_element(:css, "a").click

    fj('button.ui-dialog-titlebar-close:visible').click
  end

  context 'group assignment' do
    let(:course) { @first_assignment.course }
    let!(:group) do
      group = course.groups.create!(name: 'group one')
      group.add_user(@student_1)
      group.add_user(@student_2)
      submission_one.update!(group: group)
      submission_two.update!(group: group)
      group
    end
    let(:submission_one) do
      @first_assignment.submit_homework(@student_1, :submission_type => 'online_text_entry', :body => 'asdf')
    end
    let(:submission_two) do
      @first_assignment.submit_homework(@student_2, :submission_type => 'online_text_entry', :body => 'asdf')
    end
    let(:originality_report) { submission_one.originality_reports.create!(originality_score: 1.0) }

    before { originality_report.copy_to_group_submissions! }

    it 'should show originality data for all submissions in a group' do
      get "/courses/#{@course.id}/gradebook"
      icons = ff('.gradebook-cell-turnitin')
      expect(icons).to have_size 2
    end

    it 'shows the correct originality score for the first student' do
      get "/courses/#{@course.id}/gradebook"
      icons = ff('.gradebook-cell-turnitin')

      cell = icons.first.find_element(:xpath, '..')
      driver.action.move_to(f('#gradebook_settings')).move_to(cell).perform
      expect(cell.find_element(:css, "a")).to be_displayed
      cell.find_element(:css, "a").click
      score = f('.turnitin_similarity_score')
      expect(score.text).to eq "#{originality_report.originality_score.to_i}%"
    end

    it 'shows the correct originality score for the last student' do
      get "/courses/#{@course.id}/gradebook"

      icons = ff('.gradebook-cell-turnitin')
      cell = icons.second.find_element(:xpath, '..')
      driver.action.move_to(f('#gradebook_settings')).move_to(cell).perform
      expect(cell.find_element(:css, "a")).to be_displayed
      cell.find_element(:css, "a").click
      score = f('.turnitin_similarity_score')
      expect(score.text).to eq "#{originality_report.originality_score.to_i}%"
    end
  end
end
