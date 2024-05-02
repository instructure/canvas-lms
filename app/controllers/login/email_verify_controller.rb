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

class Login::EmailVerifyController < ApplicationController
  include Login::Shared

  def show
    return redirect_to login_url unless params[:d]

    @jwt = params[:d]
    h = CanvasSecurity.decode_jwt(@jwt)
    @verification_email = h["e"]
  rescue CanvasSecurity::InvalidToken, CanvasSecurity::TokenExpired
    redirect_to login_url
  end

  def verify
    h = CanvasSecurity.decode_jwt(params[:d])
    pseudonym = Pseudonym.find_by(id: h["i"])
    code = params[:code]&.strip
    if pseudonym.migrate_login_attribute(code:)
      flash[:notice] = t("Account verification successful")
      @domain_root_account.pseudonyms.scoping do
        PseudonymSession.create!(pseudonym, false)
      end
      session[:login_aac] = pseudonym.authentication_provider.global_id
      successful_login(pseudonym.user, pseudonym)
      return
    end

    flash[:error] = t("Invalid verification code")
    redirect_back fallback_location: login_url
  rescue CanvasSecurity::InvalidToken, CanvasSecurity::TokenExpired
    redirect_to login_url
  end
end
