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
# You have received a copy of the GNU Affero General Public License along
# with this program. If not, see <http://www.gnu.org/licenses/>.
#

require 'spec_helper'

describe EventStream::Index do
  before do
    @database = double('database')

    def @database.batch;
      yield;
    end

    def @database.update_record(*args)
      ;
    end

    def @database.update(*args)
      ;
    end

    def @database.keyspace
      'test_db'
    end

    @stream = double('stream',
                     :database => @database,
                     :record_type => EventStream::Record,
                     :ttl_seconds => 1.year,
                     :read_consistency_clause => nil)
  end

  context "setup block" do
    before do
      @table = double(:to_s => double('table'))
      @entry_proc = -> { "entry" }
    end

    it "sets values as expected" do
      # can't access spec ivars inside instance_exec
      table = @table
      entry_proc = @entry_proc
      id_column = double(:to_s => double('id_column'))
      key_column = double(:to_s => double('key_column'))
      bucket_size = double(:to_i => double('bucket_size'))
      scrollback_limit = double(:to_i => double('scrollback_limit'))
      key_proc = -> { "key" }

      index = EventStream::Index.new(@stream) do
        self.table table
        self.entry_proc entry_proc
        self.id_column id_column
        self.key_column key_column
        self.bucket_size bucket_size
        self.scrollback_limit scrollback_limit
        self.key_proc key_proc
      end

      expect(index.table).to eq table.to_s
      expect(index.entry_proc).to eq entry_proc
      expect(index.id_column).to eq id_column.to_s
      expect(index.key_column).to eq key_column.to_s
      expect(index.bucket_size).to eq bucket_size.to_i
      expect(index.scrollback_limit).to eq scrollback_limit.to_i
      expect(index.key_proc).to eq key_proc
    end

    it "inherits its database from the stream" do
      # can't access spec ivars inside instance_exec
      table = @table
      entry_proc = @entry_proc
      index = EventStream::Index.new(@stream) do
        self.table table
        self.entry_proc entry_proc
      end

      expect(index.database).to eq @database
    end

    it "requires table and entry_proc" do
      # can't access spec ivars inside instance_exec
      table = @table
      entry_proc = @entry_proc

      expect {
        EventStream::Index.new(@stream) { self.table table }
      }.to raise_exception ArgumentError
      expect {
        EventStream::Index.new(@stream) { self.entry_proc entry_proc }
      }.to raise_exception ArgumentError
    end

    context "defaults" do
      before do
        # can't access spec ivars inside instance_exec
        table = @table
        entry_proc = @entry_proc
        @index = EventStream::Index.new(@stream) do
          self.table table
          self.entry_proc entry_proc
        end
      end

      it "defaults id_column to 'id'" do
        expect(@index.id_column).to eq 'id'
      end

      it "defaults key_column to 'key'" do
        expect(@index.key_column).to eq 'key'
      end

      it "defaults bucket_size to 1 week" do
        expect(@index.bucket_size).to eq 60 * 60 * 24 * 7
      end

      it "defaults scrollback_limit to 52 weeks" do
        expect(@index.scrollback_limit).to eq 52.weeks
      end

      it "defaults key_proc to nil" do
        expect(@index.key_proc).to be_nil
      end
    end
  end

  context "usage" do
    before do
      @table = double('table', :to_s => "expected_table")
      table = @table
      @index = EventStream::Index.new(@stream) do
        self.table table
        self.entry_proc lambda { |record| record.entry }
      end
    end

    describe "bucket_for_time" do
      it "uses the configured bucket_size" do
        @index.bucket_size 1000
        expect(@index.bucket_for_time(999)).to eq 0
        expect(@index.bucket_for_time(1001)).to eq 1000
      end
    end

    describe "insert" do
      before do
        @id = double('id', :to_s => '1234567890')
        @key = "key_value"
        @timestamp = double('timestamp', :to_i => 12345)
        @record = double('record', :id => @id, :created_at => @timestamp)
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
        bucket = double(:to_i => "expected_bucket")
        key_column = double(:to_s => "expected_key_column")
        @index.key_column key_column
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
        id_column = double(:to_s => "expected_id_column")
        @index.id_column id_column
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
        expect(@index.create_key(@bucket, ['42', '21'])).to eq "42/21/#{@bucket}"
      end

      it "handle a single object for key" do
        expect(@index.create_key(@bucket, '42')).to eq "42/#{@bucket}"
      end
    end

    describe "for_key" do
      before(:each) do
        shard_class = Class.new {
          define_method(:activate) { |&b| b.call }
        }

        EventStream.current_shard_lookup = lambda {
          shard_class.new
        }

        # force just one bucket
        @index.bucket_size Time.now + 1.minute
        @index.scrollback_limit 10.minutes
        @pager = @index.for_key('key')

        @ids = (1..4).to_a
        @typed_results = @ids.map { |id| @stream.record_type.new('id' => id, 'created_at' => id.minutes.ago) }
        @raw_results = @typed_results.map { |record| {'id' => record.id, 'ordered_id' => "#{record.created_at.to_i}/#{record.id}"} }
      end

      def setup_fetch(start, requested)
        returned = [@raw_results.size - start, requested + 1].min

        stub_with_multiple_yields = receive(:fetch).tap do |exp|
          @raw_results[start, returned].each do |row|
            exp.and_yield(*[row])
          end
        end

        allow(@raw_results).to stub_with_multiple_yields

        expect(@database).to receive(:execute).once.and_return(@raw_results)
        expect(@stream).to receive(:fetch).once.with(@ids[start, requested]).and_return(@typed_results[start, requested])
      end

      it "return a bookmarked collection" do
        expect(@pager).to be_a BookmarkedCollection::Proxy
      end

      it "is able to get bookmark from a typed item" do
        setup_fetch(0, 2)
        page = @pager.paginate(:per_page => 2)
        expect(page.bookmark_for(page.last)).to eq page.next_bookmark
      end

      context "one page of results" do
        before do
          setup_fetch(0, 4)
          @page = @pager.paginate(:per_page => 4)
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
          setup_fetch(0, 2)
          @page = @pager.paginate(:per_page => 2)
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
          setup_fetch(0, 2)
          page = @pager.paginate(:per_page => 2)

          setup_fetch(2, 2)
          @page = @pager.paginate(:per_page => 2, :page => page.next_page)
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
          @pager = @index.for_key('key', newest: @newest)
          allow(@stream).to receive(:fetch).and_return([])
          @query = double(:fetch => nil)
        end

        it "skip buckets newer than newest" do
          # force newest and Time.now into different buckets
          @index.bucket_size 1.minute
          @index.scrollback_limit Time.now - @newest
          bucket = @index.bucket_for_time(@newest)
          expect(@database).to receive(:execute).once.
                                   with(/WHERE #{@index.key_column} = \?/, "key/#{bucket}", anything, anything).
                                   and_return(@query)
          @pager.paginate(:per_page => 1)
        end

        it "skips results newer than newest in starting bucket" do
          expect(@database).to receive(:execute).once.
                                   with(/AND ordered_id < \?/, anything, anything, "#{@newest.to_i + 1}/").
                                   and_return(@query)
          @pager.paginate(:per_page => 1)
        end

        it "ignores newest when given a bookmark" do
          page = BookmarkedCollection::Collection.new(EventStream::Index::Bookmarker.new(@index))
          page.next_bookmark = page.bookmark_for(@typed_results[0])
          page, bookmark = page.next_page, page.next_bookmark

          expect(@database).to receive(:execute).once.
                                   with(/AND ordered_id < \?/, anything, anything, bookmark[1]).
                                   and_return(@query)
          @pager.paginate(:per_page => 1, :page => page)
        end
      end

      context "oldest parameter" do
        before do
          @oldest = @typed_results[2].created_at
          @pager = @index.for_key('key', oldest: @oldest)
          @query = double(:fetch => nil)
          allow(@stream).to receive(:fetch).and_return([])
        end

        it "skips buckets older than oldest" do
          # force Time.now and oldest into one bucket, but scrollback_limit in
          # an earlier bucket
          @index.bucket_size @oldest.to_i - 1
          @index.scrollback_limit 1.day
          bucket = @index.bucket_for_time(@oldest)
          expect(@database).to receive(:execute).once.
                                   with(/WHERE #{@index.key_column} = \?/, "key/#{bucket}", anything).
                                   and_return(@query)
          @pager.paginate(:per_page => 1)
        end

        it "skips results older than oldest in any bucket" do
          expect(@database).to receive(:execute).once.
                                   with(/AND ordered_id >= \?/, anything, "#{@oldest.to_i}/").
                                   and_return(@query)
          @pager.paginate(:per_page => 1)
        end

        it "ignores oldest when it goes past scrollback_limit" do
          # force Time.now and scrollback_limit into one bucket, but oldest in
          # an earlier bucket
          @index.scrollback_limit 1.minute
          scrollback_limit = @index.scrollback_limit.ago
          @index.bucket_size scrollback_limit.to_i - 1
          bucket = @index.bucket_for_time(scrollback_limit)

          expect(@database).to receive(:execute).once.
                                   with(/WHERE #{@index.key_column} = \?/, "key/#{bucket}", anything).
                                   and_return(@query)
          @pager.paginate(:per_page => 1)
        end

        it "handles exclusionary newest/oldest parameters" do
          @pager = @index.for_key('key', oldest: @oldest, newest: @oldest - 1.day)
          expect(@database).to receive(:execute).never
          @pager.paginate(:per_page => 1)
        end
      end
    end
  end
end
