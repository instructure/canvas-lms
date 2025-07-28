# frozen_string_literal: true

#
# Copyright (C) 2011 - present Instructure, Inc.
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
#
module CC
  module Qti
    class MigrationIdsReplacer
      REPLACEABLE_ATTRS = %w[identifier href ident].freeze
      REPLACEABLE_OBJECTS = %w[resource file quiz assessment].freeze
      REPLACEABLE_CONTENTS = %w[quiz_identifierref assignment_group_identifierref].freeze

      def initialize(manifest, new_quizzes_migration_ids_map)
        @manifest = manifest
        @new_quizzes_migration_ids_map = new_quizzes_migration_ids_map
      end

      def replace_in_xml(xml)
        doc = Nokogiri::XML(xml || "")
        doc.search("*").each do |node|
          if REPLACEABLE_OBJECTS.include?(node.node_name)
            REPLACEABLE_ATTRS.each do |attr|
              next unless node[attr]

              node[attr] = replace_in_string(node[attr])
            end
          elsif REPLACEABLE_CONTENTS.include?(node.node_name)
            node.content = replace(node.content)
          end
        end

        doc.to_xml
      end

      def replace_in_string(string)
        replaced_string = string

        migration_ids_map.each_key do |migration_id|
          next unless string.include?(migration_id)

          new_migration_id = replace(migration_id)
          replaced_string = string.gsub(migration_id, new_migration_id)
        end

        replaced_string
      end

      def replace(migration_id)
        migration_ids_map[migration_id] || migration_id
      end

      private

      def find_and_map_to_canvas_id(entity_class, external_id)
        return unless external_id

        entity = entity_class.find_by(id: external_id)
        return unless entity

        @manifest.create_key(entity)
      end

      def migration_ids_map
        @migration_ids_map ||= @new_quizzes_migration_ids_map.filter_map do |mig_id, props|
          canvas_id =
            find_and_map_to_canvas_id(Assignment, props["external_assignment_id"]) ||
            find_and_map_to_canvas_id(AssignmentGroup, props["external_assignment_group_id"])
          { mig_id => canvas_id } if canvas_id
        end.reduce({}, :merge)
      end
    end
  end
end
