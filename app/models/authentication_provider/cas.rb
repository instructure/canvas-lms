#
# Copyright (C) 2011 - present Instructure, Inc.
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

require 'casclient'

class AuthenticationProvider::CAS < AuthenticationProvider::Delegated

  def self.sti_name
    'cas'.freeze
  end

  def self.recognized_params
    [ :auth_base, :log_in_url, :jit_provisioning ].freeze
  end

  def self.deprecated_params
    [ :unknown_user_url ].freeze
  end

  def auth_provider_filter
    [nil, self]
  end

  def client
    @client ||= CASClient::Client.new(
      cas_base_url: auth_base,
      encode_extra_attributes_as: :raw
    )
  end

  def user_logout_redirect(controller, _current_user)
    client.logout_url(nil, controller.cas_login_url(id: self), controller.cas_login_url(id: self))
  end
end
