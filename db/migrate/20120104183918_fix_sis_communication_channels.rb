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

class FixSisCommunicationChannels < ActiveRecord::Migration[4.2]
  tag :predeploy

  disable_ddl_transaction!

  def self.up
    begin
      pseudonym_ids = Pseudonym.joins(:sis_communication_channel).where("pseudonyms.user_id<>communication_channels.user_id").limit(1000).pluck(:id)
      Pseudonym.where(:id => pseudonym_ids).update_all(:sis_communication_channel_id => nil)
      sleep 1
    end until pseudonym_ids.empty?
  end

  def self.down
  end
end
