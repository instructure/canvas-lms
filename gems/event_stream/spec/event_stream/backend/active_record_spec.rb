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
          @conditions = []
        end

        def written_recs
          @recs ||= []
        end

        def where(condition)
          @conditions ||= []
          @conditions << condition
          self
        end

        def create_from_event_stream!(rec)
          @recs ||= []
          @recs << rec
        end

        def connection
          self
        end

        def shard
          self
        end

        def name
          'shard_name'
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
      backend_strategy :active_record
      table "test_table"
      active_record_type ar_cls
      add_index :optional_index do
        table :items_by_optional_index
        entry_proc lambda{ |record| [record.field, record.id] if record.id > 0 }
        key_proc lambda{ |i1, i2| [i1, i2] }
        ar_scope_proc lambda { |v1, v2| ar_cls.where({key: :val}) }
      end
    end
    s.raise_on_error = true
    s
  end


  describe "executing operations" do
    let(:backend){ EventStream::Backend::ActiveRecord.new(stream) }
    after(:each) do
      ar_type.reset!
    end

    it "proxies calls through provided AR model" do
      event_record = OpenStruct.new(field: "value", id: 2)
      ar_backend = EventStream::Backend::ActiveRecord.new(stream)
      ar_backend.execute(:insert, event_record)
      expect(ar_type.written_recs.first).to eq(event_record)
    end

    it "only indexes items for which there is an entry" do
      event_record = OpenStruct.new(field: "value", id: -2)
      ar_backend = EventStream::Backend::ActiveRecord.new(stream)
      expect { ar_backend.execute(:insert, event_record) }.to_not raise_error
      expect(ar_type.written_recs.first).to eq(event_record)
    end

    it "uses shard as fingerprint" do
      expect(backend.database_fingerprint).to eq('shard_name')
    end

    it "uses shard as name" do
      expect(backend.database_name).to eq('shard_name')
    end
  end
end
