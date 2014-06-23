#
# Copyright (C) 2014 Instructure, Inc.
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

describe LtiOutbound::LTIModel do
  class Dummy < LtiOutbound::LTIModel
    proc_accessor :attribute
  end

    describe '#proc_accessor' do
    it 'acts as a regular attr_accessor for assigned values' do
      model = Dummy.new
      model.attribute = 'test_value'
      expect(model.attribute).to eq 'test_value'
    end

    it 'handles multiple attributes at once' do
      Dummy.proc_accessor(:test1, :test2)
    end

    it 'evaluates a proc when assigned a proc' do
      model = Dummy.new
      model.attribute = -> { 'test_value' }
      expect(model.attribute).to eq 'test_value'
    end

    it 'caches the result of the executed proc' do
      model = Dummy.new
      obj = double(:message => 'message')
      model.attribute = -> { obj.message() }
      2.times { model.attribute }

      expect(obj).to have_received(:message).once
    end
  end
end