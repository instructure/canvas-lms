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

require_relative "../spec_helper"

describe CollectionConnection do
  let(:items) { instance_double(BookmarkedCollection::Proxy) }
  # BookmarkedCollection::Collection extends Array with mixed-in pagination methods,
  # so instance_double can't verify against it reliably.
  let(:batch) { instance_double(BookmarkedCollection::Collection, next_page: next_page_bookmark) }
  let(:next_page_bookmark) { "bookmark:W1tdXQ" }
  let(:after_cursor) { nil }
  let(:first_value) { 10 }

  let(:connection) do
    conn = CollectionConnection.new(items, first: first_value, after: after_cursor)
    # Stub the parent's first method to avoid needing a full GraphQL context/schema.
    # We're testing CollectionConnection's logic, not the parent's max_page_size clamping.
    allow(conn).to receive(:first).and_return(first_value)
    conn
  end

  before do
    allow(items).to receive(:paginate).and_return(batch)
  end

  describe "#nodes" do
    it "returns paginated results from the collection" do
      expect(connection.nodes).to be(batch)
      expect(items).to have_received(:paginate).with(page: nil, per_page: first_value)
    end

    context "with an after cursor" do
      let(:after_cursor) { "bookmark:abc123" }

      it "passes the after cursor as the page parameter" do
        connection.nodes
        expect(items).to have_received(:paginate).with(page: after_cursor, per_page: first_value)
      end
    end

    context "when first is nil" do
      let(:first_value) { nil }

      it "falls back to 100" do
        connection.nodes
        expect(items).to have_received(:paginate).with(page: nil, per_page: 100)
      end
    end

    it "memoizes results across multiple calls" do
      result1 = connection.nodes
      result2 = connection.nodes

      expect(result1).to be(result2)
      expect(items).to have_received(:paginate).once
    end
  end

  describe "#has_next_page" do
    context "when more pages exist" do
      it "returns true" do
        connection.nodes
        expect(connection.has_next_page).to be(true)
      end
    end

    context "when on the last page" do
      let(:next_page_bookmark) { nil }

      it "returns false" do
        connection.nodes
        expect(connection.has_next_page).to be(false)
      end
    end
  end

  describe "#has_previous_page" do
    context "when after cursor is present" do
      let(:after_cursor) { "bookmark:abc123" }

      it "returns true" do
        expect(connection.has_previous_page).to be(true)
      end
    end

    context "when on the first page" do
      it "returns false" do
        expect(connection.has_previous_page).to be(false)
      end
    end
  end

  describe "#cursor_for" do
    it "returns the next page bookmark regardless of item" do
      connection.nodes
      expect(connection.cursor_for(Object.new)).to eql(next_page_bookmark)
    end
  end
end
