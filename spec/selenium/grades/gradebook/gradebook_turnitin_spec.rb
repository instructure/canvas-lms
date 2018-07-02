#
# Copyright (C) 2015 - present Instructure, Inc.
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

describe "gradebook - turnitin" do
  include_context "in-process server selenium tests"
  include GradebookCommon

  before(:once) { gradebook_data_setup }
  before(:each) { user_session(@teacher) }

  it "should show turnitin data" do
    @first_assignment.update_attribute(:turnitin_enabled, true)
    s1 = @first_assignment.submit_homework(@student_1, submission_type: 'online_text_entry', body: 'asdf')
    s1.update_attribute :turnitin_data, {
      "submission_#{s1.id}": {
        similarity_score: 0.0,
        web_overlap: 0.0,
        publication_overlap: 0.0,
        student_overlap: 0.0,
        state: 'none'
      }
    }
    a = attachment_model(context: @student_2, content_type: 'text/plain')
    s2 = @first_assignment.submit_homework(@student_2, submission_type: 'online_upload', attachments: [a])
    s2.update_attribute :turnitin_data, {
      "attachment_#{a.id}": {
        similarity_score: 1.0,
        web_overlap: 5.0,
        publication_overlap: 0.0,
        student_overlap: 0.0,
        state: 'acceptable'
      }
    }

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
end
