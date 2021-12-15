# frozen_string_literal: true

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

require_relative "../spec_helper"

describe BroadcastPolicy::InstanceMethods do
  let(:harness_class) do
    Class.new do
      include BroadcastPolicy::InstanceMethods
      attr_accessor :attributes, :changed_attributes

      def initialize
        @attributes = {}
        @changed_attributes = {}
      end

      def attribute_changed?(method)
        changed_attributes.key?(method)
      end
      alias_method :saved_change_to_attribute?, :attribute_changed?

      def new_record?
        false
      end

      def method_missing(method, *) # rubocop:disable Style/MissingRespondToMissing
        method = method.to_s
        case method
        when /^saved_change_to.+\?\z/
          method = method.sub(/^saved_change_to/, "")
                         .delete_suffix("?")
                         .to_sym
          attribute_changed? method
        when /_changed\?\z/
          method = method.delete_suffix("_changed?", "").to_sym
          attribute_changed? method
        when /_was\z/, /_before_last_save\z/
          method = method.delete_suffix("_was")
                         .delete_suffix("_before_last_save")
                         .to_sym
          attribute_changed?(method) ? changed_attributes[method] : attributes[method]
        else
          attributes[method.to_sym]
        end
      end
    end
  end

  let(:default_attrs) do
    {
      id: 1,
      workflow_state: "active",
      score: 5.0
    }
  end

  let(:harness) do
    harness_class.new.tap { |h| h.attributes = default_attrs }
  end

  describe "#changed_in_state" do
    it "is false if the field has not changed" do
      expect(harness.changed_in_state("active", fields: :score)).to be_falsey
    end

    it "is true if field has changed" do
      harness.changed_attributes[:score] = 3.0
      expect(harness.changed_in_state("active", fields: :score)).to be_truthy
    end
  end

  describe "#changed_state" do
    it "is false if the state has not changed" do
      expect(harness.changed_state("active", "deleted")).to be_falsey
    end

    it "is true if state has changed" do
      harness.changed_attributes[:workflow_state] = "deleted"
      expect(harness.changed_state("active", "deleted")).to be_truthy
    end
  end

  describe "#with_changed_attributes_from" do
    let!(:og_changed_attributes) { harness.changed_attributes }
    let(:prior_version) do
      harness_class.new.tap do |h|
        h.attributes = { id: 1, workflow_state: "created", score: 5.0 }
      end
    end

    before do
      harness.changed_attributes[:score] = 3.0
    end

    it "hides existing changed_attributes" do
      harness.with_changed_attributes_from(prior_version) do
        expect(harness.changed_attributes).not_to have_key(:score)
      end
    end

    it "applies changed attributes from it" do
      harness.with_changed_attributes_from(prior_version) do
        expect(harness.changed_attributes).to have_key(:workflow_state)
        expect(harness.changed_attributes["workflow_state"]).to eq "created"
      end
    end

    it "doesn't apply unchanged attributes from it" do
      harness.with_changed_attributes_from(prior_version) do
        expect(harness.changed_attributes).not_to have_key(:id)
      end
    end

    it "restores the original changed_attributes no matter what" do
      expect do
        harness.with_changed_attributes_from(prior_version) do
          raise "yolo"
        end
      end.to raise_error(/yolo/)
      expect(harness.changed_attributes).to equal og_changed_attributes
    end
  end
end
