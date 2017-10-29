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

describe RuboCop::Cop::Specs::NoWaitForNoSuchElement do
  subject(:cop) { described_class.new }

  it 'disallows wait_for_no_such_element' do
    inspect_source(%{
      describe "sis imports ui" do
        it 'should properly show sis stickiness options' do
          wait_for_no_such_element(method: :contain_css) do
            f("#studentAvatar", f('#courses'))
          end
        end
      end
    })
    expect(cop.offenses.size).to eq(1)
    expect(cop.messages.first).to match(/wait_for_no_such_element/)
    expect(cop.offenses.first.severity.name).to eq(:warning)
  end
end
