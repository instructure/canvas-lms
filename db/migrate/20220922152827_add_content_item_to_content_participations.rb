# frozen_string_literal: true

#
# Copyright (C) 2022 - present Instructure, Inc.
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

class AddContentItemToContentParticipations < ActiveRecord::Migration[6.1]
  tag :predeploy

  disable_ddl_transaction!

  def change
    add_column :content_participations,
               :content_item,
               :string,
               null: false,
               default: "grade",
               if_not_exists: true

    add_index :content_participations,
              %w[content_id content_type user_id content_item],
              name: "index_content_participations_by_type_uniquely",
              unique: true,
              algorithm: :concurrently,
              if_not_exists: true

    remove_index :content_participations,
                 column: %w[content_id content_type user_id],
                 name: "index_content_participations_uniquely",
                 algorithm: :concurrently,
                 if_exists: true
  end
end
