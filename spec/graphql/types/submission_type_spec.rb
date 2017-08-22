#
# Copyright (C) 2017 - present Instructure, Inc.
#
# This file is part of Canvas.
#
# Canvas is free software: you can redistribute it and/or modify it under the
# terms of the GNU Affero General Public License as published by the Free
# Software Foundation, version 3 of the License.
#
# Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
# A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
# details.
#
# You should have received a copy of the GNU Affero General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#

require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')
require File.expand_path(File.dirname(__FILE__) + '/../../helpers/graphql_type_tester')

describe Types::SubmissionType do
  before(:once) do
    student_in_course(active_all: true)
    @assignment = @course.assignments.create! name: "asdf", points_possible: 10
    @submission, _ = @assignment.grade_student(@student, score: 8, grader: @teacher)
  end

  let(:submission_type) { GraphQLTypeTester.new(Types::SubmissionType, @submission) }

  it "works" do
    expect(submission_type.user).to eq @student
    expect(submission_type.excused).to eq false
    expect(submission_type.assignment).to eq @assignment
  end

  describe "score and grade" do
    context "muted assignment" do
      before { @assignment.update_attribute(:muted, true) }

      it "returns score/grade for teachers when assignment is muted" do
        expect(submission_type.score(current_user: @teacher)).to eq @submission.score
        expect(submission_type.grade(current_user: @teacher)).to eq @submission.grade
      end

      it "doesn't return score/grade for students when assignment is muted" do
        expect(submission_type.score(current_user: @student)).to be_nil
        expect(submission_type.grade(current_user: @student)).to be_nil
      end
    end

    context "regular assignment" do
      it "returns the score and grade for authorized users" do
        expect(submission_type.score(current_user: @student)).to eq @submission.score
        expect(submission_type.grade(current_user: @student)).to eq @submission.grade
      end

      it "returns nil for unauthorized users" do
        @student2 = student_in_course(active_all: true).user
        expect(submission_type.score(current_user: @student2)).to be_nil
        expect(submission_type.grade(current_user: @student2)).to be_nil
      end
    end
  end
end
