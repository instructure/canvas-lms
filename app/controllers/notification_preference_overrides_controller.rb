#
# Copyright (C) 2020 - present Instructure, Inc.
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

class NotificationPreferenceOverridesController < ApplicationController
  before_action :require_user, :get_context

  include Api::V1::NotificationPolicy

  def enabled_for_context
    render json: { enabled: NotificationPolicyOverride.enabled_for(@current_user, @context) }
  end

  def enable
    return render_unauthorized_action unless @context.root_account.feature_enabled?(:mute_notifications_by_course)
    enabled = value_to_boolean(params[:enable])
    # don't allow users to set overrides for courses they are not in, but we
    # will allow them to disable them if the user was removed from a course
    # and is still getting notifications for some reason.
    return render_unauthorized_action if enabled && !@context.grants_any_right?(@current_user, :read)
    NotificationPolicyOverride.enable_for_context(@current_user, @context, enable: enabled)
    render json: { enabled: NotificationPolicyOverride.enabled_for(@current_user, @context) }
  end
end
