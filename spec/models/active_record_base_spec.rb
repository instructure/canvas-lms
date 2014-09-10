#
# Copyright (C) 2011 - 2013 Instructure, Inc.
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
  describe "count_by_date" do
    let_once(:account) { Account.create! }

    def create_courses(account, start_times)
      start_times.each_with_index do |time, i|
        (i + 1).times do
          course = account.courses.build
          course.start_at = time
          course.save!
        end
      end
    end

    it "should work" do
      start_times = [
        Time.zone.now,
        Time.zone.now.advance(:days => -1),
        Time.zone.now.advance(:days => -2),
        Time.zone.now.advance(:days => -3)
      ]
      create_courses(account, start_times)

      # updated_at
      account.courses.count_by_date.should eql({start_times.first.to_date => 10})

      account.courses.count_by_date(:column => :start_at).should eql Hash[
        start_times.each_with_index.map{ |t, i| [t.to_date, i + 1]}
      ]
    end

    it "should just do the last 20 days by default" do
      start_times = [
        Time.zone.now,
        Time.zone.now.advance(:days => -19),
        Time.zone.now.advance(:days => -20),
        Time.zone.now.advance(:days => 1)
      ]
      create_courses(account, start_times)

      # updated_at
      account.courses.count_by_date.should eql({start_times.first.to_date => 10})

      account.courses.count_by_date(:column => :start_at).should eql Hash[
        start_times[0..1].each_with_index.map{ |t, i| [t.to_date, i + 1]}
      ]
    end
  end

  describe "find in batches" do
    before :once do
      @c1 = course(:name => 'course1', :active_course => true)
      @c2 = course(:name => 'course2', :active_course => true)
      u1 = user(:name => 'user1', :active_user => true)
      u2 = user(:name => 'user2', :active_user => true)
      u3 = user(:name => 'user3', :active_user => true)
      @e1 = @c1.enroll_student(u1, :enrollment_state => 'active')
      @e2 = @c1.enroll_student(u2, :enrollment_state => 'active')
      @e3 = @c1.enroll_student(u3, :enrollment_state => 'active')
      @e4 = @c2.enroll_student(u1, :enrollment_state => 'active')
      @e5 = @c2.enroll_student(u2, :enrollment_state => 'active')
      @e6 = @c2.enroll_student(u3, :enrollment_state => 'active')
    end

    it "should find all enrollments from course join in batches" do
      e = Course.active.where(id: [@c1, @c2]).select("enrollments.id AS e_id").
                        joins(:enrollments).order("e_id asc")
      batch_size = 2
      es = []
      e.find_in_batches_with_temp_table(:batch_size => batch_size) do |batch|
        batch.size.should == batch_size
        batch.each do |r|
          es << r["e_id"].to_i
        end
      end
      es.length.should == 6
      es.should == [@e1.id,@e2.id,@e3.id,@e4.id,@e5.id,@e6.id]
    end

    it "should honor includes when using a cursor" do
      pending "needs PostgreSQL" unless Account.connection.adapter_name == 'PostgreSQL'
      Account.default.courses.create!
      Account.transaction do
        Account.where(:id => Account.default).includes(:courses).find_each do |a|
          a.courses.loaded?.should be_true
        end
      end
    end

    it "should not use a cursor when start is passed" do
      pending "needs PostgreSQL" unless Account.connection.adapter_name == 'PostgreSQL'
      Account.transaction do
        Account.expects(:find_in_batches_with_cursor).never
        Account.where(:id => Account.default).includes(:courses).find_each(start: 0) do |a|
          a.courses.loaded?.should be_true
        end
      end
    end

    it "should raise an error when start is used with group" do
      lambda { Account.group(:id).find_each(start: 0) }.should raise_error(ArgumentError)
    end
  end

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
      u = User.create!(:name => 'my name')
      # if we ever actually drop the name column, this spec will fail on the line
      # above, so it's all good
      ActiveRecord::Base.send(:remove_const, :DROPPED_COLUMNS)
      ActiveRecord::Base::DROPPED_COLUMNS = { 'users' => %w(name) }
      User.reset_column_information
      User.columns.any? { |c| c.name == 'name' }.should be_false
      User.column_names.should_not be_include('name')

      # load from the db should hide the attribute
      u = User.find(u.id)
      u.attributes.keys.include?('name').should be_false
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
    before :once do
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

    it "should run twice if it gets a RecordNotUnique" do
      Submission.create!(:user => @user, :assignment => @assignment)
      tries = 0
      lambda{
        User.unique_constraint_retry do
          tries += 1
          User.create!
          Submission.create!(:user => @user, :assignment => @assignment)
        end
      }.should raise_error(ActiveRecord::RecordNotUnique) # we don't catch the error the second time
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
        User.connection.expects(:select).never
        User.first
        User.connection.unstub(:select)

        User.create!
        User.connection.expects(:select).once.returns([])
        User.first
      end
    end

    it "should clear the query cache on an unsuccessful insert" do
      u = User.create
      User.cache do
        User.first
        User.connection.expects(:select).never
        User.first
        User.connection.unstub(:select)

        u2 = User.new
        u2.id = u.id
        lambda{ u2.save! }.should raise_error(ActiveRecord::RecordNotUnique)
        User.connection.expects(:select).once.returns([])
        User.first
      end
    end
  end

  context "add_polymorphs" do
    class OtherPolymorphyThing; end
    before :all do
      # it already has :submission
      ConversationMessage.add_polymorph_methods :asset, [:other_polymorphy_thing]
    end
    
    before :once do
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
      User.bulk_insert [
        {:name => "bulk_insert_1", :workflow_state => "registered"},
        {:name => "bulk_insert_2", :workflow_state => "registered"}
      ]
      names = User.order(:name).pluck(:name)
      names.should be_include("bulk_insert_1")
      names.should be_include("bulk_insert_2")
    end

    it "should not raise an error if there are no records" do
      expect { Course.bulk_insert [] }.to change(Course, :count).by(0)
    end
  end

  context "distinct" do
    before :once do
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
      User.where(id: ids).find_ids_in_batches(:batch_size => 2) do |found_ids|
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
      User.where(id: ids).find_ids_in_ranges(:batch_size => 4) do |*found_ids|
        batches << found_ids
      end
      batches.should == [ [ids[0], ids[3]],
                          [ids[4], ids[7]],
                          [ids[8], ids[9]] ]
    end

    it "should work with scopes" do
      user = User.create!
      user2 = User.create!
      user2.destroy
      User.active.where(id: [user, user2]).find_ids_in_ranges do |*found_ids|
        found_ids.should == [user.id, user.id]
      end
    end
  end

  context "after_transaction_commit" do
    self.use_transactional_fixtures = false

    before do
      Rails.env.stubs(:test?).returns(false)
    end

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
    before :once do
      @user = user_model
    end

    it "should fail with improper nested hashes" do
      expect {
        User.where(:name => { :users => { :id => @user }}).first
      }.to raise_error(ActiveRecord::StatementInvalid)
    end

    it "should fail with dot in nested column name" do
      expect {
        User.where(:name => { "users.id" => @user }).first
      }.to raise_error(ActiveRecord::StatementInvalid)
    end

    it "should not fail with a dot in column name only" do
      User.where('users.id' => @user).first.should_not be_nil
    end
  end

  describe "find_by_asset_string" do
    it "should enforce type restrictions" do
      u = User.create!
      ActiveRecord::Base.find_by_asset_string(u.asset_string).should == u
      ActiveRecord::Base.find_by_asset_string(u.asset_string, ['User']).should == u
      ActiveRecord::Base.find_by_asset_string(u.asset_string, ['Course']).should == nil
    end
  end

  describe "update_all/delete_all with_joins" do
    before :once do
      @u1 = User.create!(:name => 'a')
      @u2 = User.create!(:name => 'b')
      @p1 = @u1.pseudonyms.create!(:unique_id => 'pa', :account => Account.default)
      @p1_2 = @u1.pseudonyms.create!(:unique_id => 'pa2', :account => Account.default)
      @p2 = @u2.pseudonyms.create!(:unique_id => 'pb', :account => Account.default)
      @p1_2.destroy
    end

    before do
      pending "MySQL and Postgres only" unless %w{PostgreSQL MySQL Mysql2}.include?(ActiveRecord::Base.connection.adapter_name)
    end

    it "should do an update all with a join" do
      Pseudonym.joins(:user).active.where(:users => {:name => 'a'}).update_all(:unique_id => 'pa3')
      @p1.reload.unique_id.should == 'pa3'
      @p1_2.reload.unique_id.should == 'pa2'
      @p2.reload.unique_id.should == 'pb'
    end

    it "should do a delete all with a join" do
      Pseudonym.joins(:user).active.where(:users => {:name => 'a'}).delete_all
      lambda { @p1.reload }.should raise_error(ActiveRecord::RecordNotFound)
      @u1.reload.should_not be_deleted
      @p1_2.reload.unique_id.should == 'pa2'
      @p2.reload.unique_id.should == 'pb'
    end
  end

  describe "delete_all with_limit" do
    it "should work" do
      u = User.create!
      p1 = u.pseudonyms.create!(unique_id: 'a', account: Account.default)
      p2 = u.pseudonyms.create!(unique_id: 'b', account: Account.default)
      u.pseudonyms.scoped.reorder("unique_id DESC").limit(1).delete_all
      p1.reload
      lambda { p2.reload }.should raise_error(ActiveRecord::RecordNotFound)
    end
  end

  describe "add_index" do
    it "should raise an error on too long of name" do
      name = 'some_really_long_name_' * 10
      lambda { User.connection.add_index :users, [:id], name: name }.should raise_error
    end
  end

  describe "nested conditions" do
    it "should not barf if the condition has a question mark" do
      User.joins(:enrollments).where(enrollments: { sis_source_id: 'a?c'}).first.should be_nil
    end
  end

  describe ".polymorphic_where" do
    it "should work" do
      relation = Assignment.scoped
      user1 = User.create!
      account1 = Account.create!
      relation.expects(:where).with("(context_id=? AND context_type=?) OR (context_id=? AND context_type=?)", user1, 'User', account1, 'Account')
      relation.polymorphic_where(context: [user1, account1])
    end

    it "should work with NULLs" do
      relation = Assignment.scoped
      user1 = User.create!
      account1 = Account.create!
      relation.expects(:where).with("(context_id=? AND context_type=?) OR (context_id=? AND context_type=?) OR (context_id IS NULL AND context_type IS NULL)", user1, 'User', account1, 'Account')
      relation.polymorphic_where(context: [nil, user1, account1])
    end
  end

  describe ".nulls" do
    before :once do
      @u1 = User.create!
      User.where(id: @u1).update_all(name: nil)
      @u2 = User.create!(name: 'a')
      @u3 = User.create!
      User.where(id: @u3).update_all(name: nil)
      @u4 = User.create!(name: 'b')

      @us = [@u1, @u2, @u3, @u4]
      # for sanity
      User.where(id: @us, name: nil).order(:id).all.should == [@u1, @u3]
    end

    it "should sort nulls first" do
      User.where(id: @us).order(User.nulls(:first, :name), :id).all.should == [@u1, @u3, @u2, @u4]
    end

    it "should sort nulls last" do
      User.where(id: @us).order(User.nulls(:last, :name), :id).all.should == [@u2, @u4, @u1, @u3]
    end

    it "should sort nulls first, desc" do
      User.where(id: @us).order(User.nulls(:first, :name, :desc), :id).all.should == [@u1, @u3, @u4, @u2]
    end

    it "should sort nulls last, desc" do
      User.where(id: @us).order(User.nulls(:last, :name, :desc), :id).all.should == [@u4, @u2, @u1, @u3]
    end
  end

  describe "marshalling" do
    it "should not load associations when marshalling" do
      a = Account.default
      a.user_account_associations.loaded?.should be_false
      Marshal.dump(a)
      a.user_account_associations.loaded?.should be_false
    end
  end

  describe "callbacks" do
    it "should use default scope" do
      Account.before_save { Account.scoped.to_sql.should_not =~ /callbacks something/; true }
      Account.where(name: 'callbacks something').create!
    end
  end
end
