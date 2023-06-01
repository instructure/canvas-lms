# frozen_string_literal: true

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

describe MathMan do
  let(:latex) do
    '\sqrt{25}+12^{12}'
  end
  # we explicitly don't want a trailing slash here for the url tests
  let(:service_url) { "http://www.mml-service.com/beta" }
  let(:use_for_mml) { false }
  let(:use_for_svg) { false }

  before do
    @original_fallback = DynamicSettings.fallback_data
    DynamicSettings.fallback_data = {
      config: {
        canvas: {
          "math-man": {
            base_url: service_url,
          }
        }
      }
    }
    PluginSetting.create!(
      name: "mathman",
      settings: {
        use_for_mml:,
        use_for_svg:
      }.with_indifferent_access
    )
  end

  after do
    DynamicSettings.fallback_data = @original_fallback
  end

  describe ".url_for" do
    it "must retain the path from base_url setting" do
      url = MathMan.url_for(latex:, target: :mml)
      parsed = Addressable::URI.parse(url)
      expect(parsed.path).to eq("/beta/mml")
    end

    it "includes target string in generated url" do
      expect(MathMan.url_for(latex:, target: :mml)).to match(/mml/)
      expect(MathMan.url_for(latex:, target: :svg)).to match(/svg/)
    end

    it "errors if DynamicSettings is not configured" do
      DynamicSettings.fallback_data = nil
      expect { MathMan.url_for(latex:, target: :mml) }.to raise_error MathMan::InvalidConfigurationError
    end

    it "includes scale param if present" do
      expect(MathMan.url_for(latex:, target: :svg, scale: "2")).to match(/&scale=2/)
    end

    it "excludes scale param if not present" do
      expect(MathMan.url_for(latex:, target: :svg)).not_to match(/&scale=2/)
    end
  end

  describe ".use_for_mml?" do
    it "returns false when set to false" do
      expect(MathMan.use_for_mml?).to be_falsey
    end

    it "returns false when PluginSetting is missing" do
      PluginSetting.where(name: "mathman").first.destroy
      expect(MathMan.use_for_mml?).to be_falsey
    end

    it "does not error if DynamicSettings is not configured" do
      DynamicSettings.fallback_data = nil
      expect(MathMan.use_for_mml?).to be_falsey
    end

    context "when appropriately configured" do
      let(:use_for_mml) { true }

      it "returns true" do
        expect(MathMan.use_for_mml?).to be_truthy
      end
    end
  end

  describe ".use_for_svg?" do
    it "returns false when set to false" do
      expect(MathMan.use_for_svg?).to be_falsey
    end

    it "returns false when PluginSetting is missing" do
      PluginSetting.where(name: "mathman").first.destroy
      expect(MathMan.use_for_svg?).to be_falsey
    end

    it "does not error if DynamicSettings is not configured" do
      DynamicSettings.fallback_data = nil
      expect(MathMan.use_for_svg?).to be_falsey
    end

    context "when appropriately configured" do
      let(:use_for_svg) { true }

      it "returns true" do
        expect(MathMan.use_for_svg?).to be_truthy
      end
    end
  end
end
