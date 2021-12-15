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

describe RuboCop::Cop::Migration::AddForeignKey do
  subject(:cop) { described_class.new }

  it "complains if `delay_validation` is missing" do
    inspect_source(<<~RUBY)
      class MyMigration < ActiveRecord::Migration
        tag :predeploy

        def change
          add_foreign_key :x, :y
        end
      end
    RUBY
    expect(cop.offenses.size).to eq(1)
    expect(cop.messages.first).to include "delay_validation: true"
    expect(cop.offenses.first.severity.name).to eq(:warning)
  end

  it "complains if `disable_ddl_transaction!` is missing" do
    inspect_source(<<~RUBY)
      class MyMigration < ActiveRecord::Migration
        tag :predeploy

        def up
          add_foreign_key :x, :y, delay_validation: true
        end
      end
    RUBY
    expect(cop.offenses.size).to eq(1)
    expect(cop.messages.first).to include "delay_validation: true"
    expect(cop.offenses.first.severity.name).to eq(:warning)
  end

  it "is happy if both `disable_ddl_transaction!` and `delay_validation` are present" do
    inspect_source(<<~RUBY)
      class MyMigration < ActiveRecord::Migration
        tag :predeploy
        disable_ddl_transaction!

        def up
          add_foreign_key :x, :y, delay_validation: true
        end
      end
    RUBY
    expect(cop.offenses.size).to eq(0)
  end

  it "does not complain if we're operating on a newly-created table" do
    inspect_source(<<~RUBY)
      class MyMigration < ActiveRecord::Migration
        tag :predeploy

        def up
          create_table :foo do |t|
            t.integer :baz
          end
          add_foreign_key :foo, :quux
        end
      end
    RUBY
    expect(cop.offenses.size).to eq(0)
  end

  it "does not complain in `down`" do
    inspect_source(<<~RUBY)
      class MyMigration < ActiveRecord::Migration
        tag :predeploy

        def down
          add_foreign_key :x, :y
        end
      end
    RUBY
    expect(cop.offenses.size).to eq(0)
  end
end
