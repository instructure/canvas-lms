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

describe Mutations::CreateInstitutionalTagCategory do
  before(:once) do
    @account = Account.default
    @account.enable_feature!(:institutional_tags)
    @admin = account_admin_user(account: @account)
    @non_admin = user_model
  end

  def mutation_str(name: "Category A", description: "Desc")
    <<~GQL
      mutation {
        createInstitutionalTagCategory(input: {
          name: "#{name}"
          description: "#{description}"
        }) {
          institutionalTagCategory {
            _id
            name
            description
            workflowState
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

  it "creates a tag category" do
    expect { run_mutation }.to change { InstitutionalTagCategory.count }.by(1)
    result = run_mutation({ name: "My Category", description: "Some description" })
    cat = result.dig(:data, :createInstitutionalTagCategory, :institutionalTagCategory)
    expect(cat[:name]).to eq "My Category"
    expect(cat[:description]).to eq "Some description"
    expect(cat[:workflowState]).to eq "active"
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
end
