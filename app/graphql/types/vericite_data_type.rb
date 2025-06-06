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
#
module Types
  class VericiteContextType < BaseUnion
    possible_types SubmissionType, FileType
    def self.resolve_type(object, _)
      case object
      when Submission then SubmissionType
      when Attachment then FileType
      end
    end
  end

  class VericiteDataType < ApplicationObjectType
    field :asset_string, String, null: false
    field :report_url, String, null: true
    field :score, Float, null: true
    field :state, String, null: true
    field :status, String, null: true
    field :target, Types::VericiteContextType, null: false
  end
end
