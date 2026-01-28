# frozen_string_literal: true

#
# Copyright (C) 2015 - present Instructure, Inc.
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

require "delayed/testing"

describe BrandConfigHelpers do
  def setup_account_family_with_configs
    @parent_account = Account.default
    @parent_config = BrandConfig.for(
      variables: { "ic-brand-primary" => "red" },
      js_overrides: nil,
      css_overrides: nil,
      mobile_js_overrides: nil,
      mobile_css_overrides: nil,
      parent_md5: nil
    )
    @parent_config.save!
    @parent_account.brand_config_md5 = @parent_config.md5
    @parent_account.save!

    @child_account = Account.create!(parent_account: @parent_account)
    @child_config = BrandConfig.for(
      variables: { "ic-brand-global-nav-bgd" => "white" },
      parent_md5: @parent_config.md5,
      js_overrides: nil,
      css_overrides: nil,
      mobile_js_overrides: nil,
      mobile_css_overrides: nil
    )
    @child_config.save!
    @child_account.brand_config_md5 = @child_config.md5
    @child_account.save!

    @grand_child_account = Account.create!(parent_account: @child_account)
    @grand_child_config = BrandConfig.for(
      variables: { "ic-brand-global-nav-avatar-border" => "blue" },
      parent_md5: @child_config.md5,
      js_overrides: nil,
      css_overrides: nil,
      mobile_js_overrides: nil,
      mobile_css_overrides: nil
    )
    @grand_child_config.save!
    @grand_child_account.brand_config_md5 = @grand_child_config.md5
    @grand_child_account.save!
  end

  describe "first_parent_brand_config" do
    before :once do
      setup_account_family_with_configs
    end

    it "returns nill without a parent" do
      expect(@parent_account.first_parent_brand_config).to be_nil
    end

    it "works when parent is a root account" do
      expect(@child_account.first_parent_brand_config).to eq @parent_config
    end

    it "works when parent is a not root account" do
      expect(@grand_child_account.first_parent_brand_config).to eq @child_config
    end

    it "works with site_admin" do
      site_admin_config = BrandConfig.for(variables: { "ic-brand-primary" => "orange" })
      site_admin_config.save!
      BrandConfigRegenerator.process(Account.site_admin, user_factory, site_admin_config)

      Delayed::Testing.drain

      expect(@parent_account.first_parent_brand_config).to eq site_admin_config
      expect(Account.site_admin.first_parent_brand_config).to be_nil
    end
  end

  describe "branding_allowed?" do
    it "returns true for root accounts" do
      root_account = Account.create!
      expect(root_account.branding_allowed?).to be true
    end

    context "with sub-accounts" do
      it "returns false when root account has sub_account_includes disabled" do
        root_account = Account.create!
        sub_account = Account.create!(parent_account: root_account, root_account:)

        root_account.settings[:sub_account_includes] = false
        root_account.save!

        expect(sub_account.branding_allowed?).to be_falsey
      end

      it "returns true when root account has sub_account_includes enabled" do
        root_account = Account.create!
        sub_account = Account.create!(parent_account: root_account, root_account:)

        root_account.settings[:sub_account_includes] = true
        root_account.save!

        expect(sub_account.branding_allowed?).to be true
      end
    end

    context "with consortium parent" do
      specs_require_sharding

      before :once do
        @consortium_parent = Account.create!(name: "Consortium Parent")
        @consortium_parent.settings[:consortium_parent_account] = true
        @consortium_parent.save!

        @consortium_child = Account.create!(name: "Consortium Child")
        @consortium_parent.add_consortium_child(@consortium_child)

        @sub_account = Account.create!(
          name: "Sub Account",
          parent_account: @consortium_child,
          root_account: @consortium_child
        )
      end

      it "returns true when consortium parent has sub_account_includes enabled" do
        @consortium_parent.settings[:sub_account_includes] = true
        @consortium_parent.save!

        expect(@sub_account.reload.branding_allowed?).to be true
      end

      it "returns false when consortium parent has sub_account_includes disabled" do
        @consortium_parent.settings[:sub_account_includes] = false
        @consortium_parent.save!

        expect(@sub_account.reload.branding_allowed?).to be false
      end
    end
  end
end
