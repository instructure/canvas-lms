# frozen_string_literal: true

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

describe RuboCop::Cop::Migration::NonTransactional do
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
          add_index :my_index, algorithm: :concurrently, if_not_exists: true
        end
      end
    })
    expect(cop.offenses.size).to eq(0)
  end

  it 'complains about missing if_not_exists for add_index' do
    inspect_source(%{
      class TestMigration < ActiveRecord::Migration
        disable_ddl_transaction!

        def up
          add_index :my_index
        end
      end
    })
    expect(cop.offenses.size).to eq(1)
    expect(cop.messages.first).to match(/if_not_exists/)
    expect(cop.offenses.first.severity.name).to eq(:warning)
  end

  it 'complains about missing if_not_exists for add_column' do
    inspect_source(%{
      class TestMigration < ActiveRecord::Migration
        disable_ddl_transaction!

        def up
          add_column :table, :column, :type
        end
      end
    })
    expect(cop.offenses.size).to eq(1)
    expect(cop.messages.first).to match(/if_not_exists/)
    expect(cop.offenses.first.severity.name).to eq(:warning)
  end

  it 'is ok about missing if_not_exists for add_index when transactional' do
    inspect_source(%{
      class TestMigration < ActiveRecord::Migration
        def up
          add_index :my_index
        end
      end
    })
    expect(cop.offenses.size).to eq(0)
  end

  it 'is ok about missing if_not_exists for add_column when transactional' do
    inspect_source(%{
      class TestMigration < ActiveRecord::Migration
        def up
          add_column :table, :column, :type
        end
      end
    })
    expect(cop.offenses.size).to eq(0)
  end

  it 'is ok about if_not_exists for add_index' do
    inspect_source(%{
      class TestMigration < ActiveRecord::Migration
        disable_ddl_transaction!

        def up
          add_index :my_index, if_not_exists: true
        end
      end
    })
    expect(cop.offenses.size).to eq(0)
  end

  it 'is ok about if_not_exists for add_column' do
    inspect_source(%{
      class TestMigration < ActiveRecord::Migration
        disable_ddl_transaction!

        def up
          add_column :table, :column, :type, if_not_exists: true
        end
      end
    })
    expect(cop.offenses.size).to eq(0)
  end

  it 'complains about missing if_exists on remove_foreign_key' do
    inspect_source(%{
      class TestMigration < ActiveRecord::Migration
        disable_ddl_transaction!

        def up
          remove_foreign_key :table, :column
        end
      end
    })
    expect(cop.offenses.size).to eq(1)
    expect(cop.messages.first).to match(/if_exists/)
    expect(cop.offenses.first.severity.name).to eq(:warning)
  end
end
