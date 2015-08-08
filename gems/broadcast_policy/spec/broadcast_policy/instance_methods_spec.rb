require 'spec_helper'

describe BroadcastPolicy::InstanceMethods do

  class Harness
    include BroadcastPolicy::InstanceMethods
    attr_accessor :attributes, :changed_attributes

    def initialize
      @attributes = {}
      @changed_attributes = {}
    end

    def column_for_attribute(_)
      true
    end

    def new_record?
      false
    end

    def write_attribute(attr, value)
      @attributes[attr] = value
    end

    def method_missing(m)
      @attributes[m]
    end
  end

  let(:default_attrs) do
    {
      id: 1,
      workflow_state: 'active',
      score: 5.0
    }
  end

  let(:harness) do
    Harness.new.tap{|h| h.attributes = default_attrs}
  end

  context "#changed_in_state" do
    it "is false if the field has not changed" do
      harness.set_broadcast_flags
      expect(harness.changed_in_state('active', fields: :score)).to be_falsey
    end

    it "is true if field has changed" do
      harness.changed_attributes[:score] = 3.0
      harness.set_broadcast_flags
      expect(harness.changed_in_state('active', fields: :score)).to be_truthy
    end

    it "raises an error if prior_version has not been created" do
      expect{ harness.changed_in_state('active', fields: :score) }.to raise_error
    end
  end

  context "#changed_state" do
    it "is false if the state has not changed" do
      harness.set_broadcast_flags
      expect(harness.changed_state('active', 'deleted')).to be_falsey
    end

    it "is true if state has changed" do
      harness.changed_attributes[:workflow_state] = 'deleted'
      harness.set_broadcast_flags
      expect(harness.changed_state('active', 'deleted')).to be_truthy
    end

    it "raises an error if prior_version has not been created" do
      expect { harness.changed_state('active', 'deleted') }.to raise_error
    end
  end
end
