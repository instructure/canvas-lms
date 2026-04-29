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
  # TODO: RCX-4765 - This class generates accessibility issue data for the old wizard UI
  # that was removed in commit 70d63e25976. The new accessibility checker uses
  # AccessibilityResourceScan instead. This may still be used by external tools
  # via the /accessibility/issues API endpoints, but has no Canvas UI consumers.
  class Issue
    include WikiPageIssues
    include AssignmentIssues
    include AttachmentIssues
    include AnnouncementIssues
    include DiscussionTopicIssues
    include SyllabusIssues
    include ContentChecker

    attr_reader :context

    def initialize(context:)
      @context = context
    end

    def generate
      skip_scan = @context.exceeds_accessibility_scan_limit?
      syllabus_data = generate_syllabus_resources(skip_scan:)
      {
        pages: generate_wiki_page_resources(skip_scan:),
        assignments: generate_assignment_resources(skip_scan:),
        announcements: generate_announcement_resources(skip_scan:),
        discussion_topics: generate_discussion_topic_resources(skip_scan:),
        # TODO: Disable PDF Accessibility Checks Until Post-InstCon
        # attachments: generate_attachment_resources(skip_scan:),
        attachments: {},
        syllabus: syllabus_data[:syllabus],
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
        announcements: filter_resources(data[:announcements], query),
        discussion_topics: filter_resources(data[:discussion_topics], query),
        attachments: filter_resources(data[:attachments], query),
        syllabus: filter_single_resource(data[:syllabus], query),
        last_checked: data[:last_checked],
        accessibility_scan_disabled: data[:accessibility_scan_disabled]
      }
    end

    def update_content(rule_id, resource_type, resource_id, path, value)
      resource = self.class.find_resource(context, resource_type, resource_id)
      HtmlFixer.new(rule_id, resource, path, value).apply_fix!
    end

    # TODO: This method is only used by PreviewController#create and should be eliminated.
    # The preview should use issue_id (like PreviewController#show does) to load the
    # AccessibilityIssue from DB and use its resource, ensuring consistency with the fix action.
    def update_preview(rule_id, resource_type, resource_id, path, value)
      resource = self.class.find_resource(context, resource_type, resource_id)
      HtmlFixer.new(rule_id, resource, path, value).preview_fix(element_only: path.present?)
    end

    def generate_fix(rule_id, resource_type, resource_id, path, value)
      resource = self.class.find_resource(context, resource_type, resource_id)
      HtmlFixer.new(rule_id, resource, path, value).generate_fix
    end

    def self.find_resource(context, resource_type, resource_id)
      case resource_type
      when "Page"
        context.wiki_pages.find(resource_id)
      when "Assignment"
        context.assignments.find(resource_id)
      when "DiscussionTopic", "Announcement"
        context.discussion_topics.find(resource_id)
      when "Syllabus"
        # Syllabus is part of Course, wrap it in SyllabusResource
        # resource_id is actually the course_id for syllabus
        Accessibility::SyllabusResource.new(context)
      else
        raise ArgumentError, "Unsupported resource type: #{resource_type}"
      end
    end

    private

    def filter_resources(resources, query)
      resources.values&.select do |resource|
        resource.values&.any? { |value| value.to_s.downcase.include?(query.downcase) }
      end
    end

    def filter_single_resource(resource, query)
      return {} unless resource.present?

      if resource.values&.any? { |value| value.to_s.downcase.include?(query.downcase) }
        resource
      else
        {}
      end
    end

    def error_response(message, status)
      { json: { error: message }, status: }
    end

    def polymorphic_path(args)
      Rails.application.routes.url_helpers.polymorphic_url(args, only_path: true)
    end

    def resource_urls(resource)
      {
        url: polymorphic_path([context, resource]),
        edit_url: polymorphic_path([:edit, context, resource])
      }
    end

    def course_files_url(context, options)
      Rails.application.routes.url_helpers.course_files_url(context, options.merge(only_path: true))
    end
  end
end
