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

# Tests for the institutionalTagsConnection and institutionalTagCategoriesConnection
# fields added to AccountType on this branch.
describe "AccountType institutional tag queries" do
  before(:once) do
    @account = Account.default
    @account.enable_feature!(:institutional_tags)
    @admin = account_admin_user(account: @account)
    @non_admin = user_model

    @cat1 = institutional_tag_category_model(account: @account, name: "Animals")
    @cat2 = institutional_tag_category_model(account: @account, name: "Colors")
    @archived_cat = institutional_tag_category_model(account: @account, name: "Archived Category", workflow_state: "deleted")
    @tag1 = institutional_tag_model(account: @account, category: @cat1, name: "Dog")
    @tag2 = institutional_tag_model(account: @account, category: @cat1, name: "Cat")
    @tag3 = institutional_tag_model(account: @account, category: @cat2, name: "Blue")
    @archived_tag = institutional_tag_model(account: @account, category: @cat1, name: "Archived Tag", workflow_state: "deleted")
  end

  def run_query(query_str, current_user: @admin)
    CanvasSchema.execute(
      query_str,
      context: {
        current_user:,
        domain_root_account: @account,
        request: ActionDispatch::TestRequest.create
      }
    ).to_h.with_indifferent_access
  end

  def account_type
    GraphQLTypeTester.new(@account, current_user: @admin, domain_root_account: @account)
  end

  def non_admin_account_type
    GraphQLTypeTester.new(@account, current_user: @non_admin, domain_root_account: @account)
  end

  describe "institutionalTagCategoriesConnection" do
    it "returns active categories ordered by name" do
      result = account_type.resolve("institutionalTagCategoriesConnection { nodes { name } }")
      expect(result).to eq ["Animals", "Colors"]
    end

    it "returns totalNrOfPages in pageInfo" do
      result = run_query(<<~GQL)
        query {
          account(id: "#{@account.id}") {
            institutionalTagCategoriesConnection(first: 1) {
              pageInfo { totalNrOfPages }
            }
          }
        }
      GQL
      total_pages = result.dig(:data, :account, :institutionalTagCategoriesConnection, :pageInfo, :totalNrOfPages)
      expect(total_pages).to be 2
    end

    it "filters by search term" do
      result = account_type.resolve(
        'institutionalTagCategoriesConnection(searchTerm: "Ani") { nodes { name } }'
      )
      expect(result).to eq ["Animals"]
    end

    it "returns only active categories when workflowState is active" do
      result = account_type.resolve('institutionalTagCategoriesConnection(workflowState: "active") { nodes { name } }')
      expect(result).to eq ["Animals", "Colors"]
    end

    it "returns only deleted categories when workflowState is deleted" do
      result = account_type.resolve('institutionalTagCategoriesConnection(workflowState: "deleted") { nodes { name } }')
      expect(result).to eq ["Archived Category"]
    end

    it "returns nil for non-admins" do
      result = non_admin_account_type.resolve("institutionalTagCategoriesConnection { nodes { _id } }")
      expect(result).to be_nil
    end

    it "raises feature flag error when disabled" do
      @account.disable_feature!(:institutional_tags)
      expect { account_type.resolve("institutionalTagCategoriesConnection { nodes { _id } }") }
        .to raise_error(GraphQLTypeTester::Error, /feature flag is disabled/)
    end
  end

  describe "institutionalTagsConnection" do
    it "returns all active tags ordered by name" do
      result = account_type.resolve("institutionalTagsConnection { nodes { name } }")
      expect(result).to eq %w[Blue Cat Dog]
    end

    it "returns totalNrOfPages in pageInfo" do
      result = run_query(<<~GQL)
        query {
          account(id: "#{@account.id}") {
            institutionalTagsConnection(first: 2) {
              pageInfo { totalNrOfPages }
            }
          }
        }
      GQL
      total_pages = result.dig(:data, :account, :institutionalTagsConnection, :pageInfo, :totalNrOfPages)
      expect(total_pages).to be 2
    end

    it "filters by category_id" do
      result = account_type.resolve(
        "institutionalTagsConnection(categoryId: \"#{@cat1.id}\") { nodes { name } }"
      )
      expect(result).to match_array(["Dog", "Cat"])
    end

    it "filters by search term" do
      result = account_type.resolve(
        'institutionalTagsConnection(searchTerm: "Do") { nodes { name } }'
      )
      expect(result).to eq ["Dog"]
    end

    it "returns only active tags when workflowState is active" do
      result = account_type.resolve('institutionalTagsConnection(workflowState: "active") { nodes { name } }')
      expect(result).to eq %w[Blue Cat Dog]
    end

    it "returns only deleted tags when workflowState is deleted" do
      result = account_type.resolve('institutionalTagsConnection(workflowState: "deleted") { nodes { name } }')
      expect(result).to eq ["Archived Tag"]
    end

    it "returns nil for non-admins" do
      result = non_admin_account_type.resolve("institutionalTagsConnection { nodes { _id } }")
      expect(result).to be_nil
    end

    it "raises feature flag error when disabled" do
      @account.disable_feature!(:institutional_tags)
      expect { account_type.resolve("institutionalTagsConnection { nodes { _id } }") }
        .to raise_error(GraphQLTypeTester::Error, /feature flag is disabled/)
    end
  end

  describe "top-level institutionalTag query" do
    def run_tag_query(id, current_user: @admin)
      run_query(<<~GQL, current_user:)
        query { institutionalTag(id: "#{id}") { _id name } }
      GQL
    end

    it "resolves a tag by legacy id" do
      result = run_tag_query(@tag1.id)
      expect(result.dig(:data, :institutionalTag, :_id)).to eq @tag1.id.to_s
      expect(result.dig(:data, :institutionalTag, :name)).to eq "Dog"
    end

    it "returns nil for an unknown tag" do
      result = run_tag_query(0)
      expect(result.dig(:data, :institutionalTag)).to be_nil
    end

    it "returns nil for non-admins" do
      result = run_tag_query(@tag1.id, current_user: @non_admin)
      expect(result.dig(:data, :institutionalTag)).to be_nil
    end
  end

  describe "top-level institutionalTagCategory query" do
    def run_category_query(id, current_user: @admin)
      run_query(<<~GQL, current_user:)
        query { institutionalTagCategory(id: "#{id}") { _id name } }
      GQL
    end

    it "resolves a category by legacy id" do
      result = run_category_query(@cat1.id)
      expect(result.dig(:data, :institutionalTagCategory, :_id)).to eq @cat1.id.to_s
      expect(result.dig(:data, :institutionalTagCategory, :name)).to eq "Animals"
    end

    it "returns nil for an unknown category" do
      result = run_category_query(0)
      expect(result.dig(:data, :institutionalTagCategory)).to be_nil
    end

    it "returns nil for non-admins" do
      result = run_category_query(@cat1.id, current_user: @non_admin)
      expect(result.dig(:data, :institutionalTagCategory)).to be_nil
    end
  end
end
