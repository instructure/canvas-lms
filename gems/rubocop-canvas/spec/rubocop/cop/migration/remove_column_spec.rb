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
      expect(cop.messages.first).to match(/column removal/)
      expect(cop.offenses.first.severity.name).to eq(:error)
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
      expect(cop.messages.first).to match(/column removal/)
      expect(cop.offenses.first.severity.name).to eq(:error)
    end

    it 'disallows remove_column in `change`' do
      inspect_source(%{
        class MyMigration < ActiveRecord::Migration
          tag :predeploy

          def change
            remove_column :x, :y
          end
        end
      })
      expect(cop.offenses.size).to eq(1)
      expect(cop.messages.first).to match(/column removal/)
      expect(cop.offenses.first.severity.name).to eq(:error)
    end

    it 'disallows a bunch of other column removal methods' do
      inspect_source(%{
        class MyMigration < ActiveRecord::Migration
          tag :predeploy

          def up
            change_table :x do |t|
              t.remove :y
              t.remove_belongs_to :y
              t.remove_references :y
              t.remove_timestamps
            end
            remove_reference :y
            remove_columns :y, :z
          end
        end
      })
      expect(cop.offenses.size).to eq(6)
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
