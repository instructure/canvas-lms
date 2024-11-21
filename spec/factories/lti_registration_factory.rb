# frozen_string_literal: true

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

module Factories
  def lti_registration_model(**params)
    params ||= {}
    params[:created_by] ||= user_model
    params[:updated_by] ||= params[:created_by]
    params[:account] ||= account_model
    params[:name] ||= "Test Registration"
    include_binding = params.delete(:bound)
    overlay_data = params.delete(:overlay)
    @lti_registration = Lti::Registration.create!(params)
    if include_binding
      lti_registration_account_binding_model(registration: @lti_registration, account: @lti_registration.account, workflow_state: :on)
    end
    if overlay_data.present?
      lti_overlay_model(registration: @lti_registration, account: @lti_registration.account, data: overlay_data, updated_by: @lti_registration.created_by)
    end
    @lti_registration
  end
end
