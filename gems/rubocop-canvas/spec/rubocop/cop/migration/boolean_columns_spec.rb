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

describe RuboCop::Cop::Migration::BooleanColumns do
  subject(:cop) { described_class.new }

  context "create_table/change_table block with t.boolean" do
    it "complains if a boolean column is nullable" do
      inspect_source(<<~RUBY)
        class TestMigration < ActiveRecord::Migration
          def up
            create_table :widgets do |t|
              t.boolean :purple, default: true
            end
          end
        end
      RUBY
      expect(cop.offenses.size).to eq 1
      expect(cop.messages.first).to include "Boolean columns should be NOT NULL"
      expect(cop.offenses.first.severity.name).to eq(:convention)
    end

    it "complains if a boolean column has no default" do
      inspect_source(<<~RUBY)
        class TestMigration < ActiveRecord::Migration
          def up
            create_table :widgets do |t|
              t.boolean :purple, null: false, default: true
              t.boolean :yellow, null: false
            end
          end
        end
      RUBY
      expect(cop.offenses.size).to eq 1
      expect(cop.messages.first).to include "have a default value"
      expect(cop.offenses.first.severity.name).to eq(:convention)
    end

    it "doesn't complain if its requirements are met" do
      inspect_source(<<~RUBY)
        class TestMigration < ActiveRecord::Migration
          def up
            create_table :widgets do |t|
              t.boolean :purple, default: true, null: false
            end
          end
        end
      RUBY
      expect(cop.offenses.size).to eq 0
    end
  end

  context "create_table/change_table block with t.column" do
    it "complains if a boolean column is nullable" do
      inspect_source(<<~RUBY)
        class TestMigration < ActiveRecord::Migration
          def change
            change_table :widgets do |t|
              t.column :purple, :boolean, default: true
            end
          end
        end
      RUBY
      expect(cop.offenses.size).to eq 1
      expect(cop.messages.first).to include "Boolean columns should be NOT NULL"
      expect(cop.offenses.first.severity.name).to eq(:convention)
    end

    it "complains if a boolean column has no default" do
      inspect_source(<<~RUBY)
        class TestMigration < ActiveRecord::Migration
          def change
            change_table :widgets do |t|
              t.column :purple, :boolean, null: false, default: true
              t.column :yellow, :boolean, null: false
            end
          end
        end
      RUBY
      expect(cop.offenses.size).to eq 1
      expect(cop.messages.first).to include "have a default value"
      expect(cop.offenses.first.severity.name).to eq(:convention)
    end

    it "doesn't complain if its requirements are met" do
      inspect_source(<<~RUBY)
        class TestMigration < ActiveRecord::Migration
          def change
            change_table :widgets do |t|
              t.column :purple, :boolean, default: true, null: false
            end
          end
        end
      RUBY
      expect(cop.offenses.size).to eq 0
    end
  end

  context "add_column" do
    it "complains if a boolean column is nullable" do
      inspect_source(<<~RUBY)
        class TestMigration < ActiveRecord::Migration
          def change
            add_column :widgets, :purple, :boolean, default: true
          end
        end
      RUBY
      expect(cop.offenses.size).to eq 1
      expect(cop.messages.first).to include "Boolean columns should be NOT NULL"
      expect(cop.offenses.first.severity.name).to eq(:convention)
    end

    it "complains if a boolean column has no default" do
      inspect_source(<<~RUBY)
        class TestMigration < ActiveRecord::Migration
          def change
            add_column :widgets, :purple, :boolean, null: false
          end
        end
      RUBY
      expect(cop.offenses.size).to eq 1
      expect(cop.messages.first).to include "have a default value"
      expect(cop.offenses.first.severity.name).to eq(:convention)
    end

    it "recognizes the :bool spelling" do
      inspect_source(<<~RUBY)
        class TestMigration < ActiveRecord::Migration
          def change
            add_column :widgets, :purple, :bool
          end
        end
      RUBY
      expect(cop.offenses.size).to eq 1
    end

    it "doesn't complain if its requirements are met" do
      inspect_source(<<~RUBY)
        class TestMigration < ActiveRecord::Migration
          def change
            add_column :widgets, :purple, :boolean, null: false, default: true
            add_column :widgets, :yellow, :boolean, default: false, null: false
          end
        end
      RUBY
      expect(cop.offenses.size).to eq 0
    end
  end
end
