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

class ClientDisconnect
  def initialize(app)
    @app = app
    @on_disconnect = []
  end

  def on_disconnect(&block)
    @on_disconnect << block
  end

  def call(env)
    env['ClientDisconnect'] = self
    @on_disconnect = []

    # tested with Puma (development), and Apache + Passenger, both non-SSL
    socket = env['puma.socket'] || env['rack.input']
    # passenger wraps the actual socket in a few layers of wrapper classes; just keep looking
    socket = socket.instance_variable_get(:@socket) while socket.instance_variable_defined?(:@socket)
    if socket.is_a?(IO)
      thread = Thread.new do
        loop do
          res, = IO.select([socket])
          # if select returned the socket, it means a read won't block. that
          # could mean either there's data to be read, or the client
          # disconnected. so then we check nread to see if there's any bytes
          # available to distinguish the two
          if res == [socket] && socket.nread == 0
            @on_disconnect.each(&:call)
            break
          end
          # there's data available, but we're a background thread and can't
          # read it ourselves. we don't want to loop immediately cause that 
          # could use a lot of CPU if that data isn't getting read yet by the
          # main thread, so just do a tiny sleep in order to back off, but
          # still be responsive if the data gets slurped up, and then the client
          # quickly disconnects
          sleep 0.1 # rubocop:disable Lint/NoSleep
        end
      end
    end

    begin
      @app.call(env)
    ensure
      thread&.kill&.join
    end
  end
end
