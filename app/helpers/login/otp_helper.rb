# frozen_string_literal: true

#
# Copyright (C) 2014 - present Instructure, Inc.
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

module Login
  module OtpHelper
    def configuring?
      !!session[:pending_otp_secret_key]
    end

    def otp_via_sms?
      @otp_via_sms ||= if @current_pseudonym.authentication_provider.present?
                         @current_pseudonym.authentication_provider.otp_via_sms?
                       elsif @current_pseudonym.account.canvas_authentication?
                         @current_pseudonym.account.canvas_authentication_provider.otp_via_sms?
                       else
                         false
                       end
    end

    def otp_via_sms_message
      otp_via_sms? ? t("This can be a device that can generate verification codes, or a phone that can receive text messages.") : ""
    end
  end
end
