#
# Copyright (C) 2015 - present Instructure, Inc.
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

require 'spec_helper'

describe BroadcastPolicy::InstanceMethods do

  class Harness
    include BroadcastPolicy::InstanceMethods
    attr_accessor :attributes, :changed_attributes

    def initialize
      @attributes = {}
      @changed_attributes = {}
    end

    def attribute_changed?(method)
      changed_attributes.key?(method)
    end
    alias saved_change_to_attribute? attribute_changed?

    def new_record?
      false
    end

    def method_missing(method, *)
      case method.to_s
      when /^saved_change_to.+\?\z/
        method = method.to_s.sub(/^saved_change_to/, "").to_sym
        method = method.to_s.sub(/\?\z/, "").to_sym
        attribute_changed? method
      when /_changed\?\z/
        method = method.to_s.sub(/_changed\?\z/, "").to_sym
        attribute_changed? method
      when /_was\z/, /_before_last_save\z/
        method = method.to_s.sub(/_was\z/, "").to_sym
        method = method.to_s.sub(/_before_last_save\z/, "").to_sym
        attribute_changed?(method) ? changed_attributes[method] : attributes[method]
      else
        attributes[method]
      end
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

  describe "#changed_in_state" do
    it "is false if the field has not changed" do
      expect(harness.changed_in_state('active', fields: :score)).to be_falsey
    end

    it "is true if field has changed" do
      harness.changed_attributes[:score] = 3.0
      expect(harness.changed_in_state('active', fields: :score)).to be_truthy
    end
  end

  describe "#changed_state" do
    it "is false if the state has not changed" do
      expect(harness.changed_state('active', 'deleted')).to be_falsey
    end

    it "is true if state has changed" do
      harness.changed_attributes[:workflow_state] = 'deleted'
      expect(harness.changed_state('active', 'deleted')).to be_truthy
    end
  end

  describe "#with_changed_attributes_from" do
    let!(:og_changed_attributes) { harness.changed_attributes }

    before do
      harness.changed_attributes[:score] = 3.0
    end

    let(:prior_version) do
      Harness.new.tap { |h|
        h.attributes = { id: 1, workflow_state: "created", score: 5.0 }
      }
    end

    it "hides existing changed_attributes" do
      harness.with_changed_attributes_from(prior_version) do
        expect(harness.changed_attributes.key?(:score)).to be false
      end
    end

    it "applies changed attributes from it" do
      harness.with_changed_attributes_from(prior_version) do
        expect(harness.changed_attributes.key?(:workflow_state)).to be true
        expect(harness.changed_attributes["workflow_state"]).to eq "created"
      end
    end

    it "doesn't apply unchanged attributes from it" do
      harness.with_changed_attributes_from(prior_version) do
        expect(harness.changed_attributes.key?(:id)).to be false
      end
    end

    it "restores the original changed_attributes no matter what" do
      expect {
        harness.with_changed_attributes_from(prior_version) do
          raise "yolo"
        end
      }.to raise_error(/yolo/)
      expect(harness.changed_attributes).to equal og_changed_attributes
    end
  end
end
