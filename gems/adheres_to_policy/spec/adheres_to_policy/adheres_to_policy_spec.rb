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

require 'spec_helper'

describe AdheresToPolicy::Policy, "set_policy" do

  it "should take a block" do
    lambda {
      Class.new do
        extend AdheresToPolicy::ClassMethods
        set_policy { 1 + 1 }
      end
    }.should_not raise_error
  end

  it "should allow multiple calls" do
    lambda {
      Class.new do
        extend AdheresToPolicy::ClassMethods

        3.times do
          set_policy { 1 + 1 }
        end
      end
    }.should_not raise_error
  end
end

describe AdheresToPolicy::ClassMethods do
  before(:each) do
    @some_class = Class.new do
      extend AdheresToPolicy::ClassMethods
    end
  end

  it "should filter policy_block through a block filter with set_policy" do
    @some_class.should respond_to(:set_policy)
    lambda { @some_class.set_policy(1) }.should raise_error
    b = lambda { 1 }
    lambda { @some_class.set_policy(&b) }.should_not raise_error
  end

  it "should use set_permissions as set_policy" do
    @some_class.should respond_to(:set_permissions)
    lambda { @some_class.set_permissions(1) }.should raise_error
    b = lambda { 1 }
    lambda { @some_class.set_permissions(&b) }.should_not raise_error
  end

  it "should provide a Policy instance through policy" do
    @some_class.set_policy { 1 }
    @some_class.policy.should be_is_a(AdheresToPolicy::Policy)
  end

  it "should continue to use the same Policy instance (an important check, since this is also a constructor)" do
    @some_class.set_policy { 1 }
    @some_class.policy.should eql(@some_class.policy)
  end

  it "should apply all given policy blocks to the Policy instance" do
    @some_class.set_policy do
      given { |_| true }
      can :read
    end

    @some_class.set_policy do
      given { |_| true }
      can :write
    end

    some_class = @some_class.new
    some_class.check_policy(nil).should == [:read, :write]
  end
end

describe AdheresToPolicy::InstanceMethods do
  before(:each) do
    @some_class = Class.new do
      attr_accessor :user
      extend AdheresToPolicy::ClassMethods
      set_policy do
        given { |user| self.user == user }
        can :read
      end
    end

    class User
    end
  end

  it "should have setup a series of methods on the instance" do
    %w(check_policy grants_rights? has_rights?).each do |method|
      @some_class.new.should respond_to(method)
    end
  end

  it "should be able to check a policy" do
    some_instance = @some_class.new
    some_instance.user = 1
    some_instance.check_policy(1).should eql([:read])
  end

  it "should allow multiple forms of can statements" do
    actor_class = Class.new do
      extend AdheresToPolicy::ClassMethods
      set_policy do
        given { |user| user == 1 }
        can :read and can :write

        given { |user| user == 2 }
        can :update, :delete

        given { |user| user == 3 }
        can [:manage, :set_permissions]
      end
    end

    actor = actor_class.new
    actor.check_policy(1).should == [:read, :write]
    actor.check_policy(2).should == [:update, :delete]
    actor.check_policy(3).should == [:manage, :set_permissions]
  end

  it "should execute all conditions when searching for all rights" do
    actor_class = Class.new do
      attr_accessor :total
      extend AdheresToPolicy::ClassMethods

      def initialize
        @total = 0
      end

      set_policy do
        given { |_| @total = @total + 1 }
        can :read

        given { |_| @total = @total + 1 }
        can :write

        given { |_| @total = @total + 1 }
        can :update
      end
    end

    actor = actor_class.new
    actor.check_policy(nil).should == [:read, :write, :update]
    actor.total.should == 3
  end

  it "should skip duplicate conditions when searching for all rights" do
    actor_class = Class.new do
      attr_accessor :total
      extend AdheresToPolicy::ClassMethods

      def initialize
        @total = 0
      end

      set_policy do
        given { |_| @total = @total + 1 }
        can :read, :write

        given { |_| raise "don't execute me" }
        can :write

        given { |_| @total = @total + 1 }
        can :update
      end
    end

    actor = actor_class.new
    actor.check_policy(nil).should == [:read, :write, :update]
    actor.total.should == 2
  end

  it "should only execute relevant conditions when searching for specific rights" do
    actor_class = Class.new do
      attr_accessor :total
      extend AdheresToPolicy::ClassMethods

      def initialize
        @total = 0
      end

      set_policy do
        given { |_| @total = @total + 1 }
        can :read

        given { |_| raise "don't execute me" }
        can :write

        given { |_| raise "me either" }
        can :update
      end
    end

    actor = actor_class.new
    actor.check_policy(nil, nil, :read).should == [:read]
    actor.total.should == 1
  end

  it "should skip duplicate conditions when searching for specific rights" do
    actor_class = Class.new do
      attr_accessor :total
      extend AdheresToPolicy::ClassMethods

      def initialize
        @total = 0
      end

      set_policy do
        given { |_| @total = @total + 1 }
        can :read

        given { |_| @total = @total + 1 }
        can :write

        given { |_| raise "me either" }
        can :read and can :write
      end
    end

    actor = actor_class.new
    actor.check_policy(nil, nil, :read, :write).should == [:read, :write]
    actor.total.should == 2
  end

  context "grants_right?" do
    before(:each) do
      @actor_class = Class.new do
        extend AdheresToPolicy::ClassMethods

        set_policy do
          given { |actor| actor == "allowed actor" || actor.class.to_s == "User" }
          can :read

          given { |actor| actor == "allowed actor" }
          can :read
        end

        def is_a_context?
          false
        end
      end
    end

    it "should check the policy" do
      non_context = @actor_class.new
      non_context.grants_right?("allowed actor", :read).should be_true
      non_context.grants_right?("allowed actor", :asdf).should be_false
    end

    it "should return false if no specific ones are sought" do
      non_context = @actor_class.new
      non_context.grants_right?("allowed actor").should == false
    end

    context "caching" do
      it "should cache for contexts" do
        user = User.new
        actor = @actor_class.new
        actor.stub(:is_a_context?).and_return(true)

        Rails.cache.should_receive(:fetch).exactly(2).times.with { |p,| p =~ /context_permissions/ }.and_return([])
        actor.grants_rights?(user)
        # cache lookups for "nobody" as well
        actor.grants_rights?(nil)
      end

      it "should not cache for contexts if session[:session_affects_permissions]" do
        actor = @actor_class.new
        actor.stub(:is_a_context?).and_return(true)

        Rails.cache.should_receive(:read).never.with { |p,| p =~ /context_permissions/ }
        Rails.cache.stub(:read).with { |p,| p !~ /context_permissions/ }.and_return(nil)

        actor.grants_rights?(User.new, {:session_affects_permissions => true})
      end

      it "should not cache for non-contexts" do
        actor_class = Class.new do
          extend AdheresToPolicy::ClassMethods
          set_policy {}

          def is_a_context?
            false
          end
        end

        Rails.cache.should_receive(:fetch).never

        actor = actor_class.new
        actor_class.new.grants_rights?(actor)
      end

      it "should not nil the session argument when not caching" do
        actor_class = Class.new do
          attr_reader :session
          extend AdheresToPolicy::ClassMethods
          set_policy {
            given { |_, session| @session = session }
            can :read
          }

          def is_a_context?;
            false;
          end
        end

        Rails.cache.should_receive(:fetch).never

        actor = actor_class.new
        actor.grants_rights?(actor, {})
        actor.session.should_not be_nil
      end
    end
  end
end
