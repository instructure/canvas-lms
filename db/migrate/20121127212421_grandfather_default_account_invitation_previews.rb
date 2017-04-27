#
# Copyright (C) 2012 - present Instructure, Inc.
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

class GrandfatherDefaultAccountInvitationPreviews < ActiveRecord::Migration[4.2]
  # yes, predeploy, so that the setting is preserved before the new code goes live
  tag :predeploy

  def self.up
    Account.connection.schema_cache.clear!
    Account.reset_column_information
    return unless Account.default && Shard.current == Account.default.shard
    account = Account.default
    account.settings[:allow_invitation_previews] = true
    account.save!
  end

  def self.down
  end
end
