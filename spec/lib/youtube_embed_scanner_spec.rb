# frozen_string_literal: true

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
#

describe YoutubeEmbedScanner do
  describe ".embeds_from_html" do
    let(:youtube_embed) { described_class::YOUTUBE_EMBED }
    let(:nocookie_embed) { described_class::YOUTUBE_NOCOOKIE_EMBED }

    it "returns an empty array for nil input" do
      expect(described_class.embeds_from_html(nil)).to eq([])
    end

    it "returns an empty array for empty string" do
      expect(described_class.embeds_from_html("")).to eq([])
    end

    it "returns an empty array when there are no iframes" do
      html = "<div>No iframes here</div>"
      expect(described_class.embeds_from_html(html)).to eq([])
    end

    it "returns an empty array when iframes do not have src" do
      html = "<iframe></iframe><iframe></iframe>"
      expect(described_class.embeds_from_html(html)).to eq([])
    end

    it "returns an empty array when iframes have non-YouTube src" do
      html = '<iframe src="https://example.com/embed/123"></iframe>'
      expect(described_class.embeds_from_html(html)).to eq([])
    end

    it "returns embed objects for iframes with youtube.com/embed src" do
      html = <<~HTML
        <iframe src="#{youtube_embed}abc"></iframe>
        <iframe src="#{youtube_embed}def"></iframe>
      HTML
      result = described_class.embeds_from_html(html)
      expect(result).to match_array([
                                      { path: "/html/body/iframe[1]", src: "#{youtube_embed}abc", width: nil, height: nil },
                                      { path: "/html/body/iframe[2]", src: "#{youtube_embed}def", width: nil, height: nil }
                                    ])
    end

    it "returns embed objects for iframes with youtube-nocookie.com/embed src" do
      html = <<~HTML
        <iframe src="#{nocookie_embed}xyz"></iframe>
      HTML
      result = described_class.embeds_from_html(html)
      expect(result).to match_array([
                                      { path: "/html/body/iframe", src: "#{nocookie_embed}xyz", width: nil, height: nil }
                                    ])
    end

    it "returns embed objects for both youtube.com and youtube-nocookie.com embeds" do
      html = <<~HTML
        <iframe src="#{youtube_embed}abc"></iframe>
        <iframe src="#{nocookie_embed}xyz"></iframe>
        <iframe src="https://example.com/embed/123"></iframe>
      HTML
      result = described_class.embeds_from_html(html)
      expect(result).to match_array([
                                      { path: "/html/body/iframe[1]", src: "#{youtube_embed}abc", width: nil, height: nil },
                                      { path: "/html/body/iframe[2]", src: "#{nocookie_embed}xyz", width: nil, height: nil }
                                    ])
    end

    it "extracts width and height attributes when present" do
      html = <<~HTML
        <iframe src="#{youtube_embed}abc" width="560" height="315"></iframe>
        <iframe src="#{nocookie_embed}xyz" width="800" height="600"></iframe>
      HTML
      result = described_class.embeds_from_html(html)
      expect(result).to match_array([
                                      { path: "/html/body/iframe[1]", src: "#{youtube_embed}abc", width: "560", height: "315" },
                                      { path: "/html/body/iframe[2]", src: "#{nocookie_embed}xyz", width: "800", height: "600" }
                                    ])
    end

    it "ignores iframes with src that only partially match" do
      html = <<~HTML
        <iframe src="https://www.youtube.com/other/abc"></iframe>
        <iframe src="https://www.youtube-nocookie.com/other/xyz"></iframe>
      HTML
      expect(described_class.embeds_from_html(html)).to eq([])
    end
  end
end
