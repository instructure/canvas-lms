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

require_relative '../common'
require_relative '../helpers/blueprint_common'

describe "master courses - child courses - settings" do
  include_context "in-process server selenium tests"
  include BlueprintCourseCommon

  before :once do
    Account.default.enable_feature!(:master_courses)
    @master = course_factory(active_all: true)
    @master_teacher = @teacher
    @template = MasterCourses::MasterTemplate.set_as_master_course(@master)
    @minion = @template.add_child_course!(course_factory(name: "Minion", active_all: true)).child_course
    @minion.enroll_teacher(@master_teacher).accept!

    run_master_course_migration(@master)
  end

  before :each do
    user_session(@teacher)
  end

  it "should show the child course blueprint information modal" do
    skip("Jenkins fails with no page load at line 46, though succeeds in canvas__selenium--chrome. Browser issue?")
    get "/courses/#{@minion.id}/settings"

    info_button = f('.blueprint_information_button')
    expect(info_button).to be_displayed
    expect_new_page_load { info_button.click }
    # the info modal is opened
    expect(fxpath("//span[contains(@aria-label, 'Blueprint Course Information')]")).to be_displayed
    # the 'x' in the modal
    close_button = fxpath("//span[contains(@aria-label, 'Blueprint Course Information')]//button")
    close_button.click
    # modal has closed and focus is returned to the trigger button
    check_element_has_focus(f('.blueprint_information_button'))
  end
end
