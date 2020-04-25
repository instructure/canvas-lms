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

describe EventStream::Backend::ActiveRecord do
  let(:ar_type) do
    Class.new do
      class << self
        def reset!
          @recs = []
        end

        def written_recs
          @recs ||= []
        end

        def create_from_event_stream!(rec)
          @recs ||= []
          @recs << rec
        end

        def connection
          self
        end

        def active?
          true
        end
      end
    end
  end

  let(:stream) do
    ar_cls = ar_type
    s = EventStream::Stream.new do
      table "test_table"
      active_record_type ar_cls
    end
    s.raise_on_error = true
    s
  end

  let(:event_record) { OpenStruct.new(field: "value") }

  describe "executing operations" do
    after(:each) do
      ar_type.reset!
    end

    it "proxies calls through provided AR model" do
      ar_backend = EventStream::Backend::ActiveRecord.new(stream)
      ar_backend.execute(:insert, event_record)
      expect(ar_type.written_recs.first).to eq(event_record)
    end
  end
end
