# frozen_string_literal: true

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
#

class AbortOnDisconnect
  def initialize(app)
    @app = app
  end

  class DisconnectedError < RuntimeError
  end

  def call(env)
    main_thread = Thread.current
    env['ClientDisconnect'].on_disconnect do
      next if Canvas::DynamicSettings.find(tree: :private)["abort_on_disconnect"] == "false"
      main_thread.raise(DisconnectedError.new)
    end
    @app.call(env)
  rescue DisconnectedError
    [ 408, {}, [] ]
  end
end
