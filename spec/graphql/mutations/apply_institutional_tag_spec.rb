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

describe Mutations::ApplyInstitutionalTag do
  before(:once) do
    @account = Account.default
    @account.enable_feature!(:institutional_tags)
    @admin = account_admin_user(account: @account)
    @non_admin = user_model
    @tag = institutional_tag_model(account: @account)
    @target_user = user_model
    UserAccountAssociation.create!(user: @target_user, account: @account)
  end

  def mutation_str(tag_id: nil, user_id: nil)
    tag_id ||= @tag.id
    user_id ||= @target_user.id
    <<~GQL
      mutation {
        applyInstitutionalTag(input: {
          tagId: "#{tag_id}"
          userId: "#{user_id}"
        }) {
          institutionalTagAssociation {
            _id
            tag { _id name }
            user { _id }
          }
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

  it "creates a tag association" do
    expect { run_mutation }.to change { InstitutionalTagAssociation.count }.by(1)
    result = run_mutation
    assoc = result.dig(:data, :applyInstitutionalTag, :institutionalTagAssociation)
    expect(assoc.dig(:tag, :_id)).to eq @tag.id.to_s
    expect(assoc.dig(:user, :_id)).to eq @target_user.id.to_s
  end

  it "re-activates a previously deleted association" do
    existing = institutional_tag_association_model(
      account: @account,
      institutional_tag: @tag,
      user: @target_user,
      workflow_state: "deleted"
    )
    expect { run_mutation }.not_to change { InstitutionalTagAssociation.count }
    expect(existing.reload.workflow_state).to eq "active"
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

  it "returns not found for an unknown tag" do
    result = run_mutation({ tag_id: 0 })
    expect(result[:errors].first[:message]).to eq "not found"
  end

  it "returns not found for an unknown user" do
    result = run_mutation({ user_id: 0 })
    expect(result[:errors].first[:message]).to eq "not found"
  end

  it "returns not found for a user outside the account" do
    other_user = user_model
    result = run_mutation({ user_id: other_user.id })
    expect(result[:errors].first[:message]).to eq "not found"
  end
end
