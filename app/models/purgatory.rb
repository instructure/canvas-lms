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
#
class Purgatory < ActiveRecord::Base
  belongs_to :attachment
  belongs_to :deleted_by_user, class_name: "User"

  scope :active, -> { where(workflow_state: "active") }

  TIME_TO_EXPIRE = 30.days

  def self.expire_old_purgatories
    Purgatory.active.where("updated_at < ?", TIME_TO_EXPIRE.ago).find_in_batches do |batch|
      batch.each do |p|
        next unless p.new_instfs_uuid

        begin
          InstFS.delete_file(p.new_instfs_uuid)
        rescue # still expire the record anyway even if we fail removing from instfs
          ::Rails.logger.warn("error deleting purgatory from instfs: #{$!.inspect}")
        end
      end
      Purgatory.where(id: batch).update_all(workflow_state: "expired")
    end
  end
end
