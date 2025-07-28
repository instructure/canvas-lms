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
    DEFAULT_US_COUNTRY_CODE = "1"

    def configuring?
      !!session[:pending_otp_secret_key]
    end

    def otp_via_sms_in_us_region?
      return @otp_via_sms_in_us_region if instance_variable_defined?(:@otp_via_sms_in_us_region)

      @otp_via_sms_in_us_region = otp_via_sms_provider? && otp_in_us_region?
    end

    private

    def otp_via_sms_provider?
      if @current_pseudonym&.authentication_provider.present?
        @current_pseudonym.authentication_provider.otp_via_sms?
      elsif @current_pseudonym&.account&.canvas_authentication?
        @current_pseudonym.account.canvas_authentication_provider.otp_via_sms?
      else
        false
      end
    end

    def otp_in_us_region?
      region = Shard.current.database_server.region
      us_region_prefix = "us-"
      region ? region.start_with?(us_region_prefix) : false
    end
  end
end
