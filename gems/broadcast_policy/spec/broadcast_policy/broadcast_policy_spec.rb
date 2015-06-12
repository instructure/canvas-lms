require 'spec_helper'

describe BroadcastPolicy do
  before(:each) do
    class PolicyHarness
      def self.before_save(r); true; end
      def self.after_save(r); true; end
      extend BroadcastPolicy::ClassMethods
    end
  end

  after(:each) do
    Object.send(:remove_const, :PolicyHarness)
  end
  
  describe ".has_a_broadcast_policy" do
    it 'includes instance methods once declared to have one' do
      obj = PolicyHarness.new
      expect(obj).not_to respond_to(:messages_sent)
      class PolicyHarness
        has_a_broadcast_policy
      end
      expect(obj).to respond_to(:messages_sent)
    end
  end

  describe ".set_broadcast_policy" do
    it "handles multiple declarations" do
      class PolicyHarness
        has_a_broadcast_policy
        set_broadcast_policy { dispatch :foo; to {}; whenever{}}
        set_broadcast_policy { dispatch :bar; to {}; whenever{}}
      end

      policy_list = PolicyHarness.broadcast_policy_list
      expect(policy_list.find_policy_for('Foo')).not_to be(nil)
      expect(policy_list.find_policy_for('Bar')).not_to be(nil)
    end
  end

  describe ".set_broadcast_policy!" do
    before(:each) do
      class Parent < PolicyHarness
        has_a_broadcast_policy
        set_broadcast_policy { dispatch :foo; to {}; whenever {} }
      end

      class Child < Parent
        has_a_broadcast_policy
        set_broadcast_policy! { dispatch :bar; to {}; whenever {} }
      end
    end

    after(:each) do
      Object.send(:remove_const, :Child)
      Object.send(:remove_const, :Parent)
    end

    it "should overwrite any inherited blocks" do
      policy_list = Child.broadcast_policy_list
      expect(policy_list.find_policy_for('Foo')).to be(nil)
      expect(policy_list.find_policy_for('Bar')).not_to be(nil)
    end
  end
end

