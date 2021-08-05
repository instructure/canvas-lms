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
#

require 'openssl'

module InstAccess
  class Config
    attr_reader :signing_key

    def initialize(raw_signing_key, raw_encryption_key = nil)
      @signing_key = OpenSSL::PKey::RSA.new(raw_signing_key)
      if raw_encryption_key
        @encryption_key = OpenSSL::PKey::RSA.new(raw_encryption_key)
        if @encryption_key.private?
          raise ArgumentError, "the encryption key should be a public RSA key"
        end
      end
    rescue OpenSSL::PKey::RSAError => e
      raise ArgumentError, e
    end

    def encryption_key
      @encryption_key || raise(ConfigError, "Encryption key is not configured")
    end
  end
end
