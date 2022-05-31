# frozen_string_literal: true

#
# Copyright (C) 2012 - present Instructure, Inc.
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

module ActiveRecord
  describe Base do
    describe ".wildcard" do
      it "produces a useful wildcard sql string" do
        sql = Base.wildcard("users.name", "users.short_name", "Sinatra, Frank", { delimiter: "," })
        expect(sql).to eq "(LOWER(',' || users.name || ',') LIKE '%,sinatra, frank,%' OR LOWER(',' || users.short_name || ',') LIKE '%,sinatra, frank,%')"
      end
    end

    describe ".wildcard_pattern" do
      it "downcases the query string" do
        expect(Base.wildcard_pattern("SomeString")).to include("somestring")
      end

      it "escapes special characters in the query" do
        %w[% _].each do |char|
          expect(Base.wildcard_pattern("some" + char + "string")).to include("some\\" + char + "string")
        end
      end

      it "bases modulos on either end of the query per the configured type" do
        { full: "%somestring%", left: "%somestring", right: "somestring%" }.each do |type, result|
          expect(Base.wildcard_pattern("somestring", type: type)).to eq result
        end
      end
    end

    describe ".coalesced_wildcard" do
      it "produces a useful wildcard string for a coalesced index" do
        sql = Base.coalesced_wildcard("users.name", "users.short_name", "Sinatra, Frank")
        expect(sql).to eq "((COALESCE(LOWER(users.name), '') || ' ' || COALESCE(LOWER(users.short_name), '')) LIKE '%sinatra, frank%')"
      end
    end

    describe ".coalesce_chain" do
      it "chains together many columns for combined matching" do
        sql = Base.coalesce_chain(["foo.bar", "foo.baz", "foo.bang"])
        expect(sql).to eq "(COALESCE(LOWER(foo.bar), '') || ' ' || COALESCE(LOWER(foo.baz), '') || ' ' || COALESCE(LOWER(foo.bang), ''))"
      end
    end

    describe "find_in_batches" do
      describe "with cursor" do
        before do
          skip "needs PostgreSQL" unless Account.connection.adapter_name == "PostgreSQL"
        end

        it "iterates through all selected rows" do
          users = Set.new
          3.times { users << user_model }
          found = Set.new
          User.connection.cache { User.find_each(batch_size: 1) { |u| found << u } }
          expect(found).to eq users
        end

        it "cleans up the cursor" do
          # two cursors with the same name; if it didn't get cleaned up, it would error
          expect do
            User.all.find_each { nil }
            User.all.find_each { nil } # rubocop:disable Style/CombinableLoops
          end.to_not raise_error
        end

        it "cleans up the temp table for non-DB error" do
          User.create!
          # two temp tables with the same name; if it didn't get cleaned up, it would error
          expect do
            User.all.find_each do
              raise ArgumentError
            end
          end.to raise_error(ArgumentError)

          User.all.find_each { nil }
        end

        it "doesnt obfuscate the error when it dies in a transaction" do
          account = Account.create!
          account.courses.create!
          User.create!
          expect do
            ActiveRecord::Base.transaction do
              User.all.find_each do
                # to force a foreign key error
                Account.where(id: account).delete_all
              end
            end
          end.to raise_error(ActiveRecord::InvalidForeignKey)
        end
      end

      describe "with temp table" do
        around do |example|
          ActiveRecord::Base.in_migration = true
          example.run
        ensure
          ActiveRecord::Base.in_migration = false
        end

        it "uses a temp table when you select without an id" do
          expect do
            User.create!
            User.select(:name).find_in_batches do
              User.connection.select_value("SELECT COUNT(*) FROM users_in_batches_temp_table_#{User.select(:name).to_sql.hash.abs.to_s(36)}")
            end
          end.to_not raise_error
        end

        it "does not use a temp table for a plain query" do
          User.create!
          User.find_in_batches do
            expect { User.connection.select_value("SELECT COUNT(*) FROM users_in_batches_temp_table_#{User.all.to_sql.hash.abs.to_s(36)}") }.to raise_error(ActiveRecord::StatementInvalid)
          end
        end

        it "does not use a temp table for a select with id" do
          User.create!
          User.select(:id).find_in_batches do
            expect { User.connection.select_value("SELECT COUNT(*) FROM users_in_batches_temp_table_#{User.select(:id).to_sql.hash.abs.to_s(36)}") }.to raise_error(ActiveRecord::StatementInvalid)
          end
        end

        it "does not bomb when you try to force past the cursor option on selects with the primary key" do
          selectors = ["*", "users.*", "users.id, users.updated_at"]
          User.create!
          selectors.each do |selector|
            expect do
              User.select(selector).find_in_batches(strategy: :id) { nil }
            end.not_to raise_error
          end
        end

        it "cleans up the temp table" do
          # two temp tables with the same name; if it didn't get cleaned up, it would error
          expect do
            User.all.find_in_batches(strategy: :temp_table) { nil }
            User.all.find_in_batches(strategy: :temp_table) { nil }
          end.to_not raise_error
        end

        it "cleans up the temp table for non-DB error" do
          User.create!
          # two temp tables with the same name; if it didn't get cleaned up, it would error
          expect do
            User.all.find_in_batches(strategy: :temp_table) do
              raise ArgumentError
            end
          end.to raise_error(ArgumentError)

          User.all.find_in_batches(strategy: :temp_table) { nil }
        end

        it "does not die with index error when table size is exactly batch size" do
          user_count = 10
          User.delete_all
          user_count.times { user_model }
          expect(User.count).to eq(user_count)
          User.all.find_in_batches(strategy: :temp_table, batch_size: user_count) { nil }
        end

        it "doesnt obfuscate the error when it dies in a transaction" do
          account = Account.create!
          account.courses.create!
          User.create!
          expect do
            ActiveRecord::Base.transaction do
              User.all.find_in_batches(strategy: :temp_table) do
                # to force a foreign key error
                Account.where(id: account).delete_all
              end
            end
          end.to raise_error(ActiveRecord::InvalidForeignKey)
        end
      end

      describe "with id plucking" do
        it "iterates through all selected rows" do
          users = Set.new
          3.times { users << user_model }
          found = Set.new
          User.find_in_batches(strategy: :pluck_ids, batch_size: 1) do |u_batch|
            u_batch.each { |u| found << u }
          end
          expect(found).to eq users
        end

        it "keeps the specified order" do
          %w[user_F user_D user_A user_C user_B user_E].map { |name| user_model(name: name) }
          names = []
          User.order(:name).find_in_batches(strategy: :pluck_ids, batch_size: 3) do |u_batch|
            names += u_batch.map(&:name)
          end
          expect(names).to eq(%w[user_A user_B user_C user_D user_E user_F])
        end
      end
    end

    describe ".bulk_insert" do
      it "throws exception if it violates a foreign key" do
        attrs = {
          "request_id" => "abcde-12345",
          "uuid" => "edcba-54321",
          "account_id" => Account.default.id,
          "user_id" => -1,
          "pseudonym_id" => -1,
          "event_type" => "login",
          "created_at" => DateTime.now.utc
        }
        expect do
          Auditors::ActiveRecord::AuthenticationRecord.bulk_insert([attrs])
        end.to raise_error(ActiveRecord::InvalidForeignKey)
      end

      it "writes to the correct partition" do
        user = user_with_pseudonym(active_user: true)
        pseud = @pseudonym
        attrs_1 = {
          "request_id" => "abcde-12345",
          "uuid" => "edcba-54321",
          "account_id" => Account.default.id,
          "user_id" => user.id,
          "pseudonym_id" => pseud.id,
          "event_type" => "login",
          "created_at" => DateTime.now.utc
        }
        attrs_2 = attrs_1.merge({
                                  "created_at" => 40.days.ago
                                })
        ar_type = Auditors::ActiveRecord::AuthenticationRecord
        expect { ar_type.bulk_insert([attrs_1, attrs_2]) }.to_not raise_error
        conn = ar_type.connection
        root_partition_count = conn.execute("select count(*) from only #{ar_type.quoted_table_name};")[0]["count"]
        expect(root_partition_count).to eq(0)
        expect(ar_type.count).to eq(2)
        now_partition_name = conn.quote_table_name(ar_type.infer_partition_table_name(attrs_1))
        now_partition_count = conn.execute("select count(*) from #{now_partition_name};")[0]["count"]
        expect(now_partition_count).to eq(1)
        prev_partition_name = conn.quote_table_name(ar_type.infer_partition_table_name(attrs_2))
        prev_partition_count = conn.execute("select count(*) from #{prev_partition_name};")[0]["count"]
        expect(prev_partition_count).to eq(1)
      end
    end

    describe "deconstruct_joins" do
      describe "delete_all" do
        it "allows delete all on inner join with alias" do
          User.create(name: "dr who")
          User.create(name: "dr who")

          expect do
            User.joins("INNER JOIN #{User.quoted_table_name} u ON users.sortable_name = u.sortable_name")
                .where("u.sortable_name <> users.sortable_name").delete_all
          end.to_not raise_error
        end
      end
    end

    describe "update_all with limit" do
      it "does the right thing with a join and a limit" do
        u1 = User.create!(name: "u1")
        e1 = u1.eportfolios.create!(name: "e1")
        u2 = User.create!(name: "u2")
        e2 = u2.eportfolios.create!(name: "e2")
        Eportfolio.joins(:user).order(:id).limit(1).update_all(name: "changed")
        expect(e1.reload.name).to eq "changed"
        expect(e2.reload.name).not_to eq "changed"
      end
    end

    describe ".parse_asset_string" do
      it "parses simple asset strings" do
        expect(ActiveRecord::Base.parse_asset_string("course_123")).to eql(["Course", 123])
      end

      it "parses asset strings with multi-word class names" do
        expect(ActiveRecord::Base.parse_asset_string("content_tag_456")).to eql(["ContentTag", 456])
      end

      it "parses namespaced asset strings" do
        expect(ActiveRecord::Base.parse_asset_string("quizzes:quiz_789")).to eql(["Quizzes::Quiz", 789])
      end

      it "classifies the class name but leaves plurals in the namespaces alone" do
        expect(ActiveRecord::Base.parse_asset_string("content_tags:content_tags_0")).to eql(["ContentTags::ContentTag", 0])
      end

      it "behaves predictably on an invalid asset string" do
        expect(ActiveRecord::Base.parse_asset_string("what")).to eql(["", 0])
      end
    end

    describe ".parse_asset_string_list" do
      it "parses to a hash" do
        expect(ActiveRecord::Base.parse_asset_string_list("course_1,course_2,user_3"))
          .to eq({ "Course" => [1, 2], "User" => [3] })
      end

      it "accepts an array" do
        expect(ActiveRecord::Base.parse_asset_string_list(%w[course_1 course_2 user_3]))
          .to eq({ "Course" => [1, 2], "User" => [3] })
      end
    end

    describe ".find_all_by_asset_string" do
      let_once(:course) { course_factory }
      let_once(:user) { user_factory }

      it "works" do
        expect(ActiveRecord::Base.find_all_by_asset_string([course.asset_string, user.asset_string]))
          .to eq [course, user]
      end

      it "accepts a pre-parsed hash" do
        expect(ActiveRecord::Base.find_all_by_asset_string("Course" => [course.id], "User" => [user.id]))
          .to eq [course, user]
      end

      it "ignores unnamed asset types" do
        expect(ActiveRecord::Base.find_all_by_asset_string([course.asset_string, user.asset_string], ["User", "Group"]))
          .to eq [user]
      end
    end
  end

  describe ".asset_string" do
    it "generates a string with the reflection_type_name and id" do
      expect(User.asset_string(3)).to eq("user_3")
    end
  end

  describe ".global_id?" do
    specs_require_sharding

    before do
      @shard1.activate do
        @account = Account.create!
      end
    end

    it "returns true if passed an explicit global id" do
      @shard1.activate do
        expect(Account).to be_global_id(@account.global_id)
      end
    end

    it "returns true if passed a stringified global id" do
      @shard1.activate do
        expect(Account).to be_global_id(@account.global_id.to_s)
      end
    end

    it "returns true if passed an id that resolves to a global id" do
      @shard2.activate do
        expect(Account).to be_global_id(@account.id)
      end
    end

    it "returns false if passed an explicit local id" do
      @shard2.activate do
        expect(Account).not_to be_global_id(@account.local_id)
      end
    end

    it "returns false if passed an id that resolves to a local id" do
      @shard1.activate do
        expect(Account).not_to be_global_id(@account.id)
      end
    end

    it "returns false if passed nil" do
      @shard1.activate do
        expect(Account).not_to be_global_id(nil)
      end
    end
  end

  describe Relation do
    describe "lock_with_exclusive_smarts" do
      let(:scope) { User.active }

      it "uses FOR UPDATE on a normal exclusive lock" do
        expect(scope.lock(true).lock_value).to eq true
      end

      it "substitutes 'FOR NO KEY UPDATE' if specified" do
        expect(scope.lock(:no_key_update).lock_value).to eq "FOR NO KEY UPDATE"
      end

      it "substitutes 'FOR NO KEY UPDATE SKIP LOCKED' if specified" do
        expect(scope.lock(:no_key_update_skip_locked).lock_value).to eq "FOR NO KEY UPDATE SKIP LOCKED"
      end
    end

    describe "union" do
      shared_examples_for "query creation" do
        it "includes conditions after the union inside of the subquery" do
          scope = base.active.where(id: 99).union(User.where(id: 1))
          wheres = scope.where_clause.send(:predicates)
          expect(wheres.count).to eq 1
          sql_before_union, sql_after_union = wheres.first.split("UNION ALL")
          expect(sql_before_union).to include('"id" = 99')
          expect(sql_after_union).not_to include('"id" = 99')
        end

        it "includes conditions prior to the union outside of the subquery" do
          scope = base.active.union(User.where(id: 1)).where(id: 99)
          wheres = scope.where_clause.send(:predicates)
          expect(wheres.count).to eq 2
          union_where = wheres.detect { |w| w.is_a?(String) && w.include?("UNION ALL") }
          expect(union_where).not_to include('"id" = 99')
        end

        it "ignores null scopes" do
          s1 = Assignment.all
          s2 = Assignment.all.none
          expect(s1.union(s2)).to be s1
        end

        it "just returns self if everything is null scope" do
          s1 = Assignment.all.none
          s2 = Assignment.all.none
          expect(s1).not_to be s2
          expect(s1.union(s2)).to be s1
        end

        it "serializes to valid SQL with selects, limits, and orders" do
          s = Assignment.select(:updated_at).order(updated_at: :desc).limit(1)
          s.union(s)
        end
      end

      shared_examples_for "query creation sharding" do
        specs_require_sharding

        it "derives the appropriate shard from its input, if they all share the same shard" do
          expect(base_s1.union(base_s1).shard_value).to be @shard1

          @shard2.activate do
            expect(base_s1.union(base_s1).shard_value).to be @shard1
          end
        end

        it "rejects input that are on different shards" do
          expect { base_s1.union(base_s2) }.to raise_error(/multiple shard values passed to union/)
        end
      end

      context "directly on the table" do
        let(:base) { User.active }
        let(:base_s1) { @shard1.activate { User.active } }
        let(:base_s2) { @shard2.activate { User.active } }

        include_examples "query creation"
        include_examples "query creation sharding"
      end

      context "through a relation" do
        let(:base) { Account.create.users }
        let(:base_s1) { @shard1.activate { Account.create.users } }
        let(:base_s2) { @shard2.activate { Account.create.users } }

        include_examples "query creation"
        include_examples "query creation sharding"
      end

      context "through a where query that references multiple shards" do
        let(:user) { User.create }
        let(:user_s1) { @shard1.activate { User.create } }
        let(:user_s2) { @shard2.activate { User.create } }

        let(:base) { User.where(id: [user_s1, user_s2]) }
        let(:base_s1) { @shard1.activate { User.where(id: [user_s1, user_s2]) } }
        let(:base_s2) { @shard2.activate { User.where(id: [user_s1, user_s2]) } }

        include_examples "query creation sharding"
      end
    end

    describe "touch_all_skip_locked" do
      before :once do
        @course1 = Course.create!(name: "course 1")
        @course2 = Course.create!(name: "course 2")
        @relation = Course.where(id: [@course1.id, @course2.id])
      end

      it "uses 'SKIP LOCKED' lock" do
        Timecop.freeze do
          now = Time.now.utc
          expect(@relation).to receive(:update_all_locked_in_order).with(updated_at: now, lock_type: :no_key_update_skip_locked)
          @relation.touch_all_skip_locked
        end
      end

      it "updates the updated_at timestamp on provided relation" do
        Timecop.freeze do
          @relation.touch_all_skip_locked
          expect(@course1.reload.updated_at).to eq Time.now.utc
          expect(@course2.reload.updated_at).to eq Time.now.utc
        end
      end
    end
  end

  describe "ConnectionAdapters" do
    describe "SchemaStatements" do
      it "finds the name of a foreign key on the default column" do
        fk_name = ActiveRecord::Migration.find_foreign_key(:enrollments, :users)
        expect(fk_name).to eq("fk_rails_e860e0e46b")
      end

      it "finds the name of a foreign key on a specific column" do
        fk_name = ActiveRecord::Migration.find_foreign_key(:accounts, :outcome_imports,
                                                           column: "latest_outcome_import_id")
        expect(fk_name).to eq("fk_rails_3f0c8923c0")
      end

      it "does not find a foreign key if there is not one" do
        fk_name = ActiveRecord::Migration.find_foreign_key(:users, :courses)
        other_fk_name = ActiveRecord::Migration.find_foreign_key(:users, :users)
        expect(fk_name).to be_nil
        expect(other_fk_name).to be_nil
      end

      it "does not find a foreign key on a column that is not one" do
        fk_name = ActiveRecord::Migration.find_foreign_key(:users, :pseudonyms, column: "time_zone")
        expect(fk_name).to be_nil
      end

      it "does not crash on a non-existant column" do
        fk_name = ActiveRecord::Migration.find_foreign_key(:users, :pseudonyms, column: "notacolumn")
        expect(fk_name).to be_nil
      end

      it "does not crash on a non-existant table" do
        fk_name = ActiveRecord::Migration.find_foreign_key(:notatable, :users)
        other_fk_name = ActiveRecord::Migration.find_foreign_key(:users, :notatable)
        expect(fk_name).to be_nil
        expect(other_fk_name).to be_nil
      end

      it "actually renames foreign keys" do
        old_name = User.connection.find_foreign_key(:user_services, :users)
        User.connection.alter_constraint(:user_services, old_name, new_name: "test")
        expect(User.connection.find_foreign_key(:user_services, :users)).to eq "test"
      end

      it "allows if_not_exists on add_index" do
        expect { User.connection.add_index(:enrollments, :user_id, if_not_exists: true) }.not_to raise_exception
      end

      it "allows if_not_exists on add_column" do
        expect { User.connection.add_column(:enrollments, :user_id, :bigint, if_not_exists: true) }.not_to raise_exception
      end

      it "allows if_not_exists on add_foreign_key" do
        expect { User.connection.add_foreign_key(:enrollments, :users, if_not_exists: true) }.not_to raise_exception
      end

      it "add_foreign_key automatically validates an invalid constraint with delay_validation" do
        expect do
          User.connection.remove_foreign_key(:enrollments, column: :user_id)
          User.connection.add_foreign_key(:enrollments, :users, validate: false)
          # so that delay_validation doesn't get ignored
          allow(User.connection).to receive(:open_transactions).and_return(0)
          User.connection.add_foreign_key(:enrollments, :users, delay_validation: true)
        end.not_to raise_exception
      end

      it "remove_foreign_key allows if_exists" do
        expect { User.connection.remove_foreign_key(:discussion_topics, :conversations, if_exists: true) }.not_to raise_exception
      end

      it "remove_foreign_key allows column and if_exists" do
        expect { User.connection.remove_foreign_key(:enrollments, column: :associated_user_id, if_exists: true) }.not_to raise_exception
      end

      it "foreign_key_for prefers a 'bare' FK first" do
        expect(User.connection.foreign_key_for(:enrollments, to_table: :users).column).to eq "user_id"
      end

      it "remove_index allows if_exists" do
        expect { User.connection.remove_index(:users, column: :non_existent, if_exists: true) }.not_to raise_exception
      end

      it "remove_index by name allows if_exists" do
        expect { User.connection.remove_index(:users, name: :lti_id, if_exists: true) }.not_to raise_exception
      end
    end
  end
