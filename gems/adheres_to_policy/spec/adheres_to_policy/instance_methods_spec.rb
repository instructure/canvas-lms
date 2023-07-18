# frozen_string_literal: true

#
# Copyright (C) 2014 - present Instructure, Inc.
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

require "spec_helper"

describe AdheresToPolicy::InstanceMethods do
  let(:some_class) do
    Class.new do
      attr_accessor :user

      extend AdheresToPolicy::ClassMethods
      set_policy do
        given { |user| self.user == user }
        can :read
      end
    end
  end

  let(:user_class) { Class.new }

  it "has setup a series of methods on the instance" do
    %w[rights_status granted_rights grants_right? grants_any_right? grants_all_rights?].each do |method|
      expect(some_class.new).to respond_to(method)
    end
  end

  it "is able to check a policy" do
    some_instance = some_class.new
    some_instance.user = 1
    expect(some_instance.grants_right?(1, :read)).to be true
  end

  it "allows multiple forms of can statements" do
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
    expect(actor.rights_status(1, :read, :write)).to eq({ read: true, write: true })
    expect(actor.rights_status(2, :read, :update, :delete)).to eq({ read: false, update: true, delete: true })
    expect(actor.rights_status(3, :read, :manage, :set_permissions)).to eq({ read: false, manage: true, set_permissions: true })
  end

  it "checks parent conditions" do
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

  it "checks deeply nested parent conditions" do
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

  it "executes all conditions when searching for all rights" do
    actor_class = Class.new do
      attr_accessor :total

      extend AdheresToPolicy::ClassMethods

      def initialize
        @total = 0
      end

      set_policy do
        given { |_| @total += 1 }
        can :read

        given { |_| @total += 1 }
        can :write

        given { |_| @total += 1 }
        can :update
      end
    end

    actor = actor_class.new
    expect(actor.rights_status(nil)).to eq({ read: true, write: true, update: true })
    expect(actor.total).to eq 3
  end

  it "skips duplicate conditions when searching for all rights" do
    actor_class = Class.new do
      attr_accessor :total

      extend AdheresToPolicy::ClassMethods

      def initialize
        @total = 0
      end

      set_policy do
        given { |_| @total += 1 }
        can :read, :write

        given { |_| raise "don't execute me" }
        can :write

        given { |_| @total += 1 }
        can :update
      end
    end

    actor = actor_class.new
    expect(actor.rights_status(nil)).to eq({ read: true, write: true, update: true })
    expect(actor.total).to eq 2
  end

  it "only executes relevant conditions when searching for specific rights" do
    actor_class = Class.new do
      attr_accessor :total

      extend AdheresToPolicy::ClassMethods

      def initialize
        @total = 0
      end

      set_policy do
        given { |_| @total += 1 }
        can :read

        given { |_| raise "don't execute me" }
        can :write

        given { |_| raise "me either" }
        can :update
      end
    end

    actor = actor_class.new
    expect(actor.rights_status(nil, :read)).to eq({ read: true })
    expect(actor.total).to eq 1
  end

  it "skips duplicate conditions when searching for specific rights" do
    actor_class = Class.new do
      attr_accessor :total

      extend AdheresToPolicy::ClassMethods

      def initialize
        @total = 0
      end

      set_policy do
        given { |_| @total += 1 }
        can :read

        given { |_| @total += 1 }
        can :write

        given { |_| raise "me either" }
        can :read and can :write
      end
    end

    actor = actor_class.new
    expect(actor.rights_status(nil, :read, :write)).to eq({ read: true, write: true })
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
      expect(Rails.cache).to receive(:delete).with(%r{/read$})
      expect(Rails.cache).to receive(:delete).with(%r{/write$})

      sample = sample_class.new
      expect(sample.grants_right?(1, :read)).to be true
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

    it "checks the policy" do
      sample = sample_class.new
      expect(sample.grants_any_right?(1, :read, :write)).to be true
      expect(sample.grants_any_right?(1, :asdf)).to be false
    end

    it "returns false if no specific ones are sought" do
      sample = sample_class.new
      expect(sample.grants_any_right?(1)).to be false
    end

    context "with justifications" do
      let(:actor_class) do
        Class.new do
          extend AdheresToPolicy::ClassMethods

          set_policy do
            given { |actor| actor == "allowed actor" || AdheresToPolicy::JustifiedFailure.new(:wrong_actor) }
            can :read

            given { |actor| actor == "allowed actor" }
            can :read_more
          end
        end
      end

      it "returns true/false by default" do
        non_context = actor_class.new
        expect(non_context.grants_any_right?("allowed actor", :read, :read_more)).to be true
        expect(non_context.grants_any_right?("disallowed actor", :read, :read_more)).to be false
      end

      it "returns detailed information if requested and denied" do
        non_context = actor_class.new
        expect(non_context.grants_any_right?("allowed actor", :read, :read_more, with_justifications: true).success?).to be true
        reasoned_failure = non_context.grants_any_right?("disallowed actor", :read, :read_more, with_justifications: true)
        expect(reasoned_failure.success?).to be false
        expect(reasoned_failure.justifications.first.justification).to eq(:wrong_actor)
        reasonless_failure = non_context.grants_any_right?("disallowed actor", :read_more, with_justifications: true)
        expect(reasonless_failure.success?).to be false
        expect(reasonless_failure.justifications.length).to eq(0)
      end
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

    it "checks the policy" do
      sample = sample_class.new
      expect(sample.grants_all_rights?(1, :read, :write)).to be false
      expect(sample.grants_all_rights?(2, :read, :write)).to be true
      expect(sample.grants_all_rights?(3, :read, :asdf)).to be false
    end

    it "returns false if no specific ones are sought" do
      sample = sample_class.new
      expect(sample.grants_all_rights?(1)).to be false
    end

    context "with justifications" do
      let(:actor_class) do
        Class.new do
          extend AdheresToPolicy::ClassMethods

          set_policy do
            given { |actor| actor == "allowed actor" || AdheresToPolicy::JustifiedFailure.new(:wrong_actor) }
            can :read and can :read_more

            given { |actor| actor == "another allowed actor" }
            can :read
          end
        end
      end

      it "returns true/false by default" do
        non_context = actor_class.new
        expect(non_context.grants_all_rights?("allowed actor", :read, :read_more)).to be true
        expect(non_context.grants_all_rights?("another allowed actor", :read, :read_more)).to be false
        expect(non_context.grants_all_rights?("disallowed actor", :read, :read_more)).to be false
      end

      it "returns detailed information if requested and denied" do
        non_context = actor_class.new
        expect(non_context.grants_all_rights?("allowed actor", :read, :read_more, with_justifications: true).success?).to be true
        single_failure = non_context.grants_all_rights?("another allowed actor", :read, :read_more, with_justifications: true)
        expect(single_failure.success?).to be false
        expect(single_failure.justifications.first.justification).to eq(:wrong_actor)
        full_failure = non_context.grants_all_rights?("disallowed actor", :read, :read_more, with_justifications: true)
        expect(full_failure.success?).to be false
        expect(full_failure.justifications.first.justification).to eq(:wrong_actor)
      end
    end
  end

  context "check_condition?" do
    it "runs condition based on its arity" do
      actor_class = Class.new do
        attr_accessor :total

        extend AdheresToPolicy::ClassMethods

        def initialize
          @total = 0
        end

        set_policy do
          given { |arg1| @total += arg1 }
          can :read

          given { |arg1, arg2| @total = @total + arg1 + arg2[:count] }
          can :write
        end
      end

      actor = actor_class.new
      expect(actor.rights_status(1, { count: 2 }, :read, :write)).to eq({ read: true, write: true })
      expect(actor.total).to eq 4
    end
  end

  context "grants_right?" do
    let(:actor_class) do
      # need to copy the method to a local variable so that it's visible within the block
      user_class = self.user_class
      Class.new do
        extend AdheresToPolicy::ClassMethods

        set_policy do
          given { |actor| actor == "allowed actor" || actor.is_a?(user_class) }
          can :read

          given { |actor| actor == "allowed actor" }
          can :read
        end
      end
    end

    it "checks the policy" do
      non_context = actor_class.new
      expect(non_context.grants_right?("allowed actor", :read)).to be true
      expect(non_context.grants_right?("allowed actor", :asdf)).to be false
    end

    it "returns false if no specific ones are sought" do
      non_context = actor_class.new
      expect(non_context.grants_right?("allowed actor")).to be false
    end

    it "returns false if no user is provided" do
      non_context = actor_class.new
      expect(non_context.grants_right?("allowed actor", :read)).to be true
      expect(non_context.grants_right?(nil, :read)).to be false
    end

    it "raises argument exception if anything other then one right is provided" do
      non_context = actor_class.new
      expect(non_context.grants_right?("allowed actor", :read)).to be true
      expect do
        non_context.grants_right?("allowed actor", :asdf, :read)
      end.to raise_exception ArgumentError
    end

    context "caching" do
      after do
        AdheresToPolicy.configuration.reset!
      end

      it "caches permissions" do
        user = user_class
        actor = actor_class.new

        expect(AdheresToPolicy::Cache).to receive(:fetch).twice.with(/permissions/, an_instance_of(Hash)).and_return([AdheresToPolicy::Failure.instance])
        actor.rights_status(user)
        # cache lookups for "nobody" as well
        actor.rights_status(nil)
      end

      it "does not nil the session argument when not caching" do
        actor_class = Class.new do
          attr_reader :session

          extend AdheresToPolicy::ClassMethods
          set_policy do
            given { |_, session| @session = session }
            can :read
          end
        end

        actor = actor_class.new
        actor.rights_status(actor, {})
        expect(actor.session).not_to be_nil
      end

      it "changes cache key based on session[:permissions_key]" do
        session = {
          permissions_key: "permissions_key",
          session_id: "session_id"
        }
        actor_class = Class.new do
          extend AdheresToPolicy::ClassMethods
          set_policy do
            given { |_| true }
            can :read
          end

          def call_permission_cache_key_for(*args)
            permission_cache_key_for(*args)
          end
        end

        actor = actor_class.new
        expect(actor.call_permission_cache_key_for(nil, session, :read)).to match(%r{>/permissions_key/read$})

        session.delete(:permissions_key)
        expect(actor.call_permission_cache_key_for(nil, session, :read)).to match(%r{>/default/read$})

        expect(actor.call_permission_cache_key_for(nil, nil, :read)).to match(%r{>/read$})
      end

      it "must not use the rails cache for permissions included in the configured blacklist" do
        klass = Class.new do
          extend AdheresToPolicy::ClassMethods
          set_policy do
            given { |_| true }
            can :read
          end
        end
        instance = klass.new
        AdheresToPolicy.configuration.blacklist = [".read"]
        expect(AdheresToPolicy::Cache).to receive(:fetch)
          .with(an_instance_of(String), a_hash_including(use_rails_cache: false))
          .and_return([AdheresToPolicy::Failure.instance])
        instance.granted_rights(instance)
      end

      it "must cache permissions calculated using the same given block by default" do
        klass = Class.new do
          extend AdheresToPolicy::ClassMethods
          set_policy do
            given { |_| true }
            can :read, :write
          end
        end
        instance = klass.new

        allow(AdheresToPolicy::Cache).to receive(:write)
          .with(/read/, AdheresToPolicy::Success.instance, an_instance_of(Hash))

        expect(AdheresToPolicy::Cache).to receive(:write)
          .with(/write/, AdheresToPolicy::Success.instance, an_instance_of(Hash))
        instance.grants_right?("", :read)
      end

      it "must not cache related permissions when configured not to" do
        AdheresToPolicy.configuration.cache_related_permissions = false
        klass = Class.new do
          extend AdheresToPolicy::ClassMethods
          set_policy do
            given { |_| true }
            can :read, :write
          end
        end
        instance = klass.new

        allow(AdheresToPolicy::Cache).to receive(:write)
          .with(/read/, AdheresToPolicy::Success.instance, an_instance_of(Hash))

        expect(AdheresToPolicy::Cache).to receive(:write)
          .with(/write/, AdheresToPolicy::Success.instance, a_hash_including(use_rails_cache: false))
        instance.grants_right?("", :read)
      end

      it "must cache permissions calculated in the course of calculating others" do
        klass = Class.new do
          extend AdheresToPolicy::ClassMethods

          set_policy do
            given { |_| true }
            can :create

            given { |u| grants_right?(u, :create) }
            can :update
          end
        end
        instance = klass.new

        allow(AdheresToPolicy::Cache).to receive(:fetch).and_yield
        expect(AdheresToPolicy::Cache).to receive(:fetch)
          .with(/create/, a_hash_including(use_rails_cache: true))
        instance.grants_right?("foobar", :update)
      end

      it "must not cache permissions calculated in the course of calculating others when configured not to" do
        AdheresToPolicy.configuration.cache_intermediate_permissions = false

        klass = Class.new do
          extend AdheresToPolicy::ClassMethods

          set_policy do
            given { |_| true }
            can :create

            given { |u| grants_right?(u, :create) }
            can :update
          end
        end
        instance = klass.new

        expect(AdheresToPolicy::Cache).to receive(:fetch)
          .with(/update/, a_hash_including(use_rails_cache: true))
          .twice
          .and_yield
          .and_return([AdheresToPolicy::Failure.instance])
        expect(AdheresToPolicy::Cache).to receive(:fetch)
          .with(/create/, a_hash_including(use_rails_cache: false))
          .twice
          .and_return([AdheresToPolicy::Failure.instance])
        instance.grants_right?("foobar", :update)
        instance.grants_right?("foobar", :update)
      end

      it "must not cache anything when configured not to" do
        AdheresToPolicy.configuration.cache_permissions = false

        klass = Class.new do
          extend AdheresToPolicy::ClassMethods

          set_policy do
            given { |_| true }
            can :create, :update
          end
        end
        instance = klass.new

        expect(AdheresToPolicy::Cache).to receive(:fetch)
          .with(/create/, a_hash_including(use_rails_cache: false))
          .and_yield
        expect(AdheresToPolicy::Cache).to receive(:write)
          .with(/update/, AdheresToPolicy::Success.instance, a_hash_including(use_rails_cache: false))
        instance.grants_right?("foobar", :create)
      end
    end

    context "with justifications" do
      let(:actor_class) do
        Class.new do
          extend AdheresToPolicy::ClassMethods

          set_policy do
            given { |actor| actor == "allowed actor" || AdheresToPolicy::JustifiedFailure.new(:wrong_actor) }
            can :read
          end
        end
      end

      it "returns true/false by default" do
        non_context = actor_class.new
        expect(non_context.grants_right?("allowed actor", :read)).to be true
        expect(non_context.grants_right?("disallowed actor", :read)).to be false
      end

      it "returns detailed information if requested" do
        non_context = actor_class.new
        expect(non_context.grants_right?("allowed actor", :read, with_justifications: true).success?).to be true
        full_failure = non_context.grants_right?("disallowed actor", :read, with_justifications: true)
        expect(full_failure.success?).to be false
        expect(full_failure.justifications.first.justification).to eq(:wrong_actor)
      end
    end
  end
end
