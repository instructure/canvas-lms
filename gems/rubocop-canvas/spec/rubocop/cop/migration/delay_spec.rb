# frozen_string_literal: true

#
# Copyright (C) 2015 - present Instructure, Inc.
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

describe RuboCop::Cop::Migration::Delay do
  subject(:cop) { described_class.new }

  it 'catches other forms of delay' do
    inspect_source(%{
      class TestMigration < ActiveRecord::Migration

        def up
          MyClass.delay(max_attempts: 5).run
        end
      end
    })
    expect(cop.offenses.size).to eq(1)
    expect(cop.messages.first).to match(/if_production/)
    expect(cop.offenses.first.severity.name).to eq(:warning)
  end

  it 'disallows delay in predeploys' do
    inspect_source(%{
      class TestMigration < ActiveRecord::Migration
        tag :predeploy

        def up
          MyClass.delay_if_production(:run, max_attempts: 1)
        end
      end
    })
    expect(cop.offenses.size).to eq(1)
    expect(cop.messages.first).to match(/predeploy/)
    expect(cop.offenses.first.severity.name).to eq(:warning)
  end
end
