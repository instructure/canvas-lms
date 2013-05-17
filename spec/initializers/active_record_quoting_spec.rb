require File.expand_path('../spec_helper', File.dirname( __FILE__ ))

module ActiveRecord
  module ConnectionAdapters
    describe PostgreSQLAdapter do
      describe 'quoting' do
        # These tests are adapted from the ActiveRecord tests located here:
        # https://github.com/rails/rails/blob/06c23c4c7ff842f7c6237f3ac43fc9d19509a947/activerecord/test/cases/adapters/postgresql/quoting_test.rb
        before do 
          @conn = ActiveRecord::Base.connection
        end

        it 'properly quotes NaN' do
          nan = 0.0/0
          c = Column.new(nil, 1, 'float')
          assert_equal "'NaN'", @conn.quote(nan, c)
        end

        it 'properly quotes Infinity' do
          infinity = 1.0/0
          c = Column.new(nil, 1, 'float')
          assert_equal "'Infinity'", @conn.quote(infinity, c)
        end
      end
    end
  end
end
