# frozen_string_literal: true

#
# Copyright (C) 2025 - present Instructure, Inc.
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
describe Accessibility::Rules::ImgAltRuleHelper do
  describe ".filename_like?" do
    it "returns true for text that looks like a filename" do
      expect(described_class.filename_like?("image.jpg")).to be true
      expect(described_class.filename_like?("photo.png")).to be true
      expect(described_class.filename_like?("document.gif")).to be true
      expect(described_class.filename_like?("screenshot.webp")).to be true
      expect(described_class.filename_like?("my-image.jpeg")).to be true
    end

    it "returns false for text that doesn't look like a filename" do
      expect(described_class.filename_like?("A beautiful landscape")).to be false
      expect(described_class.filename_like?("Person smiling")).to be false
      expect(described_class.filename_like?("Person smiling.laughing lot")).to be false
      expect(described_class.filename_like?("")).to be false
      expect(described_class.filename_like?(nil)).to be false
    end

    it "returns true for filenames with paths" do
      expect(described_class.filename_like?("path/to/image.jpg")).to be true
      expect(described_class.filename_like?("/absolute/path/photo.png")).to be true
    end
  end

  describe ".adjust_img_style" do
    it "returns styled HTML for an image element" do
      html = '<img src="test.jpg" alt="test">'
      doc = Nokogiri::HTML.fragment(html)
      elem = doc.at_css("img")

      result = described_class.adjust_img_style(elem)

      expect(result).to include("display: flex")
      expect(result).to include("justify-content: center")
      expect(result).to include("align-items: center")
      expect(result).to include("max-width: 100%")
      expect(result).to include("max-height: 100%")
      expect(result).to include("object-fit: contain")
      expect(result).to include('src="test.jpg"')
      expect(result).to include('alt="test"')
    end
  end

  describe ".fix_alt_text!" do
    it "sets role=presentation and alt='' for nil value" do
      html = '<img src="test.jpg">'
      doc = Nokogiri::HTML.fragment(html)
      elem = doc.at_css("img")

      result = described_class.fix_alt_text!(elem, nil)

      expect(result).to be_a(Hash)
      expect(result[:changed]).to eq(elem)
      expect(elem["role"]).to eq("presentation")
      expect(elem["alt"]).to eq("")
      expect(result[:content_preview]).to include("display: flex")
      expect(result[:content_preview]).to include("justify-content: center")
      expect(result[:content_preview]).to include("align-items: center")
      expect(result[:content_preview]).to include("max-width: 100%")
      expect(result[:content_preview]).to include("max-height: 100%")
      expect(result[:content_preview]).to include("object-fit: contain")
    end

    it "sets alt text for valid values" do
      html = '<img src="test.jpg">'
      doc = Nokogiri::HTML.fragment(html)
      elem = doc.at_css("img")

      result = described_class.fix_alt_text!(elem, "A beautiful landscape")

      expect(result).to be_a(Hash)
      expect(result[:changed]).to eq(elem)
      expect(elem["alt"]).to eq("A beautiful landscape")
      expect(result[:content_preview]).to include("display: flex")
      expect(result[:content_preview]).to include("justify-content: center")
      expect(result[:content_preview]).to include("align-items: center")
      expect(result[:content_preview]).to include("max-width: 100%")
      expect(result[:content_preview]).to include("max-height: 100%")
      expect(result[:content_preview]).to include("object-fit: contain")
    end

    it "raises error for filename-like values" do
      html = '<img src="test.jpg">'
      doc = Nokogiri::HTML.fragment(html)
      elem = doc.at_css("img")

      expect do
        described_class.fix_alt_text!(elem, "image.jpg")
      end.to raise_error(StandardError, /Alt text can not be a filename/)
    end

    it "raises error for values longer than MAX_LENGTH" do
      html = '<img src="test.jpg">'
      doc = Nokogiri::HTML.fragment(html)
      elem = doc.at_css("img")
      long_text = "a" * (Accessibility::Rules::ImgAltRuleHelper::MAX_LENGTH + 2)

      expect do
        described_class.fix_alt_text!(elem, long_text)
      end.to raise_error(StandardError, /Keep alt text under/)
    end

    it "raises error for empty string" do
      html = '<img src="test.jpg">'
      doc = Nokogiri::HTML.fragment(html)
      elem = doc.at_css("img")

      expect do
        described_class.fix_alt_text!(elem, "")
      end.to raise_error(StandardError, /Alt text is required/)
    end

    it "raises error for whitespace-only string" do
      html = '<img src="test.jpg">'
      doc = Nokogiri::HTML.fragment(html)
      elem = doc.at_css("img")

      expect do
        described_class.fix_alt_text!(elem, "   ")
      end.to raise_error(StandardError, /Alt text is required/)
    end
  end
end
