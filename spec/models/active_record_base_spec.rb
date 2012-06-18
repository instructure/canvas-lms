#
# Copyright (C) 2011 Instructure, Inc.
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

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper.rb')

describe ActiveRecord::Base do
  describe "#remove_dropped_columns" do
    before do
      @orig_dropped = ActiveRecord::Base::DROPPED_COLUMNS
    end

    after do
      ActiveRecord::Base.send(:remove_const, :DROPPED_COLUMNS)
      ActiveRecord::Base::DROPPED_COLUMNS = @orig_dropped
      User.reset_column_information
    end

    it "should mask columns marked as dropped from column info methods" do
      User.columns.any? { |c| c.name == 'name' }.should be_true
      User.column_names.should be_include('name')
      # if we ever actually drop the name column, this spec will fail on the line
      # above, so it's all good
      ActiveRecord::Base.send(:remove_const, :DROPPED_COLUMNS)
      ActiveRecord::Base::DROPPED_COLUMNS = { 'users' => %w(name) }
      User.reset_column_information
      User.columns.any? { |c| c.name == 'name' }.should be_false
      User.column_names.should_not be_include('name')
    end

    it "should only drop columns from the specific table specified" do
      ActiveRecord::Base.send(:remove_const, :DROPPED_COLUMNS)
      ActiveRecord::Base::DROPPED_COLUMNS = { 'users' => %w(name) }
      User.reset_column_information
      Group.reset_column_information
      User.columns.any? { |c| c.name == 'name' }.should be_false
      Group.columns.any? { |c| c.name == 'name' }.should be_true
    end
  end

  context "rank helpers" do
    it "should generate appropriate rank sql" do
      ActiveRecord::Base.rank_sql(['a', ['b', 'c'], ['d']], 'foo').
        should eql "CASE WHEN foo IN ('a') THEN 0 WHEN foo IN ('b', 'c') THEN 1 WHEN foo IN ('d') THEN 2 ELSE 3 END"
    end

    it "should generate appropriate rank hashes" do
      hash = ActiveRecord::Base.rank_hash(['a', ['b', 'c'], ['d']])
      hash.should == {'a' => 1, 'b' => 2, 'c' => 2, 'd' => 3}
      hash['e'].should eql 4
    end
  end

  it "should have a valid GROUP BY clause when group_by is used correctly" do
    conn = ActiveRecord::Base.connection
    lambda {
      User.find_by_sql "SELECT id, name FROM users GROUP BY #{conn.group_by('id', 'name')}"
      User.find_by_sql "SELECT id, name FROM (SELECT id, name FROM users) u GROUP BY #{conn.group_by('id', 'name')}"
    }.should_not raise_error
  end

  context "unique_constraint_retry" do
    before do
      @user = user_model
      @assignment = assignment_model
      @orig_user_count = User.count
    end

    it "should normally run once" do
      User.unique_constraint_retry do
        User.create!
      end
      User.count.should eql @orig_user_count + 1
    end

    it "should run twice if it gets a UniqueConstraintViolation" do
      Submission.create!(:user => @user, :assignment => @assignment)
      tries = 0
      lambda{
        User.unique_constraint_retry do
          tries += 1
          User.create!
          Submission.create!(:user => @user, :assignment => @assignment)
        end
      }.should raise_error # we don't catch the error the second time 
      Submission.count.should eql 1
      tries.should eql 2
      User.count.should eql @orig_user_count
    end

    it "should run additional times if specified" do
      Submission.create!(:user => @user, :assignment => @assignment)
      tries = 0
      lambda{
        User.unique_constraint_retry(2) do
          tries += 1
          Submission.create!(:user => @user, :assignment => @assignment)
        end
      }.should raise_error # we don't catch the error the last time 
      tries.should eql 3
      Submission.count.should eql 1
    end

    it "should not cause outer transactions to roll back if the second attempt succeeds" do
      Submission.create!(:user => @user, :assignment => @assignment)
      tries = 0
      User.transaction do
        User.create!
        User.unique_constraint_retry do
          tries += 1
          User.create!
          Submission.create!(:user => @user, :assignment => @assignment) if tries == 1
        end
        User.create!
      end
      Submission.count.should eql 1
      User.count.should eql @orig_user_count + 3
    end

    it "should not eat other ActiveRecord::StatementInvalid exceptions" do
      tries = 0
      lambda {
        User.unique_constraint_retry {
          tries += 1
          User.connection.execute "this is not valid sql"
        }
      }.should raise_error(ActiveRecord::StatementInvalid)
      tries.should eql 1
    end

    it "should not eat any other exceptions" do
      tries = 0
      lambda {
        User.unique_constraint_retry {
          tries += 1
          raise "oh crap"
        }
      }.should raise_error
      tries.should eql 1
    end
  end

  # see config/initializers/rails_patches.rb
  context "query cache" do
    it "should clear the query cache on a successful insert" do
      User.create
      User.cache do
        User.first
        query_cache = User.connection.instance_variable_get(:@query_cache)
        keys = query_cache.keys
        keys.should be_present

        User.create!
        (query_cache.keys & keys).should eql []
      end
    end

    it "should clear the query cache on an unsuccessful insert" do
      u = User.create
      User.cache do
        User.first
        query_cache = User.connection.instance_variable_get(:@query_cache)
        keys = query_cache.keys
        keys.should be_present

        u2 = User.new
        u2.id = u.id
        lambda{ u2.save! }.should raise_error(ActiveRecord::Base::UniqueConstraintViolation)
        (query_cache.keys & keys).should eql []
      end
    end
  end

  context "add_polymorphs" do
    class OtherPolymorphyThing; end
    before :all do
      # it already has :submission
      ConversationMessage.add_polymorph_methods :asset, [:other_polymorphy_thing]
    end
    
    before do
      @conversation = Conversation.create
      @user = user_model
      @assignment = assignment_model
    end

    context "getter" do
      it "should return the polymorph" do
        sub = @user.submissions.create!(:assignment => @assignment)
        m = @conversation.conversation_messages.build
        m.asset = sub

        m.submission.should be_an_instance_of(Submission)
      end

      it "should not return the polymorph if the type is wrong" do
        m = @conversation.conversation_messages.build
        m.asset = @user.submissions.create!(:assignment => @assignment)

        m.other_polymorphy_thing.should be_nil
      end
    end

    context "setter" do
      it "should set the underlying association" do
        m = @conversation.conversation_messages.build
        s = @user.submissions.create!(:assignment => @assignment)
        m.submission = s
        
        m.asset_type.should eql 'Submission'
        m.asset_id.should eql s.id
        m.asset.should eql s
        m.submission.should eql s
        
        m.submission = nil

        m.asset_type.should be_nil
        m.asset_id.should be_nil
        m.asset.should be_nil
        m.submission.should be_nil
      end

      it "should not change the underlying association if it's another object and we're setting nil" do
        m = @conversation.conversation_messages.build
        s =  @user.submissions.create!(:assignment => @assignment)
        m.submission = s
        m.other_polymorphy_thing = nil

        m.asset_type.should eql 'Submission'
        m.asset_id.should eql s.id
        m.asset.should eql s
        m.submission.should eql s
        m.other_polymorphy_thing.should be_nil
      end
    end
  end

  context "bulk_insert" do
    it "should work" do
      Course.connection.bulk_insert "courses", [
        {:name => "foo"},
        {:name => "bar"}
      ]
      Course.all.map(&:name).sort.should eql ["bar", "foo"]
    end

    it "should not raise an error if there are no records" do
      lambda { Course.connection.bulk_insert "courses", [] }.should_not raise_error
      Course.all.size.should eql 0
    end
  end

  context "distinct" do
    before do
      User.create()
      User.create()
      User.create(:locale => "en")
      User.create(:locale => "en")
      User.create(:locale => "es")
    end

    it "should return distinct values" do
      User.distinct(:locale).should eql ["en", "es"]
    end

    it "should return distinct values with nil" do
      User.distinct(:locale, :include_nil => true).should eql [nil, "en", "es"]
    end
  end

  context "find_ids_in_batches" do
    it "should return ids from the table in batches of specified size" do
      ids = []
      5.times { ids << User.create!().id }
      batches = []
      User.find_ids_in_batches(:batch_size => 2) do |found_ids|
        batches << found_ids
      end
      batches.should == [ ids[0,2], ids[2,2], ids[4,1] ]
    end
  end

  describe "find_ids_in_ranges" do
    it "should return ids from the table in ranges" do
      ids = []
      10.times { ids << User.create!().id }
      batches = []
      User.find_ids_in_ranges(:batch_size => 4) do |*found_ids|
        batches << found_ids
      end
      batches.should == [ [ids[0], ids[3]],
                          [ids[4], ids[7]],
                          [ids[8], ids[9]] ]
    end
  end

  context "after_transaction_commit" do
    self.use_transactional_fixtures = false

    it "should execute the callback immediately if not in a transaction" do
      a = 0
      User.connection.after_transaction_commit { a += 1 }
      a.should == 1
    end

    it "should execute the callback after commit if in a transaction" do
      a = 0
      User.connection.transaction do
        User.connection.after_transaction_commit { a += 1 }
        a.should == 0
      end
      a.should == 1
    end

    it "should not execute the callbacks on rollback" do
      a = 0
      User.connection.transaction do
        User.connection.after_transaction_commit { a += 1 }
        a.should == 0
        raise ActiveRecord::Rollback
      end
      a.should == 0
      User.connection.transaction do
        # verify that the callback gets cleared out, so this second transaction won't trigger it
      end
      a.should == 0
    end

    it "should avoid loops due to callbacks causing a new transaction" do
      a = 0
      User.connection.transaction do
        User.connection.after_transaction_commit { User.connection.transaction { a += 1 } }
        a.should == 0
      end
      a.should == 1
    end
  end

  context "Finder tests" do
    before(:each) do
      @user = user_model
    end

    it "should fail with improper nested hashes" do
      lambda {
        User.find(:first, :conditions => { :name => { :users => { :id => @user.id }}})
      }.should raise_error(ActiveRecord::StatementInvalid)
    end

    it "should fail with dot in nested column name" do
      lambda {
        User.find(:first, :conditions => { :name => { "users.id" => @user.id }})
      }.should raise_error(ActiveRecord::StatementInvalid)
    end

    it "should not fail with a dot in column name only" do
      User.find(:first, :conditions => { 'users.id' => @user.id }).should_not be_nil
    end
  end
end
