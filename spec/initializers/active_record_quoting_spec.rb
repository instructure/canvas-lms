require File.expand_path('../spec_helper', File.dirname( __FILE__ ))

module ActiveRecord
  module ConnectionAdapters
    if defined?(PostgreSQLAdapter)
      describe PostgreSQLAdapter do
        describe 'quoting' do
          # These tests are adapted from the ActiveRecord tests located here:
          # https://github.com/rails/rails/blob/06c23c4c7ff842f7c6237f3ac43fc9d19509a947/activerecord/test/cases/adapters/postgresql/quoting_test.rb
          before do
            @conn = ActiveRecord::Base.connection
          end

          describe "Infinity and NaN" do
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

            it 'properly quotes Infinity in a datetime column' do
              infinity = 1.0/0
              c = Column.new(nil, 1, 'datetime')
              assert_equal "'infinity'", @conn.quote(infinity, c)
            end
          end

          describe "integer enforcement" do
            before do
              @col = Column.new(nil, 1, 'integer')
            end

            it 'properly quotes Numerics' do
              assert_equal "123", @conn.quote(123, @col)
              assert_equal "100000000000000000000", @conn.quote(1e20.to_i, @col)
              assert_equal "1", @conn.quote(1.23, @col)
              assert_equal "1", @conn.quote(BigDecimal.new("1.23"), @col)
            end

            it 'properly quotes numeric Strings' do
              assert_equal "123", @conn.quote("123", @col)
              assert_equal "1", @conn.quote("1.23", @col)
            end

            it 'properly quotes Times' do
              value = Time.at(1356998400) # Jan 1, 2013 00:00 GMT
              assert_equal "1356998400", @conn.quote(value, @col)
            end

            it 'aborts quoting non-Numerics' do
              expect{ @conn.quote(:symbol, @col) }.to raise_exception(ActiveRecord::StatementInvalid)
              expect{ @conn.quote(ActiveRecord::Base, @col) }.to raise_exception(ActiveRecord::StatementInvalid)
              expect{ @conn.quote(Object.new, @col) }.to raise_exception(ActiveRecord::StatementInvalid)
            end
          end

          # check we didn't screw up default handlings
          describe "fallback to original implementation" do
            it 'properly quotes strings in xml columns' do
              value = "<value/>"
              c = Column.new(nil, 1, 'xml')
              assert_equal "xml '#{value}'", @conn.quote(value, c)
            end

            it 'properly quotes other Floats' do
              value = 1.23
              c = Column.new(nil, 1, 'float')
              assert_equal value.to_s, @conn.quote(value, c)
            end

            it 'properly quotes other non-Numerics' do
              value = "value"
              c = Column.new(nil, 1, 'string')
              assert_equal "'#{value}'", @conn.quote(value, c)
            end
          end
        end
      end
    end
  end
end
