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
  
  before(:each) do
    account_model
  end
  
  it "should process a list of emails" do
    ul = UserList.new(regular)
    ul.addresses.map{|x| [x.name, x.address]}.should eql([
        ["Shaw, Ryan", "ryankshaw@gmail.com"],
        ["Last, First", "lastfirst@gmail.com"]])
    ul.errors.should == []
    ul.duplicate_addresses.should == []
    ul.duplicate_logins.should == []
    ul.logins.should == []
  end
  
  it "should process a list of only emails, without brackets" do
    ul = UserList.new without_brackets
    ul.addresses.map{|x| [x.name, x.address]}.should eql([
        [nil, "ryankshaw@gmail.com"],
        [nil, "lastfirst@gmail.com"]])
    ul.errors.should == []
    ul.duplicate_addresses.should == []
    ul.duplicate_logins.should == []
    ul.logins.should == []
  end
  
  it "should work with a mixed entry list" do
    ul = UserList.new regular + "," + %{otherryankshaw@gmail.com, otherlastfirst@gmail.com}
    ul.addresses.map{|x| [x.name, x.address]}.should eql([
        ["Shaw, Ryan", "ryankshaw@gmail.com"],
        ["Last, First", "lastfirst@gmail.com"],
        [nil, "otherryankshaw@gmail.com"],
        [nil, "otherlastfirst@gmail.com"]])
    ul.errors.should == []
    ul.duplicate_addresses.should == []
    ul.duplicate_logins.should == []
    ul.logins.should == []
  end
  
  it "should work well with a single address" do
    ul = UserList.new('ryankshaw@gmail.com')
    ul.addresses.map{|x| [x.name, x.address]}.should eql([
        [nil, "ryankshaw@gmail.com"]])
    ul.errors.should == []
    ul.duplicate_addresses.should == []
    ul.duplicate_logins.should == []
    ul.logins.should == []
  end
  
  it "should remove duplicates" do
    @account.pseudonyms.create!(:unique_id => "A123451").assert_user
    @account.pseudonyms.create!(:unique_id => "user3").assert_user
    ul = UserList.new regular + "," + without_brackets + ", A123451, user3", @account
    ul.addresses.map{|x| [x.name, x.address]}.should eql([
        ["Shaw, Ryan", "ryankshaw@gmail.com"],
        ["Last, First", "lastfirst@gmail.com"]])
    ul.errors.should == []
    ul.duplicate_addresses.map{|x| [x.name, x.address]}.should eql([
        [nil, "ryankshaw@gmail.com"],
        [nil, "lastfirst@gmail.com"]])
    ul.duplicate_logins.should == []
    ul.logins.should == [{:login=>"A123451", :name=>"User"}, {:login=>"user3", :name=>"User"}]

    ul = UserList.new regular + ",A123451 ,user3 ," + without_brackets + ", A123451, user3", @account
    ul.addresses.map{|x| [x.name, x.address]}.should eql([
        ["Shaw, Ryan", "ryankshaw@gmail.com"],
        ["Last, First", "lastfirst@gmail.com"]])
    ul.errors.should == []
    ul.duplicate_addresses.map{|x| [x.name, x.address]}.should eql([
        [nil, "ryankshaw@gmail.com"],
        [nil, "lastfirst@gmail.com"]])
    ul.duplicate_logins.should == [{:login=>"A123451"}, {:login=>"user3"}]
    ul.logins.should == [{:login=>"A123451", :name=>"User"}, {:login=>"user3", :name=>"User"}]
  end
  
  it "should process login ids and email addresses" do
    @account.pseudonyms.create!(:unique_id => "user1").assert_user
    @account.pseudonyms.create!(:unique_id => "A112351243").assert_user
    ul = UserList.new regular + "," + %{user1,test@example.com,A112351243,"thomas walsh" <test2@example.com>, "walsh, thomas" <test3@example.com>}, @account
    ul.addresses.map{|x| [x.name, x.address]}.should eql([
        ["Shaw, Ryan", "ryankshaw@gmail.com"],
        ["Last, First", "lastfirst@gmail.com"],
        [nil, "test@example.com"],
        ["thomas walsh", "test2@example.com"],
        ["walsh, thomas", "test3@example.com"]])
    ul.errors.should == []
    ul.duplicate_addresses.should == []
    ul.duplicate_logins.should == []
    ul.logins.should == [{:login=>"user1", :name=>"User"}, {:login=>"A112351243", :name=>"User"}]
  end
  
  it "should only add login ids that are existing unique ids" do
    @account.pseudonyms.create!(:unique_id => "user1").assert_user
    @account.pseudonyms.create!(:unique_id => "user2").assert_user
    ul = UserList.new "user1,user2,user3", @account
    ul.addresses.should == []
    ul.errors.should == ["user3"]
    ul.duplicate_addresses.should == []
    ul.duplicate_logins.should == []
    ul.logins.should == [{:login=>"user1", :name=>"User"}, {:login=>"user2", :name=>"User"}]
  end
end

def regular
  %{"Shaw, Ryan" <ryankshaw@gmail.com>, "Last, First" <lastfirst@gmail.com>}
end

def without_brackets
  %{ryankshaw@gmail.com, lastfirst@gmail.com}
end
