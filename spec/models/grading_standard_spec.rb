# frozen_string_literal: true

#
# Copyright (C) 2011 - present Instructure, Inc.
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

  describe "validations" do
    it { is_expected.to belong_to(:context).required }
    it { is_expected.to validate_presence_of(:data) }
    it { is_expected.to serialize(:data) }

    describe "grading standard data" do
      let(:standard) { GradingStandard.new(context: @course) }

      it "does not throw an error if `data` is not supplied" do
        expect { standard.valid? }.not_to raise_error
      end

      it "is invalid when there is no bucket with a floor value of 0.0" do
        standard.data = [["A", 0.9], ["B", 0.8], ["C", 0.7]]

        expect(standard).not_to be_valid
      end

      it "is valid when there is a bucket with a floor value of 0.0" do
        standard.data = [["A", 0.9], ["B", 0.8], ["C", 0.7], ["D", 0.0]]

        expect(standard).to be_valid
      end

      it "is valid even if the buckets are out of order" do
        standard.data = [["B", 0.8], ["A", 0.9], ["D", 0.0], ["C", 0.7]]

        expect(standard).to be_valid
      end
    end
  end

  it "strips trailing whitespaces from scheme names" do
    bad_data = GradingStandard.default_grading_standard
    bad_data[0][0] = "   A "
    standard = @course.grading_standards.create!(data: bad_data)
    expect(standard.data[0][0]).to eq "A"
  end

  it "does not strip trailing whitespaces from scheme name if saving only unrelated changes" do
    standard = @course.grading_standards.create!(data: GradingStandard.default_grading_standard)
    bad_data = standard.data
    bad_data[0][0] = "   A "
    standard.update_column(:data, bad_data)
    standard.update!(title: "updated")
    expect(standard.data[0][0]).to eq "   A "
  end

  it "upgrades the standard scheme from v1 to v2" do
    converted = GradingStandard.upgrade_data(@default_standard_v1, 1)
    default = GradingStandard.default_grading_standard
    compare_schemes(converted, default)
  end

  it "does not the argument to data=" do
    input = [["A", 0.9999]]
    standard = GradingStandard.new
    standard.data = input
    expect(standard.data[0][1]).to be_within(0.00001).of(0.9999)
    expect(input[0][1]).to be_within(0.00001).of(0.9999)
  end

  it "upgrades in memory when accessing data" do
    standard = GradingStandard.new
    standard.write_attribute(:data, @default_standard_v1)
    standard.write_attribute(:version, 1)
    compare_schemes(standard.data, GradingStandard.default_grading_standard)
    expect(standard.version).to eq GradingStandard::VERSION
  end

  it "does not upgrade repeatedly when accessing data repeatedly" do
    standard = GradingStandard.new
    standard.write_attribute(:data, @default_standard_v1)
    standard.write_attribute(:version, 1)
    compare_schemes(standard.data, GradingStandard.default_grading_standard)
    compare_schemes(standard.data, GradingStandard.default_grading_standard)
    compare_schemes(standard.data, GradingStandard.default_grading_standard)
  end

  describe "#default_standard?" do
    it "returns true for the default instance" do
      expect(GradingStandard.default_instance).to be_default_standard
    end

    it "returns false for a non-default instance" do
      expect(GradingStandard.new).not_to be_default_standard
    end
  end

  context "#for" do
    it "returns standards that match the context" do
      grading_standard_for @course

      standards = GradingStandard.for(@course)
      expect(standards.length).to eq 1
      expect(standards[0].id).to eq @standard.id
    end

    it "includes standards made in the parent account" do
      grading_standard_for @course.root_account

      standards = GradingStandard.for(@course)
      expect(standards.length).to eq 1
      expect(standards[0].id).to eq @standard.id
    end
  end

  context "sorted" do
    it "returns used grading standards before unused ones" do
      gs = grading_standard_for(@course.root_account, title: "zzz")
      gs2 = grading_standard_for(@course.root_account, title: "aaa")

      # Add this grading standard to 3 assignments, triggring the "used" condition
      3.times do
        @course.assignments.create!(title: "hi", grading_standard_id: gs.id)
      end

      standards = GradingStandard.for(@course).sorted
      expect(standards.length).to eq 2
      expect(standards.map(&:id)).to eq [gs.id, gs2.id]
    end

    it "returns standards with a title first" do
      gs = grading_standard_for(@course.root_account, title: "zzz")
      gs2 = grading_standard_for(@course.root_account, title: "aaa")
      gs2.title = nil
      gs2.save!

      standards = GradingStandard.for(@course).sorted
      expect(standards.length).to eq 2
      expect(standards.map(&:id)).to eq [gs.id, gs2.id]
    end
  end

  context "score_to_grade" do
    it "computes correct grades" do
      input = [["A", 0.90], ["B+", 0.886], ["B", 0.80], ["C", 0.695], ["D", 0.555], ["E", 0.545], ["M", 0.00]]
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
      expect(standard.score_to_grade(55.5)).to eql("D")
      expect(standard.score_to_grade(54.5)).to eql("E")
      expect(standard.score_to_grade(50)).to eql("M")
      expect(standard.score_to_grade(0)).to eql("M")
      expect(standard.score_to_grade(-100)).to eql("M")
    end

    it "assigns the lowest grade to below-scale scores" do
      input = [["A", 0.90], ["B", 0.80], ["C", 0.70], ["D", 0.60], ["E", 0.50]]
      standard = GradingStandard.new
      standard.data = input
      expect(standard.score_to_grade(40)).to eql("E")
    end
  end

  context "grade_to_score" do
    before do
      @gs = GradingStandard.default_instance
    end

    it "returns a score in the proper range for letter grades" do
      score = @gs.grade_to_score("B")
      expect(score).to eq 86.0
    end

    it "returns nil when no grade matches" do
      score = @gs.grade_to_score("Z")
      expect(score).to be_nil
    end

    it "does not return more than 3 decimal digits" do
      score = @gs.grade_to_score("A-")
      decimal_part = score.to_s.split(".")[1]
      expect(decimal_part.length).to be <= 3
    end
  end

  context "place in scheme" do
    before do
      @gs = GradingStandard.default_instance
      @gs.data = { "4.0" => 0.94,
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

    it "matches alphabetical keys regardless of case" do
      idx = @gs.place_in_scheme("m")
      expect(idx).to be(11)
    end

    it "matches numeric keys" do
      idx = @gs.place_in_scheme(4)
      expect(idx).to be(0)
    end

    it "does not confuse letters and zeros" do
      @gs.data = { "4.0" => 0.9,
                   "M" => 0.8,
                   "0" => 0.7,
                   "C" => 0.6,
                   "1.4" => 0.5 }
      [[4, 0], ["m", 1], [0, 2], ["C", 3], ["1.4", 4]].each do |grade, exp_index|
        idx = @gs.place_in_scheme(grade)
        expect(idx).to eql(exp_index)
      end
    end
  end

  context "associations" do
    it "does not count deleted standards in associations" do
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
      it "is false" do
        expect(@gs).not_to be_assessed_assignment
      end
    end

    context "with assignment link" do
      before(:once) do
        @assignment = @course.assignments.create!(title: "hi",
                                                  grading_type: "letter_grade", grading_standard_id: @gs.id, submission_types: ["online_text_entry"])
      end

      context "without submissions" do
        it "is false" do
          expect(@gs).not_to be_assessed_assignment
        end
      end

      context "with submissions" do
        before(:once) do
          @submission = @assignment.submit_homework(@student, body: "done!")
        end

        it "is false if no submissions are graded" do
          expect(@gs).not_to be_assessed_assignment
        end

        it "is true if a graded submission exists" do
          @submission.grade_it!
          expect(@gs).to be_assessed_assignment
        end
      end
    end
  end

  describe "permissions:" do
    context "course belonging to root account" do
      before(:once) do
        @root_account = Account.default
        @sub_account = @root_account.sub_accounts.create!
        course_with_teacher(account: @root_account)
        @enrollment.update(workflow_state: "active")
        @root_account_standard = grading_standard_for(@root_account)
        @sub_account_standard = grading_standard_for(@sub_account)
        @course_standard = grading_standard_for(@course)
      end

      context "root-account admin" do
        before(:once) do
          account_admin_user(account: @root_account)
        end

        it "is able to manage root-account level grading standards" do
          expect(@root_account_standard.grants_right?(@admin, :manage)).to be(true)
        end

        it "is able to manage sub-account level grading standards" do
          expect(@sub_account_standard.grants_right?(@admin, :manage)).to be(true)
        end

        it "is able to manage course level grading standards" do
          expect(@course_standard.grants_right?(@admin, :manage)).to be(true)
        end
      end

      context "sub-account admin" do
        before(:once) do
          account_admin_user(account: @sub_account)
        end

        it "is not able to manage root-account level grading standards" do
          expect(@root_account_standard.grants_right?(@admin, :manage)).to be(false)
        end

        it "is able to manage sub-account level grading standards" do
          expect(@sub_account_standard.grants_right?(@admin, :manage)).to be(true)
        end

        it "is not able to manage course level grading standards, when the course is under the root-account" do
          expect(@course_standard.grants_right?(@admin, :manage)).to be(false)
        end
      end

      context "teacher" do
        it "is not able to manage root-account level grading standards" do
          expect(@root_account_standard.grants_right?(@teacher, :manage)).to be(false)
        end

        it "is not able to manage sub-account level grading standards" do
          expect(@sub_account_standard.grants_right?(@teacher, :manage)).to be(false)
        end

        it "is able to manage course level grading standards" do
          expect(@course_standard.grants_right?(@teacher, :manage)).to be(true)
        end
      end
    end

    context "course belonging to sub-account" do
      before(:once) do
        @root_account = Account.default
        @sub_account = @root_account.sub_accounts.create!
        course_with_teacher(account: @sub_account)
        @enrollment.update(workflow_state: "active")
        @root_account_standard = grading_standard_for(@root_account)
        @sub_account_standard = grading_standard_for(@sub_account)
        @course_standard = grading_standard_for(@course)
      end

      context "root-account admin" do
        before(:once) do
          account_admin_user(account: @root_account)
        end

        it "is able to manage root-account level grading standards" do
          expect(@root_account_standard.grants_right?(@admin, :manage)).to be(true)
        end

        it "is able to manage sub-account level grading standards" do
          expect(@sub_account_standard.grants_right?(@admin, :manage)).to be(true)
        end

        it "is able to manage course level grading standards" do
          expect(@course_standard.grants_right?(@admin, :manage)).to be(true)
        end
      end

      context "sub-account admin" do
        before(:once) do
          account_admin_user(account: @sub_account)
        end

        it "is not able to manage root-account level grading standards" do
          expect(@root_account_standard.grants_right?(@admin, :manage)).to be(false)
        end

        it "is able to manage sub-account level grading standards" do
          expect(@sub_account_standard.grants_right?(@admin, :manage)).to be(true)
        end

        it "is able to manage course level grading standards, when the course is under the sub-account" do
          expect(@course_standard.grants_right?(@admin, :manage)).to be(true)
        end
      end

      context "teacher" do
        it "is not able to manage root-account level grading standards" do
          expect(@root_account_standard.grants_right?(@teacher, :manage)).to be(false)
        end

        it "is not able to manage sub-account level grading standards" do
          expect(@sub_account_standard.grants_right?(@teacher, :manage)).to be(false)
        end

        it "is able to manage course level grading standards" do
          expect(@course_standard.grants_right?(@teacher, :manage)).to be(true)
        end
      end
    end
  end

  describe "root account ID" do
    let_once(:root_account) { Account.create! }
    let_once(:subaccount) { Account.create(root_account: root_account) }
    let_once(:course) { Course.create!(account: subaccount) }

    let_once(:data) { [["A", 94], ["F", 0]] }

    context "when this grading standard is associated with a course" do
      it "is set to the course's root account ID" do
        grading_standard = course.grading_standards.create!(workflow_state: "active", data: data)
        expect(grading_standard.root_account_id).to eq root_account.id
      end
    end

    context "when this grading standard is associated with an account" do
      it "is set to the account's ID if the account is a root account" do
        grading_standard = subaccount.grading_standards.create!(workflow_state: "active", data: data)
        expect(grading_standard.root_account_id).to eq root_account.id
      end

      it "is set to the account's root account ID if the account is not a root account" do
        grading_standard = root_account.grading_standards.create!(workflow_state: "active", data: data)
        expect(grading_standard.root_account_id).to eq root_account.id
      end
    end
  end
end
