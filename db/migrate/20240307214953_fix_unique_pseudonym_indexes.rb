# frozen_string_literal: true

#
# Copyright (C) 2024 - present Instructure, Inc.
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

class FixUniquePseudonymIndexes < ActiveRecord::Migration[7.0]
  tag :postdeploy

  def up
    # these were created via `execute`, so `remove_index name: ...` doesn't work because
    # it will truncate the name and not find them
    execute "DROP INDEX IF EXISTS #{connection.quote_table_name("index_pseudonyms_on_unique_id_and_account_id_and_authentication_provider_id")}"
    execute "DROP INDEX IF EXISTS #{connection.quote_table_name("index_pseudonyms_on_unique_id_and_account_id_no_authentication_provider_id")}"
  end
end
