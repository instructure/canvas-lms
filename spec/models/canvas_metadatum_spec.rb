# frozen_string_literal: true

#
# Copyright (C) 2020 - present Instructure, Inc.
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
#

require 'spec_helper'

describe CanvasMetadatum do

  describe "getting" do

    it 'should get the default value as a hash' do
      expect(CanvasMetadatum.get('some_key', {state: 23})[:state]).to eq 23
    end

    it 'will not accept other forms of argument' do
      expect{ CanvasMetadatum.get('some_key', 'some value') }.to raise_error(CanvasMetadatum::MetadataArgumentError)
    end

    it 'should return set values' do
      CanvasMetadatum.set('some_key', {int_val: 23, string_val: "asdf", array_val: [2,4,8,16], hash_val: {nested: "string_value"}})
      payload = CanvasMetadatum.get('some_key')
      expect(payload[:int_val]).to eq(23)
      expect(payload[:string_val]).to eq("asdf")
      expect(payload[:array_val]).to eq([2,4,8,16])
      expect(payload[:hash_val][:nested]).to eq("string_value")
    end
  end

end
