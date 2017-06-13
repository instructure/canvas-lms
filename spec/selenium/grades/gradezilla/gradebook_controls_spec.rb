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

require_relative '../page_objects/gradezilla_page'

describe 'Gradebook Controls' do
  include_context "in-process server selenium tests"

  before(:once) do
    course_with_teacher(active_all: true)
  end

  before(:each) do
    user_session(@teacher)
  end

  context 'using Gradebook dropdown' do
    it 'navigates to Individual View', test_id: 3253264, priority: '1' do
      Gradezilla.visit(@course)
      expect_new_page_load { Gradezilla.gradebook_dropdown_item_click("Individual View") }
      expect(f('h1')).to include_text("Gradebook: Individual View")
    end

    it "navigates to Grading History", priority: "2", test_id: 3253265 do
      Gradezilla.visit(@course)
      expect_new_page_load { Gradezilla.gradebook_dropdown_item_click("Grading History") }
      expect(driver.current_url).to include("/courses/#{@course.id}/gradebook/history")
    end

    it "navigates to Learning Mastery", priority: "1", test_id: 3253266 do
      Account.default.set_feature_flag!('outcome_gradebook', 'on')
      Gradezilla.visit(@course)
      Gradezilla.gradebook_dropdown_item_click("Learning Mastery")
      expect(fj('button:contains("Learning Mastery")')).to be_displayed
    end
  end
end



