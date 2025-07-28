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

require_relative "../../common"
require_relative "../../helpers/rubrics_common"

describe "sub account shared rubric specs" do
  include_context "in-process server selenium tests"
  include RubricsCommon

  let(:account) { Account.create(name: "sub account from default account", parent_account: Account.default) }
  let(:rubric_url) { "/accounts/#{account.id}/rubrics" }
  let(:who_to_login) { "admin" }

  before do
    course_with_admin_logged_in
    @course.disable_feature!(:enhanced_rubrics)
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
end
