# frozen_string_literal: true

# coding: utf-8
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

  describe "to_js" do
    before :once do
      setup_subaccount_with_config
    end

    it "exports to the correct global variable" do
      expect(@subaccount_bc.to_js).to eq "CANVAS_ACTIVE_BRAND_VARIABLES = #{@subaccount_bc.to_json};"
    end
  end

  describe "to_css" do
    before :once do
      setup_subaccount_with_config
    end

    it "defines right-looking css in the :root scope" do
      expect(@subaccount_bc.to_css).to match /:root \{
[\s|\S]*--ic-brand-primary-darkened-5: #312111;
--ic-brand-primary-darkened-10: #2E1F10;
--ic-brand-primary-darkened-15: #2C1D0F;
--ic-brand-primary-lightened-5: #3D2D1C;
--ic-brand-primary-lightened-10: #473828;
--ic-brand-primary-lightened-15: #514334;
--ic-brand-button--primary-bgd-darkened-5: #312111;
--ic-brand-button--primary-bgd-darkened-15: #2C1D0F;
--ic-brand-button--secondary-bgd-darkened-5: #2B3942;
--ic-brand-button--secondary-bgd-darkened-15: #27333B;
[\s|\S]*--ic-brand-primary: #321;
[\s|\S]*--ic-brand-global-nav-bgd: #123;
/
    end
  end

  describe "save_all_files!" do
    before :once do
      setup_subaccount_with_config
    end

    before do
      @json_file = StringIO.new
      @js_file = StringIO.new
      @css_file = StringIO.new
      allow(@subaccount_bc).to receive(:json_file).and_return(@json_file)
      allow(@subaccount_bc).to receive(:js_file).and_return(@js_file)
      allow(@subaccount_bc).to receive(:css_file).and_return(@css_file)
    end

    describe "with cdn disabled" do
      before do
        expect(Canvas::Cdn).to receive(:enabled?).at_least(:once).and_return(false)
        expect(@subaccount_bc).to receive(:s3_uploader).never
        expect(File).to receive(:delete).never
      end

      it "writes the json representation to the json file" do
        @subaccount_bc.save_all_files!
        expect(@json_file.string).to eq @subaccount_bc.to_json
      end

      it "writes the JavaScript representation to the js file" do
        @subaccount_bc.save_all_files!
        expect(@js_file.string).to eq "CANVAS_ACTIVE_BRAND_VARIABLES = #{@subaccount_bc.to_json};"
      end

      it "writes the CSS variables to the css file" do
        @subaccount_bc.save_all_files!
        expect(@css_file.string).to eq @subaccount_bc.to_css
      end

    end

    describe "with cdn enabled" do
      before :each do
        expect(Canvas::Cdn).to receive(:enabled?).at_least(:once).and_return(true)
        s3 = double(bucket: nil)
        allow(Aws::S3::Resource).to receive(:new).and_return(s3)
        @upload_expectation = expect(@subaccount_bc.s3_uploader).to receive(:upload_file).exactly(3).times
        expect(File).to receive(:delete).exactly(3).times
      end

      it "writes the json representation to the json file" do
        @subaccount_bc.save_all_files!
        expect(@json_file.string).to eq @subaccount_bc.to_json
      end

      it "writes the javascript representation to the js file" do
        @subaccount_bc.save_all_files!
        expect(@js_file.string).to eq @subaccount_bc.to_js
      end

      it "writes the CSS variables representation to the css file" do
        @subaccount_bc.save_all_files!
        expect(@css_file.string).to eq @subaccount_bc.to_css
      end

      it 'uploads json, css & js file to s3' do
        @upload_expectation.with(eq(
          @subaccount_bc.public_json_path).or eq(
          @subaccount_bc.public_css_path).or eq(
          @subaccount_bc.public_js_path))
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

  it "expects md5 to be correct" do
    what_it_should_be_if_you_have_not_ran_gulp_rev = 85663486644871658581990
    what_it_should_be_if_you_have = 839184435922331766
    expect(BrandableCSS.migration_version).to eq(what_it_should_be_if_you_have_not_ran_gulp_rev).or eq(what_it_should_be_if_you_have)
    # if this spec fails, you have probably made a change to app/stylesheets/brandable_variables.json
    # you will need to update the migration that runs brand_configs and update these md5s that are
    # with and without running `rake canvas:compile_assets`
    # Also update the other use of 85663486644871658581990 in lib/brandable_css.rb
  end
end
