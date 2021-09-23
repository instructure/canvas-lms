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

class AddDeveloperKeyIdToLtiProductFamily < ActiveRecord::Migration[4.2]
  tag :predeploy
  def change
    add_column :lti_product_families, :developer_key_id, :integer, limit: 8
    add_index :lti_product_families, :developer_key_id

    remove_index :lti_product_families, {column: [:root_account_id, :vendor_code, :product_code], name: 'index_lti_product_families_on_root_account_vend_code_prod_code', unique: true}
    add_index :lti_product_families, [:product_code, :vendor_code, :root_account_id, :developer_key_id], unique: true, name: 'product_family_uniqueness'
  end
end
