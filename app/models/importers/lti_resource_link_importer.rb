# frozen_string_literal: true

#
# Copyright (C) 2021 - present Instructure, Inc.
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

module Importers
  class LtiResourceLinkImporter < Importer
    self.item_class = Lti::ResourceLink

    def self.process_migration(hash, migration)
      lti_resource_links = hash.with_indifferent_access["lti_resource_links"]

      return false unless lti_resource_links

      # Recover all resource links recorded by Importers::AssignmentImporter to
      resource_links_from_assignments = imported_resource_links_from_assignments(migration)

      # When a resource link was created into Assignment context we have to
      # update the custom params.
      # Otherwise, we have to create a resource link for Course context.
      lti_resource_links.each do |lti_resource_link|
        updated = update_custom_for_resource_link_from_assignment_context(resource_links_from_assignments, lti_resource_link)

        next if updated

        create_or_update_resource_link_for_a_course_context(lti_resource_link, migration)
      end

      true
    end

    def self.create_or_update_resource_link_for_a_course_context(lti_resource_link, migration)
      resource_link_for_course = Lti::ResourceLink.find_or_initialize_for_context_and_lookup_uuid(
        context: migration.context,
        lookup_uuid: lti_resource_link["lookup_uuid"],
        url: lti_resource_link["resource_link_url"],
        context_external_tool_launch_url: lti_resource_link["launch_url"]
      )
      resource_link_for_course.custom =
        Lti::DeepLinkingUtil.validate_custom_params(lti_resource_link["custom"])
      resource_link_for_course.save
    end

    def self.find_resource_link_from_assignment_context(resource_links_from_assignments, lookup_uuid)
      resource_links_from_assignments.find { |item| item.lookup_uuid == lookup_uuid }
    end

    def self.imported_resource_links_from_assignments(migration)
      migration.context.assignments.joins(:lti_resource_links).map(&:lti_resource_links).flatten
    end

    def self.update_custom_for_resource_link_from_assignment_context(resource_links_from_assignments, lti_resource_link)
      resource_link = find_resource_link_from_assignment_context(
        resource_links_from_assignments,
        lti_resource_link["lookup_uuid"]
      )

      return false unless resource_link

      resource_link.update(
        custom: Lti::DeepLinkingUtil.validate_custom_params(lti_resource_link["custom"])
      )

      true
    end
  end
end
