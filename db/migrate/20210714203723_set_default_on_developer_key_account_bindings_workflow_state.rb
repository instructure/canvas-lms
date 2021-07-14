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

class SetDefaultOnDeveloperKeyAccountBindingsWorkflowState < ActiveRecord::Migration[6.0]
  tag :predeploy

  def up
    change_column_default :developer_key_account_bindings, :workflow_state, 'off'
    change_column_null :developer_key_account_bindings, :created_at, false
    change_column_null :developer_key_account_bindings, :updated_at, false
  end

  def down
    change_column_default :developer_key_account_bindings, :workflow_state, nil
    change_column_null :developer_key_account_bindings, :created_at, true
    change_column_null :developer_key_account_bindings, :updated_at, true
  end
end
