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

describe RuboCop::Cop::Migration::WorkflowStateEnum do
  subject(:cop) { described_class.new }

  context "create_table block" do
    it "flags workflow_state without a check constraint" do
      offenses = inspect_source(<<~RUBY)
        class TestMigration < ActiveRecord::Migration[7.1]
          def change
            create_table :widgets do |t|
              t.string :workflow_state, default: "active", null: false, limit: 255
            end
          end
        end
      RUBY
      expect(offenses.size).to eq 1
      expect(offenses.first.message).to include "check constraint"
    end

    it "does not flag workflow_state with a check constraint" do
      offenses = inspect_source(<<~RUBY)
        class TestMigration < ActiveRecord::Migration[7.1]
          def change
            create_table :widgets do |t|
              t.string :workflow_state, default: "active", null: false, limit: 255
              t.check_constraint "workflow_state IN ('active', 'deleted')", name: "chk_workflow_state_enum"
            end
          end
        end
      RUBY
      expect(offenses.size).to eq 0
    end
  end

  context "change_table block" do
    it "flags workflow_state without a check constraint" do
      offenses = inspect_source(<<~RUBY)
        class TestMigration < ActiveRecord::Migration[7.1]
          def change
            change_table :widgets, bulk: true do |t|
              t.string :workflow_state, default: "active", null: false, limit: 255
            end
          end
        end
      RUBY
      expect(offenses.size).to eq 1
    end

    it "does not flag workflow_state with a check constraint" do
      offenses = inspect_source(<<~RUBY)
        class TestMigration < ActiveRecord::Migration[7.1]
          def change
            change_table :widgets, bulk: true do |t|
              t.string :workflow_state, default: "active", null: false, limit: 255
              t.check_constraint "workflow_state IN ('active', 'deleted')", name: "chk_workflow_state_enum"
            end
          end
        end
      RUBY
      expect(offenses.size).to eq 0
    end
  end

  context "standalone add_column" do
    it "flags workflow_state without add_check_constraint" do
      offenses = inspect_source(<<~RUBY)
        class TestMigration < ActiveRecord::Migration[7.1]
          def change
            add_column :widgets, :workflow_state, :string, default: "active", null: false, limit: 255
          end
        end
      RUBY
      expect(offenses.size).to eq 1
    end

    it "does not flag workflow_state with add_check_constraint" do
      offenses = inspect_source(<<~RUBY)
        class TestMigration < ActiveRecord::Migration[7.1]
          def change
            add_column :widgets, :workflow_state, :string, default: "active", null: false, limit: 255
            add_check_constraint :widgets, "workflow_state IN ('active', 'deleted')", name: "chk_workflow_state_enum"
          end
        end
      RUBY
      expect(offenses.size).to eq 0
    end
  end

  context "def down" do
    it "does not flag workflow_state columns" do
      offenses = inspect_source(<<~RUBY)
        class TestMigration < ActiveRecord::Migration[7.1]
          def down
            add_column :widgets, :workflow_state, :string, default: "active", null: false
          end
        end
      RUBY
      expect(offenses.size).to eq 0
    end
  end

  it "does not flag other string columns" do
    offenses = inspect_source(<<~RUBY)
      class TestMigration < ActiveRecord::Migration[7.1]
        def change
          create_table :widgets do |t|
            t.string :name, null: false, limit: 255
          end
        end
      end
    RUBY
    expect(offenses.size).to eq 0
  end
end
