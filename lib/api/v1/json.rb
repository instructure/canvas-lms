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

module Api::V1::Json
  # go through this helper for all json serialization in the api -- it handles
  # some tasks that all api json should do, like not including the root wrapper
  # object, and passing the user permissions info into the serialization engine.
  #
  # if no user/session is given, permissions will not be considered during
  # serialization! make sure that's ok.
  #
  # this returns the ruby hash of the json data, not the raw json string. you can still pass that hash to render like
  # render :json => hash
  # and it'll be stringified properly.
  def api_json(obj, user, session, opts = {}, permissions_to_return = [])
    permissions = { :user => user, :session => session, :include_permissions => false }
    if permissions_to_return.present?
      permissions[:include_permissions] = true
      permissions[:policies] = Array(permissions_to_return)
    end

    json = obj.as_json({ :include_root => false,
                  :permissions => permissions }.merge(opts))

    if block_given?
      dynamic_attributes = OpenStruct.new
      yield dynamic_attributes, obj
      json.merge!(dynamic_attributes.marshal_dump)
    end

    json
  end
end
