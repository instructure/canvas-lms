# frozen_string_literal: true

#
# Copyright (C) 2026 - present Instructure, Inc.
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

describe RuboCop::Cop::Migration::PolymorphicAssociations do
  subject(:cop) { described_class.new }

  it "flags polymorphic: true in t.references" do
    offenses = inspect_source(%(
      class TestMigration < ActiveRecord::Migration[8.0]
        def change
          create_table :things do |t|
            t.references :context, polymorphic: true, null: false, index: false
          end
        end
      end
    ))
    expect(offenses.size).to eq(1)
    expect(offenses.first.message).to include("must be an array of table names")
    expect(offenses.first.severity.name).to eq(:error)
  end

  it "flags polymorphic: { limit: 255 } in t.references" do
    offenses = inspect_source(%(
      class TestMigration < ActiveRecord::Migration[8.0]
        def change
          create_table :things do |t|
            t.references :asset, polymorphic: { limit: 255 }, null: false, index: false
          end
        end
      end
    ))
    expect(offenses.size).to eq(1)
    expect(offenses.first.message).to include("must be an array of table names")
  end

  it "allows polymorphic: %i[...] in t.references" do
    offenses = inspect_source(%(
      class TestMigration < ActiveRecord::Migration[8.0]
        def change
          create_table :things do |t|
            t.references :context, polymorphic: %i[account course], foreign_key: true, null: false, index: false
          end
        end
      end
    ))
    expect(offenses.size).to eq(0)
  end

  it "flags string values in polymorphic array" do
    offenses = inspect_source(%(
      class TestMigration < ActiveRecord::Migration[8.0]
        def change
          create_table :things do |t|
            t.references :context, polymorphic: ["account", "course"], null: false
          end
        end
      end
    ))
    expect(offenses.size).to eq(1)
    expect(offenses.first.message).to include("must be an array of table names")
  end

  it "flags mixed string and symbol values in polymorphic array" do
    offenses = inspect_source(%(
      class TestMigration < ActiveRecord::Migration[8.0]
        def change
          create_table :things do |t|
            t.references :context, polymorphic: [:account, "course"], null: false
          end
        end
      end
    ))
    expect(offenses.size).to eq(1)
    expect(offenses.first.message).to include("must be an array of table names")
  end

  it "flags polymorphic: true in add_reference" do
    offenses = inspect_source(%(
      class TestMigration < ActiveRecord::Migration[8.0]
        def change
          add_reference :things, :context, polymorphic: true, null: false
        end
      end
    ))
    expect(offenses.size).to eq(1)
    expect(offenses.first.message).to include("must be an array of table names")
  end

  it "flags polymorphic: true in self.add_reference" do
    offenses = inspect_source(%(
      class TestMigration < ActiveRecord::Migration[8.0]
        def change
          self.add_reference :things, :context, polymorphic: true, null: false
        end
      end
    ))
    expect(offenses.size).to eq(1)
  end

  it "does not flag add_reference on an arbitrary receiver" do
    offenses = inspect_source(%(
      class TestMigration < ActiveRecord::Migration[8.0]
        def change
          connection.add_reference :things, :context, polymorphic: true, null: false
        end
      end
    ))
    expect(offenses.size).to eq(0)
  end

  it "does not flag references without polymorphic" do
    offenses = inspect_source(%(
      class TestMigration < ActiveRecord::Migration[8.0]
        def change
          create_table :things do |t|
            t.references :account, foreign_key: true, null: false
          end
        end
      end
    ))
    expect(offenses.size).to eq(0)
  end

  it "flags polymorphic in change_table" do
    offenses = inspect_source(%(
      class TestMigration < ActiveRecord::Migration[8.0]
        def change
          change_table :things do |t|
            t.references :context, polymorphic: true, null: false
          end
        end
      end
    ))
    expect(offenses.size).to eq(1)
  end

  it "does not flag references inside an unrelated block" do
    offenses = inspect_source(%(
      class TestMigration < ActiveRecord::Migration[8.0]
        def change
          some_other_method do |t|
            t.references :context, polymorphic: true, null: false
          end
        end
      end
    ))
    expect(offenses.size).to eq(0)
  end
end
