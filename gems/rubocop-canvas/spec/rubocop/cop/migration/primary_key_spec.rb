#
# Copyright (C) 2015 - present Instructure, Inc.
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

describe RuboCop::Cop::Migration::PrimaryKey do
  subject(:cop) { described_class.new }

  it 'catches explicit id disabled' do
    inspect_source(%{
      class CreateNotificationEndpoints < ActiveRecord::Migration
        tag :predeploy

        def self.up
          create_table(:notification_endpoints, id: false) do |t|
            t.integer :access_token_id, limit: 8, null: false
            t.string :token, null: false
            t.string :arn, null: false
            t.timestamps
          end
          add_index :notification_endpoints, :access_token_id
          add_foreign_key :notification_endpoints, :access_tokens
        end

        def self.down
          drop_table :notification_endpoints
        end
      end
    })
    expect(cop.offenses.size).to eq(1)
    expect(cop.messages.first).to match(/include a primary key/)
    expect(cop.offenses.first.severity.name).to eq(:warning)
  end
end
