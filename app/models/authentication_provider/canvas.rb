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
#

class AuthenticationProvider::Canvas < AuthenticationProvider
  def self.sti_name
    'canvas'
  end

  def self.singleton?
    true
  end

  def self.recognized_params
    [ :self_registration ].freeze
  end

  # Rename db field
  def self_registration=(val)
    case val
    when 'none'
      self.jit_provisioning = false
      self.auth_filter = nil
    when 'observer'
      self.jit_provisioning = true
      self.auth_filter = 'observer'
    when 'all'
      self.jit_provisioning = true
      self.auth_filter = 'all'
    else
      self.jit_provisioning = ::Canvas::Plugin.value_to_boolean(val)
      self.auth_filter = jit_provisioning? ? 'all' : nil
    end
  end

  def self_registration
    jit_provisioning? ? auth_filter : 'none'
  end

  def user_logout_redirect(controller, _current_user)
    controller.canvas_login_url unless controller.instance_variable_get(:@domain_root_account).auth_discovery_url
  end
end
