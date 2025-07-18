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
      include ::Accessibility::NokogiriMethods

      CONTENT_ATTRIBUTE_MAP = {
        "Page" => "body",
        "Assignment" => "description"
      }.freeze

      attr_accessor :raw_rule, :content_type, :content_id, :path, :value, :rule, :record, :issue

      validates :raw_rule, :content_type, :content_id, :path, presence: true
      validates :content_type, inclusion: { in: CONTENT_ATTRIBUTE_MAP.keys }
      validate :rule_must_exist
      validate :record_must_exist

      def initialize(rule, content_type, content_id, path, value, issue)
        @issue        = issue
        @raw_rule     = rule
        @content_type = content_type
        @content_id   = content_id
        @path         = path
        @value        = value
        @rule         = Rule.registry[@raw_rule]
        @record       = find_record
      end

      def apply_fix!
        body = record.send(target_attribute)
        fixed_content, _, error = fix_content(body, rule, path, value)
        if error.nil?
          record.send("#{target_attribute}=", fixed_content)
          record.save!
          { json: { success: true }, status: :ok }
        else
          { json: { error: }, status: :bad_request }
        end
      end

      def fix_preview
        body = record.send(target_attribute)
        fixed_content, fixed_path, error = fix_content(body, rule, path, value)
        if error.nil?
          { json: { content: fixed_content, path: fixed_path }, status: :ok }
        else
          { json: { error: }, status: :bad_request }
        end
      end

      def generate_fix
        body = record.send(target_attribute)
        doc = Nokogiri::HTML5.fragment(body, nil, **CanvasSanitize::SANITIZE[:parser_options])
        issue.extend_nokogiri_with_dom_adapter(doc)

        begin
          element = doc.at_xpath(path)
          if element
            { json: { value: rule.generate_fix(element) }, status: :ok }
          else
            { json: { error: "Element not found for path: #{path}" }, status: :bad_request }
          end
        rescue => e
          Rails.logger.error "Cannot fix accessibility issue due to error: #{e.message} (rule #{rule.id})"
          Rails.logger.error e.backtrace.join("\n")
          { json: { error: e.message }, status: :bad_request }
        end
      end

      private

      def fix_content(html_content, rule, target_element, fix_value)
        doc = Nokogiri::HTML5.fragment(html_content, nil, **CanvasSanitize::SANITIZE[:parser_options])
        issue.extend_nokogiri_with_dom_adapter(doc)

        begin
          element = doc.at_xpath(target_element)
          if element
            changed = rule.fix!(element, fix_value)
            error = nil
            unless changed.nil?
              error = rule.test(element)
            end
            [doc.to_html, element_path(element), error]
          else
            raise "Element not found for path: #{target_element}"
          end
        rescue => e
          Rails.logger.error "Cannot fix accessibility issue due to error: #{e.message} (rule #{rule.id})"
          Rails.logger.error e.backtrace.join("\n")
          [html_content, nil, e.message]
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
