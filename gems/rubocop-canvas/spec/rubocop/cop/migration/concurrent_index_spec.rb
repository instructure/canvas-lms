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

describe RuboCop::Cop::Migration::ConcurrentIndex do
  subject(:cop) { described_class.new }

  it 'complains about concurrent indexes in ddl transaction' do
    inspect_source(%{
      class TestMigration < ActiveRecord::Migration

        def up
          add_index :my_index, algorithm: :concurrently
        end
      end
    })
    expect(cop.offenses.size).to eq(1)
    expect(cop.messages.first).to match(/disable_ddl/)
    expect(cop.offenses.first.severity.name).to eq(:warning)
  end

  it 'ignores non-concurrent indexes' do
    inspect_source(%{
      class TestMigration < ActiveRecord::Migration

        def up
          add_index :my_index
        end
      end
    })
    expect(cop.offenses.size).to eq(0)
  end

  it 'is ok with concurrent indexes added non-transactionally' do
    inspect_source(%{
      class TestMigration < ActiveRecord::Migration
        disable_ddl_transaction!

        def up
          add_index :my_index, algorithm: :concurrently
        end
      end
    })
    expect(cop.offenses.size).to eq(0)
  end

  it 'complains about unknown algorithm' do
    inspect_source(%{
      class TestMigration < ActiveRecord::Migration
        def up
          add_index :my_index, algorithm: :concurrent
        end
      end
    })
    expect(cop.offenses.size).to eq(1)
    expect(cop.messages.first).to match(/unknown algorithm/i)
    expect(cop.offenses.first.severity.name).to eq(:warning)
  end
end
