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

class CreateMediaTracks < ActiveRecord::Migration[4.2]
  tag :predeploy

  def self.up
    create_table :media_tracks do |t|
      t.integer :user_id,         :limit => 8
      t.integer :media_object_id, :limit => 8
      t.string :kind,             :default => "subtitles"
      t.string :locale,           :default => "en"
      t.text :content

      t.timestamps null: true
    end

    add_index :media_tracks, [:media_object_id, :locale], :name => 'media_object_id_locale'

  end

  def self.down
    drop_table :media_tracks
  end
end
