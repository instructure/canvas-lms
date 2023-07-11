# frozen_string_literal: true

#
# Copyright (C) 2015 - present Instructure, Inc.
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

module CanvasLinkMigrator
  class LinkParser
    REFERENCE_KEYWORDS = %w[CANVAS_COURSE_REFERENCE CANVAS_OBJECT_REFERENCE WIKI_REFERENCE IMS_CC_FILEBASE IMS-CC-FILEBASE].freeze
    LINK_PLACEHOLDER = "LINK.PLACEHOLDER"
    KNOWN_REFERENCE_TYPES = %w[
      announcements
      appointment_participants
      assignment_groups
      assignments
      attachments
      calendar_events
      context_external_tools
      context_module_tags
      context_modules
      course_paces
      created_learning_outcomes
      discussion_entries
      discussion_topics
      external_feeds
      grading_standards
      groups
      learning_outcome_groups
      learning_outcome_links
      learning_outcomes
      linked_learning_outcomes
      media_attachments_iframe
      modules
      pages
      quizzes
      rubrics
      wiki
      wiki_pages
    ].freeze

    attr_reader :unresolved_link_map, :migration_query_service

    def initialize(migration_query_service)
      @migration_query_service = migration_query_service
      reset!
    end

    def reset!
      @unresolved_link_map = {}
    end

    def add_unresolved_link(link, item_type, mig_id, field)
      key = { type: item_type, migration_id: mig_id }
      @unresolved_link_map[key] ||= {}
      @unresolved_link_map[key][field] ||= []
      @unresolved_link_map[key][field] << link
    end

    def placeholder(old_value)
      "#{LINK_PLACEHOLDER}_#{Digest::MD5.hexdigest(old_value)}"
    end

    def convert_link(node, attr, item_type, mig_id, field)
      return unless node[attr].present?

      if attr == "value" &&
         !(node[attr] =~ /IMS(?:-|_)CC(?:-|_)FILEBASE/ || node[attr].include?("CANVAS_COURSE_REFERENCE"))
        return
      end

      url = node[attr].dup
      REFERENCE_KEYWORDS.each do |ref|
        url.gsub!("%24#{ref}%24", "$#{ref}$")
      end

      result = parse_url(url, node, attr)
      if result[:resolved]
        # resolved, just replace and carry on
        new_url = result[:new_url] || url
        unless CanvasLinkMigrator.relative_url?(new_url)
          # perform configured substitutions
          if (processed_url = @migration_query_service.process_domain_substitutions(new_url))
            new_url = processed_url
          end
          # relative-ize absolute links outside the course but inside our domain
          # (analogous to what is done in Api#process_incoming_html_content)
          begin
            uri = URI.parse(new_url)
            account_hosts = @migration_query_service.context_hosts.map { |h| h.split(":").first }
            if account_hosts.include?(uri.host)
              uri.scheme = uri.host = uri.port = nil
              new_url = uri.to_s
            end
          rescue URI::InvalidURIError, URI::InvalidComponentError
            nil
          end
        end
        node[attr] = new_url
      else
        result.delete(:resolved)
        if result[:link_type] == :media_object
          # because we may actually change the media comment node itself
          # (rather than just replacing a value), we're going to
          # replace the entire node with a placeholder
          result[:old_value] = node.to_xml
          result[:placeholder] = placeholder(result[:old_value])
          placeholder_node = Nokogiri::HTML5.fragment(result[:placeholder])

          node.replace(placeholder_node)
        else
          result[:old_value] = node[attr]
          result[:placeholder] = placeholder(result[:old_value])
          node[attr] = result[:placeholder]
        end
        add_unresolved_link(result, item_type, mig_id, field)
      end
    end

    def unresolved(type, data = {})
      { resolved: false, link_type: type }.merge(data)
    end

    def resolved(new_url = nil)
      { resolved: true, new_url: }
    end

    # returns a hash with resolution status and data to hold onto if unresolved
    def parse_url(url, node, attr)
      if url =~ /wiki_page_migration_id=(.*)/
        unresolved(:wiki_page, migration_id: $1)
      elsif url =~ /discussion_topic_migration_id=(.*)/
        unresolved(:discussion_topic, migration_id: $1)
      elsif url =~ %r{\$CANVAS_COURSE_REFERENCE\$/modules/items/([^?]*)(\?.*)?}
        unresolved(:module_item, migration_id: $1, query: $2)
      elsif url =~ %r{\$CANVAS_COURSE_REFERENCE\$/file_ref/([^/?#]+)(.*)}
        unresolved(:file_ref,
                   migration_id: $1,
                   rest: $2,
                   in_media_iframe: attr == "src" && ["iframe", "source"].include?(node.name) && node["data-media-id"])
      elsif url =~ %r{(?:\$CANVAS_OBJECT_REFERENCE\$|\$WIKI_REFERENCE\$)/([^/]*)/([^?]*)(\?.*)?}
        if KNOWN_REFERENCE_TYPES.include?($1)
          unresolved(:object, type: $1, migration_id: $2, query: $3)
        else
          # If the `type` is not known, there's something amiss...
          @migration_query_service.report_link_parse_warning($1)
          resolved(url)
        end
      elsif url =~ %r{\$CANVAS_COURSE_REFERENCE\$/(.*)}
        resolved("#{@migration_query_service.context_path}/#{$1}")

      elsif url =~ %r{\$IMS(?:-|_)CC(?:-|_)FILEBASE\$/(.*)}
        rel_path = URI::DEFAULT_PARSER.unescape($1)
        if (attr == "href" && node["class"]&.include?("instructure_inline_media_comment")) ||
           (attr == "src" && ["iframe", "source"].include?(node.name) && node["data-media-id"])
          unresolved(:media_object, rel_path:)
        else
          unresolved(:file, rel_path:)
        end
      elsif (attr == "href" && node["class"]&.include?("instructure_inline_media_comment")) ||
            (attr == "src" && ["iframe", "source"].include?(node.name) && node["data-media-id"])
        # Course copy media reference, leave it alone
        resolved
      elsif @migration_query_service.supports_embedded_images && attr == "src" && (info_match = url.match(%r{\Adata:(?<mime_type>[-\w]+/[-\w+.]+)?;base64,(?<image>.*)}m))
        result = @migration_query_service.link_embedded_image(info_match)
        if result[:resolved]
          resolved(result[:url])
        else
          unresolved(:file, rel_path: result[:url])
        end
      elsif # rubocop:disable Lint/DuplicateBranch
            # Equation image, leave it alone
            (attr == "src" && node["class"] && node["class"].include?("equation_image")) || # rubocop:disable Layout/ConditionPosition
            # The file is in the context of an AQ, leave the link alone
            url =~ %r{\A/assessment_questions/\d+/files/\d+} ||
            # This points to a specific file already, leave it alone
            url =~ %r{\A/courses/\d+/files/\d+} ||
            !@migration_query_service.fix_relative_urls? ||
            # It's just a link to an anchor, leave it alone
            url.start_with?("#")
        resolved
      elsif CanvasLinkMigrator.relative_url?(url)
        unresolved(:file, rel_path: URI::DEFAULT_PARSER.unescape(url))
      else # rubocop:disable Lint/DuplicateBranch
        resolved
      end
    end
  end
end
