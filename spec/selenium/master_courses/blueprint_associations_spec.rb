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



require_relative '../common'
require_relative '../helpers/blueprint_common'

describe "Blueprint association settings" do

  include_context "in-process server selenium tests"
  include BlueprintCourseCommon

  before :once do
    Account.default.enable_feature!(:master_courses)
    account_admin_user(active_all: true)

    @master = course_factory(active_all: true)
    @template = MasterCourses::MasterTemplate.set_as_master_course(@master)

    @minion1 = @template.add_child_course!(course_factory(course_name: "Minion", active_all: true)).child_course
    @minion2 = @template.add_child_course!(course_factory(course_name: "Minion2", active_all: true)).child_course
    @minion3 = course_factory(course_name: "minion3", active_all: true)
    @minion4 = course_factory(course_name: "minion4", active_all: true)

    create_sub_account

  end

  def create_sub_account(name = 'sub account', number_to_create = 1, parent_account = Account.default)
    created_sub_accounts = []
    number_to_create.times do |i|
      sub_account = Account.create(:name => name + " #{i}", :parent_account => parent_account)
      created_sub_accounts.push(sub_account)
    end
    created_sub_accounts.count == 1 ? created_sub_accounts[0] : created_sub_accounts
  end

  before :each do
    user_session(@admin)
    get "/courses/#{@master.id}"
  end

  context "in the blueprint association settings" do

    it "courses show in the 'To be Added' area", priority: "2", test_id: 3077486 do
      open_associations
      open_courses_list
      row = f('.bca-table__course-row')
      row.find_element(xpath: 'td//label').click
      expect(fj("span:contains('To be Added')")).to be
      element = f('.bca-associations-table')
      element = element.find_element(css: "form[data-course-id=\"#{@minion3.id}\"]")
      expect(element).to be
    end

    it "leaving the search bar shouldn't close the courses tab", priority: "2", test_id: 3096112 do
      open_associations
      open_courses_list
      element = f('input', f('.bca-course-filter')) # .find_element(css: 'input')
      element.send_keys("Minion")
      f('h3', f('.bca__wrapper')).click # click away from the search bar
      expect(f('.bca-table__wrapper')).to be_displayed
    end

    it "course search dropdowns are populated", priority: "2", test_id: 3072438 do
      open_associations
      open_courses_list
      select_boxes = ff('.bca-course-filter select')
      expect(select_boxes[0]).to include_text("Default Term")
      expect(select_boxes[1]).to include_text("sub account 0")
    end
  end
end
