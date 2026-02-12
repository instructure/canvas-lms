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

module Accessibility
  module Rules
    class ImgAltRuleHelper
      MAX_LENGTH = 200
      IMAGE_FILENAME_PATTERN = /[^\s]+(.*?)\.(jpg|jpeg|png|gif|svg|bmp|webp)$/i

      def self.filename_like?(text)
        return false if text.blank?

        IMAGE_FILENAME_PATTERN.match?(text)
      end

      def self.adjust_img_style(elem)
        fixed_elem = elem.dup
        fixed_elem["style"] = "max-width: 100%; max-height: 100%; object-fit: contain;"
        wrapper = Nokogiri::XML::Node.new("div", Nokogiri::HTML::Document.new)
        wrapper["style"] = "display: flex; justify-content: center; align-items: center; width: 100%; height: 100%;"
        wrapper.add_child(fixed_elem)
        wrapper.to_html
      end

      def self.validation_error_missing
        I18n.t("Alt text is required.")
      end

      def self.validation_error_filename
        I18n.t("Alt text can not be a filename.")
      end

      def self.validation_error_too_long
        I18n.t("Keep alt text under %{max_length} characters.", max_length: MAX_LENGTH)
      end

      def self.fix_alt_text!(elem, value)
        if value.nil?
          elem["role"] = "presentation"
          elem["alt"] = ""
          return { changed: elem, content_preview: adjust_img_style(elem) }
        end

        if value.to_s.strip.empty?
          raise StandardError, validation_error_missing
        end

        if filename_like?(value)
          raise StandardError, validation_error_filename
        end

        if value.length > MAX_LENGTH
          raise StandardError, validation_error_too_long
        end

        elem["alt"] = value
        { changed: elem, content_preview: adjust_img_style(elem) }
      end
    end
  end
end
