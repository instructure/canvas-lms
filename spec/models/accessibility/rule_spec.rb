# frozen_string_literal: true

#
# Copyright (C) 2025 - present Instructure, Inc.
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

require "spec_helper"

describe Accessibility::Rule do
  describe ".registry" do
    it "returns a hash" do
      expect(described_class.registry).to be_a(Hash)
    end

    it "has values that are subclasses of Accessibility::Rule" do
      expect(described_class.registry.values).to all(be_a(Accessibility::Rule))
    end
  end

  describe ".pdf_registry" do
    it "returns an array" do
      expect(described_class.pdf_registry).to be_an(Array)
    end

    it "contains only subclasses of Accessibility::Rule" do
      expect(described_class.pdf_registry).to all(be_a(Accessibility::Rule))
    end
  end

  describe ".test" do
    context "when not overridden" do
      it "raises NotImplementedError" do
        expect do
          described_class.new.test(nil)
        end.to raise_error(NotImplementedError, "#{described_class} must implement/override test")
      end
    end
  end

  describe ".form" do
    context "by default" do
      it "returns an empty hash" do
        expect(described_class.new.form(nil)).to eq({})
      end
    end
  end

  describe ".fix" do
    context "when not overridden" do
      it "raises NotImplementedError" do
        expect do
          described_class.new.fix!(nil, nil)
        end.to raise_error(NotImplementedError, "#{described_class} must implement fix")
      end
    end
  end

  describe ".generate_fix" do
    context "when not overridden" do
      it "returns nil" do
        expect(described_class.new.generate_fix(nil)).to be_nil
      end
    end
  end

  describe ".display_name" do
    context "when not overridden" do
      it "raises NotImplementedError" do
        expect do
          described_class.new.display_name
        end.to raise_error(NotImplementedError, "#{described_class} must implement display_name")
      end
    end
  end

  describe ".message" do
    context "when not overridden" do
      it "raises NotImplementedError" do
        expect do
          described_class.new.message
        end.to raise_error(NotImplementedError, "#{described_class} must implement message")
      end
    end
  end

  describe ".why" do
    context "when not overridden" do
      it "raises NotImplementedError" do
        expect do
          described_class.new.why
        end.to raise_error(NotImplementedError, "#{described_class} must implement/override why")
      end
    end
  end

  describe ".issue_preview" do
    context "when not overridden" do
      it "returns nil by default" do
        expect(described_class.new.issue_preview(nil)).to be_nil
      end
    end
  end
end
