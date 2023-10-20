# frozen_string_literal: true

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

require_relative "../helpers/outcome_common"

describe "user outcome results page as a teacher" do
  include_context "in-process server selenium tests"
  include OutcomeCommon

  let(:outcome_url) { "/courses/#{@course.id}/outcomes/users/#{@student.id}" }

  before(:once) do
    course_with_teacher(active_all: true)
    student_in_course(active_all: true)
    course_bulk_outcome_groups_course(1, 5)
  end

  before do
    user_session @teacher
    get outcome_url
  end

  it "toggles show all artifacts after clicking button" do
    btn = f("#show_all_artifacts_link")
    expect(btn.text).to eq "Show All Artifacts"
    btn.click
    expect(btn.text).to eq "Hide All Artifacts"
    btn.click
    expect(btn.text).to eq "Show All Artifacts"
  end

  it "toggles hide unassessed outcomes after clicking button" do
    btn = f("#hide_unassessed_outcomes_link")
    expect(btn.text).to eq "Hide Unassessed Outcomes"
    btn.click
    expect(btn.text).to eq "Show Unassessed Outcomes"
    btn.click
    expect(btn.text).to eq "Hide Unassessed Outcomes"
  end

  it "assigns the html class to unassessed outcomes" do
    el = ff("tr.js_unassessed_outcome")
    expect(el.count).to eq 5
  end
end
