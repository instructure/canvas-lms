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
  class Issue
    class HtmlFixer
      include ActiveModel::Model

      CONTENT_ATTRIBUTE_MAP = {
        "Page" => "body",
        "Assignment" => "description"
      }.freeze

      attr_accessor :raw_rule, :content_type, :content_id, :path, :value, :rule, :record, :issue

      validates :raw_rule, :content_type, :content_id, :path, presence: true
      validates :content_type, inclusion: { in: CONTENT_ATTRIBUTE_MAP.keys }
      validate :rule_must_exist
      validate :record_must_exist

      def initialize(data, issue)
        @issue        = issue
        @raw_rule     = data["rule"]
        @content_type = data["content_type"]
        @content_id   = data["content_id"]
        @path         = data["path"]
        @value        = data["value"]
        @rule         = issue.rules[@raw_rule]
        @record       = find_record
      end

      def apply_fix!
        body = record.send(target_attribute)
        record.send("#{target_attribute}=", fix_content(body, rule, path, value))
        record.save!
        { json: { success: true }, status: :ok }
      end

      private

      def fix_content(html_content, rule, target_element, fix_value)
        doc = Nokogiri::HTML5.fragment(html_content, nil, **CanvasSanitize::SANITIZE[:parser_options])
        issue.extend_nokogiri_with_dom_adapter(doc)

        begin
          element = doc.at_xpath(target_element)
          if element
            rule.fix(element, fix_value)
          else
            raise "Element not found for path: #{target_element}"
          end

          doc.to_html
        rescue => e
          Rails.logger.error "Accessibility Rule content fix problem encountered: #{e.message}"
          Rails.logger.error e.backtrace.join("\n")
          html_content
        end
      end

      def target_attribute
        CONTENT_ATTRIBUTE_MAP[content_type]
      end

      def rule_must_exist
        errors.add(:raw_rule, "is invalid") if raw_rule.present? && rule.nil?
      end

      def record_must_exist
        errors.add(:content_id, "#{content_type} with ID #{content_id} not found") unless record.present?
      end

      def find_record
        case content_type
        when "Page"
          issue.context.wiki_pages.find_by(id: content_id)
        when "Assignment"
          issue.context.assignments.find_by(id: content_id)
        end
      end
    end
  end
end
