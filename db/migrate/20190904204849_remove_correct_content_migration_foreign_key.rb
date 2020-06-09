#
# Copyright (C) 2019 - present Instructure, Inc.
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
class RemoveCorrectContentMigrationForeignKey < ActiveRecord::Migration[5.2]
  tag :predeploy

  def up
    remove_foreign_key_if_exists :content_migrations, :column => :attachment_id
  end

  def down
    add_foreign_key :content_migrations, :attachments, :column => :attachment_id, :delay_validation => true, if_not_exists: true
  end
end
