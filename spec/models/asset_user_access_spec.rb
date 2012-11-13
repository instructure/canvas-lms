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

describe AssetUserAccess do
  before :each do
    @course = Account.default.courses.create!(:name => 'My Course')
    @assignment = @course.assignments.create!(:title => 'My Assignment')
    @user = User.create!

    @asset = factory_with_protected_attributes(AssetUserAccess, :user => @user, :context => @course, :asset_code => @assignment.asset_string)
    @asset.display_name = @assignment.asset_string
    @asset.save!
  end

  it "should update existing records that have bad display names" do
    @asset.display_name.should == "My Assignment"
  end

  describe "for_user" do
    it "should work with a User object" do
      AssetUserAccess.for_user(@user).should == [@asset]
    end

    it "should work with a list of User objects" do
      AssetUserAccess.for_user([@user]).should == [@asset]
    end

    it "should work with a User id" do
      AssetUserAccess.for_user(@user.id).should == [@asset]
    end

    it "should work with a list of User ids" do
      AssetUserAccess.for_user([@user.id]).should == [@asset]
    end

    it "should with with an empty list" do
      AssetUserAccess.for_user([]).should == []
    end

    it "should not find unrelated accesses" do
      AssetUserAccess.for_user(User.create!).should == []
      AssetUserAccess.for_user(@user.id + 1).should == []
    end
  end
end
