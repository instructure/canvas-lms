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

# Why are these in spec/selenium?
# ===============================
# Although these tests don't use selenium at all, they need to be have assets
# compiled in order to work. eg: `gulp rev` and `brandable_css` need to run first.
# By putting them in spec/selenium, our build server will run them with the rest
# of the browser specs, after it has compiled assets.

require_relative "../common"

RE_SHORT_MD5 = /\A[a-f0-9]{10}\z/ # 10 chars of an MD5

describe "Stuff related to how we load stuff from CDN and use brandable_css" do
  include_context "in-process server selenium tests"

  describe BrandableCSS do
    describe "cache_for" do
      it "finds the right fingerprints for normal bundles, plugins & handlebars" do
        sample_bundles = {
          "bundles/common" => false,
          "../../gems/plugins/analytics/app/stylesheets/analytics" => false, # to test that it works with plugins
          "jst/FindFlickrImageView" => false, # to test that it works with handlebars-loaded css
          "jst/messageStudentsDialog" => true
        }
        sample_bundles.each do |bundle_name, includes_no_variables|
          fingerprints = BrandableCSS.variants.map do |variant|
            data = BrandableCSS.cache_for(bundle_name, variant)
            expect(data[:combinedChecksum]).to match(RE_SHORT_MD5)
            expect(!!(data[:includesNoVariables])).to eq(includes_no_variables)
            data
          end

          expect(fingerprints.length).to eq(4), "We have 4 variants"
          msg = "make sure the combined results match the result of all_fingerprints_for"
          expect(fingerprints).to eq(BrandableCSS.all_fingerprints_for(bundle_name).values), msg
          next unless includes_no_variables

          msg = "all variants should output the same css if a bundle doesn't pull in the variables file"
          unique_fingerprints = fingerprints.pluck(:combinedChecksum).uniq
          expect(unique_fingerprints.length).to eq(1), msg
        end
      end
    end
  end

  def assert_tag(tag, attribute, value)
    selector = "#{tag}[#{attribute}='#{value}']"
    expect(f(selector)).to be_present
  end

  def check_css(bundle_name)
    variant = "new_styles_normal_contrast"
    fingerprint = BrandableCSS.cache_for(bundle_name, variant)[:combinedChecksum]
    expect(fingerprint).to match(RE_SHORT_MD5)
    url = "#{app_url}/dist/brandable_css/#{variant}/#{bundle_name}-#{fingerprint}.css"
    assert_tag("link", "href", url)
  end

  def check_asset(tag, asset_path, skip_rev = false)
    unless skip_rev
      asset_path = Canvas::Cdn.registry.url_for(asset_path)
      expect(asset_path).to be_present
    end
    attribute = (tag == "link") ? "href" : "src"
    url = "#{app_url}#{asset_path}"
    assert_tag(tag, attribute, url)
  end

  it "has the right urls for script tag and stylesheets on the login page" do
    expect(Canvas::Cdn.config).to receive(:host).at_least(:once).and_return(app_url)
    Account.default.update!(default_locale: "ca")

    get "/login/canvas"

    ["bundles/common", "bundles/login"].each { |bundle| check_css(bundle) }
    ["images/favicon-yellow.ico", "images/apple-touch-icon.png"].each { |i| check_asset("link", i) }

    check_asset("script", "/timezone/Etc/UTC.js")
    check_asset("script", "/timezone/ca_ES.js")
    Canvas::Cdn.registry.scripts_for("main").each { |c| check_asset("script", c, true) }

    expect(element_exists?("head script[src*='/moment/locale/ca']")).to be true
    expect(element_exists?("head script[src^='/javascripts']")).to be false
  end
end
