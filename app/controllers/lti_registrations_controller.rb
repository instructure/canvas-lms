# frozen_string_literal: true

#
# Copyright (C) 2012 - present Instructure, Inc.
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

class LtiRegistrationsController < ApplicationController
  def index
    require_account_context

    if @context.feature_enabled?(:lti_registrations_page)
      set_active_tab "extensions"
      add_crumb t("#crumbs.apps", "Extensions")

      render :index
    else
      render "shared/errors/404_message", status: :not_found, formats: [:html]
    end
  end
end
