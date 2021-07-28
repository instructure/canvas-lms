# frozen_string_literal: true

#
# Copyright (C) 2011 - present Instructure, Inc.
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
      expect(account.courses.count_by_date).to eql({start_times.first.to_date => 10})

      expect(account.courses.count_by_date(:column => :start_at)).to eql Hash[
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
      expect(account.courses.count_by_date).to eql({start_times.first.to_date => 10})

      expect(account.courses.count_by_date(:column => :start_at)).to eql Hash[
        start_times[0..1].each_with_index.map{ |t, i| [t.to_date, i + 1]}
      ]
    end
  end

  describe "in batches" do
    before :once do
      @c1 = course_factory(:name => 'course1', :active_course => true)
      @c2 = course_factory(:name => 'course2', :active_course => true)
      @u1 = user_factory(name: 'userC', active_user: true)
      @u2 = user_factory(name: 'userB', active_user: true)
      @u3 = user_factory(name: 'userA', active_user: true)
      @e1 = @c1.enroll_student(@u1, :enrollment_state => 'active')
      @e2 = @c1.enroll_student(@u2, :enrollment_state => 'active')
      @e3 = @c1.enroll_student(@u3, :enrollment_state => 'active')
      @e4 = @c2.enroll_student(@u1, :enrollment_state => 'active')
      @e5 = @c2.enroll_student(@u2, :enrollment_state => 'active')
      @e6 = @c2.enroll_student(@u3, :enrollment_state => 'active')
    end

    shared_examples_for "batches" do
      def do_batches(relation, **kwargs)
        result = []
        extra = defined?(extra_kwargs) ? extra_kwargs : {}
        relation.in_batches(**kwargs.reverse_merge(extra).reverse_merge(strategy: strategy)) do |batch|
          result << (block_given? ? (yield batch) : batch.to_a)
        end
        result
      end

      it "supports start" do
        expect(do_batches(Enrollment, start: @e2.id)).to eq [[@e2, @e3, @e4, @e5, @e6]]
      end

      it "supports finish" do
        expect(do_batches(Enrollment, finish: @e3.id)).to eq [[@e1, @e2, @e3]]
      end

      it "supports start and finish with a small batch size" do
        expect(do_batches(Enrollment, of: 2, start: @e2.id, finish: @e4.id)).to eq [[@e2, @e3], [@e4]]
      end

      it "respects order" do
        expect(do_batches(User.order(:name), of: 2)).to eq [[@u3, @u2], [@u1]]
      end

      it "handles a batch size the exact size of the query" do
        expect(do_batches(User.order(:id), of: 3)).to eq [[@u1, @u2, @u3]]
      end

      it "preloads" do
        Account.default.courses.create!
        a = do_batches(Account.where(id: Account.default).preload(:courses)).flatten.first
        expect(a.courses.loaded?).to eq true
      end

      it "handles pluck" do
        expect do
          expect(do_batches(User.order(:id), of: 3, load: false) { |r| r.pluck(:id) }).to eq [[@u1.id, @u2.id, @u3.id]]
        end.not_to change(User.connection_pool.connections, :length)
        # even with :copy, a new connection should not be taken out (i.e. to satisfy an "actual" query for the pluck)
      end
    end

    context "with temp_table" do
      let(:strategy) { :temp_table }
      let(:extra_kwargs) { { ignore_transaction: true } }

      include_examples "batches"

      it "raises an error when not in a transaction" do
        expect { User.all.find_in_batches(strategy: :temp_table) {} }.to raise_error(ArgumentError)
      end

      it "finds all enrollments from course join" do
        e = Course.active.where(id: [@c1, @c2]).select("enrollments.id AS e_id")
          .joins(:enrollments).order("e_id asc")
        batch_size = 2
        es = []
        Course.transaction do
          e.find_in_batches(strategy: :temp_table, batch_size: batch_size) do |batch|
            expect(batch.size).to eq batch_size
            batch.each do |r|
              es << r["e_id"].to_i
            end
          end
        end
        expect(es.length).to eq 6
        expect(es).to eq [@e1.id,@e2.id,@e3.id,@e4.id,@e5.id,@e6.id]
      end
    end

    context "with cursor" do
      let(:strategy) { :cursor }

      include_examples "batches"

      context "sharding" do
        specs_require_sharding

        it "properly transposes across multiple shards" do
          u1 = User.create!
          u2 = @shard1.activate { User.create! }
          User.transaction do
            users = []
            User.preload(:pseudonyms).where(id: [u1, u2]).find_each(strategy: :cursor) do |u|
              users << u
            end
            expect(users.sort).to eq [u1, u2].sort
          end
        end
      end
    end

    context "with copy" do
      let(:strategy) { :copy }
      let(:extra_kwargs) { { load: true } }

      include_examples "batches"

      it "works with load: false" do
        User.in_batches(strategy: :copy) { |r| expect(r.to_a).to eq [@u1, @u2, @u3] }
      end
    end

    context "with id" do
      it "should raise an error when start is used with group" do
        expect do
          Account.group(:id).find_each(strategy: :id, start: 0) {}
        end.to raise_error(ArgumentError)
      end
    end
  end

  context "rank helpers" do
    it "should generate appropriate rank sql" do
      expect(ActiveRecord::Base.rank_sql(['a', ['b', 'c'], ['d']], 'foo')).
        to eql "CASE WHEN foo IN ('a') THEN 0 WHEN foo IN ('b', 'c') THEN 1 WHEN foo IN ('d') THEN 2 ELSE 3 END"
    end

    it "should generate appropriate rank hashes" do
      hash = ActiveRecord::Base.rank_hash(['a', ['b', 'c'], ['d']])
      expect(hash).to eq({'a' => 1, 'b' => 2, 'c' => 2, 'd' => 3})
      expect(hash['e']).to eql 4
    end
  end

  it "should have a valid GROUP BY clause when group_by is used correctly" do
    conn = ActiveRecord::Base.connection
    expect {
      User.find_by_sql "SELECT id, name FROM #{User.quoted_table_name} GROUP BY #{conn.group_by('id', 'name')}"
      User.find_by_sql "SELECT id, name FROM (SELECT id, name FROM #{User.quoted_table_name}) u GROUP BY #{conn.group_by('id', 'name')}"
    }.not_to raise_error
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
      expect(User.count).to eql @orig_user_count + 1
    end

    it "should run twice if it gets a RecordNotUnique" do
      Submission.create!(:user => @user, :assignment => @assignment)
      tries = 0
      expect{
        User.unique_constraint_retry do
          tries += 1
          User.create!
          Submission.create!(:user => @user, :assignment => @assignment)
        end
      }.to raise_error(ActiveRecord::RecordNotUnique) # we don't catch the error the second time
      expect(Submission.count).to eql 1
      expect(tries).to eql 2
      expect(User.count).to eql @orig_user_count
    end

    it "should run additional times if specified" do
      Submission.create!(:user => @user, :assignment => @assignment)
      tries = 0
      expect{
        User.unique_constraint_retry(2) do
          tries += 1
          Submission.create!(:user => @user, :assignment => @assignment)
        end
      }.to raise_error(ActiveRecord::RecordNotUnique) # we don't catch the error the last time
      expect(tries).to eql 3
      expect(Submission.count).to eql 1
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
      expect(Submission.count).to eql 1
      expect(User.count).to eql @orig_user_count + 3
    end

    it "should not eat other ActiveRecord::StatementInvalid exceptions" do
      tries = 0
      expect {
        User.unique_constraint_retry {
          tries += 1
          User.connection.execute "this is not valid sql"
        }
      }.to raise_error(ActiveRecord::StatementInvalid)
      expect(tries).to eql 1
    end

    it "should not eat any other exceptions" do
      tries = 0
      expect {
        User.unique_constraint_retry {
          tries += 1
          raise "oh crap"
        }
      }.to raise_error("oh crap")
      expect(tries).to eql 1
    end
  end

  # see config/initializers/rails_patches.rb
  context "query cache" do
    it "should clear the query cache on a successful insert" do
      User.create
      User.cache do
        User.first

        count = 0
        allow(User.connection).to receive(:select).and_wrap_original do |original, args|
          count += 1
          original.call(args)
        end
        User.first
        expect(count).to eq 0

        User.create!

        count = 0
        User.first
        expect(count).to eq 1
      end
    end

    it "should clear the query cache on an unsuccessful insert" do
      u = User.create
      User.cache do
        User.first

        count = 0
        allow(User.connection).to receive(:select).and_wrap_original do |original, args|
          count += 1
          original.call(args)
        end
        User.first
        expect(count).to eq 0

        u2 = User.new
        u2.id = u.id
        expect{ u2.save! }.to raise_error(ActiveRecord::RecordNotUnique)
        count = 0
        User.first
        expect(count).to eq 1
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
      expect(names).to be_include("bulk_insert_1")
      expect(names).to be_include("bulk_insert_2")
    end

    it "should handle arrays" do
      arr1 = ['1, 2', 3, 'string with "quotes"', "another 'string'", "a fancy strîng"]
      arr2 = ['4', '5;', nil, "string with \t tab and \n newline and slash \\"]
      DeveloperKey.bulk_insert [
        {name: "bulk_insert_1", workflow_state: "registered", redirect_uris: arr1, root_account_id: Account.default.id},
        {name: "bulk_insert_2", workflow_state: "registered", redirect_uris: arr2, root_account_id: Account.default.id}
      ]
      names = DeveloperKey.order(:name).pluck(:redirect_uris)
      expect(names).to be_include(arr1.map(&:to_s))
      expect(names).to be_include(arr2)
    end

    it "should not raise an error if there are no records" do
      expect { Course.bulk_insert [] }.to change(Course, :count).by(0)
    end

    it 'should work through bulk insert objects' do
      users = [User.new(name: 'bulk_insert_1', workflow_state: 'registered', preferences: {accepted_terms: Time.zone.now})]
      User.bulk_insert_objects users
      names = User.order(:name).pluck(:name, :preferences)
      expect(names.first.last[:accepted_terms]).not_to be_nil
    end
  end

  context "distinct_values" do
    before :once do
      User.create()
      User.create()
      User.create(:locale => "en")
      User.create(:locale => "en")
      User.create(:locale => "es")
    end

    it "should return distinct values" do
      expect(User.distinct_values(:locale)).to eql ["en", "es"]
    end

    it "should return distinct values with nil" do
      expect(User.distinct_values(:locale, include_nil: true)).to eql [nil, "en", "es"]
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
      expect(batches).to eq [ ids[0,2], ids[2,2], ids[4,1] ]
    end
  end

  describe "find_ids_in_ranges" do
    before :once do
      @ids = []
      10.times { @ids << User.create!().id }
    end

    it "should return ids from the table in ranges" do
      batches = []
      User.where(id: @ids).find_ids_in_ranges(:batch_size => 4) do |*found_ids|
        batches << found_ids
      end
      expect(batches).to eq [ [@ids[0], @ids[3]],
                          [@ids[4], @ids[7]],
                          [@ids[8], @ids[9]] ]
    end

    it "should work with scopes" do
      user = User.create!
      user2 = User.create!
      user2.destroy
      User.active.where(id: [user, user2]).find_ids_in_ranges do |*found_ids|
        expect(found_ids).to eq [user.id, user.id]
      end
    end

    it "should accept an option to start searching at a given id" do
      batches = []
      User.where(id: @ids).find_ids_in_ranges(:batch_size => 4, :start_at => @ids[3]) do |*found_ids|
        batches << found_ids
      end
      expect(batches).to eq [ [@ids[3], @ids[6]], [@ids[7], @ids[9]] ]
    end

    it "should accept an option to end at a given id" do
      batches = []
      User.where(id: @ids).find_ids_in_ranges(:batch_size => 4, :end_at => @ids[5]) do |*found_ids|
        batches << found_ids
      end
      expect(batches).to eq [ [@ids[0], @ids[3]], [@ids[4], @ids[5]] ]
    end

    it "should accept both options to start and end at given ids" do
      batches = []
      User.where(id: @ids).find_ids_in_ranges(:batch_size => 4, :start_at => @ids[2], :end_at => @ids[7]) do |*found_ids|
        batches << found_ids
      end
      expect(batches).to eq [ [@ids[2], @ids[5]], [@ids[6], @ids[7]] ]
    end
  end

  context "Finder tests" do
    before :once do
      @user = user_model
    end

    it "should fail with dot in nested column name" do
      expect {
        User.where(:name => { "users.id" => @user }).first
      }.to raise_error(TypeError)
    end

    it "should not fail with a dot in column name only" do
      expect(User.where('users.id' => @user).first).not_to be_nil
    end
  end

  describe "find_by_asset_string" do
    it "should enforce type restrictions" do
      u = User.create!
      expect(ActiveRecord::Base.find_by_asset_string(u.asset_string)).to eq u
      expect(ActiveRecord::Base.find_by_asset_string(u.asset_string, ['User'])).to eq u
      expect(ActiveRecord::Base.find_by_asset_string(u.asset_string, ['Course'])).to eq nil
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
      skip "Postgres only" unless ActiveRecord::Base.connection.adapter_name == 'PostgreSQL'
    end

    it "should do an update all with a join" do
      expect(Pseudonym.joins(:user).active.where(:users => {:name => 'a'}).update_all(:unique_id => 'pa3')).to eq 1
      expect(@p1.reload.unique_id).to eq 'pa3'
      expect(@p1_2.reload.unique_id).to eq 'pa2'
      expect(@p2.reload.unique_id).to eq 'pb'
    end

    it "should do an update all with a join with join conditions spanning multiple lines" do
      scope = Pseudonym.active.joins("INNER JOIN #{User.quoted_table_name} ON
        pseudonyms.user_id=users.id AND
        users.name='a'")
      expect(scope.update_all(:unique_id => 'pa3')).to eq 1
      expect(@p1.reload.unique_id).to eq 'pa3'
      expect(@p1_2.reload.unique_id).to eq 'pa2'
      expect(@p2.reload.unique_id).to eq 'pb'
    end

    it "should do a delete all with a join" do
      expect(Pseudonym.joins(:user).active.where(:users => {:name => 'a'}).delete_all).to eq 1
      expect { @p1.reload }.to raise_error(ActiveRecord::RecordNotFound)
      expect(@u1.reload).not_to be_deleted
      expect(@p1_2.reload.unique_id).to eq 'pa2'
      expect(@p2.reload.unique_id).to eq 'pb'
    end

    # in rails 4, the where conditions use bind values for association scopes
    it "should do an update all with a join on associations" do
      @u1.pseudonyms.joins(:user).active.where(:users => {:name => 'b'}).update_all(:unique_id => 'pa3')
      expect(@p1.reload.unique_id).to_not eq 'pa3'
      @u1.pseudonyms.joins(:user).active.where(:users => {:name => 'a'}).update_all(:unique_id => 'pa3')
      expect(@p1.reload.unique_id).to eq 'pa3'
      expect(@p1_2.reload.unique_id).to eq 'pa2'
    end

    it "should do a delete all with a join on associations" do
      @u1.pseudonyms.joins(:user).active.where(:users => {:name => 'b'}).delete_all
      expect(@u1.reload).not_to be_deleted
      expect(@p1.reload.unique_id).to eq 'pa'
      expect(@p1_2.reload.unique_id).to eq 'pa2'
      @u1.pseudonyms.joins(:user).active.where(:users => {:name => 'a'}).delete_all
      expect { @p1.reload }.to raise_error(ActiveRecord::RecordNotFound)
      expect(@u1.reload).not_to be_deleted
      expect(@p1_2.reload.unique_id).to eq 'pa2'
    end
  end

  describe "delete_all with_limit" do
    it "should work" do
      u = User.create!
      p1 = u.pseudonyms.create!(unique_id: 'a', account: Account.default)
      p2 = u.pseudonyms.create!(unique_id: 'b', account: Account.default)
      u.pseudonyms.reorder("unique_id DESC").limit(1).delete_all
      p1.reload
      expect { p2.reload }.to raise_error(ActiveRecord::RecordNotFound)
    end

    it "doesn't empty the table accidentally when querying from a subquery and not the actual table" do
      u1 = User.create!(name: 'a')
      u2 = User.create!(name: 'a')
      User.from(<<-SQL)
        (WITH duplicates AS (
          SELECT users.*,
              ROW_NUMBER() OVER(PARTITION BY users.name
                                    ORDER BY users.created_at DESC)
                                    AS dup_count
          FROM #{User.quoted_table_name}
          )
        SELECT *
        FROM duplicates
        WHERE dup_count > 1) AS users
      SQL
        .limit(1).delete_all
      expect { User.find(u1.id) }.to raise_error(ActiveRecord::RecordNotFound)
      expect(User.find(u2.id)).to eq u2
    end

    it "does offset too" do
      u = User.create!
      p1 = u.pseudonyms.create!(unique_id: 'a', account: Account.default)
      p2 = u.pseudonyms.create!(unique_id: 'b', account: Account.default)
      p3 = u.pseudonyms.create!(unique_id: 'c', account: Account.default)
      u.pseudonyms.reorder("unique_id DESC").limit(1).offset(1).delete_all
      p1.reload
      expect { p2.reload }.to raise_error(ActiveRecord::RecordNotFound)
      p3.reload
    end
  end

  describe "#in_batches.delete_all" do
    it "just does a single query, instead of an ordered select and then delete" do
      u = User.create!
      expect(User.connection).to receive(:exec_query).once.and_call_original
      expect(User.where(id: u.id).in_batches.delete_all).to eq 1
      expect { User.find(u.id) }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end

  describe "add_index" do
    it "should raise an error on too long of name" do
      name = 'some_really_long_name_' * 10
      expect { User.connection.add_index :users, [:id], name: name }.to raise_error(/Index name .+ is too long/)
    end
  end

  describe "nested conditions" do
    it "should not barf if the condition has a question mark" do
      expect(User.joins(:enrollments).where(enrollments: { workflow_state: 'a?c'}).first).to be_nil
    end
  end

  describe ".polymorphic_where" do
    it "should work" do
      relation = Assignment.all
      user1 = User.create!
      account1 = Account.create!
      expect(relation).to receive(:where).with("(context_id=? AND context_type=?) OR (context_id=? AND context_type=?)", user1, 'User', account1, 'Account')
      relation.polymorphic_where(context: [user1, account1])
    end

    it "should work with NULLs" do
      relation = Assignment.all
      user1 = User.create!
      account1 = Account.create!
      expect(relation).to receive(:where).with("(context_id=? AND context_type=?) OR (context_id=? AND context_type=?) OR (context_id IS NULL AND context_type IS NULL)", user1, 'User', account1, 'Account')
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
    end

    it "should sort nulls first" do
      expect(User.where(id: @us).order(User.nulls(:first, :name), :id).all).to eq [@u1, @u3, @u2, @u4]
    end

    it "should sort nulls last" do
      expect(User.where(id: @us).order(User.nulls(:last, :name), :id).all).to eq [@u2, @u4, @u1, @u3]
    end

    it "should sort nulls first, desc" do
      expect(User.where(id: @us).order(User.nulls(:first, :name, :desc), :id).all).to eq [@u1, @u3, @u4, @u2]
    end

    it "should sort nulls last, desc" do
      expect(User.where(id: @us).order(User.nulls(:last, :name, :desc), :id).all).to eq [@u4, @u2, @u1, @u3]
    end
  end

  describe "marshalling" do
    it "should not load associations when marshalling" do
      a = Account.default
      expect(a.user_account_associations.loaded?).to be_falsey
      Marshal.dump(a)
      expect(a.user_account_associations.loaded?).to be_falsey
    end
  end

  describe "callbacks" do
    before do
      class MockAccount < Account
        include RSpec::Matchers
        before_save do
          expect(Account.all.to_sql).not_to match /callbacks something/
          expect(MockAccount.all.to_sql).not_to match /callbacks something/
          true
        end
      end
    end

    after do
      Object.send(:remove_const, :MockAccount)
    end

    it "should use default scope" do
      MockAccount.where(name: 'callbacks something').create!
    end
  end

  describe "not_recently_touched" do
    it "should work with joins" do
      Setting.set('touch_personal_space', '1')
      group_model
      expect(@group.users.not_recently_touched.to_a).to be_empty
    end
  end

  context "polymorphic associations" do
    it "allows joins to specific classes" do
      # no error
      sql = StreamItem.joins(:discussion_topic).to_sql
      # and the sql
      expect(sql).to include('asset_type')
      expect(sql).to include('DiscussionTopic')
    end

    it "validates the type field" do
      si = StreamItem.new
      si.asset_type = 'Submission'
      si.data = {}
      expect(si.valid?).to eq true

      si.context_type = 'User'
      expect(si.valid?).to eq false
    end

    it "doesn't allow mismatched assignment" do
      si = StreamItem.new
      expect { si.discussion_topic = Course.new }.to raise_error(ActiveRecord::AssociationTypeMismatch)
      expect { si.asset = Course.new }.to raise_error(ActiveRecord::AssociationTypeMismatch)
      si.asset = DiscussionTopic.new
      si.asset = nil
    end

    it "has the same backing store for both generic and specific accessors" do
      si = StreamItem.new
      dt = DiscussionTopic.new
      si.discussion_topic = dt
      expect(si.asset_type).to eq 'DiscussionTopic'
      expect(si.asset_id).to eq dt.id
      expect(si.asset.object_id).to eq si.discussion_topic.object_id
    end

    it "returns nil for the specific type if it's not that type" do
      si = StreamItem.new
      si.discussion_topic = DiscussionTopic.new
      expect(si.conversation).to eq nil
    end

    it "doesn't ignores specific type if we're setting nil" do
      si = StreamItem.new
      dt = DiscussionTopic.new
      si.discussion_topic = dt
      si.conversation = nil
      expect(si.asset).to eq dt
      si.discussion_topic = nil
      expect(si.asset).to eq nil
    end

    it "prefixes specific associations" do
      expect(AssessmentRequest.reflections.keys).to be_include('assessor_asset_submission')
    end

    it "prefixes specific associations with an explicit name" do
      expect(LearningOutcomeResult.reflections.keys).to be_include('association_assignment')
    end

    it "passes the correct foreign key down to specific associations" do
      expect(LearningOutcomeResult.reflections['association_assignment'].foreign_key).to eq :association_id
    end

    it "handles class resolution that doesn't match the association name" do
      expect(Attachment.reflections['quiz'].klass).to eq Quizzes::Quiz
    end

    it "doesn't validate the type field for non-exhaustive associations" do
      u = User.create!
      v = Version.new
      v.versionable = u
      expect(v.versionable_type).to eq 'User'
      expect(v).to be_valid
    end
  end

  describe "temp_record" do
    it "should not reload the base association for normal invertible associations" do
      c = Course.create!(:name => "some name")
      Course.where(:id => c).update_all(:name => "sadness")
      expect(c.enrollments.temp_record.course.name).to eq c.name
    end

    it "should not reload the base association for polymorphic associations" do
      c = Course.create!(:name => "some name")
      Course.where(:id => c).update_all(:name => "sadness")
      expect(c.discussion_topics.temp_record.course.name).to eq c.name
    end
  end
end

describe ActiveRecord::ConnectionAdapters::ConnectionPool do
  # create a private pool, with the same config as the regular pool, but ensure
  # max_runtime is set
  let(:spec) { ActiveRecord::ConnectionAdapters::ConnectionSpecification.new(
    'spec',
    ActiveRecord::Base.connection_pool.spec.config.merge(max_runtime: 30),
    'postgresql_connection') }
  let(:pool) { ActiveRecord::ConnectionAdapters::ConnectionPool.new(spec) }

  it "doesn't evict a normal cycle" do
    conn1 = pool.connection
    pool.checkin(conn1)
    expect(pool).to be_connected
    conn2 = pool.connection
    expect(conn2).to eql conn1
  end

  it "evicts connections on checkout" do
    allow(Concurrent).to receive(:monotonic_time).and_return(0)

    conn1 = pool.connection
    pool.checkin(conn1)

    allow(Concurrent).to receive(:monotonic_time).and_return(60)
    conn2 = pool.connection
    expect(conn2).not_to eql conn1
  end

  it "evicts connections on checkin" do
    allow(Concurrent).to receive(:monotonic_time).and_return(0)

    conn1 = pool.connection
    expect(conn1.runtime).to eq 0

    allow(Concurrent).to receive(:monotonic_time).and_return(60)

    expect(conn1.runtime).to eq 60
    pool.checkin(conn1)

    expect(pool).not_to be_connected
  end

  it "evicts connections if you call flush" do
    allow(Concurrent).to receive(:monotonic_time).and_return(0)

    conn1 = pool.connection
    pool.checkin(conn1)

    allow(Concurrent).to receive(:monotonic_time).and_return(60)

    pool.flush

    expect(pool).not_to be_connected
  end

end
