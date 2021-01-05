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

Rails.configuration.to_prepare do
  CanvasPandaPub.logger = Rails.logger
  CanvasPandaPub.cache = Rails.cache
  CanvasPandaPub.plugin_settings = -> { Canvas::Plugin.find(:pandapub) }
  CanvasPandaPub.max_queue_size = -> { Setting.get('pandapub_max_queue_size', 1000).to_i }
  CanvasPandaPub.process_interval = -> { Setting.get('pandapub_process_interval_seconds', 1.0).to_f }
  # sometimes this async worker thread grabs a connection on a Setting read or similar.
  # We need it to be released or the main thread can have a real problem.
  CanvasPandaPub.on_work_unit_end = -> { ActiveRecord::Base.clear_active_connections! }
end
