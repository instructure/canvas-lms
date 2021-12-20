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

describe RuboCop::Cop::Migration::ChangeColumn do
  subject(:cop) { described_class.new }

  it "flags calls to change_column" do
    inspect_source(<<~RUBY)
      class TestMigration < ActiveRecord::Migration
        def up
          change_column :users, :karma, :float
        end
      end
    RUBY
    expect(cop.offenses.size).to eq 1
    expect(cop.messages.first).to include "Changing column names or types usually requires a multi-deploy process"
    expect(cop.offenses.first.severity.name).to eq(:warning)
  end

  it "flags calls to rename_column" do
    inspect_source(<<~RUBY)
      class TestMigration < ActiveRecord::Migration
        def up
          rename_column :users, :karma, :chameleon
        end
      end
    RUBY
    expect(cop.offenses.size).to eq 1
    expect(cop.messages.first).to include "Changing column names or types usually requires a multi-deploy process"
    expect(cop.offenses.first.severity.name).to eq(:warning)
  end

  it "doesn't flag when subject method isn't called" do
    inspect_source(<<~RUBY)
      class TestMigration < ActiveRecord::Migration
        def up
          add_column :users, :karma, :float, default: 0.0
        end
      end
    RUBY
    expect(cop.offenses.size).to eq 0
  end
end
