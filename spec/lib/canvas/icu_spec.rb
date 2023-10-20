# frozen_string_literal: true

#
# Copyright (C) 2013 - present Instructure, Inc.
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

describe Canvas::ICU do
  shared_examples_for "Collator" do
    describe ".collate_by" do
      it "works" do
        array = [{ id: 2, str: "a" }, { id: 1, str: "b" }]
        result = Canvas::ICU.collate_by(array) { |x| x[:str] }
        expect(result.first[:id]).to eq 2
        expect(result.last[:id]).to eq 1
      end

      it "handles CanvasSort::First" do
        array = [{ id: 2, str: CanvasSort::First }, { id: 1, str: "b" }]
        result = Canvas::ICU.collate_by(array) { |x| x[:str] }
        expect(result.first[:id]).to eq 2
        expect(result.last[:id]).to eq 1
      end
    end

    describe ".collation_key" do
      it "returns something that's comparable" do
        a = "a"
        b = "b"
        a_prime = Canvas::ICU.collation_key(a)
        expect(a.object_id).not_to eq a_prime.object_id
        b_prime = Canvas::ICU.collation_key(b)
        expect(a_prime <=> b_prime).to eq(-1)
      end

      it "pass-thrus CanvasSort::First" do
        expect(Canvas::ICU.collation_key(CanvasSort::First)).to eq CanvasSort::First
      end
    end

    describe ".compare" do
      it "works" do
        expect(Canvas::ICU.compare("a", "b")).to eq(-1)
      end

      it "handles CanvasSort::First" do
        expect(Canvas::ICU.compare(CanvasSort::First, "a")).to eq(-1)
      end
    end

    describe ".collate" do
      it "works" do
        expect(Canvas::ICU.collate(["b", "a"])).to eq ["a", "b"]
      end

      it "ats the least be case insensitive" do
        results = Canvas::ICU.collate(%w[b a A B])
        expect(results[0..1].sort).to eq ["a", "A"].sort
        expect(results[2..3].sort).to eq ["b", "B"].sort
      end

      it "does not ignore punctuation" do
        expect(Canvas::ICU.collate(["ab, cd", "a, bcd"])).to eq ["a, bcd", "ab, cd"]
      end
    end
  end

  context "NaiveCollator" do
    include_examples "Collator"

    before do
      allow(Canvas::ICU).to receive(:collator).and_return(Canvas::ICU::NaiveCollator)
    end
  end

  shared_examples_for "ICU Collator" do
    it "sorts several examples correctly" do
      # English sorts ñ as just an n, but after regular n's
      expect(collate(%w[ana aña añb anb])).to eq(
        %w[ana aña anb añb]
      )

      # Spanish sorts it as a separate letter
      I18n.with_locale(:es) do
        expect(collate(%w[ana aña añb anb])).to eq(
          %w[ana anb aña añb]
        )
      end

      # Punctuation is not ignored (commas separating surnames)
      expect(collate(["Wall, Ball", "Wallart, Shmallart"])).to eq(
        ["Wall, Ball", "Wallart, Shmallart"]
      )

      # shorter words sort first
      expect(collate(["hatch", "hat"])).to eq(
        ["hat", "hatch"]
      )

      # capitalization is a secondary sort level
      expect(collate(%w[aba aBb abb aBa])).to eq(
        %w[aba aBa abb aBb]
      )

      # numbers sort naturally
      expect(collate(%w[10 1 2 11])).to eq(
        %w[1 2 10 11]
      )

      # hyphenated last name is not a word separator
      # I can't get this to pass, without breaking the Wallart case above. Either you ignore
      # punctuation, or you don't.
      # expect(Canvas::ICU.collator.collate(["Hoover, Lorelei", "Hoover-Mertz, Joseph"])).to eq(
      #   ["Hoover, Lorelei", "Hoover-Mertz, Joseph"])
    end
  end

  context "ICU" do
    include_examples "Collator"
    include_examples "ICU Collator"

    before do
      if (ICU::Lib.version rescue false)
        if Canvas::ICU.collator == Canvas::ICU::NaiveCollator
          raise "ICU appears to be installed, but we didn't load it correctly"
        end
      elsif Canvas::ICU.collator == Canvas::ICU::NaiveCollator
        skip "ICU is not installed"
      end
    end

    def collate(values)
      Canvas::ICU.collator.collate(values)
    end

    context "postgres" do
      include_examples "ICU Collator"

      before do
        skip "Postgres does not have collation support" if ActiveRecord::Base.best_unicode_collation_key("col").include?("LOWER")
      end

      def collate(values)
        ActiveRecord::Base.connection.select_values <<~SQL.squish
          SELECT col FROM ( VALUES #{values.map { |v| "(#{ActiveRecord::Base.connection.quote(v)})" }.join(", ")} ) AS s(col)
          ORDER BY #{ActiveRecord::Base.best_unicode_collation_key("col")}
        SQL
      end
    end
  end
end
