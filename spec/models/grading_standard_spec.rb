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
    expect(subject.size).to eq expected.size
    subject.each_with_index do |row, i|
      expect(row[0]).to eq expected[i][0]
      expect(row[1]).to be_within(0.001).of(expected[i][1])
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
    expect(standard.data[0][1]).to be_within(0.00001).of(0.9999)
    expect(input[0][1]).to be_within(0.00001).of(0.9999)
  end

  it "should upgrade in memory when accessing data" do
    standard = GradingStandard.new
    standard.write_attribute(:data, @default_standard_v1)
    standard.write_attribute(:version, 1)
    compare_schemes(standard.data, GradingStandard.default_grading_standard)
    expect(standard.version).to eq GradingStandard::VERSION
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
      expect(standards.length).to eq 1
      expect(standards[0].id).to eq @standard.id
    end

    it "should include standards made in the parent account" do
      grading_standard_for @course.root_account

      standards = GradingStandard.standards_for(@course)
      expect(standards.length).to eq 1
      expect(standards[0].id).to eq @standard.id
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
      expect(standards.length).to eq 2
      expect(standards.map(&:id)).to eq [gs.id, gs2.id]
    end

    it "it should return standards with a title first" do
      gs = grading_standard_for(@course.root_account, :title => "zzz")
      gs2 = grading_standard_for(@course.root_account, :title => "aaa")
      gs2.title = nil
      gs2.save!

      standards = GradingStandard.standards_for(@course).sorted
      expect(standards.length).to eq 2
      expect(standards.map(&:id)).to eq [gs.id, gs2.id]
    end
  end

  context "score_to_grade" do
    it "should compute correct grades" do
      input = [['A', 0.90], ['B+', 0.886], ['B', 0.80], ['C', 0.695], ['D', 0.55], ['M', 0.00]]
      standard = GradingStandard.new
      standard.data = input
      expect(standard.score_to_grade(1005)).to eql("A")
      expect(standard.score_to_grade(105)).to eql("A")
      expect(standard.score_to_grade(100)).to eql("A")
      expect(standard.score_to_grade(99)).to eql("A")
      expect(standard.score_to_grade(90)).to eql("A")
      expect(standard.score_to_grade(89.999)).to eql("B+")
      expect(standard.score_to_grade(88.601)).to eql("B+")
      expect(standard.score_to_grade(88.6)).to eql("B+")
      expect(standard.score_to_grade(88.599)).to eql("B")
      expect(standard.score_to_grade(80)).to eql("B")
      expect(standard.score_to_grade(79.999)).to eql("C")
      expect(standard.score_to_grade(79)).to eql("C")
      expect(standard.score_to_grade(69.501)).to eql("C")
      expect(standard.score_to_grade(69.5)).to eql("C")
      expect(standard.score_to_grade(69.499)).to eql("D")
      expect(standard.score_to_grade(60)).to eql("D")
      expect(standard.score_to_grade(50)).to eql("M")
      expect(standard.score_to_grade(0)).to eql("M")
      expect(standard.score_to_grade(-100)).to eql("M")
    end

    it "should assign the lowest grade to below-scale scores" do
      input = [['A', 0.90], ['B', 0.80], ['C', 0.70], ['D', 0.60], ['E', 0.50]]
      standard = GradingStandard.new
      standard.data = input
      expect(standard.score_to_grade(40)).to eql("E")
    end
  end

  context "grade_to_score" do
    before do
      @gs = GradingStandard.default_instance
    end

    it "should return a score in the proper range for letter grades" do
      score = @gs.grade_to_score('B')
      expect(score).to eql(86.0)
    end

    it "should return nil when no grade matches" do
      score = @gs.grade_to_score('Z')
      expect(score).to eql(nil)
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
      expect(idx).to eql(11)
    end

    it "should match numeric keys" do
      idx = @gs.place_in_scheme(4)
      expect(idx).to eql(0)
    end

    it "should not confuse letters and zeros" do
      @gs.data = {"4.0" => 0.9,
                  "M" => 0.8,
                  "0" => 0.7,
                  "C" => 0.6,
                  "1.4" => 0.5}
      [[4,0],["m",1],[0,2],["C",3],["1.4",4]].each do |grade,exp_index|
        idx = @gs.place_in_scheme(grade)
        expect(idx).to eql(exp_index)
      end
    end
  end

  context "associations" do
    it "should not count deleted standards in associations" do
      grading_standard_for(@course)
      grading_standard_for(@course).destroy
      expect(@course.grading_standards.count).to eq 1

      grading_standard_for(@course.root_account)
      grading_standard_for(@course.root_account).destroy
      expect(@course.root_account.grading_standards.count).to eq 1
    end
  end

  describe "assessed_assignment?" do
    before(:once) do
      student_in_course active_all: true
      @gs = grading_standard_for @course, title: "gs"
    end

    context "without assignment link" do
      it "should be false" do
        expect(@gs).not_to be_assessed_assignment
      end
    end

    context "with assignment link" do
      before(:once) do
        @assignment = @course.assignments.create!(:title => "hi",
          :grading_type => 'letter_grade', :grading_standard_id => @gs.id, :submission_types => ["online_text_entry"])
      end

      context "without submissions" do
        it "should be false" do
          expect(@gs).not_to be_assessed_assignment
        end
      end

      context "with submissions" do
        before(:once) do
          @submission = @assignment.submit_homework(@student, :body => "done!")
        end

        it "should be false if no submissions are graded" do
          expect(@gs).not_to be_assessed_assignment
        end

        it "should be true if a graded submission exists" do
          @submission.grade_it!
          expect(@gs).to be_assessed_assignment
        end
      end
    end
  end
end
