# frozen_string_literal: true

#
# Copyright (C) 2021 - present Instructure, Inc.
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

describe EventStream::Logger do
  it "writes standard log messages" do
    l_klass = Class.new do
      attr_reader :msgs
      def initialize
        @msgs = []
      end

      def info(msg)
        @msgs << msg
      end
    end
    fake_logger = l_klass.new
    allow(EventStream::Logger).to receive(:logger).and_return(fake_logger)
    EventStream::Logger.info("TEST", "stream_id", "insert", {'foo' => 'bar'})
    expect(fake_logger.msgs.first).to eq("[TEST:INFO] stream_id:insert {\"foo\"=>\"bar\"}")
  end
end