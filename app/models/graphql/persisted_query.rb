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

module GraphQL
  # Predefined GraphQL queries to mitigate abuse by unauthenticated users
  class PersistedQuery
    QUERIES_DIR = "ui/shared/graphql/persistedQueries"
    MANIFEST_FILE = "manifest.json"

    class << self
      def find(operation_name)
        known_queries[operation_name]
      end

      def known_queries
        @known_queries ||= load_queries
      rescue => e
        Rails.logger.error "Error while loading persisted queries: #{e}"
        raise
      end

      private

      def load_queries
        manifest_path = Rails.root.join(QUERIES_DIR, MANIFEST_FILE)
        manifest = JSON.parse(File.read(manifest_path))

        manifest.each_with_object({}) do |(query_name, metadata), result|
          query_path = Rails.root.join(QUERIES_DIR, "#{query_name}.graphql")
          query_content = File.read(query_path)

          result[query_name] = metadata.merge("query" => query_content)
        end
      end
    end
  end
end
