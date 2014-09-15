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

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper.rb')

describe Profile do
  context "sub-classing" do
    before(:all) do
      class FooProfile < Profile; end

      class Foo < ActiveRecord::Base
        self.table_name = :users
        include Profile::Association
        def root_account; Account.default; end
      end
    end

    after(:all) do
      Object.send(:remove_const, :FooProfile)
      Object.send(:remove_const, :Foo)
    end

    describe "initialization" do
      it "should be set by default" do
        Foo.new.profile.should_not be_nil
      end

      it "should have the correct class when initialized" do
        Foo.new.profile.class.should == FooProfile
      end

      it "should have the correct class when found" do
        Foo.new(:name => "foo", :workflow_state => 'registered').profile.save!
        Profile.all.first.class.should == FooProfile
      end
    end

    describe ".path" do
      it "should be inferred from the title" do
        profile = Foo.create!(:name => "My Foo!", :workflow_state => 'registered').profile
        profile.path.should == "my-foo"
        profile.save!

        profile2 = Foo.create!(:name => "My Foo?!!!", :workflow_state => 'registered').profile
        profile2.path.should == "my-foo-1"
      end
    end

    describe "#data" do
      it "should add accessors" do
        FooProfile.class_eval do
          data :bar, :default => []
        end
        profile = FooProfile.new
        profile.data.should == {}
        profile.bar.should == []
        profile.data.should == {:bar => []}
        profile.bar = ["lol"]
        profile.data.should == {:bar => ["lol"]}
      end
    end
  end
end
