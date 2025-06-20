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
      include HtmlChecker
      include PdfChecker

      NO_ACCESSIBILITY_ISSUES = { count: 0, severity: "none", issues: [] }.freeze

      private

      def build_issue(rule_class, element:, form: nil, path: nil)
        {
          id: SecureRandom.uuid,
          rule_id: rule_class.id,
          element:,
          message: rule_class.message,
          why: rule_class.why,
          path:,
          severity: "error",
          issue_url: rule_class.link,
          form:
        }
      end

      def process_issues(issues)
        unique_issues = issues.uniq { |issue| "#{issue[:rule_id]}-#{issue[:element]}-#{issue[:path]}" }
        count = unique_issues.size
        severity = issue_severity(count)

        { count:, severity:, issues: unique_issues }
      end

      def issue_severity(count)
        return "high" if count > 30
        return "medium" if count > 2
        return "low" if count > 0

        "none"
      end

      def log_rule_error(rule_class, element, error)
        Rails.logger.error "Accessibility check problem with rule '#{rule_class.id}', element '#{element}': #{error.message}"
        Rails.logger.error error.backtrace.join("\n")
      end

      def log_general_error(error)
        Rails.logger.error "General accessibility check error: #{error.message}"
        Rails.logger.error error.backtrace.join("\n")
      end
    end
  end
end
