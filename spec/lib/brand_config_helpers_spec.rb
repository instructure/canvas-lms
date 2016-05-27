# coding: utf-8
#
# Copyright (C) 2015 Instructure, Inc.
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

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper.rb')
require 'delayed/testing'

describe BrandConfigHelpers do
  def setup_account_family_with_configs
    @parent_account = Account.default
    @parent_account.enable_feature!(:use_new_styles)
    @parent_config = BrandConfig.for(
      variables: {"ic-brand-primary" => "red"},
      js_overrides: nil,
      css_overrides: nil,
      mobile_js_overrides: nil,
      mobile_css_overrides: nil,
      parent_md5: nil
    )
    @parent_config.save!
    @parent_account.brand_config_md5 = @parent_config.md5
    @parent_account.save!

    @child_account = Account.create!(:parent_account => @parent_account)
    @child_config = BrandConfig.for(
      variables: {"ic-brand-global-nav-bgd" => "white"},
      parent_md5: @parent_config.md5,
      js_overrides: nil,
      css_overrides: nil,
      mobile_js_overrides: nil,
      mobile_css_overrides: nil
    )
    @child_config.save!
    @child_account.brand_config_md5 = @child_config.md5
    @child_account.save!

    @grand_child_account = Account.create!(:parent_account => @child_account)
    @grand_child_config = BrandConfig.for(
      variables: {"ic-brand-global-nav-avatar-border" => "blue"},
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

    it "should return nill without a parent" do
      expect(@parent_account.first_parent_brand_config).to be_nil
    end

    it "should work when parent is a root account" do
      expect(@child_account.first_parent_brand_config).to eq @parent_config
    end

    it "should work when parent is a not root account" do
      expect(@grand_child_account.first_parent_brand_config).to eq @child_config
    end

    it "should work with site_admin" do
      Account.site_admin.enable_feature!(:use_new_styles)
      site_admin_config = BrandConfig.for(variables: {"ic-brand-primary" => "orange"})
      site_admin_config.save!
      regenerator = BrandConfigRegenerator.new(Account.site_admin, user, site_admin_config)

      brandable_css_stub = BrandableCSS.stubs(:compile_brand!)
      Delayed::Testing.drain

      expect(@parent_account.first_parent_brand_config).to eq site_admin_config
      expect(Account.site_admin.first_parent_brand_config).to be_nil
    end
  end
end