end

describe ActiveRecord::ConnectionAdapters::SchemaStatements do
  describe ".add_replica_identity" do
    subject { test_adapter_instance.add_replica_identity model_name, field_name, new_default_column_value }

    let(:model_name) { "Example" }
    let(:field_name) { :test_field }
    let(:existing_default_column_value) { nil }
    let(:new_default_column_value) { "test default value" }

    let(:example_model) do
      Class.new(ActiveRecord::Base) do
        self.table_name = "examples"

        def self.exists?; end
      end
    end

    let(:example_column) do
      Class.new(ActiveRecord::ConnectionAdapters::Column)
    end

    let(:test_adapter) do
      Class.new do
        include ActiveRecord::ConnectionAdapters::SchemaStatements

        @column_definitions = Hash.new { |h, k| h[k] = {} }
        class << self
          attr_reader :column_definitions
        end

        def initialize
          super
          @column_definitions = self.class.column_definitions
        end

        def self.define_column(table_name, field, column)
          @column_definitions[table_name][field] = column
        end

        def column_definitions(table_name)
          @column_definitions[table_name].keys
        end

        def new_column_from_field(table_name, field)
          @column_definitions[table_name][field]
        end

        def change_column_null(*args); end

        def add_index(*args); end

        # rubocop:disable Naming/AccessorMethodName we're implementing a module method here
        def set_replica_identity(*args); end
        # rubocop:enable Naming/AccessorMethodName
      end
    end

    let(:test_adapter_instance) { test_adapter.new }

    before do
      stub_const(model_name, example_model)
      stub_const("TestColumn", example_column)

      existing_column = TestColumn.new(field_name.to_s, existing_default_column_value)
      test_adapter.define_column(Example.table_name, field_name, existing_column)

      allow(DataFixup::BackfillNulls).to receive(:run)
    end

    it "adds an index" do
      index_name = "index_#{Example.table_name}_replica_identity"
      expect(test_adapter_instance).to receive(:add_index) do |table_name, column_name, **options|
        raise "incorrect table name #{table_name}" unless table_name == Example.table_name
        raise "incorrect column name #{column_name}" unless column_name == [field_name, Example.primary_key]
        raise "index isn't unique" unless options[:unique]
        raise "incorrect index name #{options[:name]}" unless options[:name] == index_name
      end
      subject
    end

    it "sets the replica identity" do
      index_name = "index_#{Example.table_name}_replica_identity"
      expect(test_adapter_instance).to receive(:set_replica_identity).with(Example.table_name, index_name)
      subject
    end

    context "when the column is nullable" do
      it "backfills nulls with the new default value" do
        expect(DataFixup::BackfillNulls).to receive(:run).with(Example, field_name, default_value: new_default_column_value)
        subject
      end

      it "sets the field to not be nullable" do
        expect(test_adapter_instance).to receive(:change_column_null).with(Example.table_name, field_name, false)
        subject
      end
    end

    context "when the column is not nullable" do
      before do
        existing_column = TestColumn.new(field_name.to_s, existing_default_column_value, nil, false)
        test_adapter.define_column(Example.table_name, field_name, existing_column)
      end

      it "does not run a backfill of null values" do
        expect(DataFixup::BackfillNulls).not_to receive(:run)
        subject
      end
    end

    context "on an existing table" do
      before do
        allow(Example).to receive(:exists?).and_return(true)
      end

      it "adds the index with algorithm: concurrently" do
        expect(test_adapter_instance).to receive(:add_index) do |_table_name, _field_name, **options|
          raise "didn't add index with algorithm: :concurrently" unless options[:algorithm] == :concurrently
        end
        subject
      end
    end

    context "on a new table" do
      before do
        allow(Example).to receive(:exists?).and_return(false)
      end

      it "does not require the migration run outside of a transaction" do
        expect(test_adapter_instance).to receive(:add_index) do |_table_name, _field_name, **options|
          raise "added index with algorithm: :concurrently" if options[:algorithm] == :concurrently
        end
        subject
      end
    end
  end
