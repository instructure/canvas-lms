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

describe EventStream::Backend do
  describe "backend selection from strategy" do
    let(:stream) do
      EventStream::Stream.new do
        table "test_table"
      end
    end

    it "has a cassandra strategy" do
      expect(EventStream::Backend.for_strategy(stream, :cassandra)).to(
        be_a(EventStream::Backend::Cassandra)
      )
    end

    it "has an AR strategy" do
      expect(EventStream::Backend.for_strategy(stream, :active_record)).to(
        be_a(EventStream::Backend::ActiveRecord)
      )
    end

    it "rejects other strategies" do
      expect { EventStream::Backend.for_strategy(stream, :redis) }.to raise_error(RuntimeError)
    end
  end
end