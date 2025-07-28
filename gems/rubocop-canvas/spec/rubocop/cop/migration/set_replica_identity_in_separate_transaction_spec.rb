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

describe RuboCop::Cop::Migration::SetReplicaIdentityInSeparateTransaction do
  subject(:cop) { described_class.new }

  it "complains if creating a table and setting its replica identity in the same transaction" do
    offenses = inspect_source(<<~RUBY)
      class MyMigration < ActiveRecord::Migration
        tag :predeploy

        def change
          create_table(:xes) { |t| t.integer :y }
          set_replica_identity :xes,:y
        end
      end
    RUBY
    expect(offenses.size).to eq(1)
    expect(offenses.first.message).to include "replica identity"
    expect(offenses.first.severity.name).to eq(:error)
  end

  it "complains if creating a table and setting its replica identity in the same transaction with set_replica_identity" do
    offenses = inspect_source(<<~RUBY)
      class MyMigration < ActiveRecord::Migration
        tag :predeploy

        def change
          create_table(:xes) { |t| t.integer :y }
          set_replica_identity :xes
        end
      end
    RUBY
    expect(offenses.size).to eq(1)
    expect(offenses.first.message).to include "replica identity"
    expect(offenses.first.severity.name).to eq(:error)
  end

  it "is happy if the replica identity is for a different table" do
    offenses = inspect_source(<<~RUBY)
      class MyMigration < ActiveRecord::Migration
        tag :predeploy

        def change
          create_table(:xes) { |t| t.integer :y }
          set_replica_identity :ys,:z
        end
      end
    RUBY
    expect(offenses.size).to eq(0)
  end

  it "is happy if only creating a table" do
    offenses = inspect_source(<<~RUBY)
      class MyMigration < ActiveRecord::Migration
        tag :predeploy

        def change
          create_table(:xes) { |t| t.integer :y }
        end
      end
    RUBY
    expect(offenses.size).to eq(0)
  end

  it "is happy if only setting the replica identity" do
    offenses = inspect_source(<<~RUBY)
      class MyMigration < ActiveRecord::Migration
        tag :predeploy

        def change
          set_replica_identity :xes,:y
        end
      end
    RUBY
    expect(offenses.size).to eq(0)
  end

  it "does not complain in `down`" do
    offenses = inspect_source(<<~RUBY)
      class MyMigration < ActiveRecord::Migration
        tag :predeploy

        def down
          create_table(:xes) { |t| t.integer :y }
          set_replica_identity :xes,:y
        end
      end
    RUBY
    expect(offenses.size).to eq(0)
  end
end
