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
    QUERY_FILE_PATH = "ui/shared/graphql/persistedQueries.yml"

    class << self
      def find(operation_name)
        known_queries[operation_name]
      end

      def known_queries
        @known_queries ||= YAML.safe_load_file(Rails.root.join(QUERY_FILE_PATH))
      rescue => e
        Rails.logger.error "Error while loading yaml file #{QUERY_FILE_PATH}: #{e}"
        raise
      end
    end
  end
end
