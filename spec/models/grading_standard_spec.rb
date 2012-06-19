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
  before do
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
    standard.data[0][1].should be_close(0.999, 0.00001)
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
      course_with_teacher
      grading_standard_for @course
      
      standards = GradingStandard.standards_for(@course)
      standards.length.should == 1
      standards[0].id.should == @standard.id
    end

    it "should include standards made in the parent account" do
      course_with_teacher
      grading_standard_for @course.root_account
      
      standards = GradingStandard.standards_for(@course)
      standards.length.should == 1
      standards[0].id.should == @standard.id
    end
  end

  context "score_to_grade" do
    it "should compute correct grades" do
      input = [['A', 0.90], ['B', 0.80], ['C', 0.675], ['D', 0.55], ['E', 0.00]]
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
      standard.score_to_grade(50).should eql("E")
      standard.score_to_grade(0).should eql("E")
      standard.score_to_grade(-100).should eql("E")
    end

    it "should assign the lowest grade to below-scale scores" do
      input = [['A', 0.90], ['B', 0.80], ['C', 0.70], ['D', 0.60], ['E', 0.50]]
      standard = GradingStandard.new
      standard.data = input
      standard.score_to_grade(40).should eql("E")
    end
  end
end
