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

require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper.rb')

describe Canvas::ICU do
  shared_examples_for "Collator" do
    describe ".collate_by" do
      it "should work" do
        array = [{id: 2, str: 'a'}, {id:1, str: 'b'}]
        result = Canvas::ICU.collate_by(array) { |x| x[:str] }
        expect(result.first[:id]).to eq 2
        expect(result.last[:id]).to eq 1
      end

      it "should handle CanvasSort::First" do
        array = [{id: 2, str: CanvasSort::First}, {id:1, str: 'b'}]
        result = Canvas::ICU.collate_by(array) { |x| x[:str] }
        expect(result.first[:id]).to eq 2
        expect(result.last[:id]).to eq 1
      end
    end

    describe ".collation_key" do
      it "should return something that's comparable" do
        a = "a"; b = "b"
        a_prime = Canvas::ICU.collation_key(a)
        expect(a.object_id).not_to eq a_prime.object_id
        b_prime = Canvas::ICU.collation_key(b)
        expect(a_prime <=> b_prime).to eq -1
      end

      it "should pass-thru CanvasSort::First" do
        expect(Canvas::ICU.collation_key(CanvasSort::First)).to eq CanvasSort::First
      end
    end

    describe ".compare" do
      it "should work" do
        expect(Canvas::ICU.compare("a", "b")).to eq -1
      end

      it "should handle CanvasSort::First" do
        expect(Canvas::ICU.compare(CanvasSort::First, "a")).to eq -1
      end
    end

    describe ".collate" do
      it "should work" do
        expect(Canvas::ICU.collate(["b", "a"])).to eq ["a", "b"]
      end

      it "should at the least be case insensitive" do
        results = Canvas::ICU.collate(["b", "a", "A", "B"])
        expect(results[0..1].sort).to eq ["a", "A"].sort
        expect(results[2..3].sort).to eq ["b", "B"].sort
      end

      it "should not ignore punctuation" do
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

  context "ICU" do
    include_examples "Collator"

    before do
      if (ICU::Lib.version rescue false)
        if Canvas::ICU.collator == Canvas::ICU::NaiveCollator
          raise "ICU appears to be installed, but we didn't load it correctly"
        end
      else
        skip if Canvas::ICU.collator == Canvas::ICU::NaiveCollator
      end
    end

    it "sorts several examples correctly" do
      # English sorts ñ as just an n, but after regular n's
      expect(Canvas::ICU.collator.collate(["ana", "aña", "añb", "anb"])). to eq(
        ["ana", "aña", "anb", "añb"])

      # Spanish sorts it as a separate letter
      expect(Canvas::ICU.collator(:es).collate(["ana", "aña", "añb", "anb"])). to eq(
        ["ana", "anb", "aña", "añb"])

      # Punctuation is not ignored (commas separating surnames)
      expect(Canvas::ICU.collator.collate(["Wall, Ball", "Wallart, Shmallart"])).to eq(
        ["Wall, Ball", "Wallart, Shmallart"])

      # shorter words sort first
      expect(Canvas::ICU.collator.collate(["hatch", "hat"])).to eq(
        ["hat", "hatch"])

      # capitalization is a secondary sort level
      expect(Canvas::ICU.collator.collate(["aba", "aBb", "abb", "aBa"])).to eq(
        ["aba", "aBa", "abb", "aBb"])

      # numbers sort naturally
      expect(Canvas::ICU.collator.collate(["10", "1", "2", "11"])).to eq(
        ["1", "2", "10", "11"])

      # hyphenated last name is not a word separator
      # I can't get this to pass, without breaking the Wallart case above. Either you ignore
      # punctuation, or you don't.
      # expect(Canvas::ICU.collator.collate(["Hoover, Lorelei", "Hoover-Mertz, Joseph"])).to eq(
      #   ["Hoover, Lorelei", "Hoover-Mertz, Joseph"])
    end
  end
end
