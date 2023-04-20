# frozen_string_literal: true

#
# Copyright (C) 2023 - present Instructure, Inc.
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

class AddInternalCaFieldsToAuthenticationProvider < ActiveRecord::Migration[7.0]
  tag :predeploy

  def change
    # `authentication_providers` was previously called `account_authorization_configs`. Before the rename occurred, a temporary
    # `authentication_providers` view was created in a predeploy migration. Then the view was dropped and the table was
    # *actually* renamed in a postdeploy migration.
    #
    # This means that if we're running all migrations at once (in a predeploy context), the frd `authentication_providers`
    # table will still be called by its old name -- so we need to identify the correct table to migrate.

    if connection.table_exists?(:authentication_providers)
      add_column :authentication_providers, :internal_ca, :text

      # this field will be removed after VERIFY_NONE is removed entirely
      add_column :authentication_providers, :verify_tls_cert_opt_in, :boolean, null: false, default: false
    else
      add_column :account_authorization_configs, :internal_ca, :text

      # this field will be removed after VERIFY_NONE is removed entirely
      add_column :account_authorization_configs, :verify_tls_cert_opt_in, :boolean, null: false, default: false
    end
  end
end
