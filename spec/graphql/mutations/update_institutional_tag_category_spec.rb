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

describe Mutations::UpdateInstitutionalTagCategory do
  before(:once) do
    @account = Account.default
    @account.enable_feature!(:institutional_tags)
    @admin = account_admin_user(account: @account)
    @non_admin = user_model
    @category = institutional_tag_category_model(account: @account, name: "Original")
  end

  def mutation_str(id: nil, name: nil, description: nil)
    id ||= id || @category.id
    args = ["id: \"#{id}\""]
    args << "name: \"#{name}\"" if name
    args << "description: \"#{description}\"" if description
    <<~GQL
      mutation {
        updateInstitutionalTagCategory(input: { #{args.join(", ")} }) {
          institutionalTagCategory { _id name description }
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

  it "updates the category name" do
    result = run_mutation({ name: "Updated" })
    cat = result.dig(:data, :updateInstitutionalTagCategory, :institutionalTagCategory)
    expect(cat[:name]).to eq "Updated"
    expect(@category.reload.name).to eq "Updated"
  end

  it "returns not authorized for non-admins" do
    result = run_mutation({ name: "X" }, current_user: @non_admin)
    expect(result[:errors].first[:message]).to eq "not authorized"
  end

  it "returns an error when feature flag is disabled" do
    @account.disable_feature!(:institutional_tags)
    result = run_mutation({ name: "X" })
    expect(result[:errors].first[:message]).to eq "feature flag is disabled"
  end

  it "returns not found for an unknown id" do
    result = run_mutation({ id: 0, name: "X" })
    expect(result[:errors].first[:message]).to eq "not found"
  end
end
