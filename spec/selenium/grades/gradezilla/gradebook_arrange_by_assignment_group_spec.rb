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

require_relative '../../helpers/gradezilla_common'
require_relative '../../helpers/assignment_overrides'
require_relative '../pages/gradezilla_page'
require_relative '../pages/gradezilla_cells_page'

describe "Gradezilla view menu" do
  include_context "in-process server selenium tests"
  include AssignmentOverridesSeleniumHelper
  include GradezillaCommon

  before(:once) { gradebook_data_setup }
  before(:each) { user_session(@teacher) }

  context "sort by assignment group order" do
    before(:each) do
      Gradezilla.visit(@course)
    end

    it "defaults arrange by to assignment group in the grid", priority: "1", test_id: 220028 do
      expect(Gradezilla::Cells.get_grade(@student_1, @first_assignment)).to eq @assignment_1_points
      expect(Gradezilla::Cells.get_grade(@student_1, @second_assignment)).to eq @assignment_2_points
      expect(Gradezilla::Cells.get_grade(@student_1, @third_assignment)).to eq "–"
    end

    it "shows default arrange by in the menu" do
      Gradezilla.open_view_menu_and_arrange_by_menu

      expect(Gradezilla.popover_menu_item_checked?('Default Order')).to eq 'true'
    end

    it "validates arrange columns by assignment group option", priority: "1", test_id: 3253267 do
      Gradezilla.open_view_menu_and_arrange_by_menu
      Gradezilla.view_arrange_by_submenu_item('Default Order').click

      expect(Gradezilla::Cells.get_grade(@student_1, @first_assignment)).to eq @assignment_1_points
      expect(Gradezilla::Cells.get_grade(@student_1, @second_assignment)).to eq @assignment_2_points
      expect(Gradezilla::Cells.get_grade(@student_1, @third_assignment)).to eq "–"
    end
  end

  context "assignment group dropdown" do
    before(:each) do
      Gradezilla.visit(@course)
    end

    it "sorts assignments by grade - Low to High", priority: "1", test_id: 3253345 do
      Gradezilla.click_assignment_group_header_options(@group.name,'Grade - Low to High')
      gradebook_student_names = Gradezilla.fetch_student_names

      expect(gradebook_student_names[0]).to eq(@student_name_2)
      expect(gradebook_student_names[1]).to eq(@student_name_3)
      expect(gradebook_student_names[2]).to eq(@student_name_1)
    end

    it "sorts assignments by grade - High to Low", priority: "1", test_id: 3253346 do
      Gradezilla.click_assignment_group_header_options(@group.name,'Grade - High to Low')
      gradebook_student_names = Gradezilla.fetch_student_names

      expect(gradebook_student_names[0]).to eq(@student_name_1)
      expect(gradebook_student_names[1]).to eq(@student_name_3)
      expect(gradebook_student_names[2]).to eq(@student_name_2)
    end
  end
end
