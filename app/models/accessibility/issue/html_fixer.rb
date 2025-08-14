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
      include ::Accessibility::NokogiriMethods

      attr_accessor :resource, :path, :value, :rule

      def initialize(rule_id, resource, path, value)
        @resource     = resource
        @path         = path
        @value        = value
        @rule         = Rule.registry[rule_id]
      end

      def apply_fix!
        html_content = resource.send(target_attribute)
        fixed_content, _, error = fix_content(html_content, rule, path, value)
        if error.nil?
          resource.send("#{target_attribute}=", fixed_content)
          resource.save!
          { json: { success: true }, status: :ok }
        else
          { json: { error: }, status: :bad_request }
        end
      end

      def preview_fix
        html_content = resource.send(target_attribute)
        fixed_content, fixed_path, error = fix_content(html_content, rule, path, value)
        if error.nil?
          { json: { content: fixed_content, path: fixed_path }, status: :ok }
        else
          { json: { error: }, status: :bad_request }
        end
      end

      def generate_fix
        html_content = resource.send(target_attribute)
        doc = Nokogiri::HTML5.fragment(html_content, nil, **CanvasSanitize::SANITIZE[:parser_options])
        extend_nokogiri_with_dom_adapter(doc)

        begin
          element = doc.at_xpath(path)
          if element
            generated_value = rule.generate_fix(element)
            if generated_value.nil?
              { json: { error: I18n.t("Unsupported issue type") }, status: :bad_request }
            else
              { json: { value: generated_value }, status: :ok }
            end
          else
            Rails.logger.error("Element not found for path: #{path} (rule #{rule.id})")
            { json: { error: "Invalid issue placement" }, status: :bad_request }
          end
        rescue => e
          Rails.logger.error "Cannot fix accessibility issue due to error: #{e.message} (rule #{rule.id})"
          Rails.logger.error e.backtrace.join("\n")
          { json: { error: "Internal Error" }, status: :internal_server_error }
        end
      end

      private

      def fix_content(html_content, rule, path, fix_value)
        doc = Nokogiri::HTML5.fragment(html_content, nil, **CanvasSanitize::SANITIZE[:parser_options])
        extend_nokogiri_with_dom_adapter(doc)

        begin
          element = doc.at_xpath(path)
          if element
            changed = rule.fix!(element, fix_value)
            error = nil
            unless changed.nil?
              error = rule.test(changed)
            end
            [doc.to_html, element_path(element), error]
          else
            raise "Element not found for path: #{path}"
          end
        rescue => e
          Rails.logger.error "Cannot fix accessibility issue due to error: #{e.message} (rule #{rule.id})"
          Rails.logger.error e.backtrace.join("\n")
          [html_content, nil, e.message]
        end
      end

      def target_attribute
        case resource
        when WikiPage
          :body
        when Assignment
          :description
        else
          raise ArgumentError, "Unsupported resource type: #{resource.class.name}"
        end
      end
    end
  end
end
