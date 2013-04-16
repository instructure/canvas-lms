#
# Copyright (C) 2012 Instructure, Inc.
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

require File.expand_path(File.dirname(__FILE__) + '/../../cassandra_spec_helper.rb')

describe "Canvas::Redis::Cassandra" do
  let(:db) do
    @cql_db = mock()
    CassandraCQL::Database.stubs(:new).returns(@cql_db)
    Canvas::Cassandra::Database.new([], {}, {})
  end

  describe "#batch" do
    it "should do nothing for empty batches" do
      db.expects(:execute).never
      db.in_batch?.should == false
      db.batch do
      db.in_batch?.should == true
      end
      db.in_batch?.should == false
    end

    it "should do update statements in a batch" do
      db.expects(:execute).with("1")
      db.batch { db.update("1") }

      db.expects(:execute).with("BEGIN BATCH UPDATE ? ? UPDATE ? ? APPLY BATCH", 1, 2, 3, 4)
      db.batch { db.update("UPDATE ? ?", 1, 2); db.update("UPDATE ? ?", 3, 4) }
    end

    it "should not batch up execute statements" do
      db.expects(:execute).with("SELECT").returns("RETURN")
      db.expects(:execute).with("BEGIN BATCH 1 2 APPLY BATCH")
      db.batch do
        db.update("1")
        db.execute("SELECT").should == "RETURN"
        db.update("2")
      end
    end

    it "should allow nested batch calls" do
      db.expects(:execute).with("BEGIN BATCH 1 2 APPLY BATCH")
      db.batch do
        db.update("1")
        db.batch do
          db.in_batch?.should == true
          db.update("2")
        end
      end
      db.in_batch?.should == false
    end

    it "should clean up from exceptions" do
      db.expects(:execute).never
      begin
        db.batch do
          db.update("1")
          raise "oh noes"
        end
      rescue
        db.in_batch?.should == false
      end
      db.expects(:execute).with("2")
      db.batch do
        db.update("2")
      end
    end
  end

  describe "#build_where_conditions" do
    it "should build a where clause given a hash" do
      db.build_where_conditions(name: "test1").should == ["name = ?", ["test1"]]
      db.build_where_conditions(state: "ut", name: "test1").should == ["name = ? AND state = ?", ["test1", "ut"]]
    end
  end

  describe "#update_record" do
    it "should do nothing if there are no updates or deletes" do
      db.expects(:execute).never
      db.update_record("test_table", { :id => 5 }, {})
    end

    it "should do lone updates" do
      db.expects(:execute).with("UPDATE test_table SET name = ? WHERE id = ?", "test", 5)
      db.update_record("test_table", { :id => 5 }, { :name => "test" })
      db.expects(:execute).with("UPDATE test_table SET name = ? WHERE id = ?", "test", 5)
      db.update_record("test_table", { :id => 5 }, { :name => [nil, "test"] })
    end

    it "should do multi-updates" do
      db.expects(:execute).with("UPDATE test_table SET name = ?, nick = ? WHERE id = ?", "test", "new", 5)
      db.update_record("test_table", { :id => 5 }, { :name => "test", :nick => ["old", "new"] })
    end

    it "should do lone deletes" do
      db.expects(:execute).with("DELETE name FROM test_table WHERE id = ?", 5)
      db.update_record("test_table", { :id => 5 }, { :name => nil })
      db.expects(:execute).with("DELETE name FROM test_table WHERE id = ?", 5)
      db.update_record("test_table", { :id => 5 }, { :name => ["old", nil] })
    end

    it "should do multi-deletes" do
      db.expects(:execute).with("DELETE name, nick FROM test_table WHERE id = ?", 5)
      db.update_record("test_table", { :id => 5 }, { :name => nil, :nick => ["old", nil] })
    end

    it "should do combined updates and deletes" do
      db.expects(:execute).with("BEGIN BATCH UPDATE test_table SET name = ? WHERE id = ? DELETE nick FROM test_table WHERE id = ? APPLY BATCH", "test", 5, 5)
      db.update_record("test_table", { :id => 5 }, { :name => "test", :nick => nil })
    end

    it "should work when already in a batch" do
      db.expects(:execute).with("BEGIN BATCH UPDATE ? UPDATE test_table SET name = ? WHERE id = ? DELETE nick FROM test_table WHERE id = ? UPDATE ? APPLY BATCH", 1, "test", 5, 5, 2)
      db.batch do
        db.update("UPDATE ?", 1)
        db.update_record("test_table", { :id => 5 }, { :name => "test", :nick => nil })
        db.update("UPDATE ?", 2)
      end
    end

    it "should handle compound primary keys" do
      db.expects(:execute).with("UPDATE test_table SET name = ? WHERE id = ? AND sub_id = ?", "test", 5, "sub!")
      db.update_record("test_table", { :id => 5, :sub_id => "sub!" }, { :name => "test", :id => 5, :sub_id => [nil, "sub!"] })
    end

    it "should disallow changing a primary key component" do
      expect {
        db.update_record("test_table", { :id => 5, :sub_id => "sub!" }, { :name => "test", :id => 5, :sub_id => ["old", "sub!"]})
      }.to raise_error(ArgumentError)
    end
  end

  describe "execute and update" do
    it_should_behave_like "cassandra page views"

    let(:db) { PageView.cassandra }

    it "should return the result from execute" do
      db.execute("select count(*) from page_views").fetch['count'].should == 0
      db.select_value("select count(*) from page_views").should == 0
      db.execute("insert into page_views (request_id, user_id) values (?, ?)", "test", 0).should == nil
    end

    it "should return nothing from update" do
      db.update("select count(*) from page_views").should == nil
      db.update("insert into page_views (request_id, user_id) values (?, ?)", "test", 0).should == nil
    end
  end
end
