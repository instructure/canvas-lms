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

require File.expand_path('../spec_helper', File.dirname( __FILE__ ))

module ActiveRecord
  describe Base do

    describe '.wildcard' do
      it 'produces a useful wildcard sql string' do
        sql = Base.wildcard('users.name', 'users.short_name', 'Sinatra, Frank', {:delimiter => ','})
        expect(sql).to eq "(LOWER(',' || users.name || ',') LIKE '%,sinatra, frank,%' OR LOWER(',' || users.short_name || ',') LIKE '%,sinatra, frank,%')"
      end
    end

    describe '.wildcard_pattern' do
      it 'downcases the query string' do
        expect(Base.wildcard_pattern('SomeString')).to include('somestring')
      end

      it 'escapes special characters in the query' do
        %w(% _).each do |char|
          expect(Base.wildcard_pattern('some' << char << 'string')).to include('some\\' << char << 'string')
        end
      end

      it 'bases modulos on either end of the query per the configured type' do
        {:full => '%somestring%', :left => '%somestring', :right => 'somestring%'}.each do |type, result|
          expect(Base.wildcard_pattern('somestring', :type => type)).to eq result
        end
      end
    end

    describe ".coalesced_wildcard" do
      it 'produces a useful wildcard string for a coalesced index' do
        sql = Base.coalesced_wildcard('users.name', 'users.short_name', 'Sinatra, Frank')
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
          skip "needs PostgreSQL" unless Account.connection.adapter_name == 'PostgreSQL'
        end

        it "should iterate through all selected rows" do
          users = Set.new
          3.times { users << user_model }
          found = Set.new
          User.connection.cache { User.find_each(batch_size: 1) { |u| found << u } }
          expect(found).to eq users
        end

        it "cleans up the cursor" do
          # two cursors with the same name; if it didn't get cleaned up, it would error
          User.all.find_each {}
          User.all.find_each {}
        end

        it "cleans up the temp table for non-DB error" do
          User.create!
          # two temp tables with the same name; if it didn't get cleaned up, it would error
          expect do
            User.all.find_each do
              raise ArgumentError
            end
          end.to raise_error(ArgumentError)

          User.all.find_each {}
        end

        it "doesnt obfuscate the error when it dies in a transaction" do
          account = Account.create!
          course = account.courses.create!
          User.create!
          expect do
            ActiveRecord::Base.transaction do
              User.all.find_each do |batch|
                # to force a foreign key error
                Account.where(id: account).delete_all
              end
            end
          end.to raise_error(ActiveRecord::InvalidForeignKey)
        end
      end

      describe "with temp table" do
        around do |example|
          begin
            ActiveRecord::Base.in_migration = true
            example.run
          ensure
            ActiveRecord::Base.in_migration = false
          end
        end

        it "should use a temp table when you select without an id" do
          User.create!
          User.select(:name).find_in_batches do |batch|
            User.connection.select_value("SELECT COUNT(*) FROM users_find_in_batches_temp_table_#{User.select(:name).to_sql.hash.abs.to_s(36)}")
          end
        end

        it "should not use a temp table for a plain query" do
          User.create!
          User.find_in_batches do |batch|
            expect { User.connection.select_value("SELECT COUNT(*) FROM users_find_in_batches_temp_table_#{User.all.to_sql.hash.abs.to_s(36)}") }.to raise_error(ActiveRecord::StatementInvalid)
          end
        end

        it "should not use a temp table for a select with id" do
          User.create!
          User.select(:id).find_in_batches do |batch|
            expect { User.connection.select_value("SELECT COUNT(*) FROM users_find_in_batches_temp_table_#{User.select(:id).to_sql.hash.abs.to_s(36)}") }.to raise_error(ActiveRecord::StatementInvalid)
          end
        end

        it 'should not bomb when you try to force past the cursor option on selects with the primary key' do
          selectors = ["*", "users.*", "users.id, users.updated_at"]
          User.create!
          selectors.each do |selector|
            expect {
              User.select(selector).find_in_batches(start: 0){|batch| }
            }.not_to raise_error
          end
        end

        it "cleans up the temp table" do
          # two temp tables with the same name; if it didn't get cleaned up, it would error
          User.all.find_in_batches_with_temp_table {}
          User.all.find_in_batches_with_temp_table {}
        end

        it "cleans up the temp table for non-DB error" do
          User.create!
          # two temp tables with the same name; if it didn't get cleaned up, it would error
          expect do
            User.all.find_in_batches_with_temp_table do
              raise ArgumentError
            end
          end.to raise_error(ArgumentError)

          User.all.find_in_batches_with_temp_table {}
        end

        it "doesnt obfuscate the error when it dies in a transaction" do
          account = Account.create!
          course = account.courses.create!
          User.create!
          expect do
            ActiveRecord::Base.transaction do
              User.all.find_in_batches_with_temp_table do |batch|
                # to force a foreign key error
                Account.where(id: account).delete_all
              end
            end
          end.to raise_error(ActiveRecord::InvalidForeignKey)
        end

      end
    end

    describe "deconstruct_joins" do
      describe "delete_all" do
        it "should allow delete all on inner join with alias" do
          User.create(name: 'dr who')
          User.create(name: 'dr who')

          expect { User.joins("INNER JOIN #{User.quoted_table_name} u ON users.sortable_name = u.sortable_name").
            where("u.sortable_name <> users.sortable_name").delete_all }.to_not raise_error
        end
      end
    end

    describe "update_all with limit" do
      it "does the right thing with a join and a limit" do
        u1 = User.create!(name: 'u1')
        e1 = u1.eportfolios.create!(name: 'e1')
        u2 = User.create!(name: 'u2')
        e2 = u2.eportfolios.create!(name: 'e2')
        Eportfolio.joins(:user).order(:id).limit(1).update_all(name: 'changed')
        expect(e1.reload.name).to eq 'changed'
        expect(e2.reload.name).not_to eq 'changed'
      end
    end

    describe "parse_asset_string" do
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
  end

  describe ".asset_string" do
    it "generates a string with the reflection_type_name and id" do
      expect(User.asset_string(3)).to eq('user_3')
    end
  end

  describe Relation do
    describe "lock_with_exclusive_smarts" do
      let(:scope){ User.active }

      it "uses FOR UPDATE on a normal exclusive lock" do
        expect(scope.lock(true).lock_value).to eq true
      end

      it "substitutes 'FOR NO KEY UPDATE' if specified" do
        expect(scope.lock(:no_key_update).lock_value).to eq "FOR NO KEY UPDATE"
      end
    end

    describe "union" do
      shared_examples_for "query creation" do
        it "should include conditions after the union inside of the subquery" do
          scope = base.active.where(id:99).union(User.where(id:1))
          wheres = scope.where_clause.send(:predicates)
          expect(wheres.count).to eq 1
          sql_before_union, sql_after_union = wheres.first.split("UNION ALL")
          expect(sql_before_union.include?('"id" = 99')).to be_falsey
          expect(sql_after_union.include?('"id" = 99')).to be_truthy
        end

        it "should include conditions prior to the union outside of the subquery" do
          scope = base.active.union(User.where(id:1)).where(id:99)
          wheres = scope.where_clause.send(:predicates)
          expect(wheres.count).to eq 2
          union_where = wheres.detect{|w| w.is_a?(String) && w.include?("UNION ALL")}
          expect(union_where.include?('"id" = 99')).to be_falsey
        end
      end

      context "directly on the table" do
        include_examples "query creation"
        let(:base) { User.active }
      end

      context "through a relation" do
        include_examples "query creation"
        let(:base) { Account.create.users }
      end
    end
  end

  describe 'ConnectionAdapters' do
    describe 'SchemaStatements' do

      it 'should find the name of a foreign key on the default column' do
        fk_name = ActiveRecord::Migration.find_foreign_key(:enrollments, :users)
        expect(fk_name).to eq('fk_rails_e860e0e46b')
      end

      it 'should find the name of a foreign key on a specific column' do
        fk_name = ActiveRecord::Migration.find_foreign_key(:accounts, :outcome_imports,
                                                           column: 'latest_outcome_import_id')
        expect(fk_name).to eq('fk_rails_3f0c8923c0')
      end

      it 'should not find a foreign key if there is not one' do
        fk_name = ActiveRecord::Migration.find_foreign_key(:users, :courses)
        other_fk_name = ActiveRecord::Migration.find_foreign_key(:users, :users)
        expect(fk_name).to be_nil
        expect(other_fk_name).to be_nil
      end

      it 'should not find a foreign key on a column that is not one' do
        fk_name = ActiveRecord::Migration.find_foreign_key(:users, :pseudonyms, column: 'time_zone')
        expect(fk_name).to be_nil
      end

      it 'should not crash on a non-existant column' do
        fk_name = ActiveRecord::Migration.find_foreign_key(:users, :pseudonyms, column: 'notacolumn')
        expect(fk_name).to be_nil
      end

      it 'should not crash on a non-existant table' do
        fk_name = ActiveRecord::Migration.find_foreign_key(:notatable, :users)
        other_fk_name = ActiveRecord::Migration.find_foreign_key(:users, :notatable)
        expect(fk_name).to be_nil
        expect(fk_name).to be_nil
      end

      it 'actually renames foreign keys' do
        old_name = User.connection.find_foreign_key(:user_services, :users)
        User.connection.alter_constraint(:user_services, old_name, new_name: 'test')
        expect(User.connection.find_foreign_key(:user_services, :users)).to eq 'test'
      end
    end
  end
end
