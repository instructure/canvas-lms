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

describe Mutations::CreateInstitutionalTag do
  before(:once) do
    @account = Account.default
    @account.enable_feature!(:institutional_tags)
    @admin = account_admin_user(account: @account)
    @non_admin = user_model
    @category = institutional_tag_category_model(account: @account)
  end

  def mutation_str(name: "Tag A", description: "Desc", category_id: nil)
    category_id ||= @category.id
    <<~GQL
      mutation {
        createInstitutionalTag(input: {
          name: "#{name}"
          description: "#{description}"
          categoryId: "#{category_id}"
        }) {
          institutionalTag {
            _id
            name
            description
            workflowState
            category { _id name }
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

  it "creates a tag under the given category" do
    result = run_mutation({ name: "My Tag", description: "A description" })
    tag = result.dig(:data, :createInstitutionalTag, :institutionalTag)
    expect(tag[:name]).to eq "My Tag"
    expect(tag[:description]).to eq "A description"
    expect(tag[:workflowState]).to eq "active"
    expect(tag.dig(:category, :_id)).to eq @category.id.to_s
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

  it "returns not found for an unknown category" do
    result = run_mutation({ category_id: 0 })
    expect(result[:errors].first[:message]).to eq "not found"
  end

  it "rejects creation when the category has 50 active tags" do
    50.times { |i| institutional_tag_model(account: @account, category: @category, name: "Tag #{i}") }
    result = run_mutation({ name: "One Too Many" })
    expect(result[:errors].first[:message]).to include "maximum number of tags"
  end
end
