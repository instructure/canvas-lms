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
#

require "spec_helper"

RSpec.describe TextNormalizerHelper do
  describe ".normalize" do
    it "normalizes quotes to straight ASCII and lowercases" do
      expect(TextNormalizerHelper.normalize("Hello 'world'")).to eq("hello 'world'")
      expect(TextNormalizerHelper.normalize('Hello "world"')).to eq('hello "world"')
    end

    it "converts smart quotes to straight quotes" do
      expect(TextNormalizerHelper.normalize("Hello ’world’")).to eq("hello 'world'")
      expect(TextNormalizerHelper.normalize("Hello ‘world’")).to eq("hello 'world'")
      expect(TextNormalizerHelper.normalize("Hello “world”")).to eq('hello "world"')
    end

    it "converts mixed quote types consistently" do
      expect(TextNormalizerHelper.normalize("Hello 'world' and 'universe'")).to eq("hello 'world' and 'universe'")
      expect(TextNormalizerHelper.normalize('Hello "world" and "universe"')).to eq('hello "world" and "universe"')
    end

    it "collapses multiple whitespace characters into single spaces" do
      expect(TextNormalizerHelper.normalize("Hello   world")).to eq("hello world")
      expect(TextNormalizerHelper.normalize("Hello\n\tworld")).to eq("hello world")
      expect(TextNormalizerHelper.normalize("Hello  \n  world")).to eq("hello world")
    end

    it "replaces newlines with spaces" do
      expect(TextNormalizerHelper.normalize("Hello\nworld")).to eq("hello world")
      expect(TextNormalizerHelper.normalize("Hello\n\nworld")).to eq("hello world")
      expect(TextNormalizerHelper.normalize("Hello\n\n\nworld")).to eq("hello world")
    end

    it "trims leading and trailing whitespace" do
      expect(TextNormalizerHelper.normalize("  Hello world  ")).to eq("hello world")
      expect(TextNormalizerHelper.normalize("\nHello world\n")).to eq("hello world")
    end

    it "converts text to lowercase" do
      expect(TextNormalizerHelper.normalize("Hello World")).to eq("hello world")
      expect(TextNormalizerHelper.normalize("HELLO WORLD")).to eq("hello world")
    end

    it "handles nil input gracefully" do
      expect(TextNormalizerHelper.normalize(nil)).to eq("")
    end

    it "handles non-string input gracefully" do
      expect(TextNormalizerHelper.normalize(123)).to eq("123")
      expect(TextNormalizerHelper.normalize(true)).to eq("true")
    end

    it "combines all normalizations correctly" do
      input = "  Hello 'World'  \n\n  How   are   you?  "
      expected = "hello 'world' how are you?"
      expect(TextNormalizerHelper.normalize(input)).to eq(expected)
    end

    it "handles complex text with various line breaks and formatting" do
      input = "  Hello\n'World'\n\n  How\n\n\nare\n\tyou?  "
      expected = "hello 'world' how are you?"
      expect(TextNormalizerHelper.normalize(input)).to eq(expected)
    end
  end
end
