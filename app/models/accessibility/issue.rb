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
    include WikiPageIssues
    include AssignmentIssues
    include AttachmentIssues
    include ContentChecker
    include AccessibilityHelper

    attr_reader :context

    def initialize(context:)
      @context = context
    end

    def generate
      skip_scan = exceeds_accessibility_scan_limit?
      {
        pages: generate_wiki_page_resources(skip_scan:),
        assignments: generate_assignment_resources(skip_scan:),
        # TODO: Disable PDF Accessibility Checks Until Post-InstCon
        # attachments: generate_attachment_resources(skip_scan:),
        attachments: {},
        last_checked: Time.zone.now.strftime("%b %-d, %Y"),
        accessibility_scan_disabled: skip_scan
      }
    end

    def search(query)
      data = generate
      return data if query.blank?

      {
        pages: filter_resources(data[:pages], query),
        assignments: filter_resources(data[:assignments], query),
        attachments: filter_resources(data[:attachments], query),
        last_checked: data[:last_checked],
        accessibility_scan_disabled: data[:accessibility_scan_disabled]
      }
    end

    def update_content(rule, content_type, content_id, path, value)
      html_fixer = HtmlFixer.new(rule, content_type, content_id, path, value, self)
      return error_response(html_fixer.errors.full_messages.join(", "), :bad_request) unless html_fixer.valid?

      html_fixer.apply_fix!
    end

    def update_preview(rule, content_type, content_id, path, value)
      html_fixer = HtmlFixer.new(rule, content_type, content_id, path, value, self)
      return error_response(html_fixer.errors.full_messages.join(", "), :bad_request) unless html_fixer.valid?

      html_fixer.fix_preview
    end

    def generate_fix(rule, content_type, content_id, path, value)
      html_fixer = HtmlFixer.new(rule, content_type, content_id, path, value, self)
      return error_response(html_fixer.errors.full_messages.join(", "), :bad_request) unless html_fixer.valid?

      html_fixer.generate_fix
    end

    private

    def filter_resources(resources, query)
      resources.values&.select do |resource|
        resource.values&.any? { |value| value.to_s.downcase.include?(query.downcase) }
      end
    end

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
