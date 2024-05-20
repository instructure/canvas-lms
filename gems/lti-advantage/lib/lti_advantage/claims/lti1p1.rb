# frozen_string_literal: true

#
# Copyright (C) 2021 - present Instructure, Inc.
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
  # Class represeting an LTI 1.3 message "lti1p1" claim which allows a platform
  # to pass to the tool a mapping of ids that have shifted with the transition
  # from LTI1.1 to LTI 1.3.
  # https://purl.imsglobal.org/spec/lti/claim/lti1p1
  class Lti1p1
    include ActiveModel::Model

    attr_accessor :user_id, :resource_link_id, :oauth_consumer_key, :oauth_consumer_key_sign
  end
end
