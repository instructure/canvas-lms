#
# Copyright (C) 2013 Instructure, Inc.
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

require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper.rb')

describe EventStream::Index do
  before do
    @database = stub('database')
    def @database.batch; yield; end
    def @database.update_record(*args); end
    def @database.update(*args); end

    @stream = stub('stream',
      :database => @database,
      :available? => true,
      :record_type => EventStream::Record,
      :ttl_seconds => 1.year)
  end

  context "setup block" do
    before do
      @table = stub(:to_s => stub('table'))
      @entry_proc = stub('entry_proc')
    end

    it "should set values as expected" do
      # can't access spec ivars inside instance_exec
      table = @table
      entry_proc = @entry_proc
      id_column = stub(:to_s => stub('id_column'))
      key_column = stub(:to_s => stub('key_column'))
      bucket_size = stub(:to_i => stub('bucket_size'))
      scrollback_setting = stub(:to_s => stub('scrollback_setting'))
      scrollback_default = stub(:to_i => stub('scrollback_default'))
      key_proc = stub('key_proc')

      index = EventStream::Index.new(@stream) do
        self.table table
        self.entry_proc entry_proc
        self.id_column id_column
        self.key_column key_column
        self.bucket_size bucket_size
        self.scrollback_setting scrollback_setting
        self.scrollback_default scrollback_default
        self.key_proc key_proc
      end

      index.table.should == table.to_s
      index.entry_proc.should == entry_proc
      index.id_column.should == id_column.to_s
      index.key_column.should == key_column.to_s
      index.bucket_size.should == bucket_size.to_i
      index.scrollback_setting.should == scrollback_setting.to_s
      index.scrollback_default.should == scrollback_default.to_i
      index.key_proc.should == key_proc
    end

    it "should inherit its database from the stream" do
      # can't access spec ivars inside instance_exec
      table = @table
      entry_proc = @entry_proc
      index = EventStream::Index.new(@stream) do
        self.table table
        self.entry_proc entry_proc
      end

      index.database.should == @database
    end

    it "should require table and entry_proc" do
      # can't access spec ivars inside instance_exec
      table = @table
      entry_proc = @entry_proc

      lambda{ EventStream::Index.new(@stream) { self.table table } }.should raise_exception ArgumentError
      lambda{ EventStream::Index.new(@stream) { self.entry_proc entry_proc } }.should raise_exception ArgumentError
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

      it "should default id_column to 'id'" do
        @index.id_column.should == 'id'
      end

      it "should default key_column to 'key'" do
        @index.key_column.should == 'key'
      end

      it "should default bucket_size to 1 week" do
        @index.bucket_size.should == 60 * 60 * 24 * 7
      end

      it "should default scrollback_setting to nil" do
        @index.scrollback_setting.should be_nil
      end

      it "should default scrollback_default to 52 weeks" do
        @index.scrollback_default.should == 60 * 60 * 24 * 7 * 52
      end

      it "should default key_proc to nil" do
        @index.key_proc.should be_nil
      end
    end
  end

  context "usage" do
    before do
      @table = stub('table', :to_s => "expected_table")
      table = @table
      @index = EventStream::Index.new(@stream) do
        self.table table
        self.entry_proc lambda{ |record| record.entry }
      end
    end

    describe "scrollback_limit" do
      it "should lookup the scrollback_setting if any" do
        result = stub(:to_i => stub('result'))
        scrollback_setting = stub(:to_s => stub('scrollback_setting'))
        @index.scrollback_setting scrollback_setting
        Setting.expects(:get).once.with(scrollback_setting.to_s, anything).returns(result)
        @index.scrollback_limit.should == result.to_i
      end

      it "should use the scrollback_default as default when looking up the scrollback_setting" do
        result = stub(:to_i => stub('result'))
        scrollback_default = stub(:to_i => stub(:to_s => stub('scrollback_default')))
        @index.scrollback_setting stub('scrollback_setting')
        @index.scrollback_default scrollback_default
        Setting.expects(:get).once.with(anything, scrollback_default.to_i.to_s).returns(result)
        @index.scrollback_limit.should == result.to_i
      end

      it "should just return the scrollback_default with no scrollback_setting" do
        scrollback_default = stub(:to_i => stub('scrollback_default'))
        @index.scrollback_default scrollback_default
        Setting.expects(:get).never
        @index.scrollback_limit.should == scrollback_default.to_i
      end
    end

    describe "bucket_for_time" do
      it "should use the configured bucket_size" do
        @index.bucket_size 1000
        @index.bucket_for_time(999).should == 0
        @index.bucket_for_time(1001).should == 1000
      end
    end

    describe "insert" do
      before do
        @id = stub('id', :to_s => '1234567890')
        @key = stub('key', :to_s => 'key_value')
        @timestamp = stub('timestamp', :to_i => 12345)
        @record = stub('record', :id => @id, :created_at => @timestamp)
      end

      it "should use the stream's database" do
        @database.expects(:update).once
        @index.insert(@record, @key)
      end

      it "should use the configured table" do
        @database.expects(:update).once.with(regexp_matches(/ INTO #{@table} /), anything, anything, anything, anything)
        @index.insert(@record, @key)
      end

      it "should combine the key and timestamp bucket into the configured key column" do
        bucket = stub(:to_i => "expected_bucket")
        key_column = stub(:to_s => "expected_key_column")
        @index.key_column key_column
        @index.expects(:bucket_for_time).once.with(@timestamp).returns(bucket)
        @database.expects(:update).once.with(regexp_matches(/\(#{key_column}, /), "#{@key}/#{bucket}", anything, anything, anything)
        @index.insert(@record, @key)
      end

      it "should take a prefix off the id and the bucket for the ordered_id" do
        prefix = @id.to_s[0,8]
        @database.expects(:update).once.with(regexp_matches(/, ordered_id,/), anything, "#{@timestamp.to_i}/#{prefix}", anything, anything)
        @index.insert(@record, @key)
      end

      it "should pass through the id into the configured id column" do
        id_column = stub(:to_s => "expected_id_column")
        @index.id_column id_column
        @database.expects(:update).once.with(regexp_matches(/, #{id_column}\)/), anything, anything, @id, anything)
        @index.insert(@record, @key)
      end

      it "should include the ttl" do
        @database.expects(:update).once.with(regexp_matches(/ USING TTL /), anything, anything, anything, @stream.ttl_seconds(@record))
        @index.insert(@record, @key)
      end
    end

    describe "for_key" do
      before do
        # force just one bucket
        @index.bucket_size Time.now + 1.minute
        @index.scrollback_default 10.minutes
        @pager = @index.for_key('key')

        @ids = (1..4).to_a
        @typed_results = @ids.map{ |id| @stream.record_type.new('id' => id, 'created_at' => id.minutes.ago) }
        @raw_results = @typed_results.map{ |record| { 'id' => record.id, 'ordered_id' => "#{record.created_at.to_i}/#{record.id}" } }
      end

      def setup_fetch(start, requested)
        returned = [@raw_results.size - start, requested + 1].min
        @raw_results.expects(:fetch).once.multiple_yields(*@raw_results[start, returned].map{ |result| [result] })
        @database.expects(:execute).once.returns(@raw_results)
        @stream.expects(:fetch).once.with(@ids[start, requested]).returns(@typed_results[start, requested])
      end

      it "should return a bookmarked collection" do
        @pager.should be_a BookmarkedCollection::Proxy
      end

      it "should be able to get bookmark from a typed item" do
        setup_fetch(0, 2)
        page = @pager.paginate(:per_page => 2)
        page.bookmark_for(page.last).should == page.next_bookmark
      end

      context "one page of results" do
        before do
          setup_fetch(0, 4)
          @page = @pager.paginate(:per_page => 4)
        end

        it "should get all results" do
          @page.should == @typed_results
        end

        it "should not have a next page" do
          @page.next_page.should be_nil
        end
      end

      context "first of multiple pages of results" do
        before do
          setup_fetch(0, 2)
          @page = @pager.paginate(:per_page => 2)
        end

        it "should return just the results for the page" do
          @page.should == @typed_results[0, 2]
        end

        it "should have another page" do
          @page.next_page.should_not be_nil
        end
      end

      context "last of multiple pages of results" do
        before do
          setup_fetch(0, 2)
          page = @pager.paginate(:per_page => 2)

          setup_fetch(2, 2)
          @page = @pager.paginate(:per_page => 2, :page => page.next_page)
        end

        it "should return just the results for the page" do
          @page.should == @typed_results[2, 2]
        end

        it "should not have another page" do
          @page.next_page.should be_nil
        end
      end

      context "newest parameter" do
        before do
          @newest = @typed_results[2].created_at
          @pager = @index.for_key('key', newest: @newest)
          @stream.stubs(:fetch).returns([])
          @query = stub(:fetch => nil)
        end

        it "should skip buckets newer than newest" do
          # force newest and Time.now into different buckets
          @index.bucket_size 1.minute
          @index.scrollback_default Time.now - @newest
          bucket = @index.bucket_for_time(@newest)
          @database.expects(:execute).once.
            with(regexp_matches(/WHERE #{@index.key_column} = \?/), "key/#{bucket}", anything, anything).
            returns(@query)
          @pager.paginate(:per_page => 1)
        end

        it "should skip results newer than newest in starting bucket" do
          @database.expects(:execute).once.
            with(regexp_matches(/AND ordered_id < \?/), anything, anything, "#{@newest.to_i + 1}/").
            returns(@query)
          @pager.paginate(:per_page => 1)
        end

        it "should ignore newest when given a bookmark" do
          page = BookmarkedCollection::Collection.new(EventStream::Index::Bookmarker.new(@index))
          page.next_bookmark = page.bookmark_for(@typed_results[0])
          page, bookmark = page.next_page, page.next_bookmark

          @database.expects(:execute).once.
            with(regexp_matches(/AND ordered_id < \?/), anything, anything, bookmark[1]).
            returns(@query)
          @pager.paginate(:per_page => 1, :page => page)
        end
      end

      context "oldest parameter" do
        before do
          @oldest = @typed_results[2].created_at
          @pager = @index.for_key('key', oldest: @oldest)
          @stream.stubs(:fetch).returns([])
          @query = stub(:fetch => nil)
        end

        it "should skip buckets older than oldest" do
          # force Time.now and oldest into one bucket, but scrollback_limit in
          # an earlier bucket
          @index.bucket_size @oldest.to_i - 1
          @index.scrollback_default 1.day
          bucket = @index.bucket_for_time(@oldest)
          @database.expects(:execute).once.
            with(regexp_matches(/WHERE #{@index.key_column} = \?/), "key/#{bucket}", anything).
            returns(@query)
          @pager.paginate(:per_page => 1)
        end

        it "should skip results older than oldest in any bucket" do
          @database.expects(:execute).once.
            with(regexp_matches(/AND ordered_id >= \?/), anything, "#{@oldest.to_i}/").
            returns(@query)
          @pager.paginate(:per_page => 1)
        end

        it "should ignore oldest when it goes past scrollback_limit" do
          # force Time.now and scrollback_limit into one bucket, but oldest in
          # an earlier bucket
          @index.scrollback_default 1.minute
          scrollback_limit = @index.scrollback_limit.ago
          @index.bucket_size scrollback_limit.to_i - 1
          bucket = @index.bucket_for_time(scrollback_limit)

          @database.expects(:execute).once.
            with(regexp_matches(/WHERE #{@index.key_column} = \?/), "key/#{bucket}", anything).
            returns(@query)
          @pager.paginate(:per_page => 1)
        end

        it "should handle exclusionary newest/oldest parameters" do
          @pager = @index.for_key('key', oldest: @oldest, newest: @oldest - 1.day)
          @database.expects(:execute).never
          @pager.paginate(:per_page => 1)
        end
      end
    end
  end
end
