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

describe BrandConfigHelpers do
  def setup_account_family_with_configs
    @parent_account = Account.default
    @parent_account.enable_feature!(:use_new_styles)
    @parent_config = BrandConfig.for(
      variables: {"ic-brand-primary" => "red"},
      js_overrides: nil,
      css_overrides: nil,
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
      css_overrides: nil
    )
    @child_config.save!
    @child_account.brand_config_md5 = @child_config.md5
    @child_account.save!

    @grand_child_account = Account.create!(:parent_account => @child_account)
    @grand_child_config = BrandConfig.for(
      variables: {"ic-brand-global-nav-avatar-border" => "blue"},
      parent_md5: @child_config.md5,
      js_overrides: nil,
      css_overrides: nil
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
  end

  def get_equivalent_md5(config, new_parent_config_md5)
    config.instance_eval do
      Digest::MD5.hexdigest([
        variables.to_s,
        css_overrides,
        js_overrides,
        new_parent_config_md5
      ].join)
    end
  end

  describe "get_descendant_configs_by_account_id" do
    before :once do
      setup_account_family_with_configs
    end
    it "return hash with both children and grand children with new md5s" do
      @new_parent_config = BrandConfig.for(
        variables: {"ic-brand-primary" => "purple"},
        js_overrides: nil,
        css_overrides: nil,
        parent_md5: nil
      )
      @new_parent_config.save!
      new_parent_config_md5 = @new_parent_config.md5
      @parent_account.brand_config_md5 = new_parent_config_md5
      @parent_account.save!

      new_configs = @parent_account.get_descendant_configs_by_account_id(new_parent_config_md5, is_base_theme: true, base_md5: new_parent_config_md5)

      # expect(new_configs.keys.include?(@parent_account.id)).to be_truthy
      expect(new_configs.keys.include?(@child_account.id)).to be_truthy
      expect(new_configs.keys.include?(@grand_child_account.id)).to be_truthy

      equivalent_child_md5 = get_equivalent_md5(@child_config, new_parent_config_md5)
      equivalent_grand_child_md5 = get_equivalent_md5(@grand_child_config, equivalent_child_md5)

      # expect(new_configs[@parent_account.id].md5).to eq(new_parent_config_md5)
      expect(new_configs[@child_account.id].md5).to eq(equivalent_child_md5)
      expect(new_configs[@grand_child_account.id].md5).to eq(equivalent_grand_child_md5)
    end
  end
end