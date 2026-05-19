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

# Tests for the institutionalTagsConnection field added to UserType,
# and the top-level user(id:) query added to QueryType.
describe "UserType institutionalTagsConnection" do
  before(:once) do
    @account = Account.default
    @account.enable_feature!(:institutional_tags)
    @admin = account_admin_user(account: @account)
    @target_user = user_model

    @category = institutional_tag_category_model(account: @account, name: "User Spec Category")
    @tag1 = institutional_tag_model(account: @account, category: @category, name: "Tag A")
    @tag2 = institutional_tag_model(account: @account, category: @category, name: "Tag B")
    @deleted_tag = institutional_tag_model(account: @account, category: @category, name: "Deleted Tag")

    institutional_tag_association_model(account: @account, institutional_tag: @tag1, user: @target_user)
    institutional_tag_association_model(account: @account, institutional_tag: @tag2, user: @target_user)
    institutional_tag_association_model(
      account: @account, institutional_tag: @deleted_tag, user: @target_user, workflow_state: "deleted"
    )
  end

  def user_type(user = @target_user, current_user: @admin)
    GraphQLTypeTester.new(user, current_user:, domain_root_account: @account)
  end

  describe "institutionalTagsConnection field on UserType" do
    it "returns active tags associated with the user" do
      result = user_type.resolve(
        "institutionalTagsConnection(accountId: \"#{@account.id}\") { nodes { name } }"
      )
      expect(result).to match_array(["Tag A", "Tag B"])
    end

    it "excludes tags with deleted associations" do
      result = user_type.resolve(
        "institutionalTagsConnection(accountId: \"#{@account.id}\") { nodes { name } }"
      )
      expect(result).not_to include("Deleted Tag")
    end

    it "returns nil when feature flag is disabled" do
      @account.disable_feature!(:institutional_tags)
      result = user_type.resolve(
        "institutionalTagsConnection(accountId: \"#{@account.id}\") { nodes { _id } }"
      )
      expect(result).to be_nil
    end

    it "returns nil without manage_institutional_tags_view permission" do
      result = user_type(@target_user, current_user: user_model).resolve(
        "institutionalTagsConnection(accountId: \"#{@account.id}\") { nodes { _id } }"
      )
      expect(result).to be_nil
    end

    it "returns nil for a non-root account id" do
      sub_account = @account.sub_accounts.create!(name: "Sub")
      result = user_type.resolve(
        "institutionalTagsConnection(accountId: \"#{sub_account.id}\") { nodes { _id } }"
      )
      expect(result).to be_nil
    end
  end

  describe "top-level user query" do
    def run_query(id, current_user: @admin)
      CanvasSchema.execute(
        <<~GQL,
          query {
            user(id: "#{id}") {
              _id
              institutionalTagsConnection(accountId: "#{@account.id}") {
                nodes { name }
              }
            }
          }
        GQL
        context: {
          current_user:,
          domain_root_account: @account,
          request: ActionDispatch::TestRequest.create
        }
      ).to_h.with_indifferent_access
    end

    it "resolves the user by legacy id" do
      result = run_query(@target_user.id)
      expect(result.dig(:data, :user, :_id)).to eq @target_user.id.to_s
    end

    it "returns the user's institutional tags" do
      result = run_query(@target_user.id)
      names = result.dig(:data, :user, :institutionalTagsConnection, :nodes).pluck(:name)
      expect(names).to match_array(["Tag A", "Tag B"])
    end

    it "returns nil for an unknown user" do
      result = run_query(0)
      expect(result.dig(:data, :user)).to be_nil
    end
  end
end
