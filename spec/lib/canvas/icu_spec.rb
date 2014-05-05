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
        result.first[:id].should == 2
        result.last[:id].should == 1
      end

      it "should handle CanvasSort::First" do
        array = [{id: 2, str: CanvasSort::First}, {id:1, str: 'b'}]
        result = Canvas::ICU.collate_by(array) { |x| x[:str] }
        result.first[:id].should == 2
        result.last[:id].should == 1
      end
    end

    describe ".collation_key" do
      it "should return something that's comparable" do
        a = "a"; b = "b"
        a_prime = Canvas::ICU.collation_key(a)
        a.object_id.should_not == a_prime.object_id
        b_prime = Canvas::ICU.collation_key(b)
        (a_prime <=> b_prime).should == -1
      end

      it "should pass-thru CanvasSort::First" do
        Canvas::ICU.collation_key(CanvasSort::First).should == CanvasSort::First
      end
    end

    describe ".compare" do
      it "should work" do
        Canvas::ICU.compare("a", "b").should == -1
      end

      it "should handle CanvasSort::First" do
        Canvas::ICU.compare(CanvasSort::First, "a").should == -1
      end
    end

    describe ".collate" do
      it "should work" do
        Canvas::ICU.collate(["b", "a"]).should == ["a", "b"]
      end

      it "should at the least be case insensitive" do
        results = Canvas::ICU.collate(["b", "a", "A", "B"])
        results[0..1].sort.should == ["a", "A"].sort
        results[2..3].sort.should == ["b", "B"].sort
      end

      it "should not ignore punctuation" do
        Canvas::ICU.collate(["ab, cd", "a, bcd"]).should == ["a, bcd", "ab, cd"]
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
      pending if Canvas::ICU.collator == Canvas::ICU::NaiveCollator
    end
  end
end
