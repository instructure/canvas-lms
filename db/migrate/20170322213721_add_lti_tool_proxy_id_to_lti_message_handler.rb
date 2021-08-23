# frozen_string_literal: true

#
# Copyright (C) 2017 - present Instructure, Inc.
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

class AddLtiToolProxyIdToLtiMessageHandler < ActiveRecord::Migration[4.2]
  tag :predeploy
  def up
    add_column :lti_message_handlers, :tool_proxy_id, :bigint
    add_foreign_key :lti_message_handlers, :lti_tool_proxies, column: :tool_proxy_id
    add_index :lti_message_handlers, [:tool_proxy_id]
  end

  def down
    remove_column :lti_message_handlers, :tool_proxy_id, :bigint
  end
end
