#
# Copyright (C) 2011 Instructure, Inc.
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

def user_service_model(opts={})
  @user_service = factory_with_protected_attributes(UserService, valid_user_service_attributes.merge(opts))
end

def valid_user_service_attributes
  {
    :user_id => User.create!.id,
    :token => 'value for token',
    :secret => 'value for secret', 
    :protocol => 'value for protocol',
    :service => 'value for service',
    :service_user_url => 'value for service_user_url',
    :service_user_id => 'value for service_user_id',
    :service_user_name => 'value for service_user_name',
    :service_domain => 'value for service_domain'
  }
end
