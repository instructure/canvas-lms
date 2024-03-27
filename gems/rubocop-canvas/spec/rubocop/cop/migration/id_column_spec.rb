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

describe RuboCop::Cop::Migration::IdColumn do
  subject(:cop) { described_class.new }

  context "create_table/change_table block with t.integer" do
    it "complains if a small integer column is named `_id`" do
      inspect_source(<<~RUBY)
        class TestMigration < ActiveRecord::Migration
          def up
            create_table :widgets do |t|
              t.integer :wicket_id
            end
          end
        end
      RUBY
      expect(cop.offenses.size).to eq 1
      expect(cop.messages.first).to eq "Migration/IdColumn: Use `:bigint` for id columns"
      expect(cop.offenses.first.severity.name).to eq(:warning)
    end

    it "still complains if limit: 8 is given" do
      inspect_source(<<~RUBY)
        class TestMigration < ActiveRecord::Migration
          def up
            create_table :widgets do |t|
              t.integer :wicket_id, limit: 8
            end
          end
        end
      RUBY
      expect(cop.offenses.size).to eq 1
      expect(cop.messages.first).to eq "Migration/IdColumn: Use `:bigint` for id columns"
      expect(cop.offenses.first.severity.name).to eq(:warning)
    end

    it "doesn't complain if type :bigint is given" do
      inspect_source(<<~RUBY)
        class TestMigration < ActiveRecord::Migration
          def up
            create_table :widgets do |t|
              t.bigint :wicket_id
            end
          end
        end
      RUBY
      expect(cop.offenses.size).to eq 0
    end

    it "doesn't complain about a non-id column" do
      inspect_source(<<~RUBY)
        class TestMigration < ActiveRecord::Migration
          def up
            create_table :widgets do |t|
              t.integer :fluoride
            end
          end
        end
      RUBY
      expect(cop.offenses.size).to eq 0
    end
  end

  context "create_table/change_table block with t.column" do
    it "complains if a small integer column is named `_id`" do
      inspect_source(<<~RUBY)
        class TestMigration < ActiveRecord::Migration
          def change
            change_table :widgets do |t|
              t.column :wicket_id, :integer
            end
          end
        end
      RUBY
      expect(cop.offenses.size).to eq 1
      expect(cop.messages.first).to eq "Migration/IdColumn: Use `:bigint` for id columns"
      expect(cop.offenses.first.severity.name).to eq(:warning)
    end

    it "still complains if limit: 8 is given" do
      inspect_source(<<~RUBY)
        class TestMigration < ActiveRecord::Migration
          def change
            change_table :widgets do |t|
              t.column :wicket_id, :integer, limit: 8
            end
          end
        end
      RUBY
      expect(cop.offenses.size).to eq 1
      expect(cop.messages.first).to eq "Migration/IdColumn: Use `:bigint` for id columns"
      expect(cop.offenses.first.severity.name).to eq(:warning)
    end

    it "doesn't complain if type :bigint is given" do
      inspect_source(<<~RUBY)
        class TestMigration < ActiveRecord::Migration
          def change
            change_table :widgets do |t|
              t.column :wicket_id, :bigint
            end
          end
        end
      RUBY
      expect(cop.offenses.size).to eq 0
    end

    it "doesn't complain about a non-id column" do
      inspect_source(<<~RUBY)
        class TestMigration < ActiveRecord::Migration
          def change
            change_table :widgets do |t|
              t.column :fluoride, :integer
            end
          end
        end
      RUBY
      expect(cop.offenses.size).to eq 0
    end
  end

  context "add_column" do
    it "complains if a small integer column is named `_id`" do
      inspect_source(<<~RUBY)
        class TestMigration < ActiveRecord::Migration
          def change
            add_column :widgets, :wicket_id, :integer
          end
        end
      RUBY
      expect(cop.offenses.size).to eq 1
      expect(cop.messages.first).to include "Use `:bigint` for id columns"
      expect(cop.offenses.first.severity.name).to eq(:warning)
    end

    it "still complains if limit: 8 is given" do
      inspect_source(<<~RUBY)
        class TestMigration < ActiveRecord::Migration
          def change
            add_column :widgets, :wicket_id, :integer, limit: 8
          end
        end
      RUBY
      expect(cop.offenses.size).to eq 1
      expect(cop.messages.first).to eq "Migration/IdColumn: Use `:bigint` for id columns"
      expect(cop.offenses.first.severity.name).to eq(:warning)
    end

    it "doesn't complain if type :bigint is given" do
      inspect_source(<<~RUBY)
        class TestMigration < ActiveRecord::Migration
          def change
            add_column :widgets, :wicket_id, :bigint
          end
        end
      RUBY
      expect(cop.offenses.size).to eq 0
    end

    it "doesn't complain about a non-id column" do
      inspect_source(<<~RUBY)
        class TestMigration < ActiveRecord::Migration
          def change
            add_column :widgets, :fluoride, :integer
          end
        end
      RUBY
      expect(cop.offenses.size).to eq 0
    end

    it "recognizes the :int spelling" do
      inspect_source(<<~RUBY)
        class TestMigration < ActiveRecord::Migration
          def change
            add_column :widgets, :wicket_id, :int
          end
        end
      RUBY
      expect(cop.offenses.size).to eq 1
    end
  end
end
