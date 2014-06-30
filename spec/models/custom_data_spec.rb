#
# Copyright (C) 2011 Instructure, Inc.
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

describe CustomData do
  before :once do
    custom_data_model
  end

  context "#get_data" do
    it "returns the same data that was set" do
      str = 'lol hi'
      @custom_data.set_data(nil, str)
      @custom_data.get_data(nil).should eql str

      hsh = {'lol'=>'hi', 'wut'=>'bye'}
      @custom_data.set_data(nil, hsh)
      @custom_data.get_data(nil).should eql hsh

      @custom_data.set_data('kewl/skope', str)
      @custom_data.get_data('kewl/skope').should eql str
    end

    it "recognizes sub-scopes of previously-set data" do
      @custom_data.set_data('kewl/skope', {'lol'=> {'wut'=>'ohai'} })
      @custom_data.get_data('kewl/skope/lol/wut').should eql 'ohai'
    end

    it "returns sub-scopes when a wide scope is requested" do
      @custom_data.set_data('kewl/skope', {'lol'=> {'wut'=>'ohai'} })
      @custom_data.get_data('kewl').should eql({'skope'=> {'lol'=> {'wut'=>'ohai'} } })
    end

    it "raises ArgumentError for non-existing scopes" do
      @custom_data.set_data('kewl/skope', {'lol'=> {'wut'=>'ohai'} })
      lambda { @custom_data.get_data('no/data/here') }.should raise_error(ArgumentError)
    end
  end

  context "#set_data" do
    it "raises a WriteConflict when the requested scope is invalid" do
      @custom_data.set_data('kewl/skope', 'ohai')
      lambda { @custom_data.set_data('kewl/skope/plus/more', 'bad idea dood') }.should raise_error(CustomData::WriteConflict)
    end
  end

  context "#delete_data" do
    it "deletes values" do
      @custom_data.set_data(nil, {'a'=>1, 'b'=>2, 'c'=>3})
      @custom_data.delete_data('a').should eql 1
      @custom_data.get_data(nil).should eql({'b'=>2, 'c'=>3})
    end

    it "cleans up empty JSON Objects if they result from value removal" do
      @custom_data.set_data(nil, {'a'=> {'b'=> {'c'=>'bonjour!'}}, 'croissant'=>'merci!'})
      @custom_data.delete_data('a/b/c').should eql 'bonjour!'
      @custom_data.get_data(nil).should eql({'croissant'=>'merci!'})
    end

    it "destroys the entire record if all of its data is removed" do
      @custom_data.set_data(nil, {'a'=> {'b'=> {'c'=>'bonjour!'}}})
      @custom_data.delete_data('a/b/c').should eql 'bonjour!'
      @custom_data.destroyed?.should be_true
    end

    it "raises ArgumentError for non-existing scopes" do
      @custom_data.set_data(nil, {'a'=>1, 'b'=>2, 'c'=>3})
      lambda { @custom_data.delete_data('d') }.should raise_error(ArgumentError)
    end
  end
end
