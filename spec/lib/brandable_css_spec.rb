#
# Copyright (C) 2016 Instructure, Inc.
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

describe BrandableCSS do
  describe "all_brand_variable_values" do
    it "returns defaults if called without a brand config" do
      expect(BrandableCSS.all_brand_variable_values["ic-link-color"]).to eq '#0081bd'
    end

    it "includes image_url asset path for default images" do
      # un-memoize so it calls image_url stub
      if BrandableCSS.instance_variable_get(:@variables_map_with_image_urls)
        BrandableCSS.remove_instance_variable(:@variables_map_with_image_urls)
      end
      url = "https://test.host/image.png"
      if CANVAS_RAILS4_0
        DummyControllerWithCorrectAssetUrls.helpers.stubs(:image_url).returns(url)
      else
        ActionController::Base.helpers.stubs(:image_url).returns(url)
      end
      tile_wide = BrandableCSS.all_brand_variable_values["ic-brand-msapplication-tile-wide"]
      expect(tile_wide).to eq url
    end

    describe "when called with a brand config" do
      before :once do
        parent_account = Account.default
        parent_account.enable_feature!(:use_new_styles)
        parent_config = BrandConfig.create(variables: {"ic-brand-primary" => "#321"})

        subaccount_bc = BrandConfig.for(
          variables: {"ic-brand-global-nav-bgd" => "#123"},
          parent_md5: parent_config.md5,
          js_overrides: nil,
          css_overrides: nil,
          mobile_js_overrides: nil,
          mobile_css_overrides: nil
        )
        subaccount_bc.save!
        @brand_variables = BrandableCSS.all_brand_variable_values(subaccount_bc)
      end

      it "includes custom variables from brand config" do
        expect(@brand_variables["ic-brand-global-nav-bgd"]).to eq '#123'
      end

      it "includes custom variables from parent brand config" do
        expect(@brand_variables["ic-brand-primary"]).to eq '#321'
      end

      it "includes default variables not found in brand config" do
        expect(@brand_variables["ic-link-color"]).to eq '#0081bd'
      end
    end
  end

  describe "default_json" do
    it "includes default variables not found in brand config" do
      brand_variables = JSON.parse(BrandableCSS.default_json)
      expect(brand_variables["ic-link-color"]).to eq '#0081bd'
    end
  end

  describe "save_default_file!" do
    it "writes the default json represendation to the default json file" do
      Canvas::Cdn.stubs(:enabled?).returns(false)
      file = StringIO.new
      BrandableCSS.stubs(:default_brand_json_file).returns(file)
      BrandableCSS.save_default_json!
      expect(file.string).to eq BrandableCSS.default_json
    end

    it 'uploads file to s3 if cdn is enabled' do
      Canvas::Cdn.stubs(:enabled?).returns(true)
      file = StringIO.new
      BrandableCSS.stubs(:default_brand_json_file).returns(file)
      File.stubs(:delete)
      BrandableCSS.s3_uploader.expects(:upload_file).with(BrandableCSS.public_default_json_path)
      BrandableCSS.save_default_json!
    end

    it 'delete the local file if cdn is enabled' do
      Canvas::Cdn.stubs(:enabled?).returns(true)
      file = StringIO.new
      BrandableCSS.stubs(:default_brand_json_file).returns(file)
      File.expects(:delete).with(BrandableCSS.default_brand_json_file)
      BrandableCSS.s3_uploader.expects(:upload_file)
      BrandableCSS.save_default_json!
    end
  end
end
