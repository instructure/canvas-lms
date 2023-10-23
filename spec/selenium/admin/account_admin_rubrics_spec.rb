# frozen_string_literal: true

#
# Copyright (C) 2012 - present Instructure, Inc.
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

require_relative "../common"
require_relative "../helpers/rubrics_common"

describe "account shared rubric specs" do
  include_context "in-process server selenium tests"
  include RubricsCommon

  let(:rubric_url) { "/accounts/#{Account.default.id}/rubrics" }
  let(:who_to_login) { "admin" }
  let(:account) { Account.default }

  before do
    Account.site_admin.disable_feature!(:enhanced_rubrics)
    course_with_admin_logged_in
  end

  it "deletes a rubric" do
    should_delete_a_rubric
  end

  it "edits a rubric" do
    should_edit_a_rubric
  end

  it "allows fractional points" do
    should_allow_fractional_points
  end

  it "rounds to 2 decimal places" do
    should_round_to_2_decimal_places
  end

  it "rounds to an integer when splitting" do
    should_round_to_an_integer_when_splitting
  end

  it "picks the lower value when splitting without room for an integer" do
    skip("fragile - need to refactor split_ratings method")
    should_pick_the_lower_value_when_splitting_without_room_for_an_integer
  end
end
