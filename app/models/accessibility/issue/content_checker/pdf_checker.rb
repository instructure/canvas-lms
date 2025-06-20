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
      module PdfChecker
        def check_pdf_accessibility(pdf)
          issues = []

          begin
            pdf_reader = PDF::Reader.new(pdf.open)

            pdf_rules.each do |rule_class|
              next if rule_class.test(pdf_reader)

              issues << build_issue(rule_class, element: "PDF Document")
            rescue => e
              log_rule_error(rule_class, "PDF Document", e)
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
