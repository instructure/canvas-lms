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

module AcademicBenchmark
  module OutcomeData
    class FromApi < Base
      def initialize(options={})
        super(options.merge(AcademicBenchmark.config))
        unless partner_id.present? && partner_key.present?
          raise Canvas::Migration::Error,
            'partner_id & partner_key are required'
        end
      end
      delegate :authority, :document, :partner_id, :partner_key, to: :@options

      def data
        @_data ||= api.standards.send(api_method, guid, include_obsolete_standards: false)
      end

      def error_message
        "Couldn't update standards for guid '#{guid}'"
      end

      private
      def api
        @_api ||= AcademicBenchmarks::Api::Handle.new(
          partner_id:  partner_id,
          partner_key: partner_key
        )
      end

      def api_method
        authority.present? ? :authority_tree : :document_tree
      end

      def guid
        authority || document
      end
    end
  end
end
