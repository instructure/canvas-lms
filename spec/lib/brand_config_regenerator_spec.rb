#
# Copyright (C) 2016 - present Instructure, Inc.
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

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper.rb')
require 'delayed/testing'

describe BrandConfigRegenerator do
  let(:new_brand_config) { BrandConfig.for(variables: {"ic-brand-primary" => "green"}) }
  def setup_account_family_with_configs
    @parent_account = Account.default
    @parent_account.brand_config = @parent_config = BrandConfig.for(variables: {"ic-brand-primary" => "red"})
    @parent_config.save!
    @parent_account.save!
    @parent_shared_config = @parent_account.shared_brand_configs.create!(
      name: 'parent theme',
      brand_config_md5: @parent_config.md5
    )

    @child_account = Account.create!(parent_account: @parent_account, name: 'child')
    @child_account.brand_config = @child_config = BrandConfig.for(variables: {"ic-brand-global-nav-bgd" => "white"}, parent_md5: @parent_config.md5)
    @child_config.save!
    @child_account.save!
    @child_shared_config = @child_account.shared_brand_configs.create!(
      name: 'child theme',
      brand_config_md5: @child_config.md5
    )

    @grand_child_account = Account.create!(parent_account: @child_account, name: 'grand_child')
    @grand_child_account.brand_config = @grand_child_config = BrandConfig.for(variables: {"ic-brand-global-nav-avatar-border" => "blue"}, parent_md5: @child_config.md5)
    @grand_child_config.save!
    @grand_child_account.save!
    @grand_child_shared_config = @grand_child_account.shared_brand_configs.create!(
      name: 'grandchild theme',
      brand_config_md5: @grand_child_config.md5
    )
  end

  it "generates the right child brand configs and SharedBrandConfigs within subaccounts" do
    setup_account_family_with_configs

    second_config = BrandConfig.for(variables: {"ic-brand-primary" => "orange"}, parent_md5: @child_config.md5)
    second_config.save!
    @second_shared_config = @grand_child_account.shared_brand_configs.create!(
      name: 'second theme',
      brand_config_md5: second_config.md5
    )

    regenerator = BrandConfigRegenerator.new(@parent_account, user_factory, new_brand_config)

    # 5 = 2 "inheriting" accounts + 3 "inheriting" shared configs
    brandable_css_stub = BrandableCSS.stubs(:compile_brand!).times(5)
    Delayed::Testing.drain
    expect(brandable_css_stub).to be_verified
    expect(regenerator.progresses.count).to eq(5)

    # make sure the child account's brand config is based on this new brand config
    expect(@child_account.reload.brand_config.parent).to eq(new_brand_config)
    # make sure the shared brand configs in the child account are all based this new config
    expect(@child_shared_config.reload.brand_config.parent).to eq(new_brand_config)
    # make sure the child'd active theme still is the same as its SharedBrandConfig named 'child theme'
    expect(@child_shared_config.brand_config).to eq(@child_account.brand_config)

    # make sure the same for the grandchild account.
    # (that all of it's configs point to the new one made for the child account)
    expect(@grand_child_account.reload.brand_config.parent).to eq(@child_account.brand_config)
    expect(@grand_child_shared_config.reload.brand_config.parent).to eq(@child_account.brand_config)
    expect(@grand_child_shared_config.brand_config).to eq(@grand_child_account.brand_config)

    # check the extra SavedBrandConfig in the grandchild to make sure it got regerated too
    expect(@second_shared_config.reload.brand_config.parent).to eq(@child_account.brand_config)
  end

  it "handles orphan themes that were not decendant of @parent_account" do
    setup_account_family_with_configs

    bogus_config = BrandConfig.for(variables: {"ic-brand-primary" => "brown"})
    bogus_config.save!

    @child_account.brand_config = child_config = BrandConfig.for(
      variables: {"ic-brand-primary" => "brown"},
      parent_md5: bogus_config.md5
    )
    child_config.save!
    @child_account.save!

    regenerator = BrandConfigRegenerator.new(@parent_account, user_factory, new_brand_config)

    brandable_css_stub = BrandableCSS.stubs(:compile_brand!).times(4)
    Delayed::Testing.drain
    expect(brandable_css_stub).to be_verified
    expect(regenerator.progresses.count).to eq(4)

    expect(@child_account.reload.brand_config.parent).to eq(new_brand_config)
  end

  it "handles reverting to default (nil) theme correctly" do
    setup_account_family_with_configs

    regenerator = BrandConfigRegenerator.new(@parent_account, user_factory, nil)

    brandable_css_stub = BrandableCSS.stubs(:compile_brand!).times(4)
    Delayed::Testing.drain
    expect(brandable_css_stub).to be_verified
    expect(regenerator.progresses.count).to eq(4)

    expect(@child_account.reload.brand_config.parent).to eq(nil)
    expect(@child_shared_config.reload.brand_config.parent).to eq(nil)
    expect(@child_shared_config.brand_config).to eq(@child_account.brand_config)

    expect(@grand_child_account.reload.brand_config.parent).to eq(@child_account.brand_config)
    expect(@grand_child_shared_config.reload.brand_config.parent).to eq(@child_account.brand_config)
    expect(@grand_child_shared_config.brand_config).to eq(@grand_child_account.brand_config)
  end

  it "handles site_admin correctly" do
    setup_account_family_with_configs
    site_admin_config = BrandConfig.for(variables: {"ic-brand-primary" => "orange"})
    site_admin_config.save!

    regenerator = BrandConfigRegenerator.new(Account.site_admin, user_factory, new_brand_config)

    # 6 = 3 "inheriting" accounts = 3 "inheriting" shared configs
    brandable_css_stub = BrandableCSS.stubs(:compile_brand!).times(6)
    Delayed::Testing.drain
    expect(brandable_css_stub).to be_verified
    expect(regenerator.progresses.count).to eq(6)

    expect(Account.site_admin.brand_config).to eq(new_brand_config)

    expect(@parent_account.reload.brand_config.parent).to eq(new_brand_config)
    expect(@parent_shared_config.reload.brand_config.parent).to eq(new_brand_config)
    expect(@parent_shared_config.brand_config).to eq(@parent_account.brand_config)

    expect(@child_account.reload.brand_config.parent).to eq(@parent_account.brand_config)
    expect(@child_shared_config.reload.brand_config.parent).to eq(@parent_account.brand_config)
    expect(@child_shared_config.brand_config).to eq(@child_account.brand_config)
  end
end
