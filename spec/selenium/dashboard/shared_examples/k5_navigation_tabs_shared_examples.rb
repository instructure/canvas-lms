# frozen_string_literal: true

#
# Copyright (C) 2021 - present Instructure, Inc.
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

require_relative "../../common"
require_relative "../pages/k5_dashboard_page"
require_relative "../pages/k5_dashboard_common_page"
require_relative "../../../helpers/k5_common"
require_relative "../../helpers/shared_examples_common"

shared_examples_for "k5 subject navigation tabs" do
  include K5DashboardPageObject
  include K5DashboardCommonPageObject
  include K5Common
  include SharedExamplesCommon

  let(:lti_a) { "LTI Resource A" }
  let(:lti_b) { "LTI Resource B" }
  let(:navigation_names) { ["Home", "Schedule", "Modules", "Grades", "Groups", lti_a, lti_b] }

  before :once do
    @resource_a = "context_external_tool_#{create_lti_resource(lti_a).id}"
    @resource_b = "context_external_tool_#{create_lti_resource(lti_b).id}"
  end

  it "has tabs rearranged in new configuration on the subject page" do
    @subject_course.update!(
      tab_configuration: [
        { id: Course::TAB_SCHEDULE },
        { id: Course::TAB_HOME },
        { id: Course::TAB_GRADES },
        { id: Course::TAB_MODULES }
      ]
    )

    get "/courses/#{@subject_course.id}"

    get "/courses/#{@subject_course.id}"

    tab_list_text = "Math Schedule\nSchedule\nMath Home\nHome\nMath Grades\nGrades\nMath Modules\nModules\n" \
                    "Math Resources\nResources"
    tab_list_text += "\nMath Groups\nGroups" if @subject_course.user_is_instructor?(@current_user)

    expect(k5_tablist).to include_text(tab_list_text)
  end

  it "has tabs that are hidden from the subject page" do
    @subject_course.update!(
      tab_configuration: [
        { id: Course::TAB_SCHEDULE },
        { id: Course::TAB_HOME, hidden: true },
        { id: Course::TAB_GRADES },
        { id: Course::TAB_MODULES }
      ]
    )

    get "/courses/#{@subject_course.id}"

    tab_list_text = "Math Schedule\nSchedule\nMath Grades\nGrades\nMath Modules\nModules\nMath Resources\nResources"
    tab_list_text += "\nMath Groups\nGroups" if @subject_course.user_is_instructor?(@current_user)

    expect(k5_tablist).to include_text(tab_list_text)
  end

  it "has ltis that are rearranged in new order on the resources page" do
    @subject_course.update!(
      tab_configuration: [
        { id: Course::TAB_HOME },
        { id: Course::TAB_SCHEDULE },
        { id: Course::TAB_GRADES },
        { id: Course::TAB_MODULES },
        { id: @resource_b },
        { id: @resource_a }
      ]
    )

    get "/courses/#{@subject_course.id}#resources"

    expect(k5_app_buttons[0].text).to eq lti_b
    expect(k5_app_buttons[1].text).to eq lti_a
  end

  it "has ltis that are hidden on the resources page" do
    @subject_course.update!(
      tab_configuration: [
        { id: @resource_a, hidden: true },
        { id: @resource_b }
      ]
    )

    get "/courses/#{@subject_course.id}#resources"

    expect(k5_app_buttons.count).to eq 1
    expect(k5_app_buttons[0].text).to eq lti_b
  end
end
