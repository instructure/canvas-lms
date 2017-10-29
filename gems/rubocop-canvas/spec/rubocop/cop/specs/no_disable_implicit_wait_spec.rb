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

describe RuboCop::Cop::Specs::NoDisableImplicitWait do
  subject(:cop) { described_class.new }

  it 'disallows disable_implicit_wait' do
    inspect_source(%{
      describe "sis imports ui" do
        it 'should properly show sis stickiness options' do
          expect(ff('.fc-view-container .icon-calendar-month')).to have_size(1)

          # Calendar currently has post loading javascript that places the calendar event
          # In the correct place, however we don't have a wait_ajax_animation that waits
          # Long enough for this spec to pass given that we drag too soon causing it to fail
          disable_implicit_wait do
            keep_trying_until(10) do
              # Verify Event now ends at assignment start time + 30 minutes
              drag_and_drop_element(f('.fc-end-resizer'), f('.icon-assignment'))
              expect(event1.reload.end_at).to eql(midnight + 12.hours + 30.minutes)
            end
          end
        end
      end
    })
    expect(cop.offenses.size).to eq(1)
    expect(cop.messages.first).to match(/disable_implicit_wait/)
    expect(cop.offenses.first.severity.name).to eq(:warning)
  end
end
