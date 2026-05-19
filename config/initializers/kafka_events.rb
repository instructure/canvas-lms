# frozen_string_literal: true

#
# Copyright (C) 2026 - present Instructure, Inc.
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

Rails.application.config.after_initialize do
  Canvas::KafkaEvents.build_producer

  if defined?(PhusionPassenger)
    PhusionPassenger.on_event(:stopping_worker_process) do
      Canvas::KafkaEvents.producer&.close
    end
  else
    at_exit do
      Canvas::KafkaEvents.producer&.close
    end
  end
end
