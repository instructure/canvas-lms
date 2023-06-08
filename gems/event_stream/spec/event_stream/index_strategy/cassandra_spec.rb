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

require "spec_helper"

describe EventStream::IndexStrategy::Cassandra do
  before do
    @database = double("database")

    def @database.batch
      yield
    end

    def @database.update_record(*); end

    def @database.update(*); end

    def @database.keyspace
      "test_db"
    end

    @stream = double("stream",
                     backend_strategy: :cassandra,
                     database: @database,
                     record_type: EventStream::Record,
                     ttl_seconds: 1.year,
                     read_consistency_level: nil)
  end

  it "inherits its database from the stream" do
    # can't access spec ivars inside instance_exec
    table = @table
    entry_proc = @entry_proc
    base_index = EventStream::Index.new(@stream) do
      self.table table
      self.entry_proc entry_proc
    end
    index = base_index.strategy_for(:cassandra)

    expect(index.database).to eq @database
  end

  context "usage" do
    before do
      @table = double("table", to_s: "expected_table")
      table = @table
      base_index = EventStream::Index.new(@stream) do
        self.table table
        self.entry_proc ->(record) { record.entry }
      end
      @index = base_index.strategy_for(:cassandra)
    end

    describe "bucket_for_time" do
      it "uses the configured bucket_size" do
        @index.index.bucket_size 1000
        expect(@index.bucket_for_time(999)).to eq 0
        expect(@index.bucket_for_time(1001)).to eq 1000
      end
    end

    describe "insert" do
      before do
        @id = double("id", to_s: "1234567890")
        @key = "key_value"
        @timestamp = double("timestamp", to_i: 12_345)
        @record = double("record", id: @id, created_at: @timestamp)
      end

      it "uses the stream's database" do
        expect(@database).to receive(:update).once
        @index.insert(@record, @key)
      end

      it "uses the configured table" do
        expect(@database).to receive(:update).once.with(/ INTO #{@table} /, anything, anything, anything, anything)
        @index.insert(@record, @key)
      end

      it "combines the key and timestamp bucket into the configured key column" do
        bucket = double(to_i: "expected_bucket")
        key_column = double(to_s: "expected_key_column")
        @index.index.key_column key_column
        expect(@index).to receive(:bucket_for_time).once.with(@timestamp).and_return(bucket)
        expect(@database).to receive(:update).once.with(/\(#{key_column}, /, "#{@key}/#{bucket}", anything, anything, anything)
        @index.insert(@record, @key)
      end

      it "take a prefix off the id and the bucket for the ordered_id" do
        prefix = @id.to_s[0, 8]
        expect(@database).to receive(:update).once.with(/, ordered_id,/, anything, "#{@timestamp.to_i}/#{prefix}", anything, anything)
        @index.insert(@record, @key)
      end

      it "passes through the id into the configured id column" do
        id_column = double(to_s: "expected_id_column")
        @index.index.id_column id_column
        expect(@database).to receive(:update).once.with(/, #{id_column}\)/, anything, anything, @id, anything)
        @index.insert(@record, @key)
      end

      it "include the ttl" do
        expect(@database).to receive(:update).once.with(/ USING TTL /, anything, anything, anything, @stream.ttl_seconds(@timestamp))
        @index.insert(@record, @key)
      end
    end

    describe "create_key" do
      before do
        @bucket = @index.bucket_for_time(@newest)
      end

      it "handle an array for key" do
        expect(@index.create_key(@bucket, ["42", "21"])).to eq "42/21/#{@bucket}"
      end

      it "handle a single object for key" do
        expect(@index.create_key(@bucket, "42")).to eq "42/#{@bucket}"
      end
    end

    describe "for_key" do
      before do
        shard_class = Class.new { define_method(:activate) { |&b| b.call } }

        EventStream.current_shard_lookup = lambda do
          shard_class.new
        end

        # force just one bucket
        @index.index.bucket_size 1.minute.from_now
        @index.index.scrollback_limit 10.minutes
        @pager = @index.for_key("key")

        @ids = (1..4).to_a
        @typed_results = @ids.map { |id| @stream.record_type.new("id" => id, "created_at" => id.minutes.ago) }
        @raw_results = @typed_results.map { |record| { "id" => record.id, "ordered_id" => "#{record.created_at.to_i}/#{record.id}" } }
      end

      def setup_fetch(start, requested)
        returned = [@raw_results.size - start, requested + 1].min

        stub_with_multiple_yields = receive(:fetch).tap do |exp|
          @raw_results[start, returned].each do |row|
            exp.and_yield(row)
          end
        end

        allow(@raw_results).to stub_with_multiple_yields

        expect(@stream).to receive(:fetch).once.with(@ids[start, requested], { strategy: :batch }).and_return(@typed_results[start, requested])
      end

      def setup_execute(start, requested)
        setup_fetch(start, requested)
        expect(@database).to receive(:execute).once.and_return(@raw_results)
      end

      it "return a bookmarked collection" do
        expect(@pager).to be_a BookmarkedCollection::Proxy
      end

      it "is able to get bookmark from a typed item" do
        setup_execute(0, 2)
        page = @pager.paginate(per_page: 2)
        expect(page.bookmark_for(page.last)).to eq page.next_bookmark
      end

      it "uses the configured read_consistency_level" do
        setup_fetch(0, 2)
        expect(@database).to receive(:execute).with(/%CONSISTENCY% WHERE/, anything, anything, consistency: nil).and_return(@raw_results)
        @pager.paginate(per_page: 2)

        setup_fetch(0, 2)
        allow(@stream).to receive(:read_consistency_level).and_return("ALL")
        expect(@database).to receive(:execute).with(/%CONSISTENCY% WHERE/, anything, anything, consistency: "ALL").and_return(@raw_results)
        @pager.paginate(per_page: 2)
      end

      context "one page of results" do
        before do
          setup_execute(0, 4)
          @page = @pager.paginate(per_page: 4)
        end

        it "gets all results" do
          expect(@page).to eq @typed_results
        end

        it "does not have a next page" do
          expect(@page.next_page).to be_nil
        end
      end

      context "first of multiple pages of results" do
        before do
          setup_execute(0, 2)
          @page = @pager.paginate(per_page: 2)
        end

        it "returns just the results for the page" do
          expect(@page).to eq @typed_results[0, 2]
        end

        it "has another page" do
          expect(@page.next_page).to_not be_nil
        end
      end

      context "last of multiple pages of results" do
        before do
          setup_execute(0, 2)
          page = @pager.paginate(per_page: 2)

          setup_execute(2, 2)
          @page = @pager.paginate(per_page: 2, page: page.next_page)
        end

        it "returns just the results for the page" do
          expect(@page).to eq @typed_results[2, 2]
        end

        it "does not have another page" do
          expect(@page.next_page).to be_nil
        end
      end

      context "newest parameter" do
        before do
          @newest = @typed_results[2].created_at
          @pager = @index.for_key("key", newest: @newest)
          allow(@stream).to receive(:fetch).and_return([])
          @query = double(fetch: nil)
        end

        it "skip buckets newer than newest" do
          # force newest and Time.now into different buckets
          @index.index.bucket_size 1.minute
          @index.index.scrollback_limit Time.zone.now - @newest
          bucket = @index.bucket_for_time(@newest)
          expect(@database).to receive(:execute).once
                                                .with(/WHERE #{@index.index.key_column} = \?/, "key/#{bucket}", anything, anything, anything)
                                                .and_return(@query)
          @pager.paginate(per_page: 1)
        end

        it "skips results newer than newest in starting bucket" do
          expect(@database).to receive(:execute).once
                                                .with(/AND ordered_id < \?/, anything, anything, "#{@newest.to_i + 1}/", anything)
                                                .and_return(@query)
          @pager.paginate(per_page: 1)
        end

        it "ignores newest when given a bookmark" do
          page = BookmarkedCollection::Collection.new(EventStream::IndexStrategy::Cassandra::Bookmarker.new(@index))
          page.next_bookmark = page.bookmark_for(@typed_results[0])
          page, bookmark = page.next_page, page.next_bookmark

          expect(@database).to receive(:execute).once
                                                .with(/AND ordered_id < \?/, anything, anything, bookmark[1], anything)
                                                .and_return(@query)
          @pager.paginate(per_page: 1, page:)
        end
      end

      context "oldest parameter" do
        before do
          @oldest = @typed_results[2].created_at
          @pager = @index.for_key("key", oldest: @oldest)
          @query = double(fetch: nil)
          allow(@stream).to receive(:fetch).and_return([])
        end

        it "skips buckets older than oldest" do
          # force Time.now and oldest into one bucket, but scrollback_limit in
          # an earlier bucket
          @index.index.bucket_size @oldest.to_i - 1
          @index.index.scrollback_limit 1.day
          bucket = @index.bucket_for_time(@oldest)
          expect(@database).to receive(:execute).once
                                                .with(/WHERE #{@index.index.key_column} = \?/, "key/#{bucket}", anything, anything)
                                                .and_return(@query)
          @pager.paginate(per_page: 1)
        end

        it "skips results older than oldest in any bucket" do
          expect(@database).to receive(:execute).once
                                                .with(/AND ordered_id >= \?/, anything, "#{@oldest.to_i}/", anything)
                                                .and_return(@query)
          @pager.paginate(per_page: 1)
        end

        it "ignores oldest when it goes past scrollback_limit" do
          # force Time.now and scrollback_limit into one bucket, but oldest in
          # an earlier bucket
          @index.index.scrollback_limit 1.minute
          scrollback_limit = @index.index.scrollback_limit.seconds.ago
          @index.index.bucket_size scrollback_limit.to_i - 1
          bucket = @index.bucket_for_time(scrollback_limit)

          expect(@database).to receive(:execute).once
                                                .with(/WHERE #{@index.index.key_column} = \?/, "key/#{bucket}", anything, anything)
                                                .and_return(@query)
          @pager.paginate(per_page: 1)
        end

        it "handles exclusionary newest/oldest parameters" do
          @pager = @index.for_key("key", oldest: @oldest, newest: @oldest - 1.day)
          expect(@database).not_to receive(:execute)
          @pager.paginate(per_page: 1)
        end
      end
    end

    describe "ids_for_key" do
      before do
        shard_class = Class.new { define_method(:activate) { |&b| b.call } }

        EventStream.current_shard_lookup = lambda do
          shard_class.new
        end

        # force just one bucket
        @index.index.bucket_size 1.minute.from_now
        @index.index.scrollback_limit 10.minutes
        @pager = @index.ids_for_key("key")

        @ids = (1..4).to_a
        @typed_results = @ids.map { |id| @stream.record_type.new("id" => id, "created_at" => id.minutes.ago) }
        @raw_results = @typed_results.map { |record| { "id" => record.id, "ordered_id" => "#{record.created_at.to_i}/#{record.id}", "bucket" => 0 } }
      end

      def setup_fetch(start, requested)
        returned = [@raw_results.size - start, requested + 1].min

        stub_with_multiple_yields = receive(:fetch).tap do |exp|
          @raw_results[start, returned].each do |row|
            exp.and_yield(row)
          end
        end

        allow(@raw_results).to stub_with_multiple_yields
        expect(@database).to receive(:execute).once.and_return(@raw_results)
      end

      it "is able to get bookmark from a typed item" do
        setup_fetch(0, 2)
        page = @pager.paginate(per_page: 2)
        expect(page.bookmark_for(page.last)).to eq page.next_bookmark
      end

      context "one page of results" do
        before do
          setup_fetch(0, 4)
          @page = @pager.paginate(per_page: 4)
        end

        it "gets all results" do
          expect(@page).to eq @raw_results
        end

        it "does not have a next page" do
          expect(@page.next_page).to be_nil
        end
      end

      context "first of multiple pages of results" do
        before do
          setup_fetch(0, 2)
          @page = @pager.paginate(per_page: 2)
        end

        it "returns just the results for the page" do
          expect(@page).to eq @raw_results[0, 2]
        end

        it "has another page" do
          expect(@page.next_page).to_not be_nil
        end
      end

      context "last of multiple pages of results" do
        before do
          setup_fetch(0, 2)
          page = @pager.paginate(per_page: 2)

          setup_fetch(2, 2)
          @page = @pager.paginate(per_page: 2, page: page.next_page)
        end

        it "returns just the results for the page" do
          expect(@page).to eq @raw_results[2, 2]
        end

        it "does not have another page" do
          expect(@page.next_page).to be_nil
        end
      end
    end
  end

  describe "find_with" do
    before do
      @table = double("table")
      table = @table
      @stream = EventStream::Stream.new do
        backend_strategy :cassandra
        database database
        self.table table
      end
      base_index = @stream.add_index :thing do
        self.table table
        self.entry_proc ->(record) { record.entry }
      end
      @index = base_index.strategy_for(:cassandra)

      @key = double("key")
      @entry = double("entry", key: @key)
    end

    it "translates argument through key_proc if present" do
      @index.index.key_proc ->(entry) { entry.key }
      expect(@index).to receive(:for_key).once.with(@key, { strategy: :cassandra })
      @stream.for_thing(@entry)
    end

    it "permits and forwards options" do
      options = { oldest: 1.day.ago }
      expect(@index).to receive(:for_key).once.with([@entry], options)
      @stream.for_thing(@entry, options)
    end
  end
end
