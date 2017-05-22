#
# Copyright (C) 2011 - present Instructure, Inc.
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

class ConvertStorageQuotasToBytes < ActiveRecord::Migration[4.2]
  tag :predeploy

  FIELDS_TO_FIX = [
    [ User, :storage_quota ],
    [ Account, :storage_quota ],
    [ Account, :default_storage_quota ],
    [ Course, :storage_quota ],
    [ Group, :storage_quota ],
  ]

  def self.up
    FIELDS_TO_FIX.each do |klass, field|
      change_column klass.table_name.to_s, field, :integer, :limit => 8
      update("UPDATE #{klass.quoted_table_name} SET #{field} = #{field} * 1024 * 1024 WHERE #{field} IS NOT NULL AND #{field} < 1024 * 1024")
    end
  end

  def self.down
    FIELDS_TO_FIX.each do |klass, field|
      change_column klass.table_name.to_s, field, :integer, :limit => 4
      update("UPDATE #{klass.quoted_table_name} SET #{field} = #{field} / 1024 * 1024 WHERE #{field} IS NOT NULL AND #{field} >= 1024 * 1024")
    end
  end
end
