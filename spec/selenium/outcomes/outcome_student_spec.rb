# frozen_string_literal: true

#
# Copyright (C) 2014 - present Instructure, Inc.
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
require "feature_flag_helper"

describe "outcomes as a student" do
  include_context "in-process server selenium tests"
  include OutcomeCommon
  include FeatureFlagHelper

  let(:who_to_login) { "student" }
  let(:outcome_url) { "/courses/#{@course.id}/outcomes" }

  before do
    course_with_student_logged_in
  end

  context "initial state" do
    before do
      mock_feature_flag_on_account(:improved_outcomes_management, false)
    end

    it "does not display outcome instructions" do
      course_bulk_outcome_groups_course(2, 2)
      get outcome_url
      wait_for_ajaximations
      expect(f(".outcomes-content")).not_to include_text "Setting up Outcomes"
    end

    it "selects the first outcome from the list if there are no outcome groups" do
      course_outcome 2
      get outcome_url
      expect(f(".outcomes-content .title")).to include_text "outcome 0"
    end

    it "selects the first outcome group from the list if there are outcome groups" do
      course_bulk_outcome_groups_course(2, 2)
      get outcome_url
      expect(f(".outcomes-content .title")).to include_text "group 0"
    end
  end

  it "does not display outcome manipulation controls" do
    mock_feature_flag_on_account(:improved_outcomes_management, true)
    course_bulk_outcome_groups_course(2, 2)
    get outcome_url
    wait_for_ajaximations
    button_texts = ff("button").map(&:text)
    expect(button_texts).not_to include("Find")
    expect(button_texts).not_to include("Import")
    expect(button_texts).not_to include("Create")
  end
end
