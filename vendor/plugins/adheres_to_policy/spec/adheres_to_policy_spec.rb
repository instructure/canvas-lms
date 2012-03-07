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

require 'rubygems'
require 'spec'
require File.join(File.dirname(__FILE__), "/../lib/adheres_to_policy")

include ::Instructure::AdheresToPolicy

describe Policy, "set_policy" do

  before(:each) do
    class AnotherModel
      extend ClassMethods
    end
  end

  after(:each) do
    Object.send(:remove_const, :AnotherModel)
  end

  it "should take a block" do
    lambda{ class AnotherModel
      set_policy { 1 + 1 }
    end }.should_not raise_error
  end

  it "should allow multiple calls" do
    lambda{ class AnotherModel
      3.times do
        set_policy { 1 + 1 }
      end
    end }.should_not raise_error
  end
end

describe ClassMethods do
  before(:each) do
    class A
      extend ClassMethods
    end
  end

  after(:each) do
    Object.send(:remove_const, :A)
  end

  it "should filter policy_block through a block filter with set_policy" do
    A.methods.should be_include("set_policy")
    lambda {A.set_policy(1)}.should raise_error
    b = lambda {1}
    lambda {A.set_policy(&b)}.should_not raise_error
  end

  it "should use set_permissions as set_policy" do
    A.methods.should be_include("set_permissions")
    lambda {A.set_permissions(1)}.should raise_error
    b = lambda {1}
    lambda {A.set_permissions(&b)}.should_not raise_error
  end

  it "should provide a Policy instance through policy" do
    A.set_policy { 1 }
    A.policy.should be_is_a(Policy)
  end

  it "should continue to use the same Policy instance (an important check, since this is also a constructor)" do
    A.set_policy { 1 }
    A.policy.should eql(A.policy)
  end

  it "should apply all given policy blocks to the Policy instance" do
    A.set_policy do
      given { |user| true }
      can :read
    end

    A.set_policy do
      given { |user| true }
      can :write
    end

    a = A.new
    a.check_policy(nil).should == [:read, :write]
  end
end

describe InstanceMethods do
  before(:all) do
    class A
      attr_accessor :user
      extend ClassMethods
      set_policy do
        given { |user| self.user == user }
        can :read
      end
    end
  end

  before(:each) do
    @a = A.new
  end

  after(:each) do
    Object.send(:remove_const, :B) if Object.send(:const_defined?, :B)
  end

  it "should have setup a series of methods on the instance" do
    %w(check_policy grants_rights? has_rights?).each do |method|
      @a.methods.should be_include(method)
    end
  end

  it "should be able to check a policy" do
    @a.user = 1
    @a.check_policy(1).should eql([:read])
  end

  it "should allow multiple forms of can statements" do
    class B
      extend Policy::ClassMethods
      set_policy do
        given { |user| user == 1}
        can :read and can :write

        given { |user| user == 2}
        can :update, :delete

        given { |user| user == 3}
        can [:manage, :set_permissions]
      end
    end

    b = B.new
    b.check_policy(1).should == [:read, :write]
    b.check_policy(2).should == [:update, :delete]
    b.check_policy(3).should == [:manage, :set_permissions]
  end

  it "should execute all conditions when searching for all rights" do
    class B
      attr_accessor :total
      extend Policy::ClassMethods
      def initialize
        @total = 0
      end

      set_policy do
        given { |user| @total = @total + 1}
        can :read

        given { |user| @total = @total + 1}
        can :write

        given { |user| @total = @total + 1}
        can :update
      end
    end

    b = B.new
    b.check_policy(nil).should == [:read, :write, :update]
    b.total.should == 3
  end

  it "should skip duplicate conditions when searching for all rights" do
    class B
      attr_accessor :total
      extend ClassMethods
      def initialize
        @total = 0
      end

      set_policy do
        given { |user| @total = @total + 1}
        can :read, :write

        given { |user| raise "don't execute me" }
        can :write

        given { |user| @total = @total + 1}
        can :update
      end
    end

    b = B.new
    b.check_policy(nil).should == [:read, :write, :update]
    b.total.should == 2
  end

  it "should only execute relevant conditions when searching for specific rights" do
    class B
      attr_accessor :total
      extend ClassMethods
      def initialize
        @total = 0
      end

      set_policy do
        given { |user| @total = @total + 1}
        can :read

        given { |user| raise "don't execute me" }
        can :write

        given { |user| raise "me either" }
        can :update
      end
    end

    b = B.new
    b.check_policy(nil, nil, :read).should == [:read]
    b.total.should == 1
  end

  it "should skip duplicate conditions when searching for specific rights" do
    class B
      attr_accessor :total
      extend ClassMethods
      def initialize
        @total = 0
      end

      set_policy do
        given { |user| @total = @total + 1}
        can :read

        given { |user| @total = @total + 1 }
        can :write

        given { |user| raise "me either" }
        can :read and can :write
      end
    end

    b = B.new
    b.check_policy(nil, nil, :read, :write).should == [:read, :write]
    b.total.should == 2
  end

  after(:all) do
    Object.send(:remove_const, :A)
  end
end