end

describe ActiveRecord::Migration::CommandRecorder do
  it "reverses if_exists/if_not_exists" do
    recorder = ActiveRecord::Migration::CommandRecorder.new
    r = recorder
    recorder.revert do
      r.add_column :accounts, :course_template_id, :integer, limit: 8, if_not_exists: true
      r.add_foreign_key :accounts, :courses, column: :course_template_id, if_not_exists: true
      r.add_index :accounts, :course_template_id, algorithm: :concurrently, if_not_exists: true

      r.remove_column :courses, :id, :integer, limit: 8, if_exists: true
      r.remove_foreign_key :enrollments, :users, if_exists: true
      r.remove_index :accounts, :id, if_exists: true
    end
    expect(recorder.commands).to eq([
                                      [:add_index, [:accounts, :id, { if_not_exists: true }]],
                                      [:add_foreign_key, [:enrollments, :users, { if_not_exists: true }]],
                                      [:add_column, [:courses, :id, :integer, { limit: 8, if_not_exists: true }], nil],
                                      [:remove_index, [:accounts, :course_template_id, { algorithm: :concurrently, if_exists: true }], nil],
                                      [:remove_foreign_key, [:accounts, :courses, { column: :course_template_id, if_exists: true }], nil],
                                      [:remove_column, [:accounts, :course_template_id, :integer, { limit: 8, if_exists: true }], nil],
                                    ])
  end
end
