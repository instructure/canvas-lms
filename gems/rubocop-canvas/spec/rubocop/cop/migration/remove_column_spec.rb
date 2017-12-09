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

describe RuboCop::Cop::Migration::RemoveColumn do
  subject(:cop) { described_class.new }

  context 'predeploy' do
    it 'disallows remove_column in `up`' do
      inspect_source(%{
        class MyMigration < ActiveRecord::Migration
          tag :predeploy

          def up
            remove_column :x, :y
          end
        end
      })
      expect(cop.offenses.size).to eq(1)
      expect(cop.messages.first).to match(/remove_column/)
      expect(cop.offenses.first.severity.name).to eq(:warning)
    end

    it 'disallows remove_column in `self.up`' do
      inspect_source(%{
        class MyMigration < ActiveRecord::Migration
          tag :predeploy

          def self.up
            remove_column :x, :y
          end
        end
      })
      expect(cop.offenses.size).to eq(1)
      expect(cop.messages.first).to match(/remove_column/)
      expect(cop.offenses.first.severity.name).to eq(:warning)
    end

    it 'allows remove_column in `down`' do
      inspect_source(%{
        class MyMigration < ActiveRecord::Migration
          tag :predeploy

          def down
            remove_column :x, :y
          end
        end
      })
      expect(cop.offenses.size).to eq(0)
    end
  end
end
