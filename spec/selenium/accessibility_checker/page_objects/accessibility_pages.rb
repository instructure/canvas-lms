# frozen_string_literal: true

#
# Copyright (C) 2023 - present Instructure, Inc.
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

require_relative "../../common"

module AccessibilityPages
  HTML_BASE_PATH = "spec/selenium/accessibility_checker/html"

  def paragraphs_for_headings_html
    File.read("#{HTML_BASE_PATH}/paragraphs_for_headings_rule.html")
  end

  def headings_start_at_h2_html
    File.read("#{HTML_BASE_PATH}/headings_start_at_h2_rule.html")
  end

  def table_caption_rule_html
    File.read("#{HTML_BASE_PATH}/table_caption_rule.html")
  end

  def img_alt_rule_html
    File.read("#{HTML_BASE_PATH}/img_alt_rule.html")
  end

  def small_text_contrast_rule_html
    File.read("#{HTML_BASE_PATH}/small_text_contrast_rule.html")
  end
end
