#
# Copyright (C) 2013 Instructure, Inc.
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

require File.expand_path(File.dirname(__FILE__) + '/../../lib/attr_config.rb')

describe AttrConfig do
  before do
    @class = Class.new do
      include AttrConfig

      def initialize(opts={})
        # assumes the class has had attr_config :field declared. but that
        # declaration will happen during specs since it varies
        field(opts[:field]) if opts.has_key?(:field)
        attr_config_validate
      end
    end
  end

  describe "attr_config" do
    it "should create dual accessor method" do
      @class.attr_config :field, :default => nil
      value = stub('value')
      obj = @class.new
      obj.field(value)
      obj.field.should == value
    end

    it "should error on accessor with > 1 args" do
      @class.attr_config :field, :default => nil
      obj = @class.new
      lambda{ obj.field(1, 2) }.should raise_exception ArgumentError
    end

    it "should allow defaults" do
      value = stub('value')
      @class.attr_config :field, :default => value
      obj = @class.new
      obj.field.should == value
    end

    it "should cast values with type String" do
      @class.attr_config :field, :type => String, :default => nil
      string = stub('value')
      value = mock(:to_s => string)
      obj = @class.new
      obj.field(value)
      obj.field.should == string
    end

    it "should cast values with type Fixnum" do
      @class.attr_config :field, :type => Fixnum, :default => nil
      integer = stub('value')
      value = mock(:to_i => integer)
      obj = @class.new
      obj.field(value)
      obj.field.should == integer
    end

    it "should skip cast with unknown type" do
      @class.attr_config :field, :type => stub('unknown'), :default => nil
      value = stub('value')
      obj = @class.new
      obj.field(value)
      obj.field.should == value
    end

    it "should cast defaults with type" do
      string = stub('value')
      value = mock(:to_s => string)
      @class.attr_config :field, :type => String, :default => value
      obj = @class.new
      obj.field.should == string
    end

    it "should not cast defaults with unknown type" do
      value = stub('value')
      @class.attr_config :field, :type => stub('unknown'), :default => value
      obj = @class.new
      obj.field.should == value
    end

    it "should require setting non-defaulted fields before validation" do
      value = stub('value')
      @class.attr_config :field
      obj = @class.new(:field => value)
      obj.field.should == value
      lambda{ @class.new }.should raise_exception ArgumentError
    end
  end
end
