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

class Lti::RegistrationUpdateRequest < ActiveRecord::Base
  belongs_to :lti_registration, class_name: "Lti::Registration"
  belongs_to :root_account, class_name: "Account"
  belongs_to :created_by, class_name: "User"
  belongs_to :updated_by, class_name: "User"

  self.table_name = "lti_registration_update_requests"

  def as_json
    super(include_root: false).merge(
      {
        # TODO: switch this on type of underlying registration
        internal_lti_configuration: Lti::IMS::Registration.to_internal_lti_configuration(lti_ims_registration)
      }
    )
  end
end
