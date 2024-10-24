# frozen_string_literal: true

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

require "active_model"

module LtiAdvantage::Claims
  # Class representing claim that advertises support for 1EdTech
  # LTI Platform Notification Service
  # https://purl.imsglobal.org/spec/lti/claim/platformnotificationservice
  class PlatformNotificationService
    include ActiveModel::Model

    attr_accessor :platform_notification_service_url,
                  :service_versions,
                  :scope,
                  :notice_types_supported

    validates_presence_of :scope, :platform_notification_service_url, :service_versions, :notice_types_supported
  end
end
