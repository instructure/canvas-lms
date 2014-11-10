#
# Copyright (C) 2011 Instructure, Inc.
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
      Canvas::ICU.stubs(:collator).returns(Canvas::ICU::NaiveCollator)
    end
  end

  context "ICU" do
    include_examples "Collator"

    before do
      skip if Canvas::ICU.collator == Canvas::ICU::NaiveCollator
    end
  end
end
