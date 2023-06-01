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

module ReleaseNotes
  module DevUtils
    NOTES_SCHEMA = {
      key_schema: [
        { attribute_name: "PartitionKey", key_type: "HASH" }.freeze,
        { attribute_name: "RangeKey", key_type: "RANGE" }.freeze
      ].freeze,
      attribute_definitions: [
        { attribute_name: "PartitionKey", attribute_type: "S" }.freeze,
        { attribute_name: "RangeKey", attribute_type: "S" }.freeze,
      ].freeze
    }.freeze

    def self.initialize_ddb_for_development!(recreate: false)
      ::Canvas::DynamoDB::DevUtils.initialize_ddb_for_development!(
        :release_notes,
        ReleaseNote.ddb_table_name,
        recreate:,
        schema: NOTES_SCHEMA,
        ddb: ReleaseNote.ddb_client
      )
    end
  end
end
