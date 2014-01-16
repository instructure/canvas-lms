#
# Copyright (C) 2014 Instructure, Inc.
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

# we use Rails 3 engines yet because we have to support rails 2 for the next few months
# we namespace everything having to do with DataExport so that it can be easily extracted into a gem once we are on rails 3
module DataExportsApi
  module Api::V1::DataExport
    include ::Api::V1::User
    include ::Api::V1::Account

    def data_export_json(data_export, user, session, includes = [])
      json = api_json(data_export, user, session, :only => %w(id created_at workflow_state))
      # TODO update once we have support for more granular contexts than just Account
      json["account"] = account_json(::Account.find_by_id(data_export.context_id), user, session, includes) if includes.include?(:account)
      json["user"] = user_json(User.find_by_id(data_export.user_id), user, session, includes, Account.find_by_id(data_export.context_id)) if includes.include?(:user)
      json
    end

    def data_exports_json(data_exports, user, session, includes = [])
      data_exports.map{ |dd| data_export_json(dd, user, session, includes) }
    end
  end
end
