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

describe RuboCop::Cop::Migration::DataFixup do
  subject(:cop) { described_class.new }

  it "flags calls to datafixes in predeploy migrations" do
    inspect_source(<<~RUBY)
      class TestMigration < ActiveRecord::Migration
        tag :predeploy
        def up
          DataFixup::FixWidgets.run
        end
      end
    RUBY
    expect(cop.offenses.size).to eq 1
    expect(cop.messages.first).to eq "Migration/DataFixup: Data fixups should be done in postdeploy migrations"
    expect(cop.offenses.first.severity.name).to eq(:convention)
  end

  it "does not flag calls to datafixes in postdeploy migrations" do
    inspect_source(<<~RUBY)
      class TestMigration < ActiveRecord::Migration
        tag :postdeploy
        def up
          DataFixup::FixWidgets.run
        end
      end
    RUBY
    expect(cop.offenses.size).to eq 0
  end
end
