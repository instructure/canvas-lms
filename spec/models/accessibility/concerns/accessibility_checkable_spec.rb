# frozen_string_literal: true

#
# Copyright (C) 2026 - present Instructure, Inc.
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

require_relative "../../../spec_helper"

describe Accessibility::Concerns::AccessibilityCheckable do
  # Create a test class that includes the concern
  let(:test_class) do
    Class.new do
      include Accessibility::Concerns::AccessibilityCheckable

      attr_accessor :content, :title, :updated_at

      def initialize(content: nil, title: nil, updated_at: nil)
        @content = content
        @title = title
        @updated_at = updated_at || Time.current
      end

      def scannable_content_column
        :content
      end

      def scannable_workflow_state
        "published"
      end
    end
  end

  let(:instance) { test_class.new(content: "Test content", title: "Test Title") }

  describe "#scannable_content" do
    it "returns the content from the specified column" do
      expect(instance.scannable_content).to eq("Test content")
    end

    context "when content is nil" do
      let(:instance) { test_class.new(content: nil) }

      it "returns nil" do
        expect(instance.scannable_content).to be_nil
      end
    end
  end

  describe "#scannable_display_name" do
    it "returns the title when available" do
      expect(instance.scannable_display_name).to eq("Test Title")
    end

    context "when title is nil" do
      let(:instance) { test_class.new(title: nil) }

      it "returns 'Untitled'" do
        expect(instance.scannable_display_name).to eq("Untitled")
      end
    end
  end

  describe "#scannable_content_size" do
    it "returns the size of the content" do
      expect(instance.scannable_content_size).to eq(12) # "Test content" is 12 chars
    end

    context "when content is nil" do
      let(:instance) { test_class.new(content: nil) }

      it "returns 0" do
        expect(instance.scannable_content_size).to eq(0)
      end
    end
  end

  describe "#exceeds_accessibility_scan_limit?" do
    it "returns true when content exceeds limit" do
      expect(instance.exceeds_accessibility_scan_limit?(10)).to be true
    end

    it "returns false when content is within limit" do
      expect(instance.exceeds_accessibility_scan_limit?(20)).to be false
    end
  end

  describe "#scannable_content?" do
    it "returns true when content is present" do
      expect(instance.scannable_content?).to be true
    end

    context "when content is blank" do
      let(:instance) { test_class.new(content: "") }

      it "returns false" do
        expect(instance.scannable_content?).to be false
      end
    end
  end

  describe "abstract methods" do
    let(:abstract_class) do
      Class.new do
        include Accessibility::Concerns::AccessibilityCheckable
      end
    end

    let(:instance) { abstract_class.new }

    it "raises NotImplementedError for scannable_content_column" do
      expect { instance.scannable_content_column }.to raise_error(NotImplementedError)
    end

    it "raises NotImplementedError for scannable_workflow_state" do
      expect { instance.scannable_workflow_state }.to raise_error(NotImplementedError)
    end
  end
end
