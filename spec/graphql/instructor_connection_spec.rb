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

require_relative "../spec_helper"

describe InstructorConnection do
  let(:items) { instance_double(InstructorQuery) }
  let(:fetch_results) { [+"instructor_a", +"instructor_b", +"instructor_c"] }
  let(:total) { 10 }
  let(:first_value) { 5 }
  let(:last_value) { nil }
  let(:after_cursor) { nil }
  let(:before_cursor) { nil }

  let(:connection) do
    conn = InstructorConnection.new(items, first: first_value, last: last_value, after: after_cursor, before: before_cursor)
    allow(conn).to receive_messages(first: first_value, last: last_value, after: after_cursor, before: before_cursor)
    allow(conn).to receive(:encode) { |val| Base64.strict_encode64(val) }
    allow(conn).to receive(:decode) { |val| Base64.strict_decode64(val) }
    conn
  end

  before do
    allow(items).to receive_messages(fetch_page: fetch_results, total_count: total)
  end

  describe "#nodes" do
    it "fetches page_size + 1 items to detect next page" do
      connection.nodes
      expect(items).to have_received(:fetch_page).with(6, 0)
    end

    it "returns at most page_size items" do
      allow(items).to receive(:fetch_page).and_return([+"a", +"b", +"c", +"d", +"e", +"extra"])
      expect(connection.nodes.length).to eq 5
    end

    it "memoizes results" do
      connection.nodes
      connection.nodes
      expect(items).to have_received(:fetch_page).once
    end
  end

  describe "#has_next_page" do
    context "when fetch returns more than page_size items" do
      before do
        allow(items).to receive(:fetch_page).and_return([+"a", +"b", +"c", +"d", +"e", +"extra"])
      end

      it "returns true" do
        expect(connection.has_next_page).to be true
      end
    end

    context "when fetch returns exactly page_size items" do
      before do
        allow(items).to receive(:fetch_page).and_return([+"a", +"b", +"c", +"d", +"e"])
      end

      it "returns false" do
        expect(connection.has_next_page).to be false
      end
    end

    context "when fetch returns fewer than page_size items" do
      it "returns false" do
        expect(connection.has_next_page).to be false
      end
    end
  end

  describe "#has_previous_page" do
    it "returns false when on the first page" do
      expect(connection.has_previous_page).to be false
    end

    context "with an after cursor" do
      let(:after_cursor) { Base64.strict_encode64("5") }

      it "returns true" do
        expect(connection.has_previous_page).to be true
      end
    end
  end

  describe "#cursor_for" do
    it "encodes offset-based cursor for the first item" do
      item = fetch_results[0]
      cursor = connection.cursor_for(item)
      decoded = Base64.strict_decode64(cursor)
      expect(decoded).to eq "1"
    end

    it "encodes offset-based cursor for subsequent items" do
      item = fetch_results[2]
      cursor = connection.cursor_for(item)
      decoded = Base64.strict_decode64(cursor)
      expect(decoded).to eq "3"
    end

    context "with an offset" do
      let(:after_cursor) { Base64.strict_encode64("5") }

      it "accounts for the offset in cursor value" do
        item = fetch_results[0]
        cursor = connection.cursor_for(item)
        decoded = Base64.strict_decode64(cursor)
        expect(decoded).to eq "6"
      end
    end

    it "defaults to index 0 when item is not found in nodes" do
      unknown_item = +"unknown"
      cursor = connection.cursor_for(unknown_item)
      decoded = Base64.strict_decode64(cursor)
      expect(decoded).to eq "1"
    end
  end

  describe "#total_count" do
    it "delegates to items.total_count" do
      expect(connection.total_count).to eq 10
    end

    it "memoizes the result" do
      connection.total_count
      connection.total_count
      expect(items).to have_received(:total_count).once
    end

    it "is not called by has_next_page" do
      connection.has_next_page
      expect(items).not_to have_received(:total_count)
    end
  end

  describe "page_size" do
    context "when first is provided" do
      let(:first_value) { 3 }

      it "uses first as page_size" do
        connection.nodes
        expect(items).to have_received(:fetch_page).with(4, 0)
      end
    end

    context "when first is nil and last is provided" do
      let(:first_value) { nil }
      let(:last_value) { 7 }

      it "uses last as page_size" do
        connection.nodes
        expect(items).to have_received(:fetch_page).with(8, 0)
      end
    end

    context "when both first and last are nil" do
      let(:first_value) { nil }
      let(:last_value) { nil }

      it "defaults to 5" do
        connection.nodes
        expect(items).to have_received(:fetch_page).with(6, 0)
      end
    end
  end

  describe "offset" do
    context "with an after cursor" do
      let(:after_cursor) { Base64.strict_encode64("3") }

      it "decodes cursor value as offset" do
        connection.nodes
        expect(items).to have_received(:fetch_page).with(6, 3)
      end
    end

    context "with a before cursor" do
      let(:before_cursor) { Base64.strict_encode64("8") }

      it "calculates offset as decoded value minus page_size" do
        connection.nodes
        expect(items).to have_received(:fetch_page).with(6, 3)
      end
    end

    context "with a before cursor that would produce a negative offset" do
      let(:before_cursor) { Base64.strict_encode64("2") }

      it "clamps offset to 0" do
        connection.nodes
        expect(items).to have_received(:fetch_page).with(6, 0)
      end
    end

    context "with no cursor" do
      it "defaults to 0" do
        connection.nodes
        expect(items).to have_received(:fetch_page).with(6, 0)
      end
    end
  end
end
