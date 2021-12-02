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

require 'uri'
require 'oauth'
require 'oauth/consumer'
require 'i18n'

module LtiOutbound
  require 'lti_outbound/lti_model'
  require 'lti_outbound/lti_context'
  require 'lti_outbound/lti_tool'
  require 'lti_outbound/lti_account'
  require 'lti_outbound/lti_course'
  require 'lti_outbound/lti_role'
  require 'lti_outbound/lti_user'
  require 'lti_outbound/lti_assignment'
  require 'lti_outbound/lti_consumer_instance'
  require 'lti_outbound/tool_launch'
  require 'lti_outbound/variable_substitutor'
end
