require File.expand_path('../spec_helper', File.dirname( __FILE__ ))

module ActiveRecord
  describe Base do

    describe '.wildcard' do
      it 'produces a useful wildcard sql string' do
        sql = Base.wildcard('users.name', 'users.short_name', 'Sinatra, Frank', {:delimiter => ','})
        sql.should == "(LOWER(',' || users.name || ',') LIKE '%,sinatra, frank,%' OR LOWER(',' || users.short_name || ',') LIKE '%,sinatra, frank,%')"
      end
    end

    describe '.wildcard_pattern' do
      it 'downcases the query string' do
        Base.wildcard_pattern('SomeString').should include('somestring')
      end

      it 'escapes special characters in the query' do
        %w(% _).each do |char|
          Base.wildcard_pattern('some' << char << 'string').should include('some\\' << char << 'string')
        end
      end

      it 'bases modulos on either end of the query per the configured type' do
        {:full => '%somestring%', :left => '%somestring', :right => 'somestring%'}.each do |type, result|
          Base.wildcard_pattern('somestring', :type => type).should == result
        end
      end
    end

    describe ".coalesced_wildcard" do
      it 'produces a useful wildcard string for a coalesced index' do
        sql = Base.coalesced_wildcard('users.name', 'users.short_name', 'Sinatra, Frank')
        sql.should == "((COALESCE(LOWER(users.name), '') || ' ' || COALESCE(LOWER(users.short_name), '')) LIKE '%sinatra, frank%')"
      end
    end

    describe ".coalesce_chain" do
      it "chains together many columns for combined matching" do
        sql = Base.coalesce_chain(["foo.bar", "foo.baz", "foo.bang"])
        sql.should == "(COALESCE(LOWER(foo.bar), '') || ' ' || COALESCE(LOWER(foo.baz), '') || ' ' || COALESCE(LOWER(foo.bang), ''))"
      end
    end

    describe "find_in_batches" do
      describe "with cursor" do
        before do
          pending "needs PostgreSQL" unless Account.connection.adapter_name == 'PostgreSQL'
        end

        it "should iterate through all selected rows" do
          users = Set.new
          3.times { users << user_model }
          found = Set.new
          User.connection.cache { User.find_each(batch_size: 1) { |u| found << u } }
          found.should == users
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

      end
    end

    describe "deconstruct_joins" do
      describe "delete_all" do
        it "should allow delete all on inner join with alias" do
          User.create(name: 'dr who')
          User.create(name: 'dr who')

          expect { User.joins("INNER JOIN users u ON users.sortable_name = u.sortable_name").
            where("u.sortable_name <> users.sortable_name").delete_all }.to_not raise_error
        end
      end
    end

  end
end
