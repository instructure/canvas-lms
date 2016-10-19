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
# You should have received a copy of the GNU Affero General Public License along
# with this program. If not, see <http://www.gnu.org/licenses/>.
#

require 'spec_helper'

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
    %w(rights_status granted_rights grants_right? grants_any_right? grants_all_rights?).each do |method|
      expect(@some_class.new).to respond_to(method)
    end
  end

  it "should be able to check a policy" do
    some_instance = @some_class.new
    some_instance.user = 1
    expect(some_instance.grants_right?(1, :read)).to eq true
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
    expect(actor.rights_status(1, :read, :write)).to eq({read: true, write: true})
    expect(actor.rights_status(2, :read, :update, :delete)).to eq({read: false, update: true, delete: true})
    expect(actor.rights_status(3, :read, :manage, :set_permissions)).to eq({read: false, manage: true, set_permissions: true})
  end

  it 'should check parent conditions' do
    actor_class = Class.new do
      extend AdheresToPolicy::ClassMethods
      set_policy do
        given { |value| value[0] == true }
        use_additional_policy do
          given { |value| value[1] == true }
          can :do_stuff
        end
      end
    end

    actor = actor_class.new
    expect(actor.rights_status([false, false])).to eq(do_stuff: false)
    expect(actor.rights_status([false, true])).to eq(do_stuff: false)
    expect(actor.rights_status([true, false])).to eq(do_stuff: false)
    expect(actor.rights_status([true, true])).to eq(do_stuff: true)
  end

  it 'should check deeply nested parent conditions' do
    actor_class = Class.new do
      extend AdheresToPolicy::ClassMethods
      set_policy do
        given { |value| value[0] == true }
        use_additional_policy do
          given { |value| value[1] == true }
          can :do_stuff
          use_additional_policy do
            given { |value| value[2] == true }
            can :do_things
          end
        end
      end
    end

    actor = actor_class.new
    expect(actor.rights_status([false, false, false])).to eq(do_stuff: false, do_things: false)
    expect(actor.rights_status([false, false, true])).to eq(do_stuff: false, do_things: false)
    expect(actor.rights_status([false, true, false])).to eq(do_stuff: false, do_things: false)
    expect(actor.rights_status([false, true, true])).to eq(do_stuff: false, do_things: false)
    expect(actor.rights_status([true, false, false])).to eq(do_stuff: false, do_things: false)
    expect(actor.rights_status([true, false, true])).to eq(do_stuff: false, do_things: false)
    expect(actor.rights_status([true, true, false])).to eq(do_stuff: true, do_things: false)
    expect(actor.rights_status([true, true, true])).to eq(do_stuff: true, do_things: true)
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
    expect(actor.rights_status(nil)).to eq({read: true, write: true, update: true})
    expect(actor.total).to eq 3
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
    expect(actor.rights_status(nil)).to eq({read: true, write: true, update: true})
    expect(actor.total).to eq 2
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
    expect(actor.rights_status(nil, :read)).to eq({read: true})
    expect(actor.total).to eq 1
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
    expect(actor.rights_status(nil, :read, :write)).to eq({read: true, write: true})
    expect(actor.total).to eq 2
  end

  context "clear_permissions_cache" do
    let :sample_class do
      Class.new do
        extend AdheresToPolicy::ClassMethods

        set_policy do
          given { |actor| actor == 1 }
          can :read

          given { |actor| actor == 2 }
          can :read and can :write
        end
      end
    end

    it "clear the permissions cache" do
      expect(Rails.cache).to receive(:delete).with(/\/read$/)
      expect(Rails.cache).to receive(:delete).with(/\/write$/)

      sample = sample_class.new
      expect(sample.grants_right?(1, :read)).to eq true
      sample.clear_permissions_cache(1)
    end
  end

  context "grants_any_right?" do
    let :sample_class do
      Class.new do
        extend AdheresToPolicy::ClassMethods

        set_policy do
          given { |actor| actor == 1 }
          can :read

          given { |actor| actor == 2 }
          can :read and can :write
        end
      end
    end

    it "should check the policy" do
      sample = sample_class.new
      expect(sample.grants_any_right?(1, :read, :write)).to eq true
      expect(sample.grants_any_right?(1, :asdf)).to eq false
    end

    it "should return false if no specific ones are sought" do
      sample = sample_class.new
      expect(sample.grants_any_right?(1)).to eq false
    end
  end

  context "grants_all_rights?" do
    let :sample_class do
      Class.new do
        extend AdheresToPolicy::ClassMethods

        set_policy do
          given { |actor| actor == 1 }
          can :read

          given { |actor| actor == 2 }
          can :read and can :write
        end
      end
    end

    it "should check the policy" do
      sample = sample_class.new
      expect(sample.grants_all_rights?(1, :read, :write)).to eq false
      expect(sample.grants_all_rights?(2, :read, :write)).to eq true
      expect(sample.grants_all_rights?(3, :read, :asdf)).to eq false
    end

    it "should return false if no specific ones are sought" do
      sample = sample_class.new
      expect(sample.grants_all_rights?(1)).to eq false
    end
  end

  context "check_condition?" do
    it "should run condition based on its arity" do
      actor_class = Class.new do
        attr_accessor :total
        extend AdheresToPolicy::ClassMethods

        def initialize
          @total = 0
        end

        set_policy do
          given { |arg1| @total = @total + arg1 }
          can :read

          given { |arg1, arg2| @total = @total + arg1 + arg2[:count] }
          can :write
        end
      end

      actor = actor_class.new
      expect(actor.rights_status(1, { count: 2 }, :read, :write)).to eq({read: true, write: true})
      expect(actor.total).to eq 4
    end
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
      end
    end

    it "should check the policy" do
      non_context = @actor_class.new
      expect(non_context.grants_right?("allowed actor", :read)).to eq true
      expect(non_context.grants_right?("allowed actor", :asdf)).to eq false
    end

    it "should return false if no specific ones are sought" do
      non_context = @actor_class.new
      expect(non_context.grants_right?("allowed actor")).to eq false
    end

    it "should return false if no user is provided" do
      non_context = @actor_class.new
      expect(non_context.grants_right?("allowed actor", :read)).to eq true
      expect(non_context.grants_right?(nil, :read)).to eq false
    end

    it "should raise argument exception if anything other then one right is provided" do
      non_context = @actor_class.new
      expect(non_context.grants_right?("allowed actor", :read)).to eq true
      expect{
        non_context.grants_right?("allowed actor", :asdf, :read)
      }.to raise_exception ArgumentError
    end

    context "caching" do
      it "should cache permissions" do
        user = User.new
        actor = @actor_class.new

        expect(AdheresToPolicy::Cache).to receive(:fetch).twice.with(/permissions/).and_return([])
        actor.rights_status(user)
        # cache lookups for "nobody" as well
        actor.rights_status(nil)
      end

      it "should not nil the session argument when not caching" do
        actor_class = Class.new do
          attr_reader :session
          extend AdheresToPolicy::ClassMethods
          set_policy {
            given { |_, session| @session = session }
            can :read
          }
        end

        actor = actor_class.new
        actor.rights_status(actor, {})
        expect(actor.session).not_to be_nil
      end

      it "should change cache key based on session[:permissions_key]" do
        session = {
          permissions_key: 'permissions_key',
          session_id: 'session_id'
        }
        actor_class = Class.new do
          extend AdheresToPolicy::ClassMethods
          set_policy {
            given { |_| true }
            can :read
          }

          def call_permission_cache_key_for(*args)
            permission_cache_key_for(*args)
          end
        end

        actor = actor_class.new
        expect(actor.call_permission_cache_key_for(nil, session, :read)).to match(/\>\/permissions_key\/read$/)

        session.delete(:permissions_key)
        expect(actor.call_permission_cache_key_for(nil, session, :read)).to match(/\>\/default\/read$/)

        expect(actor.call_permission_cache_key_for(nil, nil, :read)).to match(/\>\/read$/)
      end
    end
  end
end
