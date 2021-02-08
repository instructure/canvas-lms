# frozen_string_literal: true

#
# Copyright (C) 2013 - present Instructure, Inc.
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

shared_examples_for 'Id Answer Serializers' do
  it '[auto] should reject an unknown answer ID' do
    input = 12321
    input = format(input) if respond_to?(:format)

    rc = subject.serialize(input)
    expect(rc.error).not_to be_nil
    expect(rc.error).to match(/unknown answer/i)
  end

  it '[auto] should accept a string answer ID' do
    input = '12321'
    input = format(input) if respond_to?(:format)

    rc = subject.serialize(input)
    expect(rc.error).not_to be_nil
    expect(rc.error).to match(/unknown answer/i)
  end

  it '[auto] should reject a bad answer ID' do
    [ nil, [], {} ].each do |bad_input|
      bad_input = format(bad_input) if respond_to?(:format)

      rc = subject.serialize(bad_input)
      expect(rc.error).not_to be_nil
      expect(rc.error).to match(/must be of type integer/i)
    end
  end
end
