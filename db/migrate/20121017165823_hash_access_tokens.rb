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

class HashAccessTokens < ActiveRecord::Migration[4.2]
  tag :postdeploy
  disable_ddl_transaction!

  def self.up
    loop do
      batch = AccessToken.connection.select_all(<<-SQL)
        SELECT id, token FROM #{AccessToken.quoted_table_name} WHERE crypted_token IS NULL LIMIT 1000
      SQL

      break if batch.empty?

      batch.each do |at|
        updates = {
          :token_hint => at['token'][0,5],
          :crypted_token => AccessToken.hashed_token(at['token']),
        }
        AccessToken.where(:id => at['id']).update_all(updates)
      end
    end
  end

  def self.down
    AccessToken.update_all({ :crypted_token => nil, :token_hint => nil })
  end
end
