# frozen_string_literal: true

#
# Copyright (C) 2026 - present Instructure, Inc.
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

require "nokogiri"

module DataFixup
  class RemoveSyllabusExternalLinkEnhancements < CanvasOperations::DataFixup
    self.mode = :individual_record
    self.progress_tracking = false

    scope do
      Course.where(
        "syllabus_body LIKE ? OR syllabus_body LIKE ? OR syllabus_body LIKE ? " \
        "OR syllabus_body LIKE ? OR syllabus_body LIKE ? OR syllabus_body LIKE ?",
        "%external_link_icon%",
        "%file_download_btn%",
        "%ally-accessibility-score-indicator-image%",
        "%preview_container%",
        "%youtubed%",
        "%instructure_inline_media_comment%"
      )
    end

    def self.fix_html(html)
      return html if html.blank?

      doc = Nokogiri::HTML5::DocumentFragment.parse(html, nil, **CanvasSanitize::SANITIZE[:parser_options])

      doc.css("img.ally-accessibility-score-indicator-image").each(&:remove)

      doc.css("div.ally-enhancement").each(&:remove)

      doc.css("a.ally-accessible-versions").each do |a|
        (a.parent.name == "li") ? a.parent.remove : a.remove
      end

      doc.css("span.external_link_icon").each(&:remove)

      doc.css("a.file_download_btn").each(&:remove)
      doc.css("div.preview_container").each(&:remove)

      doc.css("span.instructure_file_holder").each do |span|
        span.replace(span.children)
      end

      doc.css("a.previewable").each do |link|
        classes = link["class"].to_s.split - ["previewable"]
        classes.empty? ? link.remove_attribute("class") : link["class"] = classes.join(" ")
        link.remove_attribute("aria-expanded")
        link.remove_attribute("aria-controls")
      end

      doc.css("span.ally-file-link-holder").each do |span|
        next if span["class"].to_s.split.include?("instructure_file_holder")

        if span.parent.name == "li"
          span.parent.remove
        else
          span.replace(span.children)
        end
      end

      doc.css("a.external").each do |link|
        classes = link["class"].to_s.split - ["external"]
        if classes.empty?
          link.remove_attribute("class")
        else
          link["class"] = classes.join(" ")
        end

        element_children = link.children.select(&:element?)
        if element_children.size == 1 && element_children.first.name == "span"
          element_children.first.replace(element_children.first.children)
        end
      end

      doc.css("a.youtubed").each do |link|
        if link.css("img.media_comment_thumbnail").any?
          link.remove
        else
          classes = link["class"].to_s.split - ["youtubed"]
          classes.empty? ? link.remove_attribute("class") : link["class"] = classes.join(" ")
        end
      end

      doc.css("a.instructure_inline_media_comment").each do |link|
        link.css("span.media_comment_thumbnail").each(&:remove)
        classes = link["class"].to_s.split - ["instructure_inline_media_comment"]
        classes.empty? ? link.remove_attribute("class") : link["class"] = classes.join(" ")
        if link["href"] == "#" && link["data-download"].present?
          link["href"] = link["data-download"]
          link.remove_attribute("data-download")
        end
      end

      doc.to_s
    end

    def process_record(course)
      fixed = self.class.fix_html(course.syllabus_body)
      return if fixed == course.syllabus_body

      course.update_columns(syllabus_body: fixed)
    end
  end
end
