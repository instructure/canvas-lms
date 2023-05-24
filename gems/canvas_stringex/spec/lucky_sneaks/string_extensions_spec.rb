# frozen_string_literal: true

# Copyright (C) 2011 - present Instructure, Inc.
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

require "spec_helper"

describe "StringExtensions" do
  it "to_url" do
    {
      "<p>This has 100% too much    <em>formatting</em></p>" =>
        "this-has-100-percent-too-much-formatting",
      "Tea   &amp; crumpets &amp; <strong>cr&ecirc;pes</strong> for me!" =>
        "tea-and-crumpets-and-crepes-for-me",
      "The Suspense... Is... Killing Me" =>
        "the-suspense-dot-dot-dot-is-dot-dot-dot-killing-me",
      "How to use attr_accessible and attr_protected" =>
        "how-to-use-attr-accessible-and-attr-protected",
      "I'm just making sure there's nothing wrong with things!" =>
        "im-just-making-sure-theres-nothing-wrong-with-things"
    }.each do |html, plain|
      expect(plain).to eq html.to_url
    end
  end

  it "remove_formatting" do
    {
      "<p>This has 100% too much    <em>formatting</em></p>" =>
        "This has 100 percent too much formatting",
      "Tea   &amp; crumpets &amp; <strong>cr&ecirc;pes</strong> for me!" =>
        "Tea and crumpets and crepes for me"
    }.each do |html, plain|
      expect(plain).to eq html.remove_formatting
    end
  end

  it "strip_html_tags" do
    {
      "<h1><em>This</em> is good but <strong>that</strong> is better</h1>" =>
        "This is good but that is better",
      "<p>This is invalid XHTML but valid HTML, right?" =>
        "This is invalid XHTML but valid HTML, right?",
      "<p class='foo'>Everything goes!</p>" => "Everything goes!",
      "<ol>This is completely invalid and just plain wrong</p>" =>
        "This is completely invalid and just plain wrong"
    }.each do |html, plain|
      expect(plain).to eq html.strip_html_tags
    end
  end

  it "convert_accented_entities" do
    {
      "&aring;" => "a",
      "&egrave;" => "e",
      "&icirc;" => "i",
      "&Oslash;" => "O",
      "&uuml;" => "u",
      "&Ntilde;" => "N",
      "&ccedil;" => "c"
    }.each do |entitied, plain|
      expect(plain).to eq entitied.convert_accented_entities
    end
  end

  it "convert_misc_entities" do
    {
      "America&#8482;" => "America(tm)",
      "Tea &amp; Sympathy" => "Tea and Sympathy",
      "To be continued&#8230;" => "To be continued...",
      "Foo&nbsp;Bar" => "Foo Bar",
      "100&#163;" => "100 pound",
      "&frac12; a dollar" => "half a dollar",
      "35&deg;" => "35 degrees"
    }.each do |entitied, plain|
      expect(plain).to eq entitied.convert_misc_entities
    end
  end

  it "convert_misc_characters" do
    {
      "Foo & bar make foobar" => "Foo and bar make foobar",
      "Breakdown #9" => "Breakdown number 9",
      "foo@bar.com" => "foo at bar dot com",
      "100% of yr love" => "100 percent of yr love",
      "Kisses are $3.25 each" => "Kisses are 3 dollars 25 cents each",
      "That CD is £3.25 plus tax" => "That CD is 3 pounds 25 pence plus tax",
      "This CD is ¥1000 instead" => "This CD is 1000 yen instead"
    }.each do |misc, plain|
      expect(plain).to eq misc.convert_misc_characters
    end
  end

  it "replace_whitespace" do
    {
      "this has     too much space" => "this has too much space",
      "\t\tThis is merely formatted with superfluous whitespace\n" =>
        " This is merely formatted with superfluous whitespace "
    }.each do |whitespaced, plain|
      expect(plain).to eq whitespaced.replace_whitespace
    end

    expect("now-with-more-hyphens").to eq "now with more hyphens".replace_whitespace("-")
  end

  it "collapse" do
    {
      "too      much space" => "too much space",
      "  at the beginning" => "at the beginning"
    }.each do |uncollapsed, plain|
      expect(plain).to eq uncollapsed.collapse
    end

    expect("now-with-hyphens").to eq "----now---------with-hyphens--------".collapse("-")
  end
end
