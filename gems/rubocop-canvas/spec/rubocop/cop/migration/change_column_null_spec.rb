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

describe RuboCop::Cop::Migration::ChangeColumnNull do
  subject(:cop) { described_class.new }

  it "expects a non-transactional migration" do
    offenses = inspect_source(<<~RUBY)
      class TestMigration < ActiveRecord::Migration
        def up
          DataFixup::BackfillNulls.run(User, :karma, default_value: 0)
          change_column_null :users, :karma, false
        end
      end
    RUBY
    expect(offenses.size).to eq 1
    expect(offenses.first.message).to include "Use `disable_ddl_transaction!`"
    expect(offenses.first.severity.name).to eq(:warning)
  end

  it "expects BackfillNulls" do
    offenses = inspect_source(<<~RUBY)
      class TestMigration < ActiveRecord::Migration
        disable_ddl_transaction!
        def up
          change_column_null :users, :karma, false
        end
      end
    RUBY
    expect(offenses.size).to eq 1
    expect(offenses.first.message).to include "Use `DataFixup::BackfillNulls`"
    expect(offenses.first.severity.name).to eq(:warning)
  end

  it "emits no warnings when conditions are satisfied" do
    offenses = inspect_source(<<~RUBY)
      class TestMigration < ActiveRecord::Migration
        disable_ddl_transaction!
        def up
          DataFixup::BackfillNulls.run(User, :karma, default_value: 0)
          change_column_null :users, :karma, false
        end
      end
    RUBY
    expect(offenses.size).to eq 0
  end

  it "doesn't flag when removing a not-NULL constraint" do
    offenses = inspect_source(<<~RUBY)
      class TestMigration < ActiveRecord::Migration
        def up
          change_column_null :users, :karma, true
        end
      end
    RUBY
    expect(offenses.size).to eq 0
  end

  it "doesn't flag when adding a not-NULL constraint in `down`" do
    offenses = inspect_source(<<~RUBY)
      class TestMigration < ActiveRecord::Migration
        def down
          change_column_null :users, :karma, false
        end
      end
    RUBY
    expect(offenses.size).to eq 0
  end
end
