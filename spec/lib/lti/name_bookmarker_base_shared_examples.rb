# frozen_string_literal: true

#
# Copyright (C) 2021 - present Instructure, Inc.
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

RSpec.shared_context "name_bookmarker_base_shared_examples" do
  let(:account) { account_model }

  shared_examples_for "a bookmarker for models with names" do
    let(:model_base_scope) { raise "to be implemented by examples" }
    let(:model_factory_proc) { raise "to be implemented by examples" }
    let(:model_name_proc) { ->(model) { model.name } }

    {
      simple_lowercase: %w[aaa bbb ccc],
      simple_alphanumeric: %w[Model0 Model1 Model2],
      all_equal: %w[Abc Abc Abc],
      spaces: [" Abc", "A bc", "Abc "],
      casing: %w[abc Abc ABC],
      diacritics: %w[a á ä],
      diacritic_casing: %w[Á Á á á],
      natural_numbers: %w[100 101 11 12],
      letter_plus_natural_numbers: ["a 100", "a 101", "a 11", "a 12"],
      hanzi: %w[我 很 好]
    }.each do |test_name, model_names|
      context "test set #{test_name}" do
        let!(:models) do
          model_names.map { |model_name| model_factory_proc[account, model_name] }
        end

        it "doesn't skip or repeat items (test set #{test_name})" do
          pager = double(current_bookmark: nil, include_bookmark: false)
          first_page = described_class.restrict_scope(model_base_scope, pager).first(2)
          bookmark = described_class.bookmark_for(first_page.last)
          pager = double(current_bookmark: bookmark, include_bookmark: false)
          next_page = described_class.restrict_scope(model_base_scope, pager).to_a
          expect((first_page + next_page).sort).to eq(models.sort)
        end

        it "orders bookmarks in Ruby the same way as the items returned from the database" do
          pager = double(current_bookmark: nil, include_bookmark: false)
          from_db = described_class.restrict_scope(model_base_scope, pager).to_a
          bookmark_order = models.sort_by { |model| described_class.bookmark_for(model) }

          from_db_names_ids = from_db.map { |t| [model_name_proc[t], t.id] }
          bookmark_order_names_ids = bookmark_order.map { |t| [model_name_proc[t], t.id] }
          expect(from_db_names_ids).to eq(bookmark_order_names_ids)
        end
      end
    end

    describe ".bookmark_for" do
      let(:model) { model_factory_proc[account, "ABc"] }

      it "forms a bookmark" do
        expect(described_class.bookmark_for(model)).to eq(
          [Canvas::ICU.collation_key("ABc"), model.id, "ABc"]
        )
      end
    end
  end
end
