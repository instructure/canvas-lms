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

Rails.configuration.to_prepare do
  # set this to "true" in your docker-compose override file or in your .env
  # or whatever you use in order to see logging output containing all the
  # APM traces.
  Canvas::Apm.enable_debug_mode = ENV.fetch("DATADOG_APM_DEBUG_MODE", "false").casecmp?("true")
  Canvas::Apm.hostname = Socket.gethostname
  Canvas::Apm.configure_apm!
end
