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

module Api::V1::Eportfolio
  include Api::V1::Json

  EPORTFOLIO_ATTRIBUTES = %w[id user_id name public created_at updated_at workflow_state deleted_at spam_status].freeze
  ENTRY_ATTRIBUTES = %w[id eportfolio_id position name content created_at updated_at].freeze

  def eportfolio_json(eportfolio, current_user, session)
    api_json(eportfolio, current_user, session, only: EPORTFOLIO_ATTRIBUTES).tap do |hash|
      hash["public"] = !!hash["public"]
    end
  end

  def eportfolio_entry_json(entry, current_user, session)
    api_json(entry, current_user, session, only: ENTRY_ATTRIBUTES)
  end
end
