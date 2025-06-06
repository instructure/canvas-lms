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
    module ContentChecker
      module HtmlChecker
        include ::Accessibility::NokogiriMethods

        def check_content_accessibility(html_content)
          return NO_ACCESSIBILITY_ISSUES.dup if html_content.blank? || !html_content.include?("<")

          begin
            doc = Nokogiri::HTML5.fragment(html_content, nil, **CanvasSanitize::SANITIZE[:parser_options])
            extend_nokogiri_with_dom_adapter(doc)

            issues = []

            rules.each_value do |rule_class|
              doc.children.each do |node|
                next unless node.is_a?(Nokogiri::XML::Element)

                walk_dom_tree(node) do |element|
                  next if rule_class.test(element)

                  issues << build_issue(rule_class, element: element.name, form: rule_class.form(element).to_h, path: element_path(element))
                rescue => e
                  log_rule_error(rule_class, element, e)
                end
              end
            end

            process_issues(issues)
          rescue => e
            log_general_error(e)
            NO_ACCESSIBILITY_ISSUES.dup
          end
        end
      end
    end
  end
end
