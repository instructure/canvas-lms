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
            _, body = parse_html_content(html_content)

            issues = []

            Rule.registry.each_value do |rule|
              body.children.each do |node|
                next unless node.is_a?(Nokogiri::XML::Element)

                walk_dom_tree(node) do |element|
                  next if rule.test(element).nil?

                  # Use built-in .path and strip /html/body prefix
                  xpath = element.path.sub(%r{^/html/body}, ".")

                  issues << build_issue(rule, element: element.name, form: rule.form(element).to_h, path: xpath)
                rescue => e
                  log_rule_error(rule, element, e)
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
