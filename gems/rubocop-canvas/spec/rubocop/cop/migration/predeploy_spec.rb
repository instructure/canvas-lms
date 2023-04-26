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

describe RuboCop::Cop::Migration::Predeploy do
  subject(:cop) { described_class.new }

  it "flags table, column, and index creation in a postdeploy migration" do
    inspect_source(<<~RUBY)
      class TestMigration < ActiveRecord::Migration
        tag :postdeploy

        def up
          create_table :widgets do |t| # 0
            t.text :colour # no warning here; create_table is enough
          end

          change_table :widgets, bulk: true do |t| # this can be used in pre- and post-deploy, so we need to look inside
            t.index :colour # 1
            t.boolean :visible, default: true, null: false # 2
          end

          add_index :widgets, :flavour # 3
          add_column :widgets, :flavour, :text # 4
          add_reference :widgets, :wickets # 5
        end
      end
    RUBY

    expect(cop.offenses.size).to eq 6
    expect(cop.messages[0]).to eq "Migration/Predeploy: Create tables in a predeploy migration"
    expect(cop.messages[1]).to eq "Migration/Predeploy: Add indexes in a predeploy migration"
    expect(cop.messages[2]).to eq "Migration/Predeploy: Add columns in a predeploy migration"
    expect(cop.messages[3]).to eq "Migration/Predeploy: Add indexes in a predeploy migration"
    expect(cop.messages[4]).to eq "Migration/Predeploy: Add columns in a predeploy migration"
    expect(cop.messages[5]).to eq "Migration/Predeploy: Add columns in a predeploy migration"
  end

  it "doesn't flag column removal in a change_table block in a postdeploy migration" do
    inspect_source(<<~RUBY)
      class TestMigration < ActiveRecord::Migration
        tag :postdeploy

        def up
          change_table :widgets do |t|
            t.remove :colour
          end
        end
      end
    RUBY
    expect(cop.offenses.size).to eq 0
  end

  it "ignores `down`" do
    inspect_source(<<~RUBY)
      class TestMigration < ActiveRecord::Migration
        tag :postdeploy

        def down
          create_table :widgets do |t|
            t.text :colour
          end
        end
      end
    RUBY
    expect(cop.offenses.size).to eq 0
  end

  it "doesn't flag table, column, or index creation in a predeploy migration" do
    inspect_source(<<~RUBY)
      class TestMigration < ActiveRecord::Migration
        tag :predeploy

        def up
          create_table :widgets do |t|
            t.text :colour
          end

          change_table :widgets, bulk: true do |t|
            t.index :colour
            t.boolean :visible, default: true, null: false
          end

          add_index :widgets, :flavour
          add_column :widgets, :flavour, :text
          add_reference :widgets, :wickets
        end
      end
    RUBY

    expect(cop.offenses.size).to eq 0
  end
end
