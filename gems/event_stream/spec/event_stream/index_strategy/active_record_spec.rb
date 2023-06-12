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
                      record_type: EventStream::Record,
                      active_record_type: fake_record_type)
      ar_cls = fake_record_type
      base_index = EventStream::Index.new(stream) do
        table "table"
        entry_proc ->(_a1, _a2) {}
        ar_scope_proc ->(a1, a2) { ar_cls.where({ one: a1.id, two: a2.id }) }
      end
      @index = base_index.strategy_for(:active_record)
    end

    it "loads records from DB" do
      arg1 = double("arg1", id: "abc")
      arg2 = double("arg2", id: "def")
      outcome = @index.for_ar_scope([arg1, arg2], {})
      outcome.paginate(per_page: 10)
      conditions = fake_record_type.applied_conditions
      expect(conditions).to include({ one: "abc", two: "def" })
      expect(conditions).to include("created_at DESC")
    end

    it "handles bookmark presence" do
      pager_type = Class.new do
        def current_bookmark
          "2020-06-12T15:34:13-06:00"
        end

        def per_page
          10
        end
      end
      base_scope = fake_record_type
      expect(fake_record_type).to receive(:where).with("created_at < ?", Time.zone.parse("2020-06-12T15:34:13-06:00")).and_return(fake_record_type)
      expect(fake_record_type).to receive(:order).with("created_at DESC").and_return(fake_record_type)
      EventStream::IndexStrategy::ActiveRecord.pager_to_records(base_scope, pager_type.new)
    end
  end

  describe "internal Bookmarker" do
    it "just uses the created_at field for bookmarking" do
      bookmarker = EventStream::IndexStrategy::ActiveRecord::Bookmarker.new(fake_record_type)
      model = fake_record_type.new
      bookmark_value = bookmarker.bookmark_for(model)
      expect(bookmark_value).to eq(model.created_at.to_s)
      expect(bookmarker.validate(bookmark_value)).to be(true)
    end
  end
end
