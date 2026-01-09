# frozen_string_literal: true

#
# Copyright (C) 2020 - present Instructure, Inc.
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

describe EventStream::IndexStrategy::ActiveRecord do
  let(:fake_record_type) do
    Class.new do
      def created_at
        @created_at ||= Time.zone.now
      end

      def id
        @id ||= rand(1..1000)
      end

      def self.paginate(**)
        self
      end

      def self.to_ary
        [new]
      end

      def self.next_page
        self
      end

      def self.where(condition)
        apply_condition(condition)
        self
      end

      def self.order(condition)
        apply_condition(condition)
        self
      end

      def self.apply_condition(condition)
        @conditions ||= []
        @conditions << condition
      end

      def self.applied_conditions
        @conditions
      end
    end
  end

  describe "scope assembly" do
    before do
      stream = double("stream",
                      record_type: fake_record_type)
      ar_cls = fake_record_type
      base_index = EventStream::Index.new(stream) do
        ar_scope_proc ->(a1, a2) { ar_cls.where({ one: a1.id, two: a2.id }) }
      end
      @index = base_index.strategy
    end

    it "applies scope conditions with dual sorting" do
      arg1 = double("arg1", id: "abc")
      arg2 = double("arg2", id: "def")
      outcome = @index.for_ar_scope([arg1, arg2], {})
      outcome.paginate(per_page: 10)
      conditions = fake_record_type.applied_conditions
      expect(conditions).to include({ one: "abc", two: "def" })
      expect(conditions).to include({ created_at: :desc, id: :desc })
    end

    describe "pager_to_records" do
      let(:test_timestamp) { "2020-06-12T15:34:13-06:00" }
      let(:parsed_timestamp) { Time.zone.parse(test_timestamp) }
      let(:pager_base) do
        Class.new do
          attr_reader :bookmark_value

          def initialize(bookmark)
            @bookmark_value = bookmark
          end

          def current_bookmark
            @bookmark_value
          end

          def per_page
            10
          end
        end
      end

      context "with legacy string bookmark" do
        it "applies timestamp-only WHERE clause with dual sorting" do
          pager = pager_base.new(test_timestamp)
          base_scope = fake_record_type
          expect(fake_record_type).to receive(:where).with(created_at: ...parsed_timestamp).and_return(fake_record_type)
          expect(fake_record_type).to receive(:order).with({ created_at: :desc, id: :desc }).and_return(fake_record_type)
          EventStream::IndexStrategy::ActiveRecord.pager_to_records(base_scope, pager)
        end
      end

      context "with array bookmark" do
        it "applies compound WHERE clause with timestamp and id" do
          pager = pager_base.new([test_timestamp, 150])
          base_scope = fake_record_type

          expect(fake_record_type).to receive(:where).with(
            "(created_at < ? OR (created_at = ? AND id < ?))",
            parsed_timestamp,
            parsed_timestamp,
            150
          ).and_return(fake_record_type)
          expect(fake_record_type).to receive(:order).with({ created_at: :desc, id: :desc }).and_return(fake_record_type)
          EventStream::IndexStrategy::ActiveRecord.pager_to_records(base_scope, pager)
        end
      end
    end
  end

  describe "internal Bookmarker" do
    let(:bookmarker) { EventStream::IndexStrategy::ActiveRecord::Bookmarker.new(fake_record_type) }

    describe "#bookmark_for" do
      it "returns array with [created_at, id]" do
        model = fake_record_type.new
        model.instance_variable_set(:@id, 123)
        bookmark_value = bookmarker.bookmark_for(model)
        expect(bookmark_value).to eq([model.created_at.to_s, 123])
      end
    end

    describe "#validate" do
      context "with valid bookmarks" do
        it "accepts array with [timestamp, id]" do
          bookmark = [Time.zone.now.to_s, 123]
          expect(bookmarker.validate(bookmark)).to be(true)
        end

        it "accepts legacy string format for backward compatibility" do
          bookmark = Time.zone.now.to_s
          expect(bookmarker.validate(bookmark)).to be(true)
        end
      end

      context "with invalid array bookmarks" do
        it "rejects array with wrong size" do
          bookmark = [Time.zone.now.to_s]
          expect(bookmarker.validate(bookmark)).to be(false)
        end

        it "rejects array with non-string timestamp" do
          bookmark = [123, 456]
          expect(bookmarker.validate(bookmark)).to be(false)
        end

        it "rejects array with non-integer id" do
          bookmark = [Time.zone.now.to_s, "not_an_integer"]
          expect(bookmarker.validate(bookmark)).to be(false)
        end

        it "rejects array with invalid timestamp" do
          bookmark = ["not a timestamp", 123]
          expect(bookmarker.validate(bookmark)).to be(false)
        end
      end

      context "with invalid types" do
        it "rejects integer" do
          expect(bookmarker.validate(123)).to be(false)
        end

        it "rejects nil" do
          expect(bookmarker.validate(nil)).to be(false)
        end

        it "rejects hash" do
          expect(bookmarker.validate({ "created_at" => Time.zone.now.to_s, "id" => 123 })).to be(false)
        end

        it "rejects empty array" do
          expect(bookmarker.validate([])).to be(false)
        end
      end
    end
  end
end
