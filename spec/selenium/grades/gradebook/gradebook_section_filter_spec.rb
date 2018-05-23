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
require_relative '../../helpers/groups_common'

describe "gradebook" do
  include_context "in-process server selenium tests"
  include GradebookCommon
  include GroupsCommon

  before(:once) { gradebook_data_setup }
  before(:each) { user_session(@teacher) }

  it "should handle multiple enrollments correctly" do
    @course.enroll_student(@student_1, :section => @other_section, :allow_multiple_enrollments => true)

    get "/courses/#{@course.id}/gradebook"

    meta_cells = find_slick_cells(0, f('.grid-canvas'))
    expect(meta_cells[0]).to include_text @course.default_section.display_name
    expect(meta_cells[0]).to include_text @other_section.display_name

    switch_to_section(@course.default_section)
    meta_cells = find_slick_cells(0, f('.grid-canvas'))
    expect(meta_cells[0]).to include_text @student_name_1

    switch_to_section(@other_section)
    meta_cells = find_slick_cells(0, f('.grid-canvas'))
    expect(meta_cells[0]).to include_text @student_name_1
  end

  it "should allow showing only a certain section", priority: "1", test_id: 210024 do
    get "/courses/#{@course.id}/gradebook"
    # grade the first assignment
    edit_grade('#gradebook_grid .container_1 .slick-row:nth-child(1) .b2', 0)
    edit_grade('#gradebook_grid .container_1 .slick-row:nth-child(2) .b2', 1)

    switch_to_section(@other_section)
    expect(fj('.section-select-button:visible')).to include_text(@other_section.name)

    expect(f('#gradebook_grid .container_1 .slick-row:nth-child(1) .b2')).to include_text '1'

    # verify that it remembers the section to show across page loads
    get "/courses/#{@course.id}/gradebook"
    expect(fj('.section-select-button:visible')).to include_text @other_section.name
    expect(f('#gradebook_grid .container_1 .slick-row:nth-child(1) .b2')).to include_text '1'

    # now verify that you can set it back

    fj('.section-select-button:visible').click
    expect(fj('.section-select-menu:visible')).to be_displayed
    f("label[for='section_option_']").click
    expect(fj('.section-select-button:visible')).to include_text "All Sections"

    # validate all grades (i.e. submissions) were loaded
    expect(f('#gradebook_grid .container_1 .slick-row:nth-child(1) .b2')).to include_text '0'
    expect(f('#gradebook_grid .container_1 .slick-row:nth-child(2) .b2')).to include_text '1'
  end
end
