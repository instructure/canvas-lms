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

  it "complains about concurrent indexes in ddl transaction" do
    offenses = inspect_source(<<~RUBY)
      class TestMigration < ActiveRecord::Migration

        def up
          add_index :my_index, algorithm: :concurrently
        end
      end
    RUBY
    expect(offenses.size).to eq(1)
    expect(offenses.first.message).to match(/disable_ddl/)
    expect(offenses.first.severity.name).to eq(:error)
  end

  it "ignores non-concurrent indexes" do
    offenses = inspect_source(<<~RUBY)
      class TestMigration < ActiveRecord::Migration

        def up
          add_index :my_index
        end
      end
    RUBY
    expect(offenses.size).to eq(0)
  end

  it "is ok with concurrent indexes added non-transactionally" do
    offenses = inspect_source(<<~RUBY)
      class TestMigration < ActiveRecord::Migration
        disable_ddl_transaction!

        def up
          add_index :my_index, algorithm: :concurrently, if_not_exists: true
        end
      end
    RUBY
    expect(offenses.size).to eq(0)
  end

  it "complains about missing if_not_exists for add_index" do
    offenses = inspect_source(<<~RUBY)
      class TestMigration < ActiveRecord::Migration
        disable_ddl_transaction!

        def up
          add_index :my_index
        end
      end
    RUBY
    expect(offenses.size).to eq(1)
    expect(offenses.first.message).to match(/if_not_exists/)
    expect(offenses.first.severity.name).to eq(:error)
  end

  it "complains about missing if_not_exists for add_column" do
    offenses = inspect_source(<<~RUBY)
      class TestMigration < ActiveRecord::Migration
        disable_ddl_transaction!

        def up
          add_column :table, :column, :type
        end
      end
    RUBY
    expect(offenses.size).to eq(1)
    expect(offenses.first.message).to match(/if_not_exists/)
    expect(offenses.first.severity.name).to eq(:error)
  end

  it "complains about missing if_not_exists for add_reference" do
    offenses = inspect_source(<<~RUBY)
      class TestMigration < ActiveRecord::Migration
        disable_ddl_transaction!

        def up
          add_reference :courses, :homeroom_course, foreign_key: { to_table: :courses }
        end
      end
    RUBY
    expect(offenses.size).to eq 1
    expect(offenses.first.message).to match(/if_not_exists/)
    expect(offenses.first.severity.name).to eq :error
  end

  it "is ok about missing if_not_exists for add_index when transactional" do
    offenses = inspect_source(<<~RUBY)
      class TestMigration < ActiveRecord::Migration
        def up
          add_index :my_index
        end
      end
    RUBY
    expect(offenses.size).to eq(0)
  end

  it "is ok about missing if_not_exists for add_column when transactional" do
    offenses = inspect_source(<<~RUBY)
      class TestMigration < ActiveRecord::Migration
        def up
          add_column :table, :column, :type
        end
      end
    RUBY
    expect(offenses.size).to eq(0)
  end

  it "is ok about if_not_exists for add_index" do
    offenses = inspect_source(<<~RUBY)
      class TestMigration < ActiveRecord::Migration
        disable_ddl_transaction!

        def up
          add_index :my_index, if_not_exists: true
        end
      end
    RUBY
    expect(offenses.size).to eq(0)
  end

  it "is ok about if_not_exists for add_column" do
    offenses = inspect_source(<<~RUBY)
      class TestMigration < ActiveRecord::Migration
        disable_ddl_transaction!

        def up
          add_column :table, :column, :type, if_not_exists: true
        end
      end
    RUBY
    expect(offenses.size).to eq(0)
  end

  it "complains about missing if_exists on remove_foreign_key" do
    offenses = inspect_source(<<~RUBY)
      class TestMigration < ActiveRecord::Migration
        disable_ddl_transaction!

        def up
          remove_foreign_key :table, :column
        end
      end
    RUBY
    expect(offenses.size).to eq(1)
    expect(offenses.first.message).to match(/if_exists/)
    expect(offenses.first.severity.name).to eq(:error)
  end

  it "complains about missing if_not_exists on create_table" do
    offenses = inspect_source(<<~RUBY)
      class TestMigration < ActiveRecord::Migration
        disable_ddl_transaction!

        def up
          create_table :table do |t|
            t.timestamps
          end
        end
      end
    RUBY
    expect(offenses.size).to eq(1)
    expect(offenses.first.message).to match(/if_not_exists/)
    expect(offenses.first.severity.name).to eq(:error)
  end

  it "complains about missing if_not_exists on indexes in create_table" do
    offenses = inspect_source(<<~RUBY)
      class TestMigration < ActiveRecord::Migration
        disable_ddl_transaction!

        def up
          create_table :table, if_not_exists: true do |t|
            t.timestamps
            t.index :created_at
          end
        end
      end
    RUBY
    expect(offenses.size).to eq(1)
    expect(offenses.first.message).to match(/if_not_exists/)
    expect(offenses.first.severity.name).to eq(:error)
  end

  it "complains about missing if_not_exists on indexes in add_reference" do
    offenses = inspect_source(<<~RUBY)
      class TestMigration < ActiveRecord::Migration
        disable_ddl_transaction!

        def up
          create_table :table, if_not_exists: true do |t|
            t.references :column, index: true
            t.timestamps
          end
        end
      end
    RUBY
    expect(offenses.size).to eq(1)
    expect(offenses.first.message).to match(/if_not_exists/)
    expect(offenses.first.severity.name).to eq(:error)
  end

  it "complains about missing if_not_exists on indexes with options in add_reference" do
    offenses = inspect_source(<<~RUBY)
      class TestMigration < ActiveRecord::Migration
        disable_ddl_transaction!

        def up
          create_table :table, if_not_exists: true do |t|
            t.references :column, index: { name: "special" }
            t.timestamps
          end
        end
      end
    RUBY
    expect(offenses.size).to eq(1)
    expect(offenses.first.message).to match(/if_not_exists/)
    expect(offenses.first.severity.name).to eq(:error)
  end

  it "doesn't complain about present if_not_exists on indexes in add_reference" do
    offenses = inspect_source(<<~RUBY)
      class TestMigration < ActiveRecord::Migration
        disable_ddl_transaction!

        def up
          create_table :table, if_not_exists: true do |t|
            t.references :column, index: { name: "special", if_not_exists: true }
            t.timestamps
            t.index :create_at, if_not_exists: true
          end
        end
      end
    RUBY
    expect(offenses.size).to eq(0)
  end

  it "doesn't complain about non-index in add_reference" do
    offenses = inspect_source(<<~RUBY)
      class TestMigration < ActiveRecord::Migration
        disable_ddl_transaction!

        def up
          create_table :table, if_not_exists: true do |t|
            t.references :column, index: false
          end
        end
      end
    RUBY
    expect(offenses.size).to eq(0)
  end

  it "complains about drop_table without if_exists" do
    offenses = inspect_source(<<~RUBY)
      class TestMigration < ActiveRecord::Migration
        disable_ddl_transaction!

        def up
          drop_table :table
        end
      end
    RUBY
    expect(offenses.size).to eq(1)
    expect(offenses.first.message).to match(/if_exists/)
    expect(offenses.first.severity.name).to eq(:error)
  end

  it "doesn't complain about drop_table with if_exists" do
    offenses = inspect_source(<<~RUBY)
      class TestMigration < ActiveRecord::Migration
        disable_ddl_transaction!

        def up
          drop_table :table, if_exists: true
        end
      end
    RUBY
    expect(offenses.size).to eq(0)
  end
end
