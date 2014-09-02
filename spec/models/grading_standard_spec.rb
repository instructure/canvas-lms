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

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper.rb')

describe GradingStandard do
  before :once do
    course_with_teacher
    @default_standard_v1 = {
      "A" => 1.0,
      "A-" => 0.93,
      "B+" => 0.89,
      "B" => 0.86,
      "B-" => 0.83,
      "C+" => 0.79,
      "C" => 0.76,
      "C-" => 0.73,
      "D+" => 0.69,
      "D" => 0.66,
      "D-" => 0.63,
      "F" => 0.6
    }.to_a.sort_by { |i| i[1] }.reverse
  end

  def compare_schemes(subject, expected)
    subject.size.should == expected.size
    subject.each_with_index do |row, i|
      row[0].should == expected[i][0]
      row[1].should be_close(expected[i][1], 0.001)
    end
  end

  it "should upgrade the standard scheme from v1 to v2" do
    converted = GradingStandard.upgrade_data(@default_standard_v1, 1)
    default = GradingStandard.default_grading_standard
    compare_schemes(converted, default)
  end

  it "should not the argument to data=" do
    input = [['A', 0.9999]]
    standard = GradingStandard.new
    standard.data = input
    standard.data[0][1].should be_close(0.9999, 0.00001)
    input[0][1].should be_close(0.9999, 0.00001)
  end

  it "should upgrade in memory when accessing data" do
    standard = GradingStandard.new
    standard.write_attribute(:data, @default_standard_v1)
    standard.write_attribute(:version, 1)
    compare_schemes(standard.data, GradingStandard.default_grading_standard)
    standard.version.should == GradingStandard::VERSION
  end

  it "should not upgrade repeatedly when accessing data repeatedly" do
    standard = GradingStandard.new
    standard.write_attribute(:data, @default_standard_v1)
    standard.write_attribute(:version, 1)
    compare_schemes(standard.data, GradingStandard.default_grading_standard)
    compare_schemes(standard.data, GradingStandard.default_grading_standard)
    compare_schemes(standard.data, GradingStandard.default_grading_standard)
  end

  context "standards_for" do
    it "should return standards that match the context" do
      grading_standard_for @course

      standards = GradingStandard.standards_for(@course)
      standards.length.should == 1
      standards[0].id.should == @standard.id
    end

    it "should include standards made in the parent account" do
      grading_standard_for @course.root_account

      standards = GradingStandard.standards_for(@course)
      standards.length.should == 1
      standards[0].id.should == @standard.id
    end
  end

  context "sorted" do
    it "should return used grading standards before unused ones" do
      gs = grading_standard_for(@course.root_account, :title => "zzz")
      gs2 = grading_standard_for(@course.root_account, :title => "aaa")

      # Add this grading standard to 3 assignments, triggring the "used" condition
      3.times do
        @course.assignments.create!(:title => "hi", :grading_standard_id => gs.id)
      end

      standards = GradingStandard.standards_for(@course).sorted
      standards.length.should == 2
      standards.map(&:id).should == [gs.id, gs2.id]
    end

    it "it should return standards with a title first" do
      gs = grading_standard_for(@course.root_account, :title => "zzz")
      gs2 = grading_standard_for(@course.root_account, :title => "aaa")
      gs2.title = nil
      gs2.save!

      standards = GradingStandard.standards_for(@course).sorted
      standards.length.should == 2
      standards.map(&:id).should == [gs.id, gs2.id]
    end
  end

  context "score_to_grade" do
    it "should compute correct grades" do
      input = [['A', 0.90], ['B', 0.80], ['C', 0.675], ['D', 0.55], ['M', 0.00]]
      standard = GradingStandard.new
      standard.data = input
      standard.score_to_grade(1005).should eql("A")
      standard.score_to_grade(105).should eql("A")
      standard.score_to_grade(100).should eql("A")
      standard.score_to_grade(99).should eql("A")
      standard.score_to_grade(90).should eql("A")
      standard.score_to_grade(89.999).should eql("B")
      standard.score_to_grade(89.001).should eql("B")
      standard.score_to_grade(89).should eql("B")
      standard.score_to_grade(88.999).should eql("B")
      standard.score_to_grade(80).should eql("B")
      standard.score_to_grade(79).should eql("C")
      standard.score_to_grade(67.501).should eql("C")
      standard.score_to_grade(67.5).should eql("C")
      standard.score_to_grade(67.499).should eql("D")
      standard.score_to_grade(60).should eql("D")
      standard.score_to_grade(50).should eql("M")
      standard.score_to_grade(0).should eql("M")
      standard.score_to_grade(-100).should eql("M")
    end

    it "should assign the lowest grade to below-scale scores" do
      input = [['A', 0.90], ['B', 0.80], ['C', 0.70], ['D', 0.60], ['E', 0.50]]
      standard = GradingStandard.new
      standard.data = input
      standard.score_to_grade(40).should eql("E")
    end
  end

  context "grade_to_score" do
    before do
      @gs = GradingStandard.default_instance
    end

    it "should return a score in the proper range for letter grades" do
      score = @gs.grade_to_score('B')
      score.should eql(86.0)
    end

    it "should return nil when no grade matches" do
      score = @gs.grade_to_score('Z')
      score.should eql(nil)
    end
  end

  context "place in scheme" do
    before do
      @gs = GradingStandard.default_instance
      @gs.data = {"4.0" => 0.94,
                  "3.7" => 0.90,
                  "3.3" => 0.87,
                  "3.0" => 0.84,
                  "2.7" => 0.80,
                  "2.3" => 0.77,
                  "2.0" => 0.74,
                  "1.7" => 0.70,
                  "1.3" => 0.67,
                  "1.0" => 0.64,
                  "0" => 0.01,
                  "M" => 0.0 }
    end

    it "should match alphabetical keys regardless of case" do
      idx = @gs.place_in_scheme('m')
      idx.should eql(11)
    end

    it "should match numeric keys" do
      idx = @gs.place_in_scheme(4)
      idx.should eql(0)
    end

    it "should not confuse letters and zeros" do
      @gs.data = {"4.0" => 0.9,
                  "M" => 0.8,
                  "0" => 0.7,
                  "C" => 0.6,
                  "1.4" => 0.5}
      [[4,0],["m",1],[0,2],["C",3],["1.4",4]].each do |grade,exp_index|
        idx = @gs.place_in_scheme(grade)
        idx.should eql(exp_index)
      end
    end
  end

  context "associations" do
    it "should not count deleted standards in associations" do
      grading_standard_for(@course)
      grading_standard_for(@course).destroy
      @course.grading_standards.count.should == 1

      grading_standard_for(@course.root_account)
      grading_standard_for(@course.root_account).destroy
      @course.root_account.grading_standards.count.should == 1
    end
  end
end
