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

class AddThumbnailUuid < ActiveRecord::Migration[4.2]
  tag :predeploy

  class Thumbnail < ActiveRecord::Base
  end

  def self.up
    add_column :thumbnails, :uuid, :string
    add_index :thumbnails, [:id, :uuid]

    Thumbnail.find_each do |t|
      t.uuid ||= CanvasSlug.generate_securish_uuid
      t.save
    end
  end

  def self.down
    remove_column :thumbnails, :uuid
  end
end
