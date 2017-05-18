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
#

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper.rb')

describe BrandableCSS do
  describe "all_brand_variable_values" do
    it "returns defaults if called without a brand config" do
      expect(BrandableCSS.all_brand_variable_values["ic-link-color"]).to eq '#008EE2'
    end

    it "includes image_url asset path for default images" do
      # un-memoize so it calls image_url stub
      if BrandableCSS.instance_variable_get(:@variables_map_with_image_urls)
        BrandableCSS.remove_instance_variable(:@variables_map_with_image_urls)
      end
      url = "https://test.host/image.png"
      ActionController::Base.helpers.stubs(:image_url).returns(url)
      tile_wide = BrandableCSS.all_brand_variable_values["ic-brand-msapplication-tile-wide"]
      expect(tile_wide).to eq url
    end

    describe "when called with a brand config" do
      before :once do
        parent_account = Account.default
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
        expect(@brand_variables["ic-link-color"]).to eq '#008EE2'
      end
    end
  end

  describe "all_brand_variable_values_as_js" do
    it "eports the default js to the right global variable" do
      expected_js = "CANVAS_ACTIVE_BRAND_VARIABLES = #{BrandableCSS.default_json};"
      expect(BrandableCSS.default_js).to eq expected_js
    end
  end

  describe "default_json" do
    it "includes default variables not found in brand config" do
      brand_variables = JSON.parse(BrandableCSS.default_json)
      expect(brand_variables["ic-link-color"]).to eq '#008EE2'
    end
  end

  describe "save_default_json!" do
    it "writes the default json representation to the default json file" do
      Canvas::Cdn.stubs(:enabled?).returns(false)
      file = StringIO.new
      BrandableCSS.stubs(:default_brand_json_file).returns(file)
      BrandableCSS.save_default_json!
      expect(file.string).to eq BrandableCSS.default_json
    end

    it 'uploads json file to s3 if cdn is enabled' do
      Canvas::Cdn.stubs(:enabled?).returns(true)
      Canvas::Cdn.stubs(:config).returns(ActiveSupport::OrderedOptions.new.merge(region: 'us-east-1'))

      file = StringIO.new
      BrandableCSS.stubs(:default_brand_json_file).returns(file)
      File.stubs(:delete)
      BrandableCSS.s3_uploader.expects(:upload_file).with(BrandableCSS.public_default_json_path)
      BrandableCSS.save_default_json!
    end

    it 'deletes the local json file if cdn is enabled' do
      Canvas::Cdn.stubs(:enabled?).returns(true)
      Canvas::Cdn.stubs(:config).returns(ActiveSupport::OrderedOptions.new.merge(region: 'us-east-1'))
      file = StringIO.new
      BrandableCSS.stubs(:default_brand_json_file).returns(file)
      File.expects(:delete).with(BrandableCSS.default_brand_json_file)
      BrandableCSS.s3_uploader.expects(:upload_file)
      BrandableCSS.save_default_json!
    end
  end

  describe "save_default_js!" do
    it "writes the default javascript representation to the default js file" do
      Canvas::Cdn.stubs(:enabled?).returns(false)
      file = StringIO.new
      BrandableCSS.stubs(:default_brand_js_file).returns(file)
      BrandableCSS.save_default_js!
      expect(file.string).to eq BrandableCSS.default_js
    end

    it 'uploads javascript file to s3 if cdn is enabled' do
      Canvas::Cdn.stubs(:enabled?).returns(true)
      Canvas::Cdn.stubs(:config).returns(ActiveSupport::OrderedOptions.new.merge(region: 'us-east-1'))

      file = StringIO.new
      BrandableCSS.stubs(:default_brand_js_file).returns(file)
      File.stubs(:delete)
      BrandableCSS.s3_uploader.expects(:upload_file).with(BrandableCSS.public_default_js_path)
      BrandableCSS.save_default_js!
    end

    it 'delete the local javascript file if cdn is enabled' do
      Canvas::Cdn.stubs(:enabled?).returns(true)
      Canvas::Cdn.stubs(:config).returns(ActiveSupport::OrderedOptions.new.merge(region: 'us-east-1'))
      file = StringIO.new
      BrandableCSS.stubs(:default_brand_js_file).returns(file)
      File.expects(:delete).with(BrandableCSS.default_brand_js_file)
      BrandableCSS.s3_uploader.expects(:upload_file)
      BrandableCSS.save_default_js!
    end
  end
end
