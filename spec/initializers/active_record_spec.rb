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
      end

      describe "with temp table" do
        it "should use a temp table when you select without an id" do
          User.create!
          User.select(:name).find_in_batches do |batch|
            User.connection.select_value("SELECT COUNT(*) FROM users_find_in_batches_temp_table_#{User.select(:name).to_sql.hash.abs.to_s(36)}")
          end
        end

        it "should not use a temp table for a plain query" do
          User.create!
          User.find_in_batches do |batch|
            expect { User.connection.select_value("SELECT COUNT(*) FROM users_find_in_batches_temp_table_#{User.scoped.to_sql.hash.abs.to_s(36)}") }.to raise_error
          end
        end

        it "should not use a temp table for a select with id" do
          User.create!
          User.select(:id).find_in_batches do |batch|
            expect { User.connection.select_value("SELECT COUNT(*) FROM users_find_in_batches_temp_table_#{User.select(:id).to_sql.hash.abs.to_s(36)}") }.to raise_error
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

  describe Relation do
    describe "lock_with_exclusive_smarts" do
      let(:scope){ User.active }

      context "with postgres 90300" do
        before do
          scope.connection.stubs(:postgresql_version).returns(90300)
        end

        it "uses FOR UPDATE on a normal exclusive lock" do
          scope.expects(:lock_without_exclusive_smarts).with(true)
          scope.lock(true)
        end

        it "substitutes 'FOR NO KEY UPDATE' if specified" do
          scope.expects(:lock_without_exclusive_smarts).with("FOR NO KEY UPDATE")
          scope.lock(:no_key_update)
        end
      end

      context "with postgres 90299" do
        before do
          scope.connection.stubs(:postgresql_version).returns(90299)
        end

        it "uses FOR UPDATE on a normal exclusive lock" do
          scope.expects(:lock_without_exclusive_smarts).with(true)
          scope.lock(true)
        end

        it "ignores 'FOR NO KEY UPDATE' if specified" do
          scope.expects(:lock_without_exclusive_smarts).with(true)
          scope.lock(:no_key_update)
        end
      end
    end

    describe "union" do
      shared_examples_for "query creation" do
        it "should include conditions after the union inside of the subquery" do
          wheres = base.active.where(id:99).union(User.where(id:1)).where_values
          expect(wheres.count).to eq 1
          sql_before_union, sql_after_union = wheres.first.split("UNION ALL")
          expect(sql_before_union.include?("99")).to be_falsey
          expect(sql_after_union.include?("99")).to be_truthy
        end

        it "should include conditions prior to the union outside of the subquery" do
          wheres = base.active.union(User.where(id:1)).where(id:99).where_values
          expect(wheres.count).to eq 2
          union_where = wheres.detect{|w| w.is_a?(String) && w.include?("UNION ALL")}
          expect(union_where.include?("99")).to be_falsey
        end
      end

      context "directly on the table" do
        include_examples "query creation"
        let(:base) { User.active }
      end

      context "through a relation" do
        include_examples "query creation"
        a = Account.create!
        let(:base) { Account.find(a.id).users }
      end
    end
  end
end
