#
# Copyright (C) 2020 - present Instructure, Inc.
#
# This file is part of Canvas.
#
# Canvas is free software: you can redistribute it and/or modify
# the terms of the GNU Affero General Public License as publishe
# Software Foundation, version 3 of the License.
#
# Canvas is distributed in the hope that it will be useful, but
# WARRANTY; without even the implied warranty of MERCHANTABILITY
# A PARTICULAR PURPOSE. See the GNU Affero General Public Licens
# details.
#
# You should have received a copy of the GNU Affero General Publ
# with this program. If not, see <http://www.gnu.org/licenses/>.

class RemoveFkConstraintsForCrossShardRootAccountIds < ActiveRecord::Migration[5.2]
  tag :predeploy

  def change
    remove_foreign_key :attachment_associations, :accounts, column: :root_account_id, if_exists: true
    remove_foreign_key :attachments, :accounts, column: :root_account_id, if_exists: true
    remove_foreign_key :communication_channels, :accounts, column: :root_account_id, if_exists: true
    remove_foreign_key :folders, :accounts, column: :root_account_id, if_exists: true
  end
end
