# frozen_string_literal: true

#
# Copyright (C) 2014 - present Instructure, Inc.
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

shared_examples 'essay [:full_credit]' do
  let :question_data do
    { points_possible: 3 }
  end

  it 'should count all students who received full credit' do
    output = subject.run([
      { points: 3 }, { points: 2 }, { points: 3 }
    ])

    expect(output[:full_credit]).to eq(2)
  end

  it 'should count students who received more than full credit' do
    output = subject.run([
      { points: 3 }, { points: 2 }, { points: 5 }
    ])

    expect(output[:full_credit]).to eq(2)
  end

  it 'should be 0 otherwise' do
    output = subject.run([
      { points: 1 }
    ])

    expect(output[:full_credit]).to eq(0)
  end

  it 'should count those who exceed the maximum points possible' do
    output = subject.run([{ points: 5 }])
    expect(output[:full_credit]).to eq(1)
  end
end