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
    end

  end
end
