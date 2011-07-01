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

describe UserList do
  
  it "should process a list of emails" do
    UserList.new(regular).addresses.should eql([TMail::Address.parse(%{"Shaw, Ryan" <ryankshaw@gmail.com>}), TMail::Address.parse(%{"Last, First" <lastfirst@gmail.com>})])
  end
  
  it "should process a list of only emails, without brackets" do
    UserList.new(without_brackets).addresses.should eql([TMail::Address.parse("ryankshaw@gmail.com"), TMail::Address.parse("lastfirst@gmail.com")])
  end
  
  it "should not break on commas inside of single quotes" do
    s = regular.gsub(/"/, "'")
    UserList.new(s).addresses.should eql([TMail::Address.parse(%{"Shaw, Ryan" <ryankshaw@gmail.com>}), TMail::Address.parse(%{"Last, First" <lastfirst@gmail.com>})])
  end
  
  it "should work with a mixed entry list" do
    s = regular + "," + %{otherryankshaw@gmail.com, otherlastfirst@gmail.com}
    UserList.new(s).addresses.should eql([
        TMail::Address.parse(%{"Shaw, Ryan" <ryankshaw@gmail.com>}), 
        TMail::Address.parse(%{"Last, First" <lastfirst@gmail.com>}), 
        TMail::Address.parse("otherryankshaw@gmail.com"), 
        TMail::Address.parse("otherlastfirst@gmail.com")
      ])
  end
  
  it "should work well with a single address" do
    UserList.new('ryankshaw@gmail.com').addresses.should eql([TMail::Address.parse('ryankshaw@gmail.com')])
  end
  
  it "should remove duplicates" do
    s = regular + "," + without_brackets
    UserList.new(s).addresses.should eql([
        TMail::Address.parse(%{"Shaw, Ryan" <ryankshaw@gmail.com>}), 
        TMail::Address.parse(%{"Last, First" <lastfirst@gmail.com>})
      ])
    UserList.new(s).duplicates.should eql([
        TMail::Address.parse("ryankshaw@gmail.com"), 
        TMail::Address.parse("lastfirst@gmail.com")
      ])
  end
end

def regular
  %{"Shaw, Ryan" <ryankshaw@gmail.com>, "Last, First" <lastfirst@gmail.com>}
end

def without_brackets
  %{ryankshaw@gmail.com, lastfirst@gmail.com}
end
