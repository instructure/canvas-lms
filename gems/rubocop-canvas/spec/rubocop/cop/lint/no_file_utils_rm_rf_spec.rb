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

describe RuboCop::Cop::Lint::NoFileUtilsRmRf do
  subject(:cop) { described_class.new }

  it 'disallows FileUtils.rm_rf' do
    inspect_source(%{
      def rm_sekrets
        FileUtils.rm_rf
      end
    })
    expect(cop.offenses.size).to eq(1)
    expect(cop.messages.first).to match(/avoid FileUtils.rm_rf/)
    expect(cop.offenses.first.severity.name).to eq(:warning)
  end
end
