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
#
class ChangeBrandConfigMd5Size < ActiveRecord::Migration[5.0]
  tag :predeploy

  def up
    change_column :brand_configs, :md5, :string, limit: 255
    change_column :brand_configs, :parent_md5, :string, limit: 255
    change_column :shared_brand_configs, :brand_config_md5, :string, limit: 255
    change_column :accounts, :brand_config_md5, :string, limit: 255
  end

  def down
    change_column :brand_configs, :md5, :string, limit: 32
    change_column :brand_configs, :parent_md5, :string, limit: 32
    change_column :shared_brand_configs, :brand_config_md5, :string, limit: 32
    change_column :accounts, :brand_config_md5, :string, limit: 32
  end
end
