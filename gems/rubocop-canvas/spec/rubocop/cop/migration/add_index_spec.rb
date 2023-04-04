# frozen_string_literal: true

#
# Copyright (C) 2021 - present Instructure, Inc.
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

describe RuboCop::Cop::Migration::AddIndex do
  subject(:cop) { described_class.new }

  context "add_index" do
    it "expects a non-transactional migration" do
      inspect_source(<<~RUBY)
        class TestMigration < ActiveRecord::Migration
          def up
            add_index :users, :karma, algorithm: :concurrently
            add_index :users, :shoe_size, algorithm: :concurrently
          end
        end
      RUBY
      expect(cop.offenses.size).to eq 1 # only nags about this once
      expect(cop.messages.first).to include "`disable_ddl_transaction!`"
      expect(cop.offenses.first.severity.name).to eq(:warning)
    end

    it "expects `algorithm: :concurrently`" do
      inspect_source(<<~RUBY)
        class TestMigration < ActiveRecord::Migration
          disable_ddl_transaction!
          def up
            add_index :users, :karma
            add_index :users, :shoe_size
          end
        end
      RUBY
      expect(cop.offenses.size).to eq 2
      expect(cop.messages.first).to include "`algorithm: :concurrently`"
      expect(cop.offenses.first.severity.name).to eq(:warning)
    end

    it "emits no warnings when conditions are satisfied" do
      inspect_source(<<~RUBY)
        class TestMigration < ActiveRecord::Migration
          disable_ddl_transaction!
          def up
            add_index :users, :karma, algorithm: :concurrently
          end
        end
      RUBY
      expect(cop.offenses.size).to eq 0
    end

    it "still finds `algorithm: :concurrently` if other index options are given" do
      inspect_source(<<~RUBY)
        class TestMigration < ActiveRecord::Migration
          disable_ddl_transaction!
          def up
            add_index :users, :karma, unique: true, algorithm: :concurrently
          end
        end
      RUBY
      expect(cop.offenses.size).to eq 0
    end

    it "emits no warnings when adding an index to a table created in the same migration" do
      inspect_source(<<~RUBY)
        class TestMigration < ActiveRecord::Migration
          def change
            create_table :wickets do |t|
              t.string :color
            end
            add_index :wickets, :color
          end
        end
      RUBY
      expect(cop.offenses.size).to eq 0
    end

    it "doesn't flag when adding an index in `down`" do
      inspect_source(<<~RUBY)
        class TestMigration < ActiveRecord::Migration
          def down
            add_index :users, :karma
          end
        end
      RUBY
      expect(cop.offenses.size).to eq 0
    end

    it "handles non-constant table names" do
      inspect_source(<<~RUBY)
        class TestMigration < ActiveRecord::Migration
          def up
            with_each_partition do |partition|
              add_index partition, :account_id, algorithm: :concurrently
              add_index partition, :submission_id, algorithm: :concurrently
              add_index partition, :student_id, algorithm: :concurrently
              add_index partition, :grader_id, algorithm: :concurrently
            end
          end
        end
      RUBY
      expect(cop.offenses.size).to eq 1
    end
  end

  context "add_reference" do
    it "expects a non-transactional migration" do
      inspect_source(<<~RUBY)
        class TestMigration < ActiveRecord::Migration
          def up
            add_reference :users, :organizations, index: { algorithm: :concurrently }
          end
        end
      RUBY
      expect(cop.offenses.size).to eq 1
      expect(cop.messages.first).to include "`disable_ddl_transaction!`"
      expect(cop.offenses.first.severity.name).to eq(:warning)
    end

    it "expects `algorithm: :concurrently` if `index: true` is given" do
      inspect_source(<<~RUBY)
        class TestMigration < ActiveRecord::Migration
          disable_ddl_transaction!
          def up
            add_reference :users, :organizations, index: true
          end
        end
      RUBY
      expect(cop.offenses.size).to eq 1
      expect(cop.messages.first).to include "Use `index: { algorithm: :concurrently }`"
      expect(cop.offenses.first.severity.name).to eq(:warning)
    end

    it "expects `algorithm: :concurrently` if no `index` option is given (since it defaults to `true`)" do
      inspect_source(<<~RUBY)
        class TestMigration < ActiveRecord::Migration
          disable_ddl_transaction!
          def up
            add_reference :users, :organizations
          end
        end
      RUBY
      expect(cop.offenses.size).to eq 1
      expect(cop.messages.first).to include "Use `index: { algorithm: :concurrently }`"
      expect(cop.offenses.first.severity.name).to eq(:warning)
    end

    it "doesn't complain if not indexed" do
      inspect_source(<<~RUBY)
        class TestMigration < ActiveRecord::Migration
          def up
            add_reference :users, :organizations, index: false
          end
        end
      RUBY
      expect(cop.offenses.size).to eq 0
    end

    it "emits no warnings when conditions are satisfied" do
      inspect_source(<<~RUBY)
        class TestMigration < ActiveRecord::Migration
          disable_ddl_transaction!
          def up
            add_reference :users, :organizations, index: { algorithm: :concurrently }
          end
        end
      RUBY
      expect(cop.offenses.size).to eq 0
    end

    it "still finds `algorithm: :concurrently` when other index options are given" do
      inspect_source(<<~RUBY)
        class TestMigration < ActiveRecord::Migration
          disable_ddl_transaction!
          def up
            add_reference :users, :organizations, index: { unique: true, algorithm: :concurrently }
          end
        end
      RUBY
      expect(cop.offenses.size).to eq 0
    end

    it "emits no warnings when adding a reference on a table created in the same migration" do
      inspect_source(<<~RUBY)
        class TestMigration < ActiveRecord::Migration
          def change
            create_table "wickets" do |t|
            end
            add_reference :wickets, :color, index: true
          end
        end
      RUBY
      expect(cop.offenses.size).to eq 0
    end

    it "doesn't flag when adding a reference in `down`" do
      inspect_source(<<~RUBY)
        class TestMigration < ActiveRecord::Migration
          def down
            add_reference :wickets, :color, index: true
          end
        end
      RUBY
      expect(cop.offenses.size).to eq 0
    end
  end

  context "create_table" do
    it "does not complain about indexes or references in a new table" do
      inspect_source(<<~RUBY)
        class TestMigration < ActiveRecord::Migration
          def change
            create_table :widgets do |t|
              t.text :color
              t.index :color
              t.references :wicket
            end
          end
        end
      RUBY
      expect(cop.offenses.size).to eq 0
    end
  end

  context "change_table" do
    context "t.index" do
      it "expects a non-transactional migration" do
        inspect_source(<<~RUBY)
          class TestMigration < ActiveRecord::Migration
            def change
              change_table :widgets do |t|
                t.text :color
                t.index :color, algorithm: :concurrently
              end
            end
          end
        RUBY
        expect(cop.offenses.size).to eq 1
        expect(cop.messages.first).to include "`disable_ddl_transaction!`"
        expect(cop.offenses.first.severity.name).to eq(:warning)
      end

      it "expects `algorithm: :concurrently`" do
        inspect_source(<<~RUBY)
          class TestMigration < ActiveRecord::Migration
            disable_ddl_transaction!
            def change
              change_table :widgets, bulk: true do |t|
                t.text :color
                t.index :color
              end
            end
          end
        RUBY
        expect(cop.offenses.size).to eq 1
        expect(cop.messages.first).to include "`algorithm: :concurrently`"
        expect(cop.offenses.first.severity.name).to eq(:warning)
      end

      it "emits no warnings when conditions are satisfied" do
        inspect_source(<<~RUBY)
          class TestMigration < ActiveRecord::Migration
            disable_ddl_transaction!
            def change
              change_table :widgets do |t|
                t.text :color
                t.index :color, algorithm: :concurrently
              end
            end
          end
        RUBY
        expect(cop.offenses.size).to eq 0
      end

      it "doesn't flag when adding an index in `down`" do
        inspect_source(<<~RUBY)
          class TestMigration < ActiveRecord::Migration
            def down
              change_table :widgets do |d|
                t.index :color
              end
            end
          end
        RUBY
        expect(cop.offenses.size).to eq 0
      end
    end

    context "t.references" do
      it "expects a non-transactional migration" do
        inspect_source(<<~RUBY)
          class TestMigration < ActiveRecord::Migration
            def change
              change_table :widgets do |t|
                t.references :color, index: { algorithm: :concurrently }
              end
            end
          end
        RUBY
        expect(cop.offenses.size).to eq 1
        expect(cop.messages.first).to include "`disable_ddl_transaction!`"
        expect(cop.offenses.first.severity.name).to eq(:warning)
      end

      it "expects `algorithm: :concurrently` if `index: true` is given" do
        inspect_source(<<~RUBY)
          class TestMigration < ActiveRecord::Migration
            disable_ddl_transaction!
            def change
              change_table :widgets do |t|
                t.references :color, index: true
              end
            end
          end
        RUBY
        expect(cop.offenses.size).to eq 1
        expect(cop.messages.first).to include "Use `index: { algorithm: :concurrently }`"
        expect(cop.offenses.first.severity.name).to eq(:warning)
      end

      it "expects `algorithm: :concurrently` if no `index` option is given (since it defaults to `true`)" do
        inspect_source(<<~RUBY)
          class TestMigration < ActiveRecord::Migration
            disable_ddl_transaction!
            def change
              change_table :widgets do |t|
                t.references :color
              end
            end
          end
        RUBY
        expect(cop.offenses.size).to eq 1
        expect(cop.messages.first).to include "Use `index: { algorithm: :concurrently }`"
        expect(cop.offenses.first.severity.name).to eq(:warning)
      end

      it "doesn't complain if not indexed" do
        inspect_source(<<~RUBY)
          class TestMigration < ActiveRecord::Migration
            disable_ddl_transaction!
            def change
              change_table :widgets do |t|
                t.references :color, index: false
              end
            end
          end
        RUBY
        expect(cop.offenses.size).to eq 0
      end

      it "emits no warnings when conditions are satisfied" do
        inspect_source(<<~RUBY)
          class TestMigration < ActiveRecord::Migration
            disable_ddl_transaction!
            def change
              change_table :widgets do |t|
                t.references :color, index: { algorithm: :concurrently }
              end
            end
          end
        RUBY
        expect(cop.offenses.size).to eq 0
      end

      it "doesn't flag when adding a reference in `down`" do
        inspect_source(<<~RUBY)
          class TestMigration < ActiveRecord::Migration
            def down
              change_table :widgets do |t|
                t.references :color
              end
            end
          end
        RUBY
        expect(cop.offenses.size).to eq 0
      end
    end
  end
end
