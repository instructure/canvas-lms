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
module Canvas::Vault
  # Adapter class to take static data written to disk
  # in config/vault_contents.yml and provide ruby objects
  # that act like a real vault client providing vault responses.
  class FileClient
    class Response
      def initialize(hash)
        @hash = hash
      end

      def data
        @hash.symbolize_keys
      end

      def lease_duration
        nil
      end
    end

    class << self
      Canvas::Reloader.on_reload { @_client = nil }
      def get_client
        @_client ||= FileClient.new
      end
    end

    def initialize
      @config = ConfigFile.load("vault_contents") || {}
    end

    def logical
      self
    end

    def read(key_path)
      Response.new(@config.fetch(key_path, {}))
    end
  end
end