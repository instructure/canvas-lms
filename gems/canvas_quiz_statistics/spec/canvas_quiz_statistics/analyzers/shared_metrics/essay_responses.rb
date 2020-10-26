# frozen_string_literal: true

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

shared_examples 'essay [:responses]' do
  it 'should count students who have written anything' do
    expect(subject.run([{ text: 'foo' }])[:responses]).to eq(1)
  end

  it 'should not count students who have written a blank response' do
    expect(subject.run([{ }])[:responses]).to eq(0)
    expect(subject.run([{ text: nil }])[:responses]).to eq(0)
    expect(subject.run([{ text: '' }])[:responses]).to eq(0)
  end
end