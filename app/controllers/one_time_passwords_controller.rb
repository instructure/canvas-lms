# frozen_string_literal: true

#
# Copyright (C) 2011 Instructure, Inc.
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

class OneTimePasswordsController < ApplicationController
  before_action :require_user, :require_password_session, :disallow_masquerading, :require_otp

  def index
    @current_user.generate_one_time_passwords
    @otps = @current_user.one_time_passwords
    add_meta_tag(name: "viewport", id: "vp", content: "initial-scale=1.0,user-scalable=yes,width=device-width")
  end

  def destroy_all
    @current_user.generate_one_time_passwords(regenerate: true)
    redirect_to one_time_passwords_url
  end

  def disallow_masquerading
    render_unauthorized_action if @real_current_user
  end

  def require_otp
    render_unauthorized_action unless @current_user.otp_secret_key
  end
end
