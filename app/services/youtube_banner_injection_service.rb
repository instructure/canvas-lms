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

class YoutubeBannerInjectionService
  YOUTUBE_MESSAGE = I18n.t("This page has embedded YouTube content that may display advertisements.")

  # InstUI Alert-styled banner HTML
  YOUTUBE_BANNER_HTML = <<~HTML.freeze
    <div role="alert" style="line-height: 1.5;
                            font-weight: 400;
                            font-size: 1rem;
                            direction: ltr;
                            opacity: 1;
                            font-family: LatoWeb, Lato, 'Helvetica Neue', Helvetica, Arial, sans-serif;
                            max-width: 100%;
                            overflow: visible;
                            overscroll-behavior: auto;
                            color: rgb(39, 53, 64);
                            background: rgb(255, 255, 255);
                            box-sizing: border-box;
                            display: flex;
                            min-width: 12rem;
                            border-width: 0.125rem;
                            border-style: solid;
                            border-radius: 0.25rem;
                            border-color: rgb(43, 122, 188);
                            box-shadow: rgba(0, 0, 0, 0.1) 0px 0.1875rem 0.375rem, rgba(0, 0, 0, 0.15) 0px 0.1875rem 0.375rem;
                            margin: 0.75rem;
                            transition: outline-color 0.2s, outline-offset 0.25s;
                            outline-offset: -0.8rem;
                            outline: rgba(43, 122, 188, 0) solid 0.125rem;">
      <div style="line-height: 1.5;
                  font-weight: 400;
                  font-family: LatoWeb, Lato, 'Helvetica Neue', Helvetica, Arial, sans-serif;
                  color: rgb(255, 255, 255);
                  box-sizing: border-box;
                  flex: 0 0 2.5rem;
                  display: flex;
                  -webkit-box-align: center;
                  align-items: center;
                  -webkit-box-pack: center;
                  justify-content: center;
                  font-size: 1.125rem;
                  border-right: 0.125rem solid rgb(43, 122, 188);
                  margin: -1px;
                  border-start-start-radius: 0.25rem;
                  border-end-start-radius: 0.25rem;
                  background: rgb(43, 122, 188);">
        <svg name="IconInfoBorderless"
          viewBox="0 0 1920 1920"
          rotate="0"
          width="1em"
          height="1em"
          aria-hidden="true"
          role="presentation"
          focusable="false"
          style="font-weight: 400;
                font-family: LatoWeb, Lato, 'Helvetica Neue', Helvetica, Arial, sans-serif;
                font-size: 1.125rem;
                fill: currentcolor;
                display: inline-block;
                overflow: visible;
                color: inherit;
                vertical-align: middle;
                line-height: 1;
                width: 1em;
                height: 1em;">
          <g role="presentation">
            <path d="M1229.93 594.767c36.644 37.975 50.015 91.328 43.72 142.909-9.128 74.877-30.737 144.983-56.093 215.657-27.129 75.623-54.66 151.09-82.332 226.512-44.263 120.685-88.874 241.237-132.65 362.1-10.877 30.018-18.635 62.072-21.732 93.784-3.376 34.532 21.462 51.526 52.648 36.203 24.977-12.278 49.288-28.992 68.845-48.768 31.952-32.31 63.766-64.776 94.805-97.98 15.515-16.605 30.86-33.397 45.912-50.438 11.993-13.583 24.318-34.02 40.779-42.28 31.17-15.642 55.226 22.846 49.582 49.794-5.39 25.773-23.135 48.383-39.462 68.957l-1.123 1.416a1559.53 1559.53 0 0 0-4.43 5.6c-54.87 69.795-115.043 137.088-183.307 193.977-67.103 55.77-141.607 103.216-223.428 133.98-26.65 10.016-53.957 18.253-81.713 24.563-53.585 12.192-112.798 11.283-167.56 3.333-40.151-5.828-76.246-31.44-93.264-68.707-29.544-64.698-8.98-144.595 6.295-210.45 18.712-80.625 46.8-157.388 75.493-234.619l2.18-5.867 1.092-2.934 2.182-5.87 2.182-5.873c33.254-89.517 67.436-178.676 101.727-267.797 31.294-81.296 62.72-162.537 93.69-243.95 2.364-6.216 5.004-12.389 7.669-18.558l1-2.313c6.835-15.806 13.631-31.617 16.176-48.092 6.109-39.537-22.406-74.738-61.985-51.947-68.42 39.4-119.656 97.992-170.437 156.944l-6.175 7.17c-15.78 18.323-31.582 36.607-47.908 54.286-16.089 17.43-35.243 39.04-62.907 19.07-29.521-21.308-20.765-48.637-3.987-71.785 93.18-128.58 205.056-248.86 350.86-316.783 60.932-28.386 146.113-57.285 225.882-58.233 59.802-.707 116.561 14.29 157.774 56.99Zm92.038-579.94c76.703 29.846 118.04 96.533 118.032 190.417-.008 169.189-182.758 284.908-335.53 212.455-78.956-37.446-117.358-126.202-98.219-227.002 26.494-139.598 183.78-227.203 315.717-175.87Z" fill-rule="evenodd"></path>
          </g>
        </svg>
      </div>
      <div style="color: rgb(39, 53, 64);
                  box-sizing: border-box;
                  flex: 1 1 0%;
                  min-width: 0.0625rem;
                  font-size: 1rem;
                  font-family: LatoWeb, Lato, 'Helvetica Neue', Helvetica, Arial, sans-serif;
                  font-weight: 400;
                  line-height: 1.25;
                  padding: 0.75rem 1.5rem;">
          #{YOUTUBE_MESSAGE}
        </div>
      </div>
    </div>
  HTML

  class << self
    def inject_banner_if_needed(html_content, mobile_device: false)
      return html_content unless mobile_device
      return html_content if html_content.blank?

      # Check if YouTube embeds are present
      youtube_embeds = YoutubeEmbedScanner.embeds_from_html(html_content)
      return html_content if youtube_embeds.empty?

      # Check if banner is already injected to avoid duplicates
      return html_content if html_content.include?(YOUTUBE_MESSAGE)

      # Inject the banner at the top of the HTML content
      inject_banner_at_top(html_content)
    end

    private

    def inject_banner_at_top(html_content)
      # For simple HTML content without body tags, just prepend
      return YOUTUBE_BANNER_HTML + html_content unless html_content.include?("<body")

      # For full HTML documents, inject after body tag
      html_content.sub(/<body[^>]*>/i) do |body_tag|
        "#{body_tag}\n#{YOUTUBE_BANNER_HTML}"
      end
    end
  end
end
