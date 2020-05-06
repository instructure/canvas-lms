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

describe EventStream::IndexStrategy::ActiveRecord do
  describe "#for_ar_scope" do

    it "loads records from DB" do
      query_options = {}
      fake_record_type = Class.new do
      end
      stream = double('stream',
                     :record_type => EventStream::Record,
                     :active_record_type => fake_record_type)
      base_index = EventStream::Index.new(stream) do
        self.table "table"
        self.entry_proc lambda{|a1, a2| nil}
        self.ar_conditions_proc lambda {|a1, a2| { one: a1.id, two: a2.id}}
      end
      index = base_index.strategy_for(:active_record)
      arg1 = double('arg1', :id => "abc")
      arg2 = double('arg2', :id => "def")
      expect(fake_record_type).to receive(:where).with({ one: 'abc', two: 'def'})
      outcome = index.for_ar_scope([arg1, arg2], {})
    end
  end
end