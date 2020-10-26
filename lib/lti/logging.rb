# frozen_string_literal: true

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

# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.

module Lti::Logging
  PREFIX_MAP = {
    lti_1: "LTI 1.1",
    lti_1_3: "LTI 1.3"
  }.freeze

  def self.lti_1_launch_generated(base_string)
    log("Generated launch with base string #{base_string}")
  end

  def self.log(message, version: :lti_1, level: :info)
    Rails.logger.send(
      level,
      "[#{PREFIX_MAP[version]}] #{message}"
    )
  end
end