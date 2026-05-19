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

describe Mutations::UpdateInstitutionalTag do
  before(:once) do
    @account = Account.default
    @account.enable_feature!(:institutional_tags)
    @admin = account_admin_user(account: @account)
    @non_admin = user_model
    @tag = institutional_tag_model(account: @account, name: "Original")
    @other_category = institutional_tag_category_model(account: @account, name: "Other Category")
  end

  def mutation_str(id: nil, name: nil, description: nil, category_id: nil)
    id ||= @tag.id
    args = ["id: \"#{id}\""]
    args << "name: \"#{name}\"" if name
    args << "categoryId: \"#{category_id}\"" if category_id
    args << "description: \"#{description}\"" if description
    <<~GQL
      mutation {
        updateInstitutionalTag(input: { #{args.join(", ")} }) {
          institutionalTag { _id name description category { _id } }
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

  it "reassigns the tag to a different category" do
    result = run_mutation({ category_id: @other_category.id })
    tag = result.dig(:data, :updateInstitutionalTag, :institutionalTag)
    expect(tag.dig(:category, :_id)).to eq @other_category.id.to_s
    expect(@tag.reload.category_id).to eq @other_category.id
  end

  it "updates the tag name" do
    result = run_mutation({ name: "Updated" })
    tag = result.dig(:data, :updateInstitutionalTag, :institutionalTag)
    expect(tag[:name]).to eq "Updated"
    expect(@tag.reload.name).to eq "Updated"
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
