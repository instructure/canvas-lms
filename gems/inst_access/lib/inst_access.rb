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

require 'active_support'
require 'json/jwt'
require 'inst_access/errors'
require 'inst_access/config'
require 'inst_access/token'

module InstAccess
  class << self
    # signing_key is required.  if you are going to be producing (and therefore
    # signing) tokens, this needs to be an RSA private key.  if you're just
    # consuming tokens, it can be the RSA public key corresponding to the
    # private key that signed them.
    # encryption_key is only required if you are going to be producing tokens.
    def configure(signing_key:, encryption_key: nil)
      @config = Config.new(signing_key, encryption_key)
    end

    # set a configuration only for the duration of the given block, then revert
    # it.  useful for testing.
    def with_config(signing_key:, encryption_key: nil)
      old_config = @config
      configure(signing_key: signing_key, encryption_key: encryption_key)
      yield
    ensure
      @config = old_config
    end

    def config
      @config || raise(ConfigError, "InstAccess is not configured!")
    end
  end
end
