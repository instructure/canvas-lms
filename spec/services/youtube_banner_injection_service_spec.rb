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

require_relative "../spec_helper"

describe YoutubeBannerInjectionService do
  describe ".inject_banner_if_needed" do
    let(:html_with_youtube) do
      '<p>Here is some content with a YouTube video:</p><iframe src="https://www.youtube.com/embed/dQw4w9WgXcQ" width="560" height="315"></iframe>'
    end

    let(:html_with_youtube_nocookie) do
      '<p>Content with nocookie:</p><iframe src="https://www.youtube-nocookie.com/embed/dQw4w9WgXcQ" width="560" height="315"></iframe>'
    end

    let(:html_without_youtube) do
      '<p>This is regular content without any videos.</p><img src="/images/test.jpg" alt="test">'
    end

    let(:html_with_body_tag) do
      '<html><head><title>Test</title></head><body><p>Content</p><iframe src="https://www.youtube.com/embed/test"></iframe></body></html>'
    end

    context "when mobile_device is false" do
      it "returns original HTML unchanged" do
        result = YoutubeBannerInjectionService.inject_banner_if_needed(html_with_youtube, mobile_device: false)
        expect(result).to eq(html_with_youtube)
      end
    end

    context "when mobile_device is true" do
      context "with YouTube embeds present" do
        it "injects banner at the top of simple HTML content" do
          result = YoutubeBannerInjectionService.inject_banner_if_needed(html_with_youtube, mobile_device: true)

          expect(result).to include("This page has embedded YouTube content that may display advertisements.")
          expect(result).to include(html_with_youtube)
        end

        it "injects banner for YouTube nocookie embeds" do
          result = YoutubeBannerInjectionService.inject_banner_if_needed(html_with_youtube_nocookie, mobile_device: true)

          expect(result).to include("This page has embedded YouTube content that may display advertisements.")
          expect(result).to include(html_with_youtube_nocookie)
        end

        it "injects banner after body tag in full HTML documents" do
          result = YoutubeBannerInjectionService.inject_banner_if_needed(html_with_body_tag, mobile_device: true)

          expect(result).to include("This page has embedded YouTube content that may display advertisements.")
          expect(result).to include("<body>")
          expect(result).to match(/<body[^>]*>\s*<div role="alert"/)
        end

        it "does not inject duplicate banners" do
          html_with_existing_banner = YoutubeBannerInjectionService.inject_banner_if_needed(html_with_youtube, mobile_device: true)
          result = YoutubeBannerInjectionService.inject_banner_if_needed(html_with_existing_banner, mobile_device: true)

          banner_count = result.scan("This page has embedded YouTube content that may display advertisements.").length
          expect(banner_count).to eq(1)
        end
      end

      context "without YouTube embeds" do
        it "returns original HTML unchanged when no YouTube embeds are present" do
          result = YoutubeBannerInjectionService.inject_banner_if_needed(html_without_youtube, mobile_device: true)
          expect(result).to eq(html_without_youtube)
        end
      end

      context "with blank or nil HTML" do
        it "returns blank HTML unchanged" do
          result = YoutubeBannerInjectionService.inject_banner_if_needed("", mobile_device: true)
          expect(result).to eq("")
        end

        it "returns nil HTML unchanged" do
          result = YoutubeBannerInjectionService.inject_banner_if_needed(nil, mobile_device: true)
          expect(result).to be_nil
        end
      end
    end

    context "banner content validation" do
      it "includes informative message for users" do
        result = YoutubeBannerInjectionService.inject_banner_if_needed(html_with_youtube, mobile_device: true)

        expect(result).to include("This page has embedded YouTube content that may display advertisements.")
      end
    end
  end
end
