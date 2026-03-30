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

describe Types::InstitutionalTagType do
  before(:once) do
    @account = Account.default
    @account.enable_feature!(:institutional_tags)
    @admin = account_admin_user(account: @account)
    @category = institutional_tag_category_model(account: @account, name: "Tag Type Spec Category")
    @tag = institutional_tag_model(account: @account, category: @category, name: "Alpha")
    @user1 = user_model
    @user2 = user_model
    institutional_tag_association_model(account: @account, institutional_tag: @tag, user: @user1)
    institutional_tag_association_model(account: @account, institutional_tag: @tag, user: @user2)
  end

  let(:tag_type) { GraphQLTypeTester.new(@tag, current_user: @admin, domain_root_account: @account) }

  it "exposes basic fields" do
    expect(tag_type.resolve("_id")).to eq @tag.id.to_s
    expect(tag_type.resolve("name")).to eq "Alpha"
    expect(tag_type.resolve("workflowState")).to eq "active"
  end

  it "exposes the category" do
    expect(tag_type.resolve("category { _id }")).to eq @tag.category.id.to_s
  end

  it "returns active associations count" do
    expect(tag_type.resolve("associationsCount")).to eq 2
  end

  it "excludes deleted associations from associationsCount" do
    @tag.institutional_tag_associations.first.update!(workflow_state: "deleted")
    expect(tag_type.resolve("associationsCount")).to eq 1
  end

  describe "usersConnection" do
    it "returns users associated with this tag" do
      ids = tag_type.resolve("usersConnection { nodes { _id } }")
      expect(ids).to match_array([@user1.id.to_s, @user2.id.to_s])
    end

    it "returns nil when feature flag is disabled" do
      @account.disable_feature!(:institutional_tags)
      expect(tag_type.resolve("usersConnection { nodes { _id } }")).to be_nil
    end

    it "returns nil without manage_institutional_tags_view permission" do
      non_admin = user_model
      type = GraphQLTypeTester.new(@tag, current_user: non_admin, domain_root_account: @account)
      expect(type.resolve("usersConnection { nodes { _id } }")).to be_nil
    end
  end
end
