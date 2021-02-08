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

require File.expand_path(File.dirname(__FILE__) + '/../../common')
require File.expand_path(File.dirname(__FILE__) + '/../../helpers/rubrics_common')

describe "sub account shared rubric specs" do
  include_context "in-process server selenium tests"
  include RubricsCommon

  let(:account) { Account.create(:name => 'sub account from default account', :parent_account => Account.default) }
  let(:rubric_url) { "/accounts/#{account.id}/rubrics" }
  let(:who_to_login) { 'admin' }

  before(:each) do

    course_with_admin_logged_in
  end

  it "should delete a rubric" do
    should_delete_a_rubric
  end
  it "should edit a rubric" do
    should_edit_a_rubric
  end

  it "should allow fractional points" do
    should_allow_fractional_points
  end


  it "should round to 2 decimal places" do
    should_round_to_2_decimal_places
  end

  it "should round to an integer when splitting" do

    should_round_to_an_integer_when_splitting
  end

  it "should pick the lower value when splitting without room for an integer" do
    skip('fragile - need to refactor split_ratings method')
    should_pick_the_lower_value_when_splitting_without_room_for_an_integer
  end
end
