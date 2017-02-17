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
require 'db/migrate/20150709205405_create_k12_theme.rb'

describe BrandConfig do
  it "should create an instance with a parent_md5" do
    @bc = BrandConfig.create(variables: {"ic-brand-primary" => "#321"}, parent_md5: "123")
    expect(@bc.valid?).to be_truthy
  end

  def setup_subaccount_with_config
    @parent_account = Account.default
    @parent_config = BrandConfig.create(variables: {"ic-brand-primary" => "#321"})

    @subaccount = Account.create!(:parent_account => @parent_account)
    @subaccount_bc = BrandConfig.for(
      variables: {"ic-brand-global-nav-bgd" => "#123"},
      parent_md5: @parent_config.md5,
      js_overrides: nil,
      css_overrides: nil,
      mobile_js_overrides: nil,
      mobile_css_overrides: nil
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
        css_overrides: nil,
        mobile_js_overrides: nil,
        mobile_css_overrides: nil
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

  describe "to_json" do
    before :once do
      setup_subaccount_with_config
      @brand_variables = JSON.parse(@subaccount_bc.to_json)
    end

    it "includes custom variables from brand config" do
      expect(@brand_variables["ic-brand-global-nav-bgd"]).to eq '#123'
    end

    it "includes custom variables from parent brand config" do
      expect(@brand_variables["ic-brand-primary"]).to eq '#321'
    end

    it "includes default variables not found in brand config" do
      expect(@brand_variables["ic-link-color"]).to eq '#008EE2'
    end
  end

  describe "save_all_files!" do
    before :once do
      setup_subaccount_with_config
    end

    before :each do
      @json_file = StringIO.new
      @scss_file = StringIO.new
      @subaccount_bc.stubs(:json_file).returns(@json_file)
      @subaccount_bc.stubs(:scss_file).returns(@scss_file)
    end

    describe "with cdn disabled" do
      before :each do
        Canvas::Cdn.expects(:enabled?).returns(false)
        @subaccount_bc.expects(:s3_uploader).never
        File.expects(:delete).never
      end

      it "writes the json represendation to the json file" do
        @subaccount_bc.save_all_files!
        expect(@json_file.string).to eq @subaccount_bc.to_json
      end

      it "writes the scss represendation to scss file" do
        @subaccount_bc.save_all_files!
        expect(@scss_file.string).to eq @subaccount_bc.to_scss
      end
    end

    describe "with cdn enabled" do
      before :each do
        Canvas::Cdn.expects(:enabled?).returns(true)
        s3 = stub(bucket: nil)
        Aws::S3::Resource.stubs(:new).returns(s3)
        @upload_expectation = @subaccount_bc.s3_uploader.expects(:upload_file).once
        @delete_expectation = File.expects(:delete).once
      end

      it "writes the json represendation to the json file" do
        @subaccount_bc.save_all_files!
        expect(@json_file.string).to eq @subaccount_bc.to_json
      end

      it 'uploads json file to s3 if cdn enabled' do
        @upload_expectation.with(@subaccount_bc.public_json_path)
        @subaccount_bc.save_all_files!
      end

      it 'deletes local json file if cdn enabled' do
        @delete_expectation.with(@subaccount_bc.json_file)
        @subaccount_bc.save_all_files!
      end
    end
  end

  it "doesn't let you update an existing brand config" do
    bc = BrandConfig.create(variables: {"ic-brand-primary" => "#321"})
    bc.variables = { "ic-brand-primary" => "#123" }
    expect { bc.save! }.to raise_error(/md5 digest/)
  end

  it "returns a default config" do
    expect(BrandConfig.default).to be_present
  end

  it "returns a k12 config" do
    CreateK12Theme.new.up
    expect(BrandConfig.k12_config).to be_present
  end
end
