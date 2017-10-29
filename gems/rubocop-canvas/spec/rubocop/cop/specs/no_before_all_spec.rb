#
# Copyright (C) 2016 - present Instructure, Inc.
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

describe RuboCop::Cop::Specs::NoBeforeAll do
  subject(:cop) { described_class.new }

  it 'disallows before(:all)' do
    inspect_source(%{
      before(:all) { puts "yarrr" }
    })
    expect(cop.offenses.size).to eq(1)
    expect(cop.messages.first).to match(/Use `before\(:once\)`/)
    expect(cop.offenses.first.severity.name).to eq(:warning)
  end

  it 'allows before(:each)' do
    inspect_source(%{
        before(:each) { puts "yarrr" }
      })
    expect(cop.offenses.size).to eq(0)
  end

  it 'allows before(:once)' do
    inspect_source(%{
        before(:once) { puts "yarrr" }
      })
    expect(cop.offenses.size).to eq(0)
  end
end
