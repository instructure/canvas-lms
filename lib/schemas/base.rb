#
# Copyright (C) 2018 - present Instructure, Inc.
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

module Schemas
  class Base
    delegate :validate, :valid?, to: :schema_checker

    def self.simple_validation_errors(json_hash)
      error = self.new.validate(json_hash).to_a.first
      return nil if error.blank?
      if error['data_pointer'].present?
        return "#{error['data']} #{error['data_pointer']}. Schema: #{error['schema']}"
      end
      "The following fields are required: #{error.dig('schema', 'required').join(', ')}"
    end

    private

    def schema_checker
      @schema_checker ||= JSONSchemer.schema(schema)
    end

    def schema
      raise 'Abstract method'
    end
  end
end