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

describe Types::InstitutionalTagCategoryType do
  before(:once) do
    @account = Account.default
    @account.enable_feature!(:institutional_tags)
    @admin = account_admin_user(account: @account)
    @category = institutional_tag_category_model(account: @account, name: "Beta", description: "My desc")
    @tag1 = institutional_tag_model(account: @account, category: @category, name: "T1")
    @tag2 = institutional_tag_model(account: @account, category: @category, name: "T2")
    @archived_tag = institutional_tag_model(
      account: @account, category: @category, name: "T3", workflow_state: "deleted"
    )
  end

  let(:category_type) { GraphQLTypeTester.new(@category, current_user: @admin, domain_root_account: @account) }

  it "exposes basic fields" do
    expect(category_type.resolve("_id")).to eq @category.id.to_s
    expect(category_type.resolve("name")).to eq "Beta"
    expect(category_type.resolve("description")).to eq "My desc"
    expect(category_type.resolve("workflowState")).to eq "active"
  end

  describe "associationsCount" do
    before(:once) do
      @user1 = user_model
      @user2 = user_model
      institutional_tag_association_model(account: @account, institutional_tag: @tag1, user: @user1)
      institutional_tag_association_model(account: @account, institutional_tag: @tag1, user: @user2)
      institutional_tag_association_model(account: @account, institutional_tag: @tag2, user: @user1)
    end

    it "returns the total count of active associations across all active tags" do
      expect(category_type.resolve("associationsCount")).to eq 3
    end

    it "excludes associations on deleted tags" do
      institutional_tag_association_model(account: @account, institutional_tag: @archived_tag, user: @user2)
      expect(category_type.resolve("associationsCount")).to eq 3
    end

    it "excludes deleted associations" do
      @tag2.institutional_tag_associations.first.update!(workflow_state: "deleted")
      expect(category_type.resolve("associationsCount")).to eq 2
    end
  end

  describe "tagsConnection" do
    it "returns only active tags" do
      ids = category_type.resolve("tagsConnection { nodes { _id } }")
      expect(ids).to match_array([@tag1.id.to_s, @tag2.id.to_s])
    end

    it "does not include deleted tags" do
      ids = category_type.resolve("tagsConnection { nodes { _id } }")
      expect(ids).not_to include(@archived_tag.id.to_s)
    end
  end
end
