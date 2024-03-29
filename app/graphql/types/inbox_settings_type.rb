# frozen_string_literal: true

#
# Copyright (C) 2024 - present Instructure, Inc.
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
  class InboxSettingsType < ApplicationObjectType
    implements Interfaces::TimestampInterface
    # rubocop:disable GraphQL/ExtractType
    field :_id, ID, method: :id, null: false
    field :out_of_office_first_date, Types::DateTimeType, null: true
    field :out_of_office_last_date, Types::DateTimeType, null: true
    field :out_of_office_message, String, null: true
    field :out_of_office_subject, String, null: true
    field :signature, String, null: true
    field :use_out_of_office, Boolean, null: false
    field :use_signature, Boolean, null: false
    field :user_id, ID, null: false
    # rubocop:enable GraphQL/ExtractType
  end
end
