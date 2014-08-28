#
# Copyright (C) 2014 Instructure, Inc.
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
# You have received a copy of the GNU Affero General Public License along
# with this program. If not, see <http://www.gnu.org/licenses/>.
#

require 'spec_helper'

describe EventStream::AttrConfig do
  before do
    @class = Class.new do
      include EventStream::AttrConfig

      def initialize(opts={})
        # assumes the class has had attr_config :field declared. but that
        # declaration will happen during specs since it varies
        field(opts[:field]) if opts.has_key?(:field)
        attr_config_validate
      end
    end
  end

  describe "attr_config" do
    it "creates dual accessor method" do
      @class.attr_config :field, :default => nil
      value = double('value')
      obj = @class.new
      obj.field(value)
      obj.field.== value
    end

    it "errors on accessor with > 1 args" do
      @class.attr_config :field, :default => nil
      obj = @class.new
      expect {
        obj.field(1, 2)
      }.to raise_exception ArgumentError
    end

    it "allows defaults" do
      value = double('value')
      @class.attr_config :field, :default => value
      obj = @class.new
      obj.field.== value
    end

    it "casts values with type String" do
      @class.attr_config :field, :type => String, :default => nil
      string = double('value')
      value = double(:to_s => string)
      obj = @class.new
      obj.field(value)
      obj.field.== string
    end

    it "casts values with type Fixnum" do
      @class.attr_config :field, :type => Fixnum, :default => nil
      integer = double('value')
      value = double(:to_i => integer)
      obj = @class.new
      obj.field(value)
      obj.field.== integer
    end

    it "casts values with type Proc" do
      @class.attr_config :field, :type => Proc, :default => nil
      value = -> { 'value' }
      obj = @class.new
      obj.field(value)
      obj.field.== value
    end

    it "errors when expecting a Proc" do
      @class.attr_config :field, :type => Proc, :default => nil
      obj = @class.new

      # skips casting nil
      obj.field(nil)
      expect(obj.field).to be_nil

      expect {
        obj.field('value')
      }.to raise_exception ArgumentError
    end

    it "errors when Proc does not return the expected type" do
      @class.attr_config :field, :type => Fixnum, :default => nil
      obj = @class.new
      value = -> { [] }
      obj.field(value)

      expect {
        obj.field
      }.to raise_exception NoMethodError
    end

    it "skips cast with unknown type" do
      @class.attr_config :field, :type => double('unknown'), :default => nil
      value = double('value')
      obj = @class.new
      obj.field(value)
      obj.field.== value
    end

    it "casts defaults with type" do
      string = double('value')
      value = double(:to_s => string)
      @class.attr_config :field, :type => String, :default => value
      obj = @class.new
      obj.field.== string
    end

    it "does not cast defaults with unknown type" do
      value = double('value')
      @class.attr_config :field, :type => double('unknown'), :default => value
      obj = @class.new
      obj.field.== value
    end

    it "requires setting non-defaulted fields before validation" do
      value = double('value')
      @class.attr_config :field
      obj = @class.new(:field => value)
      obj.field.== value
      expect {
        @class.new
      }.to raise_exception ArgumentError
    end

    it "runs the value when its a Proc" do
      @class.attr_config :field, :default => nil
      value = -> { 'value' }
      obj = @class.new(:field => value)
      expect(obj.field).to eq 'value'
    end

    it "requires a value when a Proc is used when the field is required" do
      @class.attr_config :field
      value = -> {}
      obj = @class.new(:field => value)
      expect {
        obj.field
      }.to raise_exception ArgumentError
    end
  end
end
