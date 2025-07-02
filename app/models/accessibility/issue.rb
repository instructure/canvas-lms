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
    include ActiveModel::Model
    include PageIssues
    include AssignmentIssues
    include AttachmentIssues
    include ContentChecker

    attr_reader :context, :rules, :pdf_rules

    def initialize(context:, rules: Rule.registry, pdf_rules: Rule.pdf_registry)
      @context = context
      @rules = rules
      @pdf_rules = pdf_rules
    end

    def generate
      {
        pages: generate_page_issues,
        assignments: generate_assignment_issues,
        attachments: generate_attachment_issues,
        last_checked: Time.zone.now.strftime("%b %-d, %Y")
      }
    end

    def update_content(raw_data)
      html_fixer = HtmlFixer.new(raw_data, self)
      return error_response(html_fixer.errors.full_messages.join(", "), :bad_request) unless html_fixer.valid?

      html_fixer.apply_fix!
    end

    private

    def error_response(message, status)
      { json: { error: message }, status: }
    end

    def polymorphic_path(args)
      Rails.application.routes.url_helpers.polymorphic_url(args, only_path: true)
    end

    def course_files_url(context, options)
      Rails.application.routes.url_helpers.course_files_url(context, options.merge(only_path: true))
    end
  end
end
