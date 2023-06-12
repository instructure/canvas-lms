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

describe RuboCop::Cop::Migration::Execute do
  subject(:cop) { described_class.new }

  it "flags calls to execute" do
    inspect_source(<<~RUBY)
      class TestMigration < ActiveRecord::Migration
        def up
          execute("DROP TABLE users")
        end
      end
    RUBY
    expect(cop.offenses.size).to eq 1
    expect(cop.messages.first).to eq "Migration/Execute: Raw SQL in migrations must be approved by a migration reviewer"
    expect(cop.offenses.first.severity.name).to eq(:convention)
  end

  it "flags calls to execute with interpolation" do
    inspect_source(<<~RUBY)
      class TestMigration < ActiveRecord::Migration
        def up
          execute("DROP TABLE \#{table}")
        end
      end
    RUBY
    expect(cop.offenses.size).to eq 1
    expect(cop.messages.first).to eq "Migration/Execute: Raw SQL in migrations must be approved by a migration reviewer"
    expect(cop.offenses.first.severity.name).to eq(:convention)
  end

  it "flags calls to connection.execute" do
    inspect_source(<<~RUBY)
      class TestMigration < ActiveRecord::Migration
        def up
          ActiveRecord::Base.connection.execute("DROP TABLE users")
        end
      end
    RUBY
    expect(cop.offenses.size).to eq 1
    expect(cop.messages.first).to eq "Migration/Execute: Raw SQL in migrations must be approved by a migration reviewer"
    expect(cop.offenses.first.severity.name).to eq(:convention)
  end

  it "doesn't flag when execute isn't called" do
    inspect_source(<<~RUBY)
      class TestMigration < ActiveRecord::Migration
        def up
          remove_table :users
        end
      end
    RUBY
    expect(cop.offenses.size).to eq 0
  end
end
