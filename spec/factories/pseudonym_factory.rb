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

def pseudonym_model(opts={})
  user_model unless @user
  @pseudonym = factory_with_protected_attributes(Pseudonym, valid_pseudonym_attributes.merge(opts))
end

# Re-generate these because I need a Unique ID
def valid_pseudonym_attributes
  {
    :unique_id => "#{CanvasUUID.generate}@example.com",
    :password => "password",
    :password_confirmation => "password",
    :persistence_token => "pt_#{CanvasUUID.generate}",
    :perishable_token => "value for perishable_token",
    :login_count => 1,
    :failed_login_count => 0,
    :last_request_at => Time.now,
    :last_login_at => Time.now,
    :current_login_at => Time.now,
    :last_login_ip => "value for last_login_ip",
    :current_login_ip => "value for current_login_ip",
    :user => @user
  }
end
