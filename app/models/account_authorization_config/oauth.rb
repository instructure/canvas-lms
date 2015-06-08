#
# Copyright (C) 2015 Instructure, Inc.
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

require 'oauth2'

class AccountAuthorizationConfig::Oauth < AccountAuthorizationConfig::Delegated

  SENSITIVE_PARAMS = [ :consumer_secret ].freeze

  # rename DB fields to something that makes sense for OAuth2
  def consumer_key=(val)
    self.entity_id = val
  end

  def consumer_key
    entity_id
  end

  alias_method :consumer_secret=, :auth_password=
  alias_method :consumer_secret, :auth_decrypted_password

  def consumer
    @client ||= OAuth::Consumer.new(consumer_key, consumer_secret, consumer_options)
  end

  protected

  def token_options
    {}
  end
end
