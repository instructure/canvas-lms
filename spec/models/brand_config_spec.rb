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

describe BrandConfig do
  it "should create an instance with a parent_md5" do
    @bc = BrandConfig.create(variables: {"ic-brand-primary" => "#321"}, parent_md5: "123")
    expect(@bc.valid?).to be_truthy
  end

  def setup_subaccount_with_config
    @parent_account = Account.default
    @parent_account.enable_feature!(:use_new_styles)
    @parent_config = BrandConfig.create(variables: {"ic-brand-primary" => "#321"})

    @subaccount = Account.create!(:parent_account => @parent_account)
    @subaccount_bc = BrandConfig.for(
      variables: {"ic-brand-global-nav-bgd" => "#123"},
      parent_md5: @parent_config.md5,
      js_overrides: nil,
      css_overrides: nil
    )
    @subaccount_bc.save!
  end

  describe "effective_variables" do
    before :once do
      setup_subaccount_with_config
    end

    it "should inherit effective_variables from its parent" do
      expect(@subaccount_bc.variables.keys.include?("ic-brand-global-nav-bgd")).to be_truthy
      expect(@subaccount_bc.variables.keys.include?("ic-brand-primary")).to be_falsey

      expect(@subaccount_bc.effective_variables["ic-brand-global-nav-bgd"]).to eq "#123"
      expect(@subaccount_bc.effective_variables["ic-brand-primary"]).to eq "#321"
    end

    it "should overwrite parent variables if explicitly stated" do
      @new_sub_bc = BrandConfig.for(
        variables: {"ic-brand-global-nav-bgd" => "#123", "ic-brand-primary" => "red"},
        parent_md5: @parent_config.md5,
        js_overrides: nil,
        css_overrides: nil
      )
      @new_sub_bc.save!

      expect(@new_sub_bc.effective_variables["ic-brand-global-nav-bgd"]).to eq "#123"
      expect(@new_sub_bc.effective_variables["ic-brand-primary"]).to eq "red"
    end
  end

  describe "chain_of_ancestor_configs" do
    before :once do
      setup_subaccount_with_config
    end

    it "should properly find ancestors" do
      expect(@subaccount_bc.chain_of_ancestor_configs.include?(@parent_config)).to be_truthy
      expect(@subaccount_bc.chain_of_ancestor_configs.include?(@subaccount_bc)).to be_truthy
      expect(@subaccount_bc.chain_of_ancestor_configs.length).to eq 2

      expect(@parent_config.chain_of_ancestor_configs.include?(@subaccount_bc)).to be_falsey
      expect(@parent_config.chain_of_ancestor_configs.include?(@parent_config)).to be_truthy
      expect(@parent_config.chain_of_ancestor_configs.length).to eq 1
    end
  end
end