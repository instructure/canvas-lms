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
require_relative "../helpers/outcome_common"

describe "sub account outcomes" do
  include_context "in-process server selenium tests"
  include OutcomeCommon

  describe "account outcome specs" do
    let(:account) { Account.create(name: "sub account from default account", parent_account: Account.default) }
    let(:outcome_url) { "/accounts/#{account.id}/outcomes" }
    let(:who_to_login) { "admin" }

    before do
      course_with_admin_logged_in
    end

    context "create/edit/delete outcomes" do
      it "creates a learning outcome with a new rating (root level)", priority: "2" do
        should_create_a_learning_outcome_with_a_new_rating_root_level
      end

      it "creates a learning outcome (nested)", priority: "2" do
        should_create_a_learning_outcome_nested
      end

      it "edits a learning outcome and delete a rating", priority: "2" do
        should_edit_a_learning_outcome_and_delete_a_rating
      end

      it "deletes a learning outcome", priority: "2" do
        skip_if_safari(:alert)
        should_delete_a_learning_outcome
      end

      it "validates decaying average_range", priority: "2" do
        should_validate_decaying_average_range
      end

      it "validates n mastery_range", priority: "2" do
        should_validate_n_mastery_range
      end
    end

    context "create/edit/delete outcome groups" do
      it "creates an outcome group (root level)", priority: "1" do
        should_create_an_outcome_group_root_level
      end

      it "creates an outcome group (nested)", priority: "1" do
        should_create_an_outcome_group_nested
      end

      it "edits an outcome group", priority: "1" do
        should_edit_an_outcome_group
      end

      it "deletes an outcome group", priority: "1" do
        skip_if_safari(:alert)
        should_delete_an_outcome_group
      end
    end

    describe "find/import dialog" do
      it "does not allow importing top level groups", priority: "1" do
        get outcome_url
        wait_for_ajaximations

        f(".find_outcome").click
        wait_for_ajaximations
        groups = ff(".outcome-group")
        expect(groups.size).to eq 2
        groups.each do |g|
          g.click
          expect(f(".ui-dialog-buttonpane .btn-primary")).not_to be_displayed
        end
      end
    end
  end
end
