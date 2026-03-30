# frozen_string_literal: true

#
# Copyright (C) 2025 - present Instructure, Inc.
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
#

require_relative "../graphql_spec_helper"

describe Mutations::UpdateInstitutionalTagArchivedState do
  before(:once) do
    @account = Account.default
    @account.enable_feature!(:institutional_tags)
    @admin = account_admin_user(account: @account)
    @non_admin = user_model
    @tag = institutional_tag_model(account: @account)
    @user = user_model
    @assoc = institutional_tag_association_model(account: @account, institutional_tag: @tag, user: @user)
  end

  def mutation_str(id: nil, archived: true)
    id ||= @tag.id
    <<~GQL
      mutation {
        updateInstitutionalTagArchivedState(input: {
          id: "#{id}"
          archived: #{archived}
        }) {
          institutionalTag { _id workflowState }
          errors { attribute message }
        }
      }
    GQL
  end

  def run_mutation(opts = {}, current_user: @admin)
    CanvasSchema.execute(
      mutation_str(**opts),
      context: {
        current_user:,
        domain_root_account: @account,
        request: ActionDispatch::TestRequest.create
      }
    ).to_h.with_indifferent_access
  end

  it "archives the tag" do
    result = run_mutation({ archived: true })
    tag = result.dig(:data, :updateInstitutionalTagArchivedState, :institutionalTag)
    expect(tag[:workflowState]).to eq "deleted"
    expect(@tag.reload.workflow_state).to eq "deleted"
  end

  it "also deletes active associations when archiving" do
    run_mutation({ archived: true })
    expect(@assoc.reload.workflow_state).to eq "deleted"
  end

  it "unarchives a deleted tag" do
    @tag.update!(workflow_state: "deleted")
    result = run_mutation({ archived: false })
    tag = result.dig(:data, :updateInstitutionalTagArchivedState, :institutionalTag)
    expect(tag[:workflowState]).to eq "active"
  end

  it "returns not authorized for non-admins" do
    result = run_mutation(current_user: @non_admin)
    expect(result[:errors].first[:message]).to eq "not authorized"
  end

  it "returns an error when feature flag is disabled" do
    @account.disable_feature!(:institutional_tags)
    result = run_mutation
    expect(result[:errors].first[:message]).to eq "feature flag is disabled"
  end

  it "returns not found for an unknown id" do
    result = run_mutation({ id: 0 })
    expect(result[:errors].first[:message]).to eq "not found"
  end
end
