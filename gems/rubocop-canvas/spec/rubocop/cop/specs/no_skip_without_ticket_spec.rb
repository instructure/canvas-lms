#
# Copyright (C) 2017 - present Instructure, Inc.
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

describe RuboCop::Cop::Specs::NoSkipWithoutTicket do
  subject(:cop) { described_class.new }

  it 'disallows skipping without referencing a ticket' do
    inspect_source(%{
      describe "date stuff" do
        it 'should do date stuff' do
          skip("fragile")
          next_year = 1.year.from_now
        end
      end
    })
    expect(cop.offenses.size).to eq(1)
    expect(cop.messages.first).to match(/Reference a ticket if skipping/)
    expect(cop.offenses.first.severity.name).to eq(:warning)
  end

  it 'allows skipping if referencing a ticket' do
    inspect_source(%{
      describe "date stuff" do
        it 'should do date stuff' do
          skip("CNVS-1234")
          next_year = 1.year.from_now
        end
      end
    })
    expect(cop.offenses.size).to eq(0)
  end

  it 'allows conditional skipping without a ticket' do
    inspect_source(%{
      describe "date stuff" do
        it 'should do date stuff' do
          skip("redis required") unless Canvas.redis_eanbled?
          next_year = 1.year.from_now
        end
      end
    })
    expect(cop.offenses.size).to eq(0)
  end
end
