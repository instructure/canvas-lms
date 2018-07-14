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

require 'atom'

class ObserverPairingCodesApiController < ApplicationController

  before_action :require_user

  def create
    user = api_find(User, params[:user_id])
    return render_unauthorized_action unless user.has_student_enrollment?
    
    # 1. Students can generate pairing codes for themselves
    # 2. Admins can if they have the permission
    # 3. Anyone else can if they have the permission as well
    if user == @current_user || 
        @current_user.account.grants_right?(@current_user, :generate_observer_pairing_code) ||
        @current_user.courses.any? { |c| c.grants_right?(@current_user, :generate_observer_pairing_code) }
      code = user.generate_observer_pairing_code
      render json: presenter(code)
      return
    end

    render_unauthorized_action
  end

  def presenter(code)
    {
      user_id: code.user_id,
      code: code.code,
      expires_at: code.expires_at,
      workflow_state: code.workflow_state
    }
  end
end